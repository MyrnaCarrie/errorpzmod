if isServer() then return end

if not IPPJModCheck then
	Events.OnPlayerUpdate.Add(function()
		local count = 2
		if IPPJGFError then			count = count + 2
		elseif IPPJModError then	count = count + 1
		end
		for i = 5, count, -1 do
			getPlayer():Say("--------")
		end
		getPlayer():Say(getText("[Improved Projectile]"))
		getPlayer():Say(getText("IGUI_IPPJModCheck"))
		if IPPJGFError then
			getPlayer():Say(getText("IGUI_IPPJGFError1"))
			getPlayer():Say(getText("IGUI_IPPJGFError2"))
		end
		if IPPJModError then
			getPlayer():Say(getText("IGUI_IPPJModError"))
		end
	end)
	return
end

local AddonCheck = getActivatedMods():contains("ImprovedProjectileAddon")

--require "luautils"
--require "ImprovedProjectile_options"

ImprovedProjectile = {}
ImprovedProjectile.isValid = false
ImprovedProjectile.currInfo = {}
ImprovedProjectile.Strength = 0
ImprovedProjectile.Aiming = 0
ImprovedProjectile.Nimble = 0
ImprovedProjectile.activeProjectiles = {}
ImprovedProjectile.projId = 0
ImprovedProjectile.aimSize = 100
ImprovedProjectile.actualMinAim = 0

ImprovedProjectile.crossHair = {}
ImprovedProjectile.crossHair.instance = nil
ImprovedProjectile.visualRecoil = {0, 0, 0, 0, 0}
ImprovedProjectile.doSneezeCough = {false, false}

ImprovedProjectile.gameTimeMult = 0.3
ImprovedProjectile.blockVehicleShoot = false
ImprovedProjectile.isOutOfRange = false

ImprovedProjectile.accZombie = {nil, nil, nil}
ImprovedProjectile.accPVP = {nil, nil, nil}

local zombieHighReact		= {"HeadLeft", "HeadRight", "Uppercut"}
local zombieMidReact		= {"ShotBelly", "ShotChestL", "ShotChestR"}
local zombieMidReactCrit	= {"ShotBellyStep", "ShotChestStepL", "ShotChestStepR"}
local zombieLowReact		= {"ShotLegL", "ShotLegR"}

--*************************************************************************************--
--** Information texts
--*************************************************************************************--
ImprovedProjectile.hitX = {0, TextDrawObject.new(), 1.0}

local aimOffOption = 0
IPPJAimOff = 0
local aimOffText = TextDrawObject.new()
aimOffText:setDefaultColors(1, 1, 1)
aimOffText:setOutlineColors(0, 0, 0, 1)
aimOffText:setAllowAnyImage(true)
aimOffText:setHorizontalAlign("left")

ImprovedProjectile.aimHeightOff = 0
ImprovedProjectile.aimLyingOff = 0

IPPJAmmoCount = 0
local aimAmmoText = TextDrawObject.new()
aimAmmoText:setDefaultColors(1, 1, 1)
aimAmmoText:setOutlineColors(0, 0, 0, 1)
aimAmmoText:setAllowAnyImage(true)
aimAmmoText:setHorizontalAlign("left")

local cannotText = {TextDrawObject.new(), TextDrawObject.new()}
cannotText[1]:setDefaultColors(1, 1, 1)
cannotText[1]:setOutlineColors(1, 0.3, 0.3, 1)
cannotText[1]:ReadString(UIFont.Small, getText("IGUI_IPPJOutofRange"), -1)
cannotText[2]:setDefaultColors(1, 1, 1)
cannotText[2]:setOutlineColors(1, 0.3, 0.3, 1)
cannotText[2]:ReadString(UIFont.Small, getText("IGUI_IPPJOutofAngle"), -1)

local ZOOM = getCore():getZoom(0)

--*************************************************************************************--
--** Key bindings and onKeyPressed function
--*************************************************************************************--
local bind = {}
bind.value = "[Improved Projectile]"
table.insert(keyBinding, bind)

bind = {}
bind.value = "IPPJ_AimLevel"
bind.key = Keyboard.KEY_LSHIFT
table.insert(keyBinding, bind)

bind = {}
bind.value = "IPPJ_ToogleReset"
bind.key = Keyboard.KEY_NONE
table.insert(keyBinding, bind)

IPPJzoomScroll = 0
local aimSetting = {"", false, false, 0, 0.5, 0}
local function onKeyKeepPressed(key)
	if key ~= getCore():getKey("IPPJ_AimLevel") then return end
	local player = getPlayer()
	if Mouse.getWheelState() > 0 then
		if player:isAiming() and ImprovedProjectile.isValid then
			IPPJzoomScroll = 1
			if aimOffOption + player:getZ() < 7 then
				--IPPJzoomScroll = 1
				--getCore():doZoomScroll(0, 1)
				aimOffOption = aimOffOption + 1
				return
			end
		end
	elseif Mouse.getWheelState() < 0 then
		if player:isAiming() and ImprovedProjectile.isValid then
			IPPJzoomScroll = -1
			if aimOffOption + player:getZ() > 0 then
				--IPPJzoomScroll = -1
				--getCore():doZoomScroll(0, -1)
				aimOffOption = aimOffOption - 1
				return
			end
		end
	elseif Mouse.isMiddlePressed() then
		if player:isAiming() and ImprovedProjectile.isValid then
			aimOffOption = 0
			aimSetting[4] = 0
			aimSetting[5] = 0.5
			aimSetting[6] = 0
			return
		end
	end
end

local function onKeyPressed(key)
	if key == getCore():getKey("IPPJ_ToogleReset") then
		IPPJSettings.ResetLevel = not IPPJSettings.ResetLevel
		if IPPJSettings.ResetLevel then
			getPlayer():addLineChatElement("[ RESET ON ]", 1.0, 1.0, 0.7, UIFont.Small, 10.0, "default")
		else
			getPlayer():addLineChatElement("[ RESET OFF ]", 1.0, 1.0, 0.7, UIFont.Small, 10.0, "default")
		end
	end
end

--*************************************************************************************--
--** Create new table
--*************************************************************************************--
function ImprovedProjectile.createInfoTable(infoTable)
	local infoTableNew = {}

	for i, v in pairs(infoTable) do
		if type(v) == "table" then
			infoTableNew[i] = {}
			for j, w in pairs(v) do
				infoTableNew[i][j] = w
			end
		else
			infoTableNew[i] = v
		end
	end
	return infoTableNew
end

--*************************************************************************************--
--** Create new table for server
--*************************************************************************************--
local function createInfoTableServer(infoTable)
	local infoTableNew = {
		nil,								-- [1]
		infoTable[2],						-- [2]
		nil,								-- [3]
		{infoTable[10][2],					-- [4] [1]
		infoTable[10][3]},					-- [4] [2]
		{infoTable[7][1],					-- [5] [1]
		infoTable[7][2],					-- [5] [2]
		infoTable[7][3]},					-- [5] [3]
		infoTable[9],						-- [6]
		infoTable[10][1],					-- [7]
		infoTable[16],						-- [8]
		infoTable[22],						-- [9]
		infoTable[23],						-- [10]
		ImprovedProjectile.gameTimeMult		-- [11]
	}
	return infoTableNew
end

--*************************************************************************************--
--** Create projectile at square
--*************************************************************************************--
function ImprovedProjectile.createProjectile(square, projName, angle, coord, item)
	if square:getZ() > 7 then return end
	local xOff, yOff, zOff = coord[1] - math.floor(coord[1]), coord[2] - math.floor(coord[2]), coord[3] - math.floor(coord[3])
	local invItem	= item or InventoryItemFactory.CreateItem(projName)
	local worldItem = IsoWorldInventoryObject.new(invItem, square, xOff, yOff, zOff)
	invItem:setWorldItem(worldItem)
	square:getWorldObjects():add(worldItem)
	square:getObjects():add(worldItem)
	local chunk = square:getChunk()	-- ?
	if chunk then 
		chunk:recalcHashCodeObjects()
	else
		return
	end

	invItem:setWorldZRotation(angle)
	return invItem
end

--*************************************************************************************--
--** Remove projectile from square
--*************************************************************************************--
function ImprovedProjectile.removeProjectile(proj)
	if not (proj and proj:getWorldItem()) then return end
	proj:getWorldItem():removeFromWorld()
	proj:getWorldItem():removeFromSquare()
	--proj:getWorldItem():setSquare(nil)
end

--*************************************************************************************--
--** Update player moodles
--*************************************************************************************--
ImprovedProjectile.moodleStats = {1, 1, 0, 0}
ImprovedProjectile.panicAim = 0
local playerUpdateDelay = 20
function ImprovedProjectile:updateMoodle(player)
	self.panicAim = 6 * player:getMoodleLevel(MoodleType.Panic)
	if SandboxVars.ImprovedProjectile.IPPJMoodleEffectHC then
		if player:isAiming() then
			local currMoodles = {0, 0, 0, 0}
			currMoodles[1] = player:getMoodleLevel(MoodleType.Tired) * SandboxVars.ImprovedProjectile.IPPJTiredAimingTimeLvl * 0.01
			currMoodles[2] = player:getMoodleLevel(MoodleType.Tired) * SandboxVars.ImprovedProjectile.IPPJTiredRecoilLvl * 0.01
			currMoodles[3] = player:getMoodleLevel(MoodleType.Endurance) * SandboxVars.ImprovedProjectile.IPPJEnduranceRecoilLvl * 0.01
			currMoodles[4] = player:getMoodleLevel(MoodleType.FoodEaten) * SandboxVars.ImprovedProjectile.IPPJFoodEatenRecoilLvl * 0.01

			local prevPanicAim = self.moodleStats[4]
			self.moodleStats[1] = 1 - currMoodles[1]											-- Aimingtime
			self.moodleStats[2] = 1 + currMoodles[2] + currMoodles[3] - currMoodles[4]			-- Recoil
			local reliefDrunkMiss = SandboxVars.ImprovedProjectile.IPPJDrunkMissChanceLvl * self.Aiming
			self.moodleStats[3] = math.max(SandboxVars.ImprovedProjectile.IPPJDrunkMissChance * player:getMoodleLevel(MoodleType.Drunk) - reliefDrunkMiss, 0)
			local rand = ZombRandFloat(0, 1)
			local reliefPanicAim = math.max(1 - SandboxVars.ImprovedProjectile.IPPJPanicAimMinMultLvl * 0.01 * self.Aiming, 0)
			self.moodleStats[4] = SandboxVars.ImprovedProjectile.IPPJPanicAimMinMult * self.panicAim * (1.2 * rand^4 + 0.8) * reliefPanicAim
			if prevPanicAim > self.moodleStats[4] then
				self.aimSize = self.aimSize - 0.5 * (prevPanicAim - self.moodleStats[4])
			end
		end
		--[[
		local currMoodles = {0, 0, 0, 0}
		currMoodles[1] = player:getMoodleLevel(MoodleType.Tired) * 0.1 -- player:getMoodleLevel(MoodleType.Tired) * SandboxVars.ImprovedProjectile.IPPJTiredAimingTimeLvl * 0.01
		currMoodles[2] = player:getMoodleLevel(MoodleType.Endurance) * 0.06 -- player:getMoodleLevel(MoodleType.Tired) * 
		currMoodles[3] = player:getMoodleLevel(MoodleType.FoodEaten) * 0.05

		self.moodleStats[1] = 1 - currMoodles[1]											-- Aimingtime
		self.moodleStats[2] = 1 + (currMoodles[1] * 0.5) + currMoodles[2] - currMoodles[3]	-- Recoil
		self.moodleStats[3] = 2 * player:getMoodleLevel(MoodleType.Drunk)^2
		--self.moodleStats[4] = self.panicAim * ZombRandFloat(0.8, 1.4)						-- Aim min size
		local rand = ZombRandFloat(0, 1)
		self.moodleStats[4] = self.panicAim * (1.7 * rand^4 + 0.8)
		]]
	else
		self.moodleStats = {1, 1, 0, 0}
	end
