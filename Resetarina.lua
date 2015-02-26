local KatarinaVersion = 1

AddLoadCallback(function()
 if myHero.charName ~= 'Katarina' then return end
 --Requirements--
 require 'SxOrbWalk'
 --Initialize Katarina Class--
 Katarina()
end)

class 'Katarina'

	function Katarina:__init()

		self.spells = {
			Q = Spells(_Q, 675, 'Bouncing Blades', 'targeted', ARGB(255,17, 0 , 255 )),
			W =	Spells(_W, 375, 'Sinister Steel',  'notarget', ARGB(255,17, 0 , 255 )),
			E =	Spells(_E, 700, 'Shunpo',          'targeted', ARGB(255,17, 0 , 255 )),
			R =	Spells(_R, 550, 'Death Lotus',     'notarget')
		}

		self.Q = {throwing = false, last = 0}
		self.targetsWithQ = {}
   	self.E = {last = 0, delay = 0, canuse = true}
		self.R = {using  = false, last = 0}
		self:Menu()
		self.comp = false
		self.target = nil

		self.enemyMinions   = minionManager(MINION_ENEMY,   self.spells.E:Range(), myHero, MINION_SORT_MAXHEALTH_DEC)
		self.allyMinions    = minionManager(MINION_ALLY,    self.spells.E:Range(), myHero, MINION_SORT_MAXHEALTH_DEC)
		self.jungleMinions  = minionManager(MINION_JUNGLE,  self.spells.E:Range(), myHero, MINION_SORT_MAXHEALTH_DEC)
		self.otherMinions   = minionManager(MINION_OTHER,   self.spells.E:Range(), myHero, MINION_SORT_MAXHEALTH_DEC)
  	_G.myHero.SaveMove = _G.myHero.MoveTo
		_G.myHero.SaveAttack = _G.myHero.Attack
		_G.myHero.MoveTo = function(...) if not self.R.using then _G.myHero.SaveMove(...) end end
		_G.myHero.Attack = function(...) if not self.R.using then _G.myHero.SaveAttack(...) end end
		AddTickCallback(function() self:Tick() end)
		AddDrawCallback(function() self:Draw() end)
		AddMsgCallback(function (msg, key) self:WndMsg(msg, key) end)
		AddProcessSpellCallback(function(unit, spell) self:Spells(unit, spell)	end)
		AddApplyBuffCallback(function(unit, source, buff) self:ApplyBuff(unit, source, buff) end)
		AddRemoveBuffCallback(function(unit, buff) self:RemoveBuff(unit, buff) end)
		AddCastSpellCallback(function(iSpell, startPos, endPos, targetUnit) self:OnCastSpell(iSpell,startPos,endPos,targetUnit) end)

		print("<font color=\"#ff0000\">Resetarino:</font> <font color=\"#00FF55\">Loaded Version: "..KatarinaVersion.."</font>")
	end


	function Katarina:Menu()

		self.menu = scriptConfig('Resetarino', 'Resetarino')
			self.menu:addSubMenu('Skill Settings ', 'skills')
				self.menu.skills:addSubMenu('Q - ['..self.spells.Q.name..']', 'Q')
					self.menu.skills.Q:addParam('autoQ',   'Auto Harass Enemies', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.Q:addParam('comboQ',  'Use Q in Combo',  SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.Q:addParam('harassQ', 'Use Q in Harass', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.Q:addParam('clearQ',  'Use  in Clear ', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.Q:addParam('drawQ',   'Draw Q Range ',   SCRIPT_PARAM_ONOFF, true)
				self.menu.skills:addSubMenu('W - ['..self.spells.W.name..']', 'W')
					self.menu.skills.W:addParam('autoW',   'Auto Harass Enemies', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.W:addParam('comboW',  'Use W in Combo',  SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.W:addParam('harassW', 'Use W in Harass', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.W:addParam('clearW',  'Use W in Clear ', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.W:addParam('drawW',   'Draw W Range ',   SCRIPT_PARAM_ONOFF, true)
				self.menu.skills:addSubMenu('E - ['..self.spells.E.name..']', 'E')
					self.menu.skills.E:addParam('comboE',    'Use E in Combo',  SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.E:addParam('harassE',   'Use E in Harass', SCRIPT_PARAM_ONOFF, false)
					self.menu.skills.E:addParam('clearE',    'Use E in Clear ', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.E:addParam('drawE',     'Draw E Range ',   SCRIPT_PARAM_ONOFF, true)			
					self.menu.skills.E:addParam('humanizer', 'Use Humanizer', SCRIPT_PARAM_ONOFF, false)
					self.menu.skills.E:addParam('maxdelay',  'Max Delay',     SCRIPT_PARAM_SLICE, 1.5, 0, 3, 1)
				self.menu.skills:addSubMenu('R - ['..self.spells.R.name..']', 'R')
					self.menu.skills.R:addParam('stopclick',  'Stop R With Right Click',      SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.R:addParam('stopkill',   'Stop R if I Can Kill Target',  SCRIPT_PARAM_ONOFF, true)
			
			self.menu:addSubMenu('Combo Settings', 'combo')
				self.menu.combo:addParam('procQ',    'Q Mark', SCRIPT_PARAM_ONOFF, true)
			
			self.menu:addSubMenu('Harass Settings', 'harass')
				self.menu.harass:addParam('procQ', 'Q Mark', SCRIPT_PARAM_ONOFF, true)
			
			self.menu:addSubMenu('Orbwalk Settings', 'orbwalk')
				SxOrb:LoadToMenu(self.menu.orbwalk, true)
				SxOrb:RegisterHotKey('fight',     self.menu, 'comboKey')
				SxOrb:RegisterHotKey('harass',    self.menu, 'harassKey')
				SxOrb:RegisterHotKey('laneclear', self.menu, 'clearKey')
				SxOrb:RegisterHotKey('lasthit',   self.menu, 'lasthitKey')
				self.menu:addSubMenu('Ks Settings', 'killsteal')
			self.menu:addSubMenu('Farming Settings', 'farming')
				self.menu.farming:addParam('farmQToggle', 'Farm With Q',     SCRIPT_PARAM_ONKEYTOGGLE , false, GetKey('Z'))
				self.menu.farming:addParam('farmQLast',   'LastHit With Q', SCRIPT_PARAM_ONOFF, true)
				self.menu.farming:addParam('farmWToggle', 'Farm With W',     SCRIPT_PARAM_ONOFF, true)
			self.menu:addSubMenu('Other Settings', 'other')
				self.menu.other:addParam('drawText', 'Draw Damage Text on Enemy', SCRIPT_PARAM_ONOFF, true)
			self.menu:addParam('comboKey',    'Full Combo Key', SCRIPT_PARAM_ONKEYDOWN, false, 32)
			self.menu:addParam('harassKey',   'Harass Key',     SCRIPT_PARAM_ONKEYDOWN, false, GetKey('t'))
			self.menu:addParam('clearKey',    'Clear Key',      SCRIPT_PARAM_ONKEYDOWN, false, GetKey('v'))
			self.menu:addParam('lasthitKey',  'Last Hit Key',   SCRIPT_PARAM_ONKEYDOWN, false, GetKey('x'))
			

			self.ts = TargetSelector(TARGET_LESS_CAST, self.spells.E.range, DAMAGE_MAGIC, true)
			self.ts.name = 'Katarina'
			self.menu:addTS(self.ts)
			self:LoadPriorityTable()
			self:SetTablePriorities()
	end

	function Katarina:Tick()
		self.target = self:GetTarget()
		if self.target  and not self.using then
			if self.menu.comboKey then
				self:Combo(self.target)
			elseif self.menu.harassKey then
				self:Harass(self.target)
			end
			if self.menu.skills.Q.autoQ then
				self.spells.Q:Cast(self.target)
			end
			if self.menu.skills.W.autoW then
				self.spells.W:Cast(self.target)
			end
		end
		if self.menu.clearKey then
			self:Clear()
		end
		if self.menu.killsteal.killswitch then
			self:KillSteal()
		end
		if not self.menu.comboKey then 
			self:Farm()
		end
		if self.Q.throwing then
			if (os.clock() - self.Q.last) > 0.5 then
				self.Q.throwing = false
			end
		end
		if self.R.using then
			if (os.clock() - self.R.last) > 2.5 then
				self.R.using = false
				self.R.last  = 0
			end
		end
		if not self.E.canuse then
			if (os.clock() - self.E.last) > self.E.delay then
				self.E.canuse = true
			end
		end
		if not self.comp then
			if _G.AutoCarry then
				print("<font color=\"#00FFF7\">Resetarino:</font> <font color=\"#00FFF7\">Found SAC Disabling SxOrb</font>")
				if self.menu.orbwalk.General.Enabled and self.menu.orbwalk.General.Enabled == true then
			 		self.menu.orbwalk.General.Enabled = true
			 	end
				self.comp = true
			 elseif _G.MMA_Loaded then
			 	print("<font color=\"#00FFF7\">Resetarino:</font> <font color=\"#00FFF7\">Found MMA Disabling SxOrb</font>")
			 	if self.menu.orbwalk.General.Enabled and self.menu.orbwalk.General.Enabled == true then
			 		self.menu.orbwalk.General.Enabled = true
			 	end
			 	self.comp = true
			 end
		end
	end

	function Katarina:random(min, max, precision)
   		local precision = precision or 0
   		local num = math.random()
   		local range = math.abs(max - min)
   		local offset = range * num
   		local randomnum = min + offset
   		return math.floor(randomnum * math.pow(10, precision) + 0.5) / math.pow(10, precision)
	end

	function Katarina:Draw()
		if self.menu.skills.Q.drawQ and self.spells.Q:Ready() then
			self:DrawCircle(myHero.x, myHero.y, myHero.z, self.spells.Q:Range(), self.spells.Q:Color())
		end
		if self.menu.skills.W.drawW and self.spells.W:Ready() then
			self:DrawCircle(myHero.x, myHero.y, myHero.z, self.spells.W:Range(), self.spells.W:Color())
		end
		if self.menu.skills.E.drawE and self.spells.E:Ready() then
			self:DrawCircle(myHero.x, myHero.y, myHero.z, self.spells.E:Range(), self.spells.E:Color())
		end
		if self.menu.other.drawText then
			for i, enemy in ipairs(GetEnemyHeroes()) do
				if ValidTarget(enemy) then
					local pos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
					local enemyText, color =  self:GetDrawText(enemy)
					if enemyText ~= nil then
						DrawText(enemyText, 15, pos.x, pos.y, color)
					end
				end
			end
		end
	end

	function Katarina:GetDrawText(unit)
		local DmgTable = { Q = self.spells.Q:Damage(unit), W = self.spells.W:Damage(unit), E = self.spells.E:Damage(unit), R = self.spells.R:Damage(unit)}
		local ExtraDmg = 0
		if DmgTable.W > unit.health then
			return 'W', RGBA(139, 0, 0, 255)
		elseif DmgTable.Q > unit.health then
			return 'Q', RGBA(139, 0, 0, 255)
		elseif DmgTable.E > unit.health then
			return 'E', Graphics.RGBA(139, 0, 0, 255)
		elseif DmgTable.Q + DmgTable.W > unit.health then
			return 'W + Q', RGBA(139, 0, 0, 255)
		elseif DmgTable.E + DmgTable.W > unit.health then
			return 'E + W', Graphics.RGBA(139, 0, 0, 255)
		elseif DmgTable.Q + DmgTable.W + DmgTable.E > unit.health then
			return 'Q + W + E', RGBA(255, 0, 0, 255)
		elseif DmgTable.Q + self:QBuffDmg(unit) + DmgTable.W + DmgTable.E > unit.health then
			return '(Q + Passive) + W +E', RGBA(255, 0, 0, 255)
		elseif ExtraDmg > 0 and ExtraDmg + DmgTable.Q + self:QBuffDmg(unit) + DmgTable.W + DmgTable.E > unit.health then
			return 'Q + W + E + Ult ('.. string.format('%4.1f', (unit.health -  DmgTable.Q + DmgTable.W + DmgTable.E) * (1/(DmgTable.R*10))) .. ' Secs)', RGBA(255, 69, 0, 255)
		else
			return 'Cant Kill Yet', RGBA(0, 255, 0, 255)
		end
	end

	function Katarina:Combo(target)
		if self.menu.skills.Q.comboQ then
			self.spells.Q:Cast(target)
		end
		if self.menu.skills.W.comboW then
			self.spells.W:Cast(target)
		end
		if not self.spells.Q:Ready() and self.menu.skills.E.comboE then
			if self.menu.combo.procQ then
				if not self.Q.throwing then
					self.spells.E:Cast(target)
				end
			else
				self.spells.E:Cast(target)
			end
		end
		if not self.spells.Q:Ready() and not self.spells.W:Ready() and not self.spells.E:Ready() then
			self.spells.R:Cast(target)
		end
	end

	function Katarina:Harass(target)
		if self.menu.skills.Q.harassQ then
			self.spells.Q:Cast(target)
		end
		if self.menu.skills.W.harassW then
			self.spells.W:Cast(target)
		end
		if not self.spells.Q:Ready() and self.menu.skills.E.harassE then
			if self.menu.harass.procQ then
				if not self.Q.throwing then
					self.spells.E:Cast(target)
				end
			else
				self.spells.Q:Cast(target)
			end
		end
	end

	function Katarina:Farm()
		self.enemyMinions:update()
		for i, minion in ipairs(self.enemyMinions.objects) do
			if self.menu.farming.farmWToggle then
				if ValidTarget(minion) and minion.health <= self.spells.W:Damage(minion) then
					self.spells.W:Cast(minion)
				end
			end
			if self.menu.farming.farmQToggle or (self.menu.farming.farmQLast and self.menu.lasthitKey) then
				if ValidTarget(minion) and minion.health <= self.spells.Q:Damage(minion) then
					self.spells.Q:Cast(minion)
				end
			end
		end
	end

	function Katarina:Clear()
		local cleartarget = nil
		self.enemyMinions:update()
		self.otherMinions:update()
		self.jungleMinions:update()
		for i, minion in ipairs(self.enemyMinions.objects) do
			if ValidTarget(minion, 600) and (cleartarget == nil or not ValidTarget(cleartarget)) then
				cleartarget = minion
			end
		end
		for i, jungleminion in ipairs(self.jungleMinions.objects) do
			if ValidTarget(jungleminion, 600) and (cleartarget == nil or not ValidTarget(cleartarget)) then
				cleartarget = jungleminion
			end
		end
		for i, otherminion in ipairs(self.otherMinions.objects) do
			if ValidTarget(otherminion, 600) and (cleartarget == nil or not ValidTarget(cleartarget)) then
				cleartarget = otherminion
			end
		end
		if cleartarget ~= nil then
			if self.menu.skills.Q.clearQ then
				self.spells.Q:Cast(cleartarget)
			end
			if self.menu.skills.W.clearW then
				self.spells.W:Cast(cleartarget)
			end
			if self.menu.skills.E.clearE then
				self.spells.E:Cast(cleartarget)
			end
		end
	end

	function Katarina:KillSteal()
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, 700) then
				local DmgTable = { Q = self.spells.Q:Ready() and self.spells.Q:Damage(enemy) or 0, W = self.spells.W:Ready() and self.spells.W:Damage(enemy) or 0, E = self.spells.E:Ready() and self.spells.E:Damage(enemy) or 0}
				local ExtraDmg = 0
				if self.targetsWithQ[enemy.networkID] ~= nil then
					ExtraDmg = ExtraDmg + self:QBuffDmg(enemy)
				end
				if DmgTable.W > enemy.health + ExtraDmg then
					self.spells.W:Cast(enemy)
				elseif DmgTable.Q > enemy.health + ExtraDmg then
					self.spells.Q:Cast(enemy)
				elseif DmgTable.E > enemy.health + ExtraDmg then
					self.spells.E:Cast(enemy)
				elseif DmgTable.Q + DmgTable.W > enemy.health and GetDistance(enemy) <= self.spells.W:Range() + ExtraDmg then
					self.spells.W:Cast(enemy)
					self.spells.Q:Cast(enemy)
				elseif DmgTable.E + DmgTable.W > enemy.health + ExtraDmg then
					self.spells.E:Cast(enemy)
					self.spells.W:Cast(enemy)
				elseif DmgTable.Q + DmgTable.W + DmgTable.E > enemy.health + ExtraDmg then
					self.spells.E:Cast(enemy)
					self.spells.Q:Cast(enemy)
					self.spells.W:Cast(enemy)
				end
			elseif  self.menu.killsteal.wards and ValidTarget(enemy, self.spells.Q:Range() + 590) and (GetDistance(enemy) > self.spells.Q:Range()) then
				local ExtraDmg = 0
			 	if enemy.health <= (self.spells.Q:Damage(enemy) + ExtraDmg) then
						self.spells.Q:Cast(enemy)
					end
				end
			end
		end

	function Katarina:QBuffDmg(unit)
		return getDmg('Q', unit, myHero, 2) or 0
	end

	function Katarina:MaxDmg(unit)
		local DmgTable = { Q = self.spells.Q:Ready() and self.spells.Q:Damage(unit) or 0, W = self.spells.W:Ready() and self.spells.W:Damage(unit) or 0, E = self.spells.E:Ready() and self.spells.E:Damage(unit) or 0}
		local ExtraDmg = 0
		if self.targetsWithQ[unit.networkID] ~= nil then
			ExtraDmg = ExtraDmg + self:QBuffDmg(unit)
		end
		return DmgTable.Q + DmgTable.W + DmgTable.E + ExtraDmg
	end

	function Katarina:OtherMovements(bool)
		if _G.AutoCarry then
			if _G.AutoCarry.MainMenu ~= nil then
				if _G.AutoCarry.CanAttack ~= nil then
					_G.AutoCarry.CanAttack = bool
					_G.AutoCarry.CanMove = bool
				end
			elseif _G.AutoCarry.Keys ~= nil then
					if _G.AutoCarry.MyHero ~= nil then
					_G.AutoCarry.MyHero:MovementEnabled(bool)
					_G.AutoCarry.MyHero:AttacksEnabled(bool)
				end
			end
		elseif _G.MMA_Loaded then
			_G.MMA_Orbwalker	= bool
			_G.MMA_HybridMode	= bool
			_G.MMA_LaneClear	= bool
			_G.MMA_LastHit		= bool
		end
	end

	function Katarina:DrawCircle(x, y, z, radius, color)
		local vPos1 = Vector(x, y, z)
		local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
		local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
		local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
		
		if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
			self:DrawCircleNextLvl(x, y, z, radius, 1, color, 300) 
		end
	end

	function Katarina:DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
		radius = radius or 300
		quality = math.max(8, self:Round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
		quality = 2 * math.pi / quality
		radius = radius * .92
		local points = {}
		
		for theta = 0, 2 * math.pi + quality, quality do
			local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
			points[#points + 1] = D3DXVECTOR2(c.x, c.y)
		end
		DrawLines2(points, width or 1, color or 4294967295)
	end

	function Katarina:Round(number)
		if number >= 0 then 
			return math.floor(number+.5) 
		else 
			return math.ceil(number-.5) 
		end
	end
	
	function Katarina:WndMsg(msg, key)
		if self.menu.skills.R.stopclick then
			if msg == WM_RBUTTONDOWN and self.R.using then 
				self.R.using = false
			end
		end
	end

	function Katarina:OnCastSpell(iSpell,startPos,endPos,targetUnit)
		if iSpell == 3 then
			self.R.using = true
			self.R.last  = os.clock()
		end
	end



	function Katarina:ApplyBuff(unit, source,  buff)
		if unit == myHero and buff.name == 'katarinaqmark' then
			self.targetsWithQ[source.networkID] = true
			if self.Q.throwing then
				self.Q.throwing = false
			end
		end
	end

	function Katarina:RemoveBuff(unit, buff)
		if buff.name == 'katarinaqmark' then
			self.targetsWithQ[unit.networkID] = nil
		end
		if unit.isMe and buff.name == "katarinarsound" then
			self.R.using = false
			self.R.last  = 0
		end
	end

	function Katarina:Spells(unit, spell)
		if unit.isMe then
			if spell.name == 'KatarinaQ' then
				self.Q.throwing = true
				self.Q.last     = os.clock()
			elseif  self.menu.skills.E.humanizer and spell.name == 'KatarinaE' then
				self.E.last   = os.clock()
				self.E.delay  = self:random(0, self.menu.skills.E.maxdelay, 2)
				self.E.canuse = false
			end
		end
	end

	function Katarina:GetTarget()
		self.ts:update()
        if _G.MMA_Target and _G.MMA_Target.type == myHero.type then 
        	return _G.MMA_Target 
	    elseif _G.AutoCarry and  _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then 
	    	return _G.AutoCarry.Attack_Crosshair.target 
	    elseif self.ts.target and ValidTarget(self.ts.target) then
	    	return self.ts.target
	    end
	end

	function Katarina:LoadPriorityTable()
		self.priorityTable = {
			AP = {
				'Annie', 'Ahri', 'Akali', 'Anivia', 'Annie', 'Azir', 'Brand', 'Cassiopeia', 'Diana', 'Evelynn', 'FiddleSticks', 'Fizz', 'Gragas', 'Heimerdinger', 'Karthus',
				'Kassadin', 'Katarina', 'Kayle', 'Kennen', 'Leblanc', 'Lissandra', 'Lux', 'Malzahar', 'Mordekaiser', 'Morgana', 'Nidalee', 'Orianna',
				'Ryze', 'Sion', 'Swain', 'Syndra', 'Teemo', 'TwistedFate', 'Veigar', 'Viktor', 'Vladimir', 'Xerath', 'Ziggs', 'Zyra'
			},
			Support = {
				'Alistar', 'Blitzcrank', 'Braum', 'Janna', 'Karma', 'Leona', 'Lulu', 'Nami', 'Nunu', 'Sona', 'Soraka', 'Taric', 'Thresh', 'Zilean'
			},
			Tank = {
				'Amumu', 'Chogath', 'DrMundo', 'Galio', 'Hecarim', 'Malphite', 'Maokai', 'Nasus', 'Rammus', 'Sejuani', 'Nautilus', 'Shen', 'Singed', 'Skarner', 'Volibear',
				'Warwick', 'Yorick', 'Zac'
			},
			AD_Carry = {
				'Ashe', 'Caitlyn', 'Corki', 'Draven', 'Ezreal', 'Graves', 'Jayce', 'Jinx', 'Kalista', 'KogMaw', 'Lucian', 'MasterYi', 'MissFortune', 'Pantheon', 'Quinn', 'Shaco', 'Sivir',
				'Talon','Tryndamere', 'Tristana', 'Twitch', 'Urgot', 'Varus', 'Vayne', 'Yasuo','Zed'
			},
			Bruiser = {
				'Aatrox', 'Darius', 'Elise', 'Fiora', 'Gnar', 'Gangplank', 'Garen', 'Irelia', 'JarvanIV', 'Jax', 'Khazix', 'LeeSin', 'Nocturne', 'Olaf', 'Poppy',
				'Renekton', 'Rengar', 'Riven', 'RekSai', 'Rumble', 'Shyvana', 'Trundle', 'Udyr', 'Vi', 'MonkeyKing', 'XinZhao'
			}
		}
	end


	function Katarina:SetTablePriorities()
		local table = GetEnemyHeroes()
		if #table == 5 then
			for i, enemy in ipairs(table) do
				self:SetPriority(self.priorityTable.AD_Carry, enemy, 1)
				self:SetPriority(self.priorityTable.AP, enemy, 2)
				self:SetPriority(self.priorityTable.Support, enemy, 3)
				self:SetPriority(self.priorityTable.Bruiser, enemy, 4)
				self:SetPriority(self.priorityTable.Tank, enemy, 5)
			end
		elseif #table == 3 then
			for i, enemy in ipairs(table) do
				self:SetPriority(self.priorityTable.AD_Carry, enemy, 1)
				self:SetPriority(self.priorityTable.AP, enemy, 1)
				self:SetPriority(self.priorityTable.Support, enemy, 2)
				self:SetPriority(self.priorityTable.Bruiser, enemy, 2)
				self:SetPriority(self.priorityTable.Tank, enemy, 3)
			end
		else
			print('Not Enough Champions To Set Priority!')
		end
	end

	function Katarina:SetPriority(table, hero, priority)
		for i = 1, #table do
			if hero.charName:find(table[i]) ~= nil then
				TS_SetHeroPriority(priority, hero.charName)
			end
		end
	end

class 'Spells'

	function Spells:__init(slot, range, name, type, color)
		self.slot   = slot
		self.range  = range
		self.name   = name
		self.type   = type
		self.string = self:SlotToString(slot)
		self.color  = color
	end

	function Spells:Cast(unit)
		if self:Ready() and GetDistance(unit) <= self.range then
			if self.type == 'targeted' then
				CastSpell(self.slot, unit)
			else
				CastSpell(self.slot)
			end
		end
	end

	function Spells:Color()
		return self.color
	end

	function Spells:Damage(target)
		return getDmg(self.string, target, myHero) or 0
	end

	function Spells:Data()
		return myHero:GetSpellData(self.slot)
	end

	function Spells:Range()
		return self.range
	end

	function Spells:Ready()
		return myHero:CanUseSpell(self.slot) == READY
	end

	function Spells:Ready2()
		return self:Data().level > 0 and self:Data().currentCd == 0
	end

	function Spells:Slot()
		return self.slot
	end

	function Spells:SlotToString(slot)
		local strings = { [_Q] = 'Q', [_W] = 'W', [_E] = 'E', [_R] = 'R'}
		return strings[slot]
	end
	
	
	
		local Version = 1
	local ServerResult = GetWebResult("raw.github.com","/BrynnClarke/BrynnClarkeRepo/blob/master/Resetarina.lua")
	print(ServerResult)
	if ServerResult then
		ServerVersion = tonumber(ServerResult)
		if Version < ServerVersion then
			print("A new version is available: v"..KatarinaVersion..". Attempting to download now.")
			DelayAction(function() DownloadFile("https://github.com/BrynnClarke/BrynnClarkeRepo/blob/master/Resetarina.lua".."?rand"..math.random(1,9999), SCRIPT_PATH.."Restarina.lua", function() print("Successfully downloaded the latest version: v"..KatarinaVersion..".") end) end, 2)
		else
			print("You are running the latest version: v"..Version..".")
		end
	else
		print("Error finding server version.")
	end