end

local isCrouch = false
local isCrawl = false
local function onPlayerUpdate(player)
	if IPPJzoomScroll ~= 0 then
		if IPPJzoomScroll == -1 and ZOOM ~= getCore():getMaxZoom() then
			getCore():doZoomScroll(0, IPPJzoomScroll)
		elseif IPPJzoomScroll == 1 and ZOOM ~= getCore():getMinZoom() then
			getCore():doZoomScroll(0, IPPJzoomScroll)
		end
		IPPJzoomScroll = 0
	end

	if player:isLocalPlayer() then
		if player:isAiming() and ImprovedProjectile.isValid then
			local isCrouchNow = player:getVariableBoolean("IsCrouchAim")
			local isCrawlNow = player:getVariableBoolean("isCrawling")
			if isCrawlNow ~= isCrawl then
				ImprovedProjectile.aimSize = ImprovedProjectile.aimSize + 60
			elseif not (isCrouch or isCrawlNow) and isCrouchNow ~= isCrouch then
				if ImprovedProjectile.aimSize > ImprovedProjectile.currInfo["aimSizeMin"] + ImprovedProjectile.actualMinAim then
					ImprovedProjectile.aimSize = ImprovedProjectile.aimSize + SandboxVars.ImprovedProjectile.IPPJCrouchPenalty
				else
					ImprovedProjectile.aimSize = ImprovedProjectile.aimSize + SandboxVars.ImprovedProjectile.IPPJCrouchPenalty * 0.5
				end
			end
			isCrouch = isCrouchNow
			isCrawl = isCrawlNow
		end

		if playerUpdateDelay > 0 then
			playerUpdateDelay = playerUpdateDelay - 1
			return
		end

		if ImprovedProjectile.isValid then
			ImprovedProjectile:updateMoodle(player)
		end
		playerUpdateDelay = 12
	end
end

--*************************************************************************************--
--** Check zombies and players arround projectile
--*************************************************************************************--
function IPPJcheckTarget(player, coord, cosT, sinT, speed, projId, hitbox, pvp)
	local zombieTable	= {}
	local playerTable	= {}
	local hitBoxX		= speed
	local playerFaction	= Faction.getPlayerFaction(player)
	local x = {}
	local y = {}

	if speed > 1 then
		x = {coord[1] - 2, coord[1] - 1, coord[1], coord[1] + 1, coord[1] + 2}
		y = {coord[2] - 2, coord[2] - 1, coord[2], coord[2] + 1, coord[2] + 2}
	else
		x = {coord[1] - 1, coord[1], coord[1] + 1}
		y = {coord[2] - 1, coord[2], coord[2] + 1}
	end
	local z = math.floor(coord[3])

	for ix, vx in pairs(x) do
		for jy, vy in pairs(y) do
			local sq = getCell():getOrCreateGridSquare(vx, vy, z)
			if sq:TreatAsSolidFloor() then
				local objects = sq:getMovingObjects()
				for i = 1, objects:size() do
					local movingObject = objects:get(i - 1)
					if instanceof(movingObject, "IsoZombie") and movingObject:isAlive() and (not movingObject:getModData().IPPJHitBy or movingObject:getModData().IPPJHitBy ~= projId) then
						table.insert(zombieTable, movingObject)
					elseif instanceof(movingObject,"IsoPlayer") and movingObject ~= player then
						-- Multiplayer PVP
						if isClient() then
							if pvp[4] and (pvp[5] or (pvp[2] and not movingObject:getSafety():isEnabled()) or (getServerOptions():getBoolean("PVP") and not getServerOptions():getBoolean("SafetySystem"))) then
								if not (SandboxVars.ImprovedProjectile.IPPJEnableNonPVPZone and NonPvpZone.getNonPvpZone(vx, vy)) then
									local targetFaction = Faction.getPlayerFaction(movingObject)
									if targetFaction and playerFaction and playerFaction == targetFaction then
										if SandboxVars.ImprovedProjectile.IPPJIgnoreFactionPVP or (pvp[3] and movingObject:isFactionPvp()) then
											table.insert(playerTable, movingObject)
										end
									else
										table.insert(playerTable, movingObject)
									end
								end
							end
						-- Singleplayer NPC Mods
						else
							if pvp[1] then
								table.insert(playerTable, movingObject)
							elseif movingObject:getModData().isHostile or movingObject:getModData().semiHostile then
								table.insert(playerTable, movingObject)
							end
						end
					end
				end
			else
				local sqb = getCell():getOrCreateGridSquare(vx, vy, z - 1)
				if sqb:TreatAsSolidFloor() then
					local objects = sqb:getMovingObjects()
					for i = 1, objects:size() do
						local movingObject = objects:get(i - 1)
						if coord[3] - movingObject:getZ() < 0.8 then
							if instanceof(movingObject, "IsoZombie") and movingObject:isAlive() and (not movingObject:getModData().IPPJHitBy or movingObject:getModData().IPPJHitBy ~= projId) then
								table.insert(zombieTable, movingObject)
							elseif instanceof(movingObject,"IsoPlayer") and movingObject ~= player then
								-- Multiplayer PVP
								if isClient() then
									if pvp[4] and (pvp[5] or (pvp[2] and not movingObject:getSafety():isEnabled()) or (getServerOptions():getBoolean("PVP") and not getServerOptions():getBoolean("SafetySystem"))) then
										if not (SandboxVars.ImprovedProjectile.IPPJEnableNonPVPZone and NonPvpZone.getNonPvpZone(vx, vy)) then
											local targetFaction = Faction.getPlayerFaction(movingObject)
											if targetFaction and playerFaction and playerFaction == targetFaction then
												if SandboxVars.ImprovedProjectile.IPPJIgnoreFactionPVP or (pvp[3] and movingObject:isFactionPvp()) then
													table.insert(playerTable, movingObject)
												end
											else
												table.insert(playerTable, movingObject)
											end
										end
									end
								-- Singleplayer NPC Mods
								else
									if pvp[1] then
										table.insert(playerTable, movingObject)
									elseif movingObject:getModData().isHostile or movingObject:getModData().semiHostile then
										table.insert(playerTable, movingObject)
									end
								end
							end
						end
					end
				end
			end
		end
	end

	local distance			= 0
	local zombieDataTable	= {}	-- {{zombie, distance, multiplier}, ...}
	local zombieNum			= 0
	local playerCheck		= {false, 10 , 0.2}	-- player / distance / multiplier
	for i, v in pairs(zombieTable) do
		local movX	= v:getX() - coord[1]
		local movY	= v:getY() - coord[2]
		local rotX	= (cosT * movX) + (sinT * movY)
		local rotY	= math.abs((cosT * movY) - (sinT * movX))
		local zData	= {false, 10, 0}
		if rotX >= -0.1 and rotX <= hitBoxX and rotY <= hitbox[1] then
			distance = movX^2 + movY^2
			if rotY < hitbox[3] then
				zData = {v, distance, 1}
				table.insert(zombieDataTable, zData)
				zombieNum = zombieNum + 1
			elseif rotY < hitbox[4] then
				zData = {v, distance, 0.6}
				table.insert(zombieDataTable, zData)
				zombieNum = zombieNum + 1
			else
				zData = {v, distance, 0.2}
				table.insert(zombieDataTable, zData)
				zombieNum = zombieNum + 1
			end
		end
	end
	table.sort(zombieDataTable, function(a, b) return a[2] < b[2] end)
	for i, v in pairs(playerTable) do
		local movX	= v:getX() - coord[1]
		local movY	= v:getY() - coord[2]
		local rotX	= (cosT * movX) + (sinT * movY)
		local rotY	= math.abs((cosT * movY) - (sinT * movX))
		if rotX >= -0.1 and rotX <= hitBoxX and rotY <= hitbox[2] then
			distance = movX^2 + movY^2
			if rotY < hitbox[5] then
				if distance < playerCheck[2] then
					playerCheck = {v, distance, 1}
				end
			elseif rotY < hitbox[6] and playerCheck[3] < 0.8 then
				if distance < playerCheck[2] then
					playerCheck = {v, distance, 0.6}
				end
			elseif playerCheck[3] < 0.4 then
				if distance < playerCheck[2] then
					playerCheck = {v, distance, 0.2}
				end
			end
		end
	end
	return zombieDataTable, playerCheck, zombieNum
end

function ImprovedProjectile:calcAccChance()
	if SandboxVars.ImprovedProjectile.IPPJAccPenalty > 1 then
		local option = SandboxVars.ImprovedProjectile.IPPJAccPenalty
		local chance = {}
		chance[1] = SandboxVars.ImprovedProjectile.IPPJAccPenaltyA
		chance[2] = SandboxVars.ImprovedProjectile.IPPJAccPenaltyB
		chance[3] = SandboxVars.ImprovedProjectile.IPPJAccPenaltyC

		self.accZombie[3] = math.max(chance[3] - self.Aiming * (chance[3] / (option + 1)), 0)
		self.accZombie[2] = math.max(chance[2] - self.Aiming * (chance[2] / (option + 1)), 0)
		self.accZombie[1] = math.max(chance[1] - self.Aiming * (chance[1] / (option + 1)), 0)
	end

	if SandboxVars.ImprovedProjectile.IPPJAccPenaltyPVP > 1 then
		local option = SandboxVars.ImprovedProjectile.IPPJAccPenaltyPVP
		local chance = {}
		chance[1] = SandboxVars.ImprovedProjectile.IPPJAccPenaltyPVPA
		chance[2] = SandboxVars.ImprovedProjectile.IPPJAccPenaltyPVPB
		chance[3] = SandboxVars.ImprovedProjectile.IPPJAccPenaltyPVPC

		self.accPVP[3] = math.max(chance[3] - self.Aiming * (chance[3] / (option + 1)), 0)
		self.accPVP[2] = math.max(chance[2] - self.Aiming * (chance[2] / (option + 1)), 0)
		self.accPVP[1] = math.max(chance[1] - self.Aiming * (chance[1] / (option + 1)), 0)
	end
end

function ImprovedProjectile:applyAccPenalty(damage, wType, isZombie)
	local result = damage
	local actualChance = nil
	if isZombie == true then
		actualChance = self.accZombie
	else
		actualChance = self.accPVP
	end

	if not actualChance then return result end

	local rand = ZombRand(100) + ZombRandFloat(0, 1)
	if wType == "Shotgun" then
		rand = rand * 1.5
	end
	if result > 0.8 then
		if rand < actualChance[1] + self.moodleStats[3] then
			result = -1
		end
	elseif result > 0.4 then
		if rand < actualChance[2] + self.moodleStats[3] then
			result = -1
		end
	else
		if rand < actualChance[3] + self.moodleStats[3] then
			result = -1
		end
	end

	return result
end

--*************************************************************************************--
--** Player aim update
--*************************************************************************************--
local pUpdateTick = 0
local aimBegin = true
local aimProCooldown = 0
local playerZSave = 0
local penaltyTimer = {0, 10}
function ImprovedProjectile:playerOnTick()
	local player = getPlayer()
	if not player then return end
	self.gameTimeMult = getGameTime():getMultiplier()
	local weapon = player:getPrimaryHandItem()

	-- Player aiming ranged weapon
	if player:isAiming() and self.isValid and self.currInfo["weaponName"] == weapon:getFullType() then
		pUpdateTick = pUpdateTick - 1	-- For performance..
		Mouse.setCursorVisible(false)
		weapon:setMaxHitCount(0)

		self.currInfo["gameTimeMult"] = self.gameTimeMult * self.currInfo["aiming"] * self.moodleStats[1]
		self.actualMinAim = self.currInfo["aimMinLimit"] + self.moodleStats[4] + self.currInfo["distPenalty"]
		local actualMAxAim = self.currInfo["aimSizeMax"] + self.actualMinAim * 0.5

		if self.aimSize > actualMAxAim then
			self.aimSize = actualMAxAim
		end

		if aimBegin == true then
			self:updateMoodle(player)

			self.calcWeaponAiming(player, weapon)
			self:calcAiming(player, weapon)
			self:calcAccChance()

			self.currInfo["weaponRangeOrigin"] = weapon:getMaxRange(player)
			self.currInfo["weaponRange"] = self.currInfo["weaponType"] == "Rifle" and self.currInfo["weaponRangeOrigin"] * 0.9 or self.currInfo["weaponRangeOrigin"]
			self.currInfo["weaponRange"] = self.currInfo["weaponRange"] * SandboxVars.ImprovedProjectile.IPPJRangeMult + 0.7

			if IPPJSettings.ResetLevel then
				aimOffOption = 0
			end

			if UserIsoCursorVis > 0 then
				if IPPJSettings.RemoveIsoCursor == true then
					getCore():setIsoCursorVisibility(0)
				else
					getCore():setIsoCursorVisibility(UserIsoCursorVis)
				end
			end

			if AddonCheck then
				if self.currInfo["isHandgun"] then
					if player:isRecipeKnown("IPPJAimingProHg") and aimProCooldown + 5 < getTimestamp() then
						self.aimSize = self.aimSize - 30
						aimProCooldown = getTimestamp()
					end
				elseif self.currInfo["weaponType"] ~= "XBow" then
					if player:isRecipeKnown("IPPJAimingProRf") and aimProCooldown + 5 < getTimestamp() then
						self.aimSize = self.aimSize - 30
						aimProCooldown = getTimestamp()
					end
				end
			end
			aimBegin = false
		end

		if player:getVariableBoolean("isMoving") then
			if penaltyTimer[1] < 10 then
				penaltyTimer[1] = math.min(penaltyTimer[1] + self.gameTimeMult * (0.25 - self.Nimble * 0.01), 10)
			else
				self.aimSize = self.aimSize + (self.gameTimeMult * self.currInfo["penalty"] * SandboxVars.ImprovedProjectile.IPPJMovingPenalty * penaltyTimer[1] * 0.1)
				penaltyTimer[1] = penaltyTimer[1] + self.gameTimeMult * 0.1
			end
		else
			penaltyTimer[1] = math.max(penaltyTimer[1] - self.gameTimeMult * 0.25, 0)
		end
		--print(string.format("[IPPJ] %.2f", penaltyTimer[1]))

		if player:getVariableBoolean("isTurning") then
			self.aimSize = self.aimSize + (self.gameTimeMult * self.currInfo["penalty"] * SandboxVars.ImprovedProjectile.IPPJTurningPenalty * penaltyTimer[2] * 0.1)
			penaltyTimer[2] = penaltyTimer[2] + self.gameTimeMult * 0.3
		else
			penaltyTimer[2] = math.max(penaltyTimer[2] - self.gameTimeMult * 0.75, 10)
		end

		local notSneezeCough = true
		local isSneezingCoughing = player:getBodyDamage():IsSneezingCoughing()
		if isSneezingCoughing > 0 then
			if (isSneezingCoughing == 1 or isSneezingCoughing == 3) then
				if SandboxVars.ImprovedProjectile.IPPJMoodleEffectHC and SandboxVars.ImprovedProjectile.IPPJSneezeAim > 0 then
					self.aimSize = self.aimSize + SandboxVars.ImprovedProjectile.IPPJSneezeAim * self.gameTimeMult
					notSneezeCough = false
				end
				self.doSneezeCough[1] = true
			elseif (isSneezingCoughing == 2 or isSneezingCoughing == 4) then
				if SandboxVars.ImprovedProjectile.IPPJMoodleEffectHC and SandboxVars.ImprovedProjectile.IPPJCoughAim > 0 then
					self.aimSize = self.aimSize + SandboxVars.ImprovedProjectile.IPPJCoughAim * self.gameTimeMult
					notSneezeCough = false
				end
				self.doSneezeCough[2] = true
			end
		end
		if notSneezeCough == true then
			if self.aimSize > self.currInfo["aimSizeMin"] + self.actualMinAim then
				--self.aimSize = math.max(self.aimSize - self.currInfo["gameTimeMult"], self.currInfo["aimSizeMin"] + self.moodleStats[4])
				self.aimSize = math.max(self.aimSize - self.currInfo["gameTimeMult"], self.actualMinAim)
			else
				self.aimSize = math.max(self.aimSize - self.currInfo["gameTimeMult"] * self.currInfo["pcAiming"], self.actualMinAim)
			end
		end
		if (SandboxVars.ImprovedProjectile.IPPJVisualRecoil == 1 and IPPJSettings.VisualRecoil) or SandboxVars.ImprovedProjectile.IPPJVisualRecoil == 2 then
			if self.visualRecoil[5] == 0 then
				self.visualRecoil = {0, 0, 0, 0, 0}
			else
				self.visualRecoil[1] = self.visualRecoil[1] - self.visualRecoil[3]
				self.visualRecoil[2] = self.visualRecoil[2] - self.visualRecoil[4]
				self.visualRecoil[5] = self.visualRecoil[5] - 1
			end
		end
		if not self.crossHair.instance and (IPPJSettings.CrosshairTypeIdx ~= 5 or IPPJSettings.CrosshairDot) then
			if IPPJSettings.CrosshairTypeIdx <= 2 then
				self.crossHair.instance = self.crossHair:new(0, 0, 200, 200, "media/textures/" .. tostring(IPPJSettings.CrosshairTypeIdx), 16, 92, IPPJSettings.CrosshairHeight, IPPJSettings.HitMarkTypeIdx)
			else
				self.crossHair.instance = self.crossHair:new(0, 0, 200, 200, "media/textures/" .. tostring(IPPJSettings.CrosshairTypeIdx), 18, 91, IPPJSettings.CrosshairHeight, IPPJSettings.HitMarkTypeIdx)
			end
			self.crossHair.instance:initialise()
			self.crossHair.instance:backMost()
			self.crossHair.instance:addToUIManager()
			self.doSneezeCough[1] = false
			self.doSneezeCough[2] = false
			if UserUIFBO == true and UserUIRenderFPS < 30 then
				getCore():setOptionUIRenderFPS(30)
			end
		end

		-----------------------------------------------------------------------------
		-- Z-axis settings ----------------------------------------------------------
		-----------------------------------------------------------------------------
		if pUpdateTick < 1 then
			ZOOM = getCore():getZoom(0)

			if weapon:getModData().IPPJAimingTimeTotal ~= weapon:getAimingTime() then
				self.calcWeaponAiming(player, weapon)
				self:calcAiming(player, weapon)
			end

			if self.currInfo["weaponRangeOrigin"] ~= weapon:getMaxRange(player) then
				self.currInfo["weaponRangeOrigin"] = weapon:getMaxRange(player)
				self.currInfo["weaponRange"] = self.currInfo["weaponType"] == "Rifle" and self.currInfo["weaponRangeOrigin"] * 0.9 or self.currInfo["weaponRangeOrigin"]
				self.currInfo["weaponRange"] = self.currInfo["weaponRange"] * SandboxVars.ImprovedProjectile.IPPJRangeMult + 0.7
			end

			local playerZ = player:getZ()
			if aimOffOption >= 1 then
				if math.floor(playerZSave) < math.floor(playerZ) then
					aimOffOption = aimOffOption - 1
				end
			end
			playerZSave = playerZ

			self.aimHeightOff = 0
			IPPJAimOff = 0
			aimSetting[1] = ""
			aimSetting[2] = false	-- Is aim not on player level?

			if IPPJSettings.AdjustLevelFloor then
				if aimOffOption < 0 then aimOffOption = 0 end
			end

			if aimOffOption ~= 0 then
				IPPJAimOff = -math.floor(playerZ)
				local aimCheck = aimOffOption - IPPJAimOff
				if aimCheck > 7 then
					IPPJAimOff = IPPJAimOff + 7
				elseif aimCheck >= 0 then
					IPPJAimOff = aimOffOption
				end
				if IPPJAimOff ~= 0 then
					aimSetting[2] = true
				end
			end

			if playerZ - math.floor(playerZ) > 0 then
				IPPJAimOff = IPPJAimOff - playerZ + math.floor(playerZ)
			end

			local mouseX, mouseY = getMouseXScaled(), getMouseYScaled()
			local aimX, aimY = ISCoordConversion.ToWorld(mouseX, mouseY, playerZ)
			aimX = aimX + 1.5
			aimY = aimY + 1.5
			local aimZ = playerZ + IPPJAimOff

			local distToAim = IsoUtils.DistanceTo(player:getX(), player:getY(), aimX, aimY)
			-- Distance aim penalty
			if SandboxVars.ImprovedProjectile.IPPJDistancePenalty > 1 and self.Aiming < SandboxVars.ImprovedProjectile.IPPJDistancePenalty + 2 and self.currInfo["weaponRange"] > 5 then
				local penaltyMax = SandboxVars.ImprovedProjectile.IPPJDistancePenaltyMax * math.min(self.currInfo["weaponRange"] * 0.15, 1)
				local perLvl = (penaltyMax - 15) / (SandboxVars.ImprovedProjectile.IPPJDistancePenalty + 1)
				local currAim = math.max(distToAim - 4, 0)
				local maxAim = math.max(self.currInfo["weaponRange"] - 4, 0.1)
				local percent = math.min(currAim / maxAim, 1)
				self.currInfo["distPenalty"] = percent * (penaltyMax - self.Aiming * perLvl)
				--print(string.format("Weapon Range : %.3f / Penalty Max : %.3f", self.currInfo["weaponRange"], penaltyMax))
			else
				self.currInfo["distPenalty"] = 0
			end
			-- Is out of range?
			if IPPJSettings.ShowOutOfRange then
				if distToAim > self.currInfo["weaponRange"] then
					self.isOutOfRange = true
				else
					self.isOutOfRange = false
				end
			else
				self.isOutOfRange = false
			end

			-- Auto level down
			if IPPJSettings.AdjustLevelFloor then
				local sqt = getCell():getOrCreateGridSquare(aimX, aimY, aimZ)
				if not (sqt:TreatAsSolidFloor() or sqt:HasStairsBelow()) then
					for i = aimZ - 1, 0, -1 do
						sqt = getCell():getOrCreateGridSquare(aimX, aimY, i)
						if sqt:TreatAsSolidFloor() then
							IPPJAimOff = IPPJAimOff + i - aimZ
							aimZ = playerZ + IPPJAimOff
							break
						end
					end
				end
			end

			if aimSetting[6] ~= 0 then
				local sqs = getCell():getOrCreateGridSquare(aimX, aimY, aimZ + aimSetting[6])
				if sqs:IsOnScreen() and sqs:TreatAsSolidFloor() then
					IPPJAimOff = IPPJAimOff + aimSetting[6]
					aimZ = playerZ + IPPJAimOff
				else
					aimSetting[6] = 0
				end
			end
			if aimSetting[4] ~= 0 then
				local sqs = getCell():getOrCreateGridSquare(aimX, aimY, aimZ + aimSetting[4])
				if sqs:isCouldSee(0) and sqs:TreatAsSolidFloor() then
					if aimSetting[4] == 1 and aimSetting[5] > 0.6 then
						IPPJAimOff = IPPJAimOff + 1
						aimZ = playerZ + IPPJAimOff
						aimSetting[4] = 0
						aimSetting[6] = 1
					elseif not sqs:HasStairs() and aimSetting[5] < 0.4 then
						IPPJAimOff = IPPJAimOff - 1
						aimZ = playerZ + IPPJAimOff
						aimSetting[4] = 0
						aimSetting[6] = -1
					end
				else
					aimSetting[4] = 0
				end
			end

			aimSetting[3] = false	-- Is aim on stairs?
			local sq = getCell():getOrCreateGridSquare(aimX, aimY, aimZ)
			if sq:isCouldSee(0) and sq:HasStairs() then
				local xOff = aimX - math.floor(sq:getX())
				local yOff = aimY - math.floor(sq:getY())
				local zOff = sq:getApparentZ(xOff, yOff)
				IPPJAimOff = IPPJAimOff + zOff - math.floor(zOff)
				aimSetting[3] = true
				aimSetting[4] = 1
				aimSetting[5] = zOff
			elseif sq:HasStairsBelow() then
				local sqb = getCell():getGridSquare(aimX, aimY, aimZ - 1)
				if sqb:isCouldSee(0) then
					local xOff = aimX - math.floor(sq:getX())
					local yOff = aimY - math.floor(sq:getY())
					local zOff = sqb:getApparentZ(xOff, yOff)
					IPPJAimOff = IPPJAimOff - 1 + zOff - math.floor(zOff)
					aimSetting[3] = true
					aimSetting[4] = -1
					aimSetting[5] = zOff
				end
			end

			-- Aim assist for lying zombie
			self.aimLyingOff = 0
			local heightOff = (100 + IPPJSettings.CrosshairHeight) / ZOOM
			if isKeyDown(getCore():getKey("ManualFloorAtk")) then
				self.aimLyingOff = heightOff
			elseif IPPJSettings.AimAssistLZombie then
				local x = {aimX - 1, aimX, aimX + 1}
				local y = {aimY - 1, aimY, aimY + 1}
				local check = false
				local heightAdd = 0
				for ix, vx in pairs(x) do
					for jy, vy in pairs(y) do
						local square = getCell():getOrCreateGridSquare(vx, vy, aimZ)
						if square:TreatAsSolidFloor() then
							local targets = square:getMovingObjects()
							for i = 1, targets:size() do
								local target = targets:get(i - 1)
								if instanceof(target, "IsoZombie") then
									if target:isProne() then
										self.aimLyingOff = heightOff
									else
										self.aimLyingOff = 0
										check = true
										break
									end
								end
							end
						end
						if check then break end
					end
					if check then break end
				end
			end
			if IPPJAimOff ~= 0 then
				self.aimHeightOff = (200 * IPPJAimOff) / ZOOM
				local aimOff = math.abs(IPPJAimOff)
				if IPPJAimOff - math.floor(IPPJAimOff) > 0 then
					aimOff = string.format("%.1f", aimOff)
				else
					aimOff = tostring(aimOff)
				end
				if aimSetting[4] ~= 0 then
					aimSetting[1] = "[img=media/ui/VanillaStair.png]: " .. aimOff
				elseif IPPJAimOff > 0 then
					aimSetting[1] = "[img=media/ui/VanillaArrowUp.png]: " .. aimOff
				else
					aimSetting[1] = "[img=media/ui/VanillaArrowDown.png]: " .. aimOff
				end
				getCore():setIsoCursorVisibility(0)
				aimOffText:ReadString(UIFont.Medium, aimSetting[1], -1)
			elseif UserIsoCursorVis > 0 and IPPJSettings.RemoveIsoCursor == false then
				getCore():setIsoCursorVisibility(UserIsoCursorVis)
			end

			if player:getVehicle() and SandboxVars.ImprovedProjectile.IPPJRestrictAngleVehicle then
				local vehicle = player:getVehicle()
				local vec3f = vehicle:getForwardVector(BaseVehicle.allocVector3f())
				local vec2V = BaseVehicle.allocVector2()
				vec2V:setX(vec3f:x())
				vec2V:setY(vec3f:z())
				vec2V:normalize()

				local seat = vehicle:getSeat(player)
				local area = vehicle:getScript():getAreaById(vehicle:getPassengerArea(seat))
				local angle = -90
				if area:getX() > 0 then angle = 90 end

				vec2V:rotate(math.rad(angle))
				vec2V:normalize()

				local vec2T = BaseVehicle.allocVector2()
				vec2T:setX(aimX - player:getX())
				vec2T:setY(aimY - player:getY())
				vec2T:normalize()

				local var = vec2T:dot(vec2V)
				if var > -0.6 then
					self.blockVehicleShoot = true
				else
					self.blockVehicleShoot = false
				end

				BaseVehicle.releaseVector2(vec2V)
				BaseVehicle.releaseVector2(vec2T)
				BaseVehicle.releaseVector3f(vec3f)
			else
				self.blockVehicleShoot = false
			end

			pUpdateTick = 6	-- Calculate every 6 ticks
		end
	else
		if aimBegin == false then
			if self.crossHair.instance then
				getCore():setIsoCursorVisibility(UserIsoCursorVis)
				if UserUIFBO == true and UserUIRenderFPS < 30 then
					getCore():setOptionUIRenderFPS(UserUIRenderFPS)
				end
				self.crossHair.instance:removeFromUIManager()
				self.crossHair.instance = nil
			end
			self.aimSize = 130
			self.visualRecoil = {0, 0, 0, 0, 0}
			pUpdateTick = 0
			aimSetting = {"", false, false, 0, 0.5, 0}
			penaltyTimer = {0, 10}
			self.blockVehicleShoot = false
			aimBegin = true
		end
	end
end

local fontMHeight = getTextManager():getFontHeight(UIFont.Medium)
local function drawText()
	--print("[IPPJ] ", player:getForname(), " ", player:getSurname(), " : ", player:isLocalPlayer())
	if ImprovedProjectile.hitX[1] > 0 then
		ImprovedProjectile.hitX[1] = ImprovedProjectile.hitX[1] - 1
		if IPPJSettings.HitInfoText then
			ImprovedProjectile.hitX[2]:AddBatchedDraw(getMouseX(), getMouseY() + 50 / ZOOM - ImprovedProjectile.aimHeightOff, true)
		end
	end

	if ImprovedProjectile.crossHair.instance then
		local textXOff = getMouseX() + 35
		local textYOff = getMouseY() - ImprovedProjectile.aimHeightOff + ImprovedProjectile.aimLyingOff - IPPJSettings.CrosshairHeight / ZOOM + 35
		if ImprovedProjectile.blockVehicleShoot then
			cannotText[2]:AddBatchedDraw(getMouseX(), textYOff - 90, true)
		elseif ImprovedProjectile.isOutOfRange then
			cannotText[1]:AddBatchedDraw(getMouseX(), textYOff - 90, true)
		end
		if IPPJSettings.ShowAmmoCount then
			local weapon = getPlayer():getPrimaryHandItem()
			IPPJAmmoCount = weapon:getCurrentAmmoCount()
			if weapon:isRoundChambered() then
				IPPJAmmoCount = IPPJAmmoCount + 1
			end
			if IPPJAmmoCount == 0 or weapon:isJammed() then
				aimAmmoText:setOutlineColors(1, 0.3, 0.3, 1)
				aimAmmoText:ReadString(UIFont.Medium, "[img=media/ui/VanillaBullet3.png]: " .. tostring(IPPJAmmoCount), -1)
			else
				aimAmmoText:setOutlineColors(0, 0, 0, 1)
				aimAmmoText:ReadString(UIFont.Medium, "[img=media/ui/VanillaBullet2.png]: " .. tostring(IPPJAmmoCount), -1)
			end
			aimAmmoText:AddBatchedDraw(textXOff, textYOff, true)
			textYOff = textYOff + fontMHeight + 5
		end
		if IPPJAimOff ~= 0 then
			aimOffText:AddBatchedDraw(textXOff, textYOff, true)
		end
	end
end

--*************************************************************************************--
--** Check projectile on tick
--*************************************************************************************--
local projText = TextDrawObject.new()
projText:setDefaultColors(1, 1, 1, 0.7)
projText:setOutlineColors(0, 0, 0, 0)
projText:setAllowAnyImage(true)
local function projectileOnTick()
	ImprovedProjectile:playerOnTick()
	local projTable = ImprovedProjectile.activeProjectiles
	local checkRemoveProjectile = SandboxVars.ImprovedProjectile.IPPJRemoveProjectile	-- Remove projectile?
	local doSimplify = IPPJSettings.SimplifiedProj or not getCore():isOption3DGroundItem()

	for iv, v in pairs(projTable) do
		local checkPorj = true
		local fgRoll = ZombRand(10)
		v[4] = getCell():getOrCreateGridSquare(v[7][1], v[7][2], v[7][3])
		if v[4] then
			-----------------------------------------------------------------------------
			-- Create Projectile --------------------------------------------------------
			-----------------------------------------------------------------------------
			ImprovedProjectile.removeProjectile(v[1])
			if checkRemoveProjectile ~= 3 and v[4]:IsOnScreen() then
				if doSimplify == false then
					v[1] = ImprovedProjectile.createProjectile(v[4], v[2], v[23], v[7], v[1])
				else
					local xx, yy = ISCoordConversion.ToScreen(v[7][1], v[7][2], v[7][3])
					xx = xx / ZOOM
					if ZOOM < 0.55 then
						yy = (yy - 6) / ZOOM
						projText:ReadString(UIFont.Medium, "[img=media/ui/IPPJSimpProj2.png]", -1)
					else
						yy = (yy - 4) / ZOOM
						projText:ReadString(UIFont.Medium, "[img=media/ui/IPPJSimpProj.png]", -1)
					end
					projText:AddBatchedDraw(xx, yy, true)
				end
			end

			-----------------------------------------------------------------------------
			-- Check projectile hits zombie ---------------------------------------------
			-----------------------------------------------------------------------------
			local zombieTable, hitPlayer, zombieNum = IPPJcheckTarget(v[15], v[7], v[5][2], v[5][3], v[10][1], v[16], v[20], v[21])
			local lastZombie = nil
			-- Projectile hit zombie
			if zombieNum > 0 then
				for i = 1, zombieNum do
					if ImprovedProjectile.checkHitOverWall(zombieTable[i][1], v[5][1], v[7], {v[10][2], v[10][3], v[10][1]}, v[15], v[18], fgRoll) then
						if SandboxVars.ImprovedProjectile.IPPJAccPenalty > 1 and ImprovedProjectile.Aiming < SandboxVars.ImprovedProjectile.IPPJAccPenalty + 1 then
							zombieTable[i][3] = ImprovedProjectile:applyAccPenalty(zombieTable[i][3], v[3], true)
						end
						if zombieTable[i][3] > 0 then
							local mult = 0
							if zombieTable[i][3] > 0.8 then
								mult = SandboxVars.ImprovedProjectile.IPPJHitBoxHighMult
							elseif zombieTable[i][3] > 0.4 then
								mult = SandboxVars.ImprovedProjectile.IPPJHitBoxMidMult
							else
								mult = SandboxVars.ImprovedProjectile.IPPJHitBoxLowMult
							end
							local hitDamage = v[8] * mult
							-- Check critical hit
							local critical = false
							if ZombRand(100) <= v[12] then
								critical = true
								hitDamage = hitDamage * 2
							end
							local weapon = v["weapon"] or InventoryItemFactory.CreateItem(v[17])
							local zModData = zombieTable[i][1]:getModData()
							triggerEvent("OnWeaponHitCharacter", v[15], zombieTable[i][1], weapon, hitDamage) -- For Combat Text Mod
							zombieTable[i][1]:setAttackedBy(v[15])
							zModData.IPPJHitBy = v[16]

							if IPPJSettings.CustomBloodEffect then
								local attachedAnim = zombieTable[i][1]:getAttachedAnimSprite()
								if attachedAnim and attachedAnim:size() > 2 then
									for j = 1, attachedAnim:size() do
										local animName = attachedAnim:get(j - 1):getName()
										if string.find(animName, "banimation") then
											zombieTable[i][1]:RemoveAttachedAnim(j - 1)
											break
										end
									end
								end
								local texSize = getCore():getOptionTexture2x() and 2 or 1
								local xPosRand = ZombRandBetween(-10, 11)
								local yPosRand = ZombRandBetween(-10, 11)
								local vec = Vector3.new()
								local vec2 = Vector3.new(0, 0, 1)
								SwipeStatePlayer.getBoneWorldPos(zombieTable[i][1], "Bip01_Spine", vec)
								local renderZ = texSize * (56 + 110 * (vec:dot3d(vec2) - zombieTable[i][1]:getZ()))
								zombieTable[i][1]:AttachAnim("banimation", "01", 15, 0.3, xPosRand, renderZ + yPosRand, false, 0, true, 0.7, ColorInfo.new(0.85, 0.85, 0.85, 1))
							end

							zombieTable[i][1]:setHealth(zombieTable[i][1]:getHealth() - hitDamage)
							zombieTable[i][1]:reportEvent("wasHit")
							--print("[IPPJ] Critical - ", critical, ", Mult - ", zombieTable[i][3])
							local zombieReaction = ""
							local doReaction = true
							if zombieTable[i][1]:isDead() then
								zombieTable[i][1]:setHitReaction("ShotBelly")
								zombieTable[i][1]:Kill(v[15])
								v[15]:setZombieKills(v[15]:getZombieKills() + 1)
								--v[15]:getXp():AddXP(Perks.Aiming, 2)

								zModData.stuck_Body01 = nil
								zModData.stuck_Body02 = nil
								zModData.stuck_Body03 = nil
								zModData.stuck_Body04 = nil
								zModData.stuck_Body05 = nil
								zModData.stuck_Body06 = nil

							else
								if SandboxVars.ImprovedProjectile.IPPJEnableZombieHitReact then
									if zombieTable[i][1]:isProne() then
										zombieReaction = "FloorBack"
										zombieTable[i][1]:addBlood(50)
									else
										if zombieTable[i][3] > 0.8 then
											zombieReaction = zombieHighReact[ZombRand(3) + 1]
											zombieTable[i][1]:addBlood(50)
										elseif zombieTable[i][3] > 0.4 then
											if critical then
												zombieReaction = zombieMidReactCrit[ZombRand(3) + 1]
												zombieTable[i][1]:addBlood(50)
											else
												zombieReaction = zombieMidReact[ZombRand(3) + 1]
												zombieTable[i][1]:addBlood(25)
											end
											if SandboxVars.ImprovedProjectile.IPPJZombieHitReactCond == 3 then
												doReaction = false
											end
										else
											if critical then
												zombieTable[i][1]:setHitFromBehind(true)
												zombieReaction = zombieLowReact[ZombRand(2) + 1]
												zombieTable[i][1]:addBlood(50)
											else
												zombieReaction = zombieLowReact[ZombRand(2) + 1]
												zombieTable[i][1]:addBlood(25)
											end
											if SandboxVars.ImprovedProjectile.IPPJZombieHitReactCond >= 2 then
												doReaction = false
											end
										end
									end
									if doReaction then
										zombieTable[i][1]:setHitReaction(zombieReaction)
									end
								else
									zombieTable[i][1]:addBlood(30)
								end

								if SandboxVars.ImprovedProjectile.IPPJPntOnKill then
									v[11] = 0
								end
							end

							v[15]:setLastHitCount(1)
							triggerEvent("OnWeaponHitXp", v[15], weapon, zombieTable[i][1], hitDamage)
							if IPPJSettings.HitMarkTypeIdx < 3 then
								ImprovedProjectile.hitX[1] = 50
								if zombieTable[i][1]:isAlive() then
									ImprovedProjectile.hitX[3] = 1.0
								else
									ImprovedProjectile.hitX[3] = 0.15
								end
							end
							if IPPJSettings.HitInfoText then
								ImprovedProjectile.hitX[1] = 50
								if critical then
									ImprovedProjectile.hitX[2]:setDefaultColors(1, 0.8, 0.1)
								else
									ImprovedProjectile.hitX[2]:setDefaultColors(1, 1, 1)
								end
								ImprovedProjectile.hitX[2]:setOutlineColors(0, 0, 0, 1)
								ImprovedProjectile.hitX[2]:ReadString(UIFont.Medium, tostring(zombieTable[i][3] * 100) .. "%", -1)
							end
							if isClient() then
								sendClientCommand("IPPJ", "hitZombie", {v[15]:getOnlineID(), zombieTable[i][1]:getOnlineID(), {zombieTable[i][1]:getX(), zombieTable[i][1]:getY(), zombieTable[i][1]:getZ()}, v[17], hitDamage, zombieReaction, doReaction})
							end
							v[11]	= v[11] - 1	-- Hit Count - 1
							v[8]	= v[8] * (1 - SandboxVars.ImprovedProjectile.IPPJDmgReductionOnPnt)

							lastZombie = zombieTable[i][1]
							if v[11] <= 0 then
								break
							end
						end
					end
				end
			end
			-----------------------------------------------------------------------------
			-- Projectile hits 'MaxHitCount' times --------------------------------------
			-----------------------------------------------------------------------------
			if v[11] <= 0 then
				if isClient() and checkRemoveProjectile == 1 then
					sendClientCommand("IPPJ", "removeProjectile", {v[15]:getOnlineID(), v[16]})
				end
				ImprovedProjectile.removeProjectile(v[1])
				projTable[iv] = nil
				checkPorj = false
				--break
			end
			-----------------------------------------------------------------------------
			-- Projectile hit player ----------------------------------------------------
			-----------------------------------------------------------------------------
			if checkPorj and hitPlayer[1] and ImprovedProjectile.checkHitOverWall(hitPlayer[1], v[5][1], v[7], {v[10][2], v[10][3], v[10][1]}, v[15], v[18], fgRoll) then
				if SandboxVars.ImprovedProjectile.IPPJAccPenaltyPVP > 1 and ImprovedProjectile.Aiming < SandboxVars.ImprovedProjectile.IPPJAccPenaltyPVP + 1 then
					hitPlayer[3] = ImprovedProjectile:applyAccPenalty(hitPlayer[3], v[3], false)
				end
				if hitPlayer[3] > 0 then
					local mult = 0
					if hitPlayer[3] > 0.8 then
						mult = SandboxVars.ImprovedProjectile.IPPJPVPHitBoxHighMult
					elseif hitPlayer[3] > 0.4 then
						mult = SandboxVars.ImprovedProjectile.IPPJPVPHitBoxMidMult
					else
						mult = SandboxVars.ImprovedProjectile.IPPJPVPHitBoxLowMult
					end
					local hitDamage = v[8] * mult
					local critical = "FALSE"
					if ZombRand(100) <= v[12] then
						critical = "TRUE"
						hitDamage = hitDamage * 2
					end
					if isClient() then
						if checkRemoveProjectile == 1 then
							sendClientCommand("IPPJ", "removeProjectile", {v[15]:getOnlineID(), v[16]})
						end
						hitDamage = hitDamage * SandboxVars.ImprovedProjectile.IPPJPVPDamageMult
						hitPlayer[1]:addBlood(50)
						--triggerEvent("OnWeaponHitCharacter", v[15], hitPlayer[1], v[15]:getPrimaryHandItem(), hitDamage)
						sendClientCommand("IPPJ", "hitPlayer", {v[15]:getOnlineID(), hitPlayer[1]:getOnlineID(), hitPlayer[3], hitDamage, critical, getItemNameFromFullType(v[17])})
					else
						local headShot = {
							BodyPartType.Head,			BodyPartType.Head,
							BodyPartType.Neck
						}
						local bodyShot = {
							BodyPartType.Torso_Upper,	BodyPartType.Torso_Lower,
							BodyPartType.Torso_Upper,	BodyPartType.Torso_Lower,
							BodyPartType.Torso_Upper,	BodyPartType.Torso_Lower,
							BodyPartType.Groin,
							BodyPartType.UpperArm_L,	BodyPartType.UpperArm_R,
							BodyPartType.ForeArm_L,		BodyPartType.ForeArm_R,
							BodyPartType.UpperLeg_L,	BodyPartType.UpperLeg_R,
							BodyPartType.UpperLeg_L,	BodyPartType.UpperLeg_R,
							BodyPartType.LowerLeg_L,	BodyPartType.LowerLeg_R
						}
						local terminalShot = {
							BodyPartType.Hand_L,		BodyPartType.Hand_R,
							BodyPartType.Foot_L,		BodyPartType.Foot_R
						}
						local hitPart = BodyPartType.Torso_Upper
						if hitPlayer[3] > 0.8 then
							hitPart = headShot[ZombRand(3) + 1]
						elseif hitPlayer[3] > 0.4 then
							hitPart = bodyShot[ZombRand(17) + 1]
						else
							hitPart = terminalShot[ZombRand(4) + 1]
						end
						local hitPlayerPart = hitPlayer[1]:getBodyDamage():getBodyPart(hitPart)
						local defenseBullet	= hitPlayer[1]:getBodyPartClothingDefense(hitPart:index(), false, true)
						local defenseBite	= hitPlayer[1]:getBodyPartClothingDefense(hitPart:index(), true, false)
						local finalDefense	= (100 + (defenseBullet * 1.5) + (defenseBite * 0.5)) / 100
						hitDamage = hitDamage / finalDefense
						if hitPlayerPart:haveBullet() then
							hitPlayerPart:setDeepWounded(true)
							hitPlayerPart:setDeepWoundTime(hitPlayerPart:getDeepWoundTime())
							hitPlayerPart:setBleedingTime(hitPlayerPart:getBleedingTime())
						else
							hitPlayerPart:setHaveBullet(true, 3)
						end
						local weapon = v["weapon"] or InventoryItemFactory.CreateItem(v[17])

						triggerEvent("OnWeaponHitCharacter", v[15], hitPlayer[1], weapon, hitDamage)
						hitPlayer[1]:addBlood(100)
						hitPlayerPart:ReduceHealth(hitDamage)
						--print("[IPPJ] Player Hit Damage : ", hitDamage)
					end
					ImprovedProjectile.removeProjectile(v[1])
					projTable[iv] = nil
					checkPorj = false
					--break
				end
			end
			-----------------------------------------------------------------------------
			-- Check projectile hit Window / Wall / Door / Vehicle ----------------------
			-----------------------------------------------------------------------------
			if checkPorj and ImprovedProjectile.checkBlocked(v[4], v[5][1], v[7], {v[10][2], v[10][3], v[22], v[10][1]}, v[19], v[15], v[18], v[17], fgRoll) then
				if isClient() and checkRemoveProjectile == 1 then
					sendClientCommand("IPPJ", "removeProjectile", {v[15]:getOnlineID(), v[16]})
				end
				ImprovedProjectile.removeProjectile(v[1])
				projTable[iv] = nil
				checkPorj = false
				--break
			end
		end
		-----------------------------------------------------------------------------
		-- Projectile reached max range ---------------------------------------------
		-----------------------------------------------------------------------------
		if checkPorj and v[9] < 0 then
			ImprovedProjectile.removeProjectile(v[1])
			projTable[iv] = nil
			checkPorj = false
			--break
		end
		-----------------------------------------------------------------------------
		-- Move projectile forward --------------------------------------------------
		-----------------------------------------------------------------------------
		if checkPorj then
			v[8] = v[8] - v[13]
			if v[8] <= 0 then
				if isClient() and checkRemoveProjectile == 1 then
					sendClientCommand("IPPJ", "removeProjectile", {v[15]:getOnlineID(), v[16]})
				end
				ImprovedProjectile.removeProjectile(v[1])
				projTable[iv] = nil
			else
				v[9] = v[9] - v[10][1]
				v[7][1] = v[7][1] + v[10][2]		-- Change current X
				v[7][2] = v[7][2] + v[10][3]		-- Change current Y
				v[7][3] = v[7][3] + v[22]			-- Change current Z
			end
		end
	end
end

--*************************************************************************************--
--** Calculate recoil and aimingtime
--*************************************************************************************--
function ImprovedProjectile.calcWeaponRecoil(player, weapon)	-- calcRecoilDelay from Gunfighter @Aresnal[26]
	local recoilSave = weapon:getRecoilDelay()

	weapon:getModData().IPPJScope	= weapon:getWeaponPart("Scope")
	weapon:getModData().IPPJCanon	= weapon:getWeaponPart("Canon")
	weapon:getModData().IPPJClip	= weapon:getWeaponPart("Clip")
	weapon:getModData().IPPJStock	= weapon:getWeaponPart("Stock")
	weapon:getModData().IPPJSling	= weapon:getWeaponPart("Sling")
	weapon:getModData().IPPJRecoil	= weapon:getWeaponPart("RecoilPad")

	weapon:detachWeaponPart(weapon:getModData().IPPJScope)
	weapon:detachWeaponPart(weapon:getModData().IPPJCanon)
	weapon:detachWeaponPart(weapon:getModData().IPPJClip)
	weapon:detachWeaponPart(weapon:getModData().IPPJStock)
	weapon:detachWeaponPart(weapon:getModData().IPPJSling)
	weapon:detachWeaponPart(weapon:getModData().IPPJRecoil)

	local calc	= 0
	local base	= 30
	if weapon:isTwoHandWeapon() then
		base 	= 30
	end
	local recoil	= 0
	local weight 	= weapon:getWeight()
	local stock		= 0
	local level		= player:getPerkLevel(Perks.Aiming) * 1
	local reducer	= 0.5

	if		player:getVehicle()						then	stock	= 0
	elseif	weapon:getSwingAnim() == "Handgun"		then	stock	= 0
	elseif	weapon:getSwingAnim() == "Rifle"		then	stock	= 6
	end

	if weapon:isRanged() then
		local 	ammo = weapon:getAmmoType() or ""
		recoil = (weapon:getMaxDamage() + weapon:getMinDamage()) * 0.5
		 -- Recoil based on damage
		if string.find(ammo, "Shotgun") or string.find(ammo, "shotgun") or ammo == "SGuns.ShrapnelShell" then
			recoil = math.min(5.58 * recoil^2 - 5.17 * recoil, 50)
		else
			recoil = math.min(recoil^3 - 6.8 * recoil^2 + 21 * recoil - 11.25, 64)
		end

		calc = ((base + recoil - weight - stock) * reducer)

		weapon:setRecoilDelay(calc)
		weapon:getModData().IPPJRecoilDelay	= calc
		weapon:getModData().IPPJHitChance	= weapon:getHitChance()
		local minAngle = weapon:getMinAngle()

		weapon:attachWeaponPart(weapon:getModData().IPPJScope)
		weapon:attachWeaponPart(weapon:getModData().IPPJCanon)
		weapon:attachWeaponPart(weapon:getModData().IPPJClip)
		weapon:attachWeaponPart(weapon:getModData().IPPJStock)
		weapon:attachWeaponPart(weapon:getModData().IPPJSling)
		weapon:attachWeaponPart(weapon:getModData().IPPJRecoil)
		weapon:getModData().IPPJRecoilDelayParts = weapon:getRecoilDelay() - calc
		weapon:getModData().IPPJHitChanceParts	= weapon:getHitChance() - weapon:getModData().IPPJHitChance
		weapon:getModData().IPPJMinAngleParts = (weapon:getMinAngle() - minAngle) * 5

		weapon:setRecoilDelay(recoilSave)
		--print("[IPPJ] : AD  -  ", weapon:getModData().IPPJRecoilDelay, " /  ADP  -  ", weapon:getModData().IPPJRecoilDelayParts)
		--print("[IPPJ] : HC  -  ", weapon:getModData().IPPJHitChance, " /  HCP  -  ", weapon:getModData().IPPJHitChanceParts)
		--print("[IPPJ] : MAP  -  ", weapon:getModData().IPPJMinAngleParts)
	end
end

function ImprovedProjectile.calcWeaponAiming(player, weapon)
	weapon:getModData().IPPJScope	= weapon:getWeaponPart("Scope")
	weapon:getModData().IPPJCanon	= weapon:getWeaponPart("Canon")
	weapon:getModData().IPPJClip	= weapon:getWeaponPart("Clip")
	weapon:getModData().IPPJStock	= weapon:getWeaponPart("Stock")
	weapon:getModData().IPPJSling	= weapon:getWeaponPart("Sling")
	weapon:getModData().IPPJRecoil	= weapon:getWeaponPart("RecoilPad")

	weapon:detachWeaponPart(weapon:getModData().IPPJScope)
	weapon:detachWeaponPart(weapon:getModData().IPPJCanon)
	weapon:detachWeaponPart(weapon:getModData().IPPJClip)
	weapon:detachWeaponPart(weapon:getModData().IPPJStock)
	weapon:detachWeaponPart(weapon:getModData().IPPJSling)
	weapon:detachWeaponPart(weapon:getModData().IPPJRecoil)

	if weapon:isRanged() then
		weapon:getModData().IPPJAimingTime = weapon:getAimingTime()

		weapon:attachWeaponPart(weapon:getModData().IPPJScope)
		weapon:attachWeaponPart(weapon:getModData().IPPJCanon)
		weapon:attachWeaponPart(weapon:getModData().IPPJClip)
		weapon:attachWeaponPart(weapon:getModData().IPPJStock)
		weapon:attachWeaponPart(weapon:getModData().IPPJSling)
		weapon:attachWeaponPart(weapon:getModData().IPPJRecoil)
		weapon:getModData().IPPJAimingTimeTotal = weapon:getAimingTime()
		weapon:getModData().IPPJAimingTimeParts	= weapon:getAimingTime() - weapon:getModData().IPPJAimingTime
		--print("[IPPJ] : AT  -  ", weapon:getModData().IPPJAimingTime, " /  ATP  -  ", weapon:getModData().IPPJAimingTimeParts)
	end
end

function ImprovedProjectile:calcRecoil(weapon)
	local fireMode = weapon:getFireMode()
	if not self.currInfo["fireMode"] or self.currInfo["fireMode"] ~= fireMode then
		if not fireMode or string.find(fireMode, "Single") or string.find(fireMode, "single")then
			self.currInfo["fmRecoil"] = 1.5 + (10 - self.Aiming) * 0.05
		elseif string.find(fireMode, "Burst") or string.find(fireMode, "burst") then
			self.currInfo["fmRecoil"] = 0.75
		else
			self.currInfo["fmRecoil"] = 1.15
		end
	end

	self.currInfo["recoil"] = self.currInfo["fmRecoil"] * ((weapon:getModData().IPPJRecoilDelay + (weapon:getModData().IPPJRecoilDelayParts * 0.8)) / self.currInfo["recoilDenom"])
	self.currInfo["fireMode"] = fireMode
end

function ImprovedProjectile:calcAiming(player, weapon)
	self.currInfo["aiming"] = 0.1
	--##
	self.currInfo["pcAiming"] = 0.4
	self.currInfo["aimSizeMin"] = 30 - self.Aiming * 0.5
	self.currInfo["aimMinLimit"] = math.max(SandboxVars.ImprovedProjectile.IPPJAimMinLimit - SandboxVars.ImprovedProjectile.IPPJAimMinLimitLvl * self.Aiming, 0)
	--self.currInfo["pcAiming"] = 1
	--self.currInfo["aimSizeMin"] = 0
	self.currInfo["aimSizeMax"]	= 110

	if weapon:getModData().IPPJAimingTime then
		local aimParts = weapon:getModData().IPPJAimingTimeParts
		if aimParts > 0 then
			aimParts = 2 * aimParts^0.6
		elseif aimParts < 0 then
			aimParts = -2 * math.abs(aimParts)^0.33
		end
		--self.currInfo["aiming"]		= ((self.Aiming * 1.1) + (weapon:getModData().IPPJAimingTime * 1.2) + (aimParts)) / 24
		self.currInfo["aiming"]		= ((self.Aiming^2 * 0.2) + (weapon:getModData().IPPJAimingTime * 1.2) + (aimParts)) / 27
		if self.currInfo["isHandgun"] and player:isRecipeKnown("IPPJAimingProHg") then
			self.currInfo["aimSizeMin"] = self.currInfo["aimSizeMin"] - 5
		elseif self.currInfo["weaponType"] ~= "XBow" and player:isRecipeKnown("IPPJAimingProRf") then
			self.currInfo["aimSizeMin"] = self.currInfo["aimSizeMin"] - 5
		end
		self.currInfo["aimSizeMax"]	= 110 - (aimParts * 1.25) - (self.Aiming * 2.5)
	end

	local maxRange = (SandboxVars.ImprovedProjectile.IPPJSniperScope == 1) and IPPJSettings.SniperScopeRangeV or SandboxVars.ImprovedProjectile.IPPJSniperScopeRange
	if weapon:getWeaponPart("Scope") and weapon:getWeaponPart("Scope"):getMaxRange() and weapon:getWeaponPart("Scope"):getMaxRange() >= maxRange then
		self.currInfo["isSniperScope"] = true
	else
		self.currInfo["isSniperScope"] = false
	end

	self.currInfo["penalty"] = self.currInfo["aiming"] * (1.2 - (self.Nimble * 0.04 + self.Aiming * 0.03))
	self.currInfo["aiming"] = self.currInfo["aiming"] * SandboxVars.ImprovedProjectile.IPPJAimingSpeed
end

--*************************************************************************************--
--** On player shoot firearm, create projectile
--*************************************************************************************--
function ImprovedProjectile:onShootWeapon(player, weapon)
	if self.projId > 100000 then
		self.projId = 0
	end

	self.calcWeaponRecoil(player, weapon)
	local aimRate = self.aimSize
	if weapon:getModData().IPPJHitChanceParts then
		aimRate = math.max(aimRate - (weapon:getModData().IPPJHitChanceParts * 0.7), 0)
	end
	--local spread = (620 + self.Aiming * 5)
	local hitChance = weapon:getModData().IPPJHitChance or weapon:getHitChance()
	local spread = (570 + math.min(hitChance + self.Aiming * weapon:getAimingPerkHitChanceModifier(), 200))
	aimRate = aimRate * math.pi / spread	-- Max aim angle is 25.7 * 2 ~ 27.7 * 2
	aimRate = ZombRandFloat(-aimRate, aimRate)

	local projObject		= nil
	local projName			= self.currInfo["projName"]
	local weaponType		= self.currInfo["weaponType"]
	local projSquare		= nil
	local playerX			= player:getX()
	local playerY			= player:getY()
	local playerZ			= player:getZ()
	--local projDirection		= player:getForwardDirection():getDirection() + aimRate
	local projDirection		= player:getLookAngleRadians() + aimRate
	local projDirectionX	= math.cos(projDirection)
	local projDirectionY	= math.sin(projDirection)
	local projDamage		= weapon:getMinDamage() + ZombRandFloat(0.0, 1.0) * (weapon:getMaxDamage() - weapon:getMinDamage())
	if weapon:getAmmoType() == "Base.Nails" then
		projDamage = weapon:getMinDamage() + ZombRandFloat(0.0, 1.0) * (weapon:getMaxDamage() - weapon:getMinDamage() + 0.4)
	end
	local projRange			= weapon:getMaxRange(player)
	local projSpeed			= self.currInfo["projSpeed"]
	local projSpeedX		= projDirectionX
	local projSpeedY		= projDirectionY
	local projMaxHit		= self.currInfo["projMaxHit"]
	local critLevelBonus	= weapon:getAimingPerkCritModifier() or 0
	local projCritChance	= weapon:getCriticalChance()
	if projCritChance > 50 then
		projCritChance = (projCritChance + 50) * 0.5
	end
	projCritChance = projCritChance + self.currInfo["critChance"] + self.Aiming * 1.5
	local damageReduction	= 0
	local projectileType	= self.currInfo["projectileType"]
	local projId			= self.projId
	local weaponName		= self.currInfo["weaponName"]
	local bPassThrough		= {}
	local hitBoxMax			= 0.5
	local hitBoxMaxPVP		= 0.5
	local hitBoxHigh		= SandboxVars.ImprovedProjectile.IPPJHitBoxHighRatio * 0.005
	local hitBoxMid			= hitBoxHigh + SandboxVars.ImprovedProjectile.IPPJHitBoxMidRatio * 0.005
	local hitBoxHighPVP		= SandboxVars.ImprovedProjectile.IPPJPVPHitBoxHighRatio * 0.005
	local hitBoxMidPVP		= hitBoxHigh + SandboxVars.ImprovedProjectile.IPPJPVPHitBoxMidRatio * 0.005
	if SandboxVars.ImprovedProjectile.IPPJLargerHitboxPVE then
		hitBoxMax	= 1
		hitBoxHigh	= hitBoxHigh * 2
		hitBoxMid	= hitBoxMid * 2
	end
	if SandboxVars.ImprovedProjectile.IPPJLargerHitboxPVP then
		hitBoxMaxPVP	= 1
		hitBoxHighPVP	= hitBoxHigh * 2
		hitBoxMidPVP	= hitBoxMid * 2
	end
	local friendlyFire		= SandboxVars.ImprovedProjectile.IPPJFriendlyFire
	local isPVPOn			= not player:getSafety():isEnabled()
	local isFactionPVP		= player:isFactionPvp()
	local notInNonPVPZone	= not (SandboxVars.ImprovedProjectile.IPPJEnableNonPVPZone and NonPvpZone.getNonPvpZone(playerX, playerY))
	local ignoreSafety		= SandboxVars.ImprovedProjectile.IPPJIgnoreSafety

	local projDirectionZ	= 0
	local fakeAngle			= nil

	local projInfo = {
		projObject,						-- [1]  Projectile WorldObject
		projName,						-- [2]  Projectile WorldObject name
		weaponType,						-- [3]  Weapon type : Rifle or Shotgun
		projSquare,						-- [4]  Current projectile location square
		{projDirection,					-- [5]	[1] Projectile direction (Angle(-180 ~ 180))
		projDirectionX,					-- [5]	[2] Projectile direction (X(cos))
		projDirectionY},				-- [5]  [3] Projectile direction (Y(sin))
		{playerX, playerY, playerZ},	-- [6]  Player original location coordinates {X, Y, Z}
		{playerX, playerY, playerZ},	-- [7]  Projectile current location coordinates {X, Y, Z}
		projDamage,						-- [8]  Projectile damage
		projRange,						-- [9]	Projectile max range(Initial) decrease by distance projectile traveled
		{projSpeed,						-- [10] [1] Projectile speed
		projSpeedX, projSpeedY},		-- [10] [2-3] Projectile speed X, Y
		projMaxHit,						-- [11] Projectile MaxHitCount
		projCritChance,					-- [12] Projectile critical chance
		damageReduction,				-- [13] Damage reduction percent by distance
		projectileType,					-- [14] Projectile type (Bow or Slingshot)
		player,							-- [15] Player who shoot firearm
		projId,							-- [16] Projectile ID
		weaponName,						-- [17]	Weapon FullType
		bPassThrough,					-- [18] Plank / Metalbar barricaded window pass through rand values
		{0, 0, 0, 0},					-- [19] [1] Tree damage / [2] Plank barricade damage / [3] Metal barriacade damage / [4] Door damage
		{hitBoxMax, hitBoxMaxPVP,		-- [20] [1-2] Hitbox Max Size
		hitBoxHigh, hitBoxMid,			-- [20] [3-4] Hitbox ratios PVE
		hitBoxHighPVP, hitBoxMidPVP},	-- [20]	[5-6] Hitbox ratios PVP
		{friendlyFire,					-- [21] [1] Allow damage to friendly NPCs?
		isPVPOn,						-- [21]	[2] Is player enabled PVP? : Enabled - true / Disabled - false
		isFactionPVP,					-- [21] [3] Is player enabled faction PVP? : Enabled - true / Disabled - false
		notInNonPVPZone,				-- [21] [4] Is Player not in the Non-PVP zone? Yes - true / No - false
		ignoreSafety},					-- [21] [5]
		projDirectionZ,					-- [22] Projectile direction (Z)
		fakeAngle						-- [23] Fake angle for shoot high or low level
	}
	-- Projectile location X, Y ,Z
	local xyOff = 0.6
	local zOff = 0.45
	if self.aimLyingOff ~= 0 then
		xyOff = 0.05
	end
	if player:getVariableBoolean("isCrawling") then
		xyOff = 0.9
		zOff = 0.1
	elseif player:getVariableBoolean("IsCrouchAim") then
		zOff = 0.3
	end
	projInfo[7][1]	= projInfo[7][1] + (projInfo[5][2] * xyOff)
	projInfo[7][2]	= projInfo[7][2] + (projInfo[5][3] * xyOff)
	projInfo[7][3]	= projInfo[7][3] + zOff

	-- Slightly debuff rifle range
	if projInfo[3] == "Rifle" then
		projInfo[9] = projInfo[9] * 0.9
	end

	projInfo[4] = getCell():getGridSquare(projInfo[7][1], projInfo[7][2], projInfo[7][3])
	if projInfo[4] == nil then return end

	-- Damage adjustment
	if SandboxVars.ImprovedProjectile.IPPJDamageAdjustment then
		projInfo[8] = 2.64575 * projInfo[8]^0.5
	end
	-- Apply damage multiplier
	projInfo[8] = projInfo[8] * SandboxVars.ImprovedProjectile.IPPJDamageMult
	if projInfo[8] < 0.1 then
		projInfo[8] = 0.1 + ZombRandFloat(0.0, 0.1)
	end
	-- Apply range multiplier
	projInfo[9] = projInfo[9] * SandboxVars.ImprovedProjectile.IPPJRangeMult
	-- Apply speed multiplier
	projInfo[10][1] = projInfo[10][1] * SandboxVars.ImprovedProjectile.IPPJSpeedMult

	local distToTarget = 0		-- Distance to where player is aiming
	if IPPJAimOff ~= 0 or self.aimLyingOff ~= 0 then
		local heightDiff = IPPJAimOff
		if self.aimLyingOff ~= 0 then
			heightDiff = heightDiff - zOff + 0.1
		end
		local mouseX, mouseY = getMouseXScaled(), getMouseYScaled()
		--local aimZ = playerZ + IPPJAimOff
		local aimX, aimY = ISCoordConversion.ToWorld(mouseX, mouseY, playerZ)
		aimX = aimX + 1.5
		aimY = aimY + 1.5
		distToTarget = math.sqrt((aimX - projInfo[7][1])^2 + (aimY - projInfo[7][2])^2)
		projInfo[22] = (heightDiff / distToTarget) * projInfo[10][1]
		if math.abs(projInfo[22]) > 0.5 then
			projInfo[10][1] = projInfo[10][1] / (math.abs(projInfo[22]) / 0.5)
			projInfo[22] = (heightDiff / distToTarget) * projInfo[10][1]
		end
		--if projInfo[3] ~= "Shotgun" then
			aimX = aimX - (3 * heightDiff)
			aimY = aimY - (3 * heightDiff)
			local xOff = aimX - projInfo[7][1]
			local yOff = aimY - projInfo[7][2]
			projInfo[23] = (math.atan2(yOff, xOff) * 180) / math.pi		-- Set fake angle for setWorldZRotation function
		--end
		--print(string.format("[IPPJ] IPPJAimOff : %.3f / disToTarget : %.3f / speed : %.3f / speedZ : %.3f", IPPJAimOff, distToTarget, projInfo[10][1], projInfo[22]))
	end

	local reducer = SandboxVars.ImprovedProjectile.IPPJDmgReduction * 0.01
	projInfo[13] = (projInfo[8] * reducer) / math.ceil(projInfo[9] / projInfo[10][1])

	projInfo["weapon"] = weapon

	projInfo[19][1] = projInfo[8] * 80 * SandboxVars.ImprovedProjectile.IPPJTreeDamageMult
	projInfo[19][2] = projInfo[8] * 50 * SandboxVars.ImprovedProjectile.IPPJBarricadeDamageMult
	projInfo[19][3] = projInfo[8] * 40 * SandboxVars.ImprovedProjectile.IPPJBarricadeDamageMult
	projInfo[19][4] = projInfo[8] * 30 * SandboxVars.ImprovedProjectile.IPPJDoorDamageMult
	-- Shotgun needs pellet setting
	local pelletNumber = SandboxVars.ImprovedProjectile.IPPJShotgunPellet
	if projInfo[3] == "Shotgun" and pelletNumber > 1 then
		local originDirection	= projInfo[5][1]
		local originDirTrans	= (originDirection * 180) / math.pi
		local angleDiff			= projInfo[23] or originDirTrans
		local angleOff			= originDirTrans - angleDiff
		local shotgunDiv		= (SandboxVars.ImprovedProjectile.IPPJShotgunDivision * math.max((1 - weapon:getModData().IPPJMinAngleParts), 0)) / 360
		local shotgunDivPellet	= (shotgunDiv * 2) / pelletNumber

		projInfo[8]				= projInfo[8] / (pelletNumber^0.3)
		projInfo[11]			= 1

		local ojbMult = 4 / pelletNumber
		projInfo[19][1] = projInfo[19][1] * ojbMult
		projInfo[19][2] = projInfo[19][2] * ojbMult
		projInfo[19][3] = projInfo[19][3] * ojbMult
		projInfo[19][4] = projInfo[19][4] * ojbMult
		for i = 1, pelletNumber do
			local pelletDirection = originDirection
			if SandboxVars.ImprovedProjectile.IPPJShotgunEvenDistribution then
				pelletDirection	= pelletDirection - (math.pi * shotgunDiv) + (math.pi * shotgunDivPellet * (i - 1))
			else
				pelletDirection	= pelletDirection + ZombRandFloat(-math.pi * shotgunDiv, math.pi * shotgunDiv)
			end
			local pelletX, pelletY	= math.cos(pelletDirection), math.sin(pelletDirection)
			pelletDirection = (pelletDirection * 180) / math.pi
			projInfo[23]	= pelletDirection - angleOff
			if pelletDirection < -180 then
				pelletDirection = 360 + pelletDirection
			elseif pelletDirection > 180 then
				pelletDirection = pelletDirection - 360
			end
			projInfo[5] 	= {pelletDirection, pelletX, pelletY}
			projInfo[10]	= {projInfo[10][1], pelletX * projInfo[10][1], pelletY * projInfo[10][1]}
			projInfo[16]	= self.projId
			projInfo[18]	= {ZombRand(5) + 1, ZombRand(4) + 1}
			if self.checkBlockedOnShoot(pelletDirection, projInfo[6], projInfo[7], projInfo[19], projInfo[15], projInfo[18], projInfo[17]) then
				if isClient() and SandboxVars.ImprovedProjectile.IPPJRemoveProjectile == 1 then
					sendClientCommand("IPPJ", "createProjectile", {player:getOnlineID(), createInfoTableServer(projInfo)})
				end
				table.insert(self.activeProjectiles, self.createInfoTable(projInfo))
				self.projId = self.projId + 1
			end
		end
	else
		projInfo[5][1] = (projInfo[5][1] * 180) / math.pi
		if projInfo[5][1] < -180 then
			projInfo[5][1] = 360 + projInfo[5][1]
		elseif projInfo[5][1] > 180 then
			projInfo[5][1] = projInfo[5][1] - 360
		end

		projInfo[10][2] = projInfo[10][2] * projInfo[10][1]
		projInfo[10][3] = projInfo[10][3] * projInfo[10][1]

		if not projInfo[11] or projInfo[11] <= 0 then
			projInfo[11] = 1
		end
		projInfo[18] = {ZombRand(5) + 1, ZombRand(4) + 1}
		projInfo[23] = projInfo[23] or projInfo[5][1]
		if self.checkBlockedOnShoot(projInfo[5][1], projInfo[6], projInfo[7], projInfo[19], projInfo[15], projInfo[18], projInfo[17]) then
			if isClient() and SandboxVars.ImprovedProjectile.IPPJRemoveProjectile == 1 then
				sendClientCommand("IPPJ", "createProjectile", {player:getOnlineID(), createInfoTableServer(projInfo)})
			end
			table.insert(self.activeProjectiles, projInfo)
			self.projId = self.projId + 1
		end
	end
	self:calcRecoil(weapon)

	local recoil = self.currInfo["recoil"]
	-- For 'True Crouching' / 'True Crawl' mod
	if player:getVariableBoolean("isCrawling") then
		recoil = recoil * 0.64
	elseif player:getVariableBoolean("IsCrouchAim") then
		recoil = recoil * 0.82
	end

	if penaltyTimer[1] < 10 then
		penaltyTimer[1] = penaltyTimer[1] + recoil * (0.03 - 0.0015 * self.Nimble)
	end
	local recoilFinal = recoil * SandboxVars.ImprovedProjectile.IPPJRecoilMult * self.moodleStats[2]

	-- Visual recoil
	if SandboxVars.ImprovedProjectile.IPPJVisualRecoil == 1 then
		recoil = recoil * IPPJSettings.VisualRecoilMult
	else
		recoil = recoil * SandboxVars.ImprovedProjectile.IPPJVisualRecoilMult
	end
	if (SandboxVars.ImprovedProjectile.IPPJVisualRecoil == 1 and IPPJSettings.VisualRecoil) or SandboxVars.ImprovedProjectile.IPPJVisualRecoil == 2 then
		self.visualRecoil[5] = math.floor((recoilFinal) / self.currInfo["gameTimeMult"])
		if self.visualRecoil[5] > 0 then
			if not weapon:getFireMode() or string.find(weapon:getFireMode(), "Single") then
				self.visualRecoil[1] = 0
				self.visualRecoil[2] = -recoil * 1.5
				self.visualRecoil[3] = 0
				self.visualRecoil[4] = self.visualRecoil[2] / self.visualRecoil[5]
			else
				local rAngle = ZombRandFloat(-3.1415927, 3.1415927)
				self.visualRecoil[1] = recoil * math.cos(rAngle) * ZombRandFloat(1.5, 2.5)
				self.visualRecoil[2] = recoil * math.sin(rAngle) * ZombRandFloat(1.5, 2.5)
				self.visualRecoil[3] = self.visualRecoil[1] / self.visualRecoil[5]
				self.visualRecoil[4] = self.visualRecoil[2] / self.visualRecoil[5]
			end
		end
	else
		self.visualRecoil = {0, 0, 0, 0, 0}
	end

	--##
	local tempRecoil = recoilFinal * 0.55
	if self.aimSize + tempRecoil < self.currInfo["aimSizeMin"] + self.moodleStats[4] then
		recoilFinal = recoilFinal * (0.43 - self.Aiming * 0.003)
	end
	self.aimSize = self.aimSize + recoilFinal

	--self.currInfo["weaponRangeOrigin"] = weapon:getMaxRange(player)
	self.currInfo["weaponRange"] = projInfo[9] + 0.7

	--print(string.format("[IPPJ] Damage : %.3f / %.3f", projDamage, projInfo[8]))
	--print(string.format("[IPPJ] MaxHitCount : %d", projInfo[11]))
	--print(string.format("[IPPJ] Aiming : %.3f / Gametimemult : %.3f", ImprovedProjectile.currInfo["aiming"], ImprovedProjectile.currInfo["gameTimeMult"]))
	--print(string.format("[IPPJ] Recoil : %.3f", recoil * SandboxVars.ImprovedProjectile.IPPJRecoilMult))
	--print(string.format("[IPPJ] Recoil : %.3f / %.3f / %.3f / %.3f / %.3f", ImprovedProjectile.visualRecoil[1], ImprovedProjectile.visualRecoil[2], ImprovedProjectile.visualRecoil[3], ImprovedProjectile.visualRecoil[4], ImprovedProjectile.visualRecoil[5]))
end

--*************************************************************************************--
--** Check player perk level and update
--*************************************************************************************--
function ImprovedProjectile:checkPerkLevel(player)
	self.Strength	= player:getPerkLevel(Perks.Strength)
	self.Aiming		= player:getPerkLevel(Perks.Aiming)
	self.Nimble		= player:getPerkLevel(Perks.Nimble)
	if self.isValid then
		local weapon = player:getPrimaryHandItem()
		if not weapon then return end
		self.currInfo["weaponRangeOrigin"] = weapon:getMaxRange(player)
		self.currInfo["weaponRange"] = self.currInfo["weaponType"] == "Rifle" and self.currInfo["weaponRangeOrigin"] * 0.9 or self.currInfo["weaponRangeOrigin"]
		self.currInfo["weaponRange"] = self.currInfo["weaponRange"] * SandboxVars.ImprovedProjectile.IPPJRangeMult + 0.7
		self.currInfo["recoilDenom"] = (((self.Aiming * 1.1) + ((self.Strength - 5) * 0.8)) * 0.067) + 1
		--self.currInfo["recoilDenom"] = ((self.Aiming + ((self.Strength - 5) * 0.8)) * 0.067) + 1
		self:calcRecoil(weapon)
		self:calcAiming(player, weapon)
		self:calcAccChance()
	end
end

local function onShootWeapon(player, weapon)
	if not player or not weapon or not player:isLocalPlayer() then return end
	if ImprovedProjectile.isValid and ImprovedProjectile.currInfo["weaponName"] == weapon:getFullType() then

		if SandboxVars.ImprovedProjectile.IPPJHitBoxHighRatio + SandboxVars.ImprovedProjectile.IPPJHitBoxMidRatio + SandboxVars.ImprovedProjectile.IPPJHitBoxLowRatio ~= 100
			and SandboxVars.ImprovedProjectile.IPPJPVPHitBoxHighRatio + SandboxVars.ImprovedProjectile.IPPJPVPHitBoxMidRatio + SandboxVars.ImprovedProjectile.IPPJPVPHitBoxLowRatio ~= 100 then
			player:Say(getText("IGUI_HitBoxRatioSumError"))
			return
		end

		if ImprovedProjectile.blockVehicleShoot == true then return end
		--ImprovedProjectile:checkPerkLevel(player)
		ImprovedProjectile:onShootWeapon(player, weapon)
	end
end

Events.OnKeyKeepPressed.Add(onKeyKeepPressed)
Events.OnKeyPressed.Add(onKeyPressed)
Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnRenderTick.Add(drawText)
Events.OnTick.Add(projectileOnTick)
Events.OnWeaponSwingHitPoint.Add(onShootWeapon)

do
	Hook.Attack.Remove(ISReloadWeaponAction.attackHook)
	local old_attackHook = ISReloadWeaponAction.attackHook
	ISReloadWeaponAction.attackHook = function(player, chargeDelta, weapon, ...)
		if (ImprovedProjectile.isValid or ImprovedProjectile.isValidExplo) and ImprovedProjectile.blockVehicleShoot == true then return end
		old_attackHook(player, chargeDelta, weapon, ...)
	end
	Hook.Attack.Add(ISReloadWeaponAction.attackHook)
end