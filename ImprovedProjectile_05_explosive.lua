if isServer() then return end
if not IPPJModCheck then return end

--require "ImprovedProjectile_main"
require "luautils"

ImprovedProjectile.isValidExplo = false
ImprovedProjectile.exploInfo = {}
ImprovedProjectile.isPreset = false
ImprovedProjectile.activeExplosives = {}

ImprovedProjectile.aimExplo = {}
ImprovedProjectile.aimExplo.instance = nil

ImprovedProjectile.explosions = {}

local zombieMidReact		= {"ShotBelly", "ShotChestL", "ShotChestR"}
local zombieMidReactCrit	= {"ShotBellyStep", "ShotChestStepL", "ShotChestStepR"}

local texturetable = {
	"media/textures/IPPJEffects/Big/Explosion01.png", "media/textures/IPPJEffects/Big/Explosion02.png", "media/textures/IPPJEffects/Big/Explosion03.png",
	"media/textures/IPPJEffects/Big/Explosion04.png", "media/textures/IPPJEffects/Big/Explosion05.png", "media/textures/IPPJEffects/Big/Explosion06.png",
	"media/textures/IPPJEffects/Big/Explosion07.png", "media/textures/IPPJEffects/Big/Explosion08.png", "media/textures/IPPJEffects/Big/Explosion09.png",
	"media/textures/IPPJEffects/Big/Explosion10.png", "media/textures/IPPJEffects/Big/Explosion11.png", "media/textures/IPPJEffects/Big/Explosion12.png",
	"media/textures/IPPJEffects/Big/Explosion13.png", "media/textures/IPPJEffects/Big/Explosion14.png", "media/textures/IPPJEffects/Big/Explosion15.png",
	"media/textures/IPPJEffects/Big/Explosion16.png", "media/textures/IPPJEffects/Big/Explosion17.png",

	"media/textures/IPPJEffects/Mid/Explosion01.png", "media/textures/IPPJEffects/Mid/Explosion02.png", "media/textures/IPPJEffects/Mid/Explosion03.png",
	"media/textures/IPPJEffects/Mid/Explosion04.png", "media/textures/IPPJEffects/Mid/Explosion05.png", "media/textures/IPPJEffects/Mid/Explosion06.png",
	"media/textures/IPPJEffects/Mid/Explosion07.png", "media/textures/IPPJEffects/Mid/Explosion08.png", "media/textures/IPPJEffects/Mid/Explosion09.png",
	"media/textures/IPPJEffects/Mid/Explosion10.png", "media/textures/IPPJEffects/Mid/Explosion11.png", "media/textures/IPPJEffects/Mid/Explosion12.png",
	"media/textures/IPPJEffects/Mid/Explosion13.png", "media/textures/IPPJEffects/Mid/Explosion14.png", "media/textures/IPPJEffects/Mid/Explosion15.png",
	"media/textures/IPPJEffects/Mid/Explosion16.png", "media/textures/IPPJEffects/Mid/Explosion17.png",

	"media/textures/IPPJEffects/Small/Explosion01.png", "media/textures/IPPJEffects/Small/Explosion02.png", "media/textures/IPPJEffects/Small/Explosion03.png",
	"media/textures/IPPJEffects/Small/Explosion04.png", "media/textures/IPPJEffects/Small/Explosion05.png", "media/textures/IPPJEffects/Small/Explosion06.png",
	"media/textures/IPPJEffects/Small/Explosion07.png", "media/textures/IPPJEffects/Small/Explosion08.png", "media/textures/IPPJEffects/Small/Explosion09.png",
	"media/textures/IPPJEffects/Small/Explosion10.png", "media/textures/IPPJEffects/Small/Explosion11.png", "media/textures/IPPJEffects/Small/Explosion12.png",
	"media/textures/IPPJEffects/Small/Explosion13.png", "media/textures/IPPJEffects/Small/Explosion14.png", "media/textures/IPPJEffects/Small/Explosion15.png",
	"media/textures/IPPJEffects/Small/Explosion16.png", "media/textures/IPPJEffects/Small/Explosion17.png"
}

local angleOff = 0
local function onKeyKeepPressed(key) -- Control angle
	if key ~= getCore():getKey("IPPJ_AimLevel") then return end
	local player = getSpecificPlayer(0)
	if Mouse.getWheelState() > 0 then
		if player:isAiming() and ImprovedProjectile.aimExplo.instance then
			IPPJzoomScroll = 1
			if angleOff < 10 then
				--IPPJzoomScroll = 1
				angleOff = angleOff + 1
			end
			return
		end
	elseif Mouse.getWheelState() < 0 then
		if player:isAiming() and ImprovedProjectile.aimExplo.instance then
			IPPJzoomScroll = -1
			if angleOff > 0 then
				--IPPJzoomScroll = -1
				angleOff = angleOff - 1
			end
			return
		end
	end
end

local function onKeyPressed(key) -- Load preset weapon setting
	if key ~= getCore():getKey("ReloadWeapon") then return end
	local player = getSpecificPlayer(0)
	local weapon = player:getPrimaryHandItem()

	if not weapon then return end

	if IPPJPreset and IPPJPreset[weapon:getFullType()] then
		if not ImprovedProjectile.isValidExplo then
			if SandboxVars.ImprovedProjectile.IPPJEnableExplo then
				if instanceof(weapon, "HandWeapon") then
					weapon:getModData().IPPJSaveInfo = {weapon:getMinRange(), weapon:getMaxRange(), weapon:getMaxHitCount(), weapon:getSwingSound()}
					weapon:setMinRange(0)
					weapon:setMaxRange(0)
					weapon:setMaxHitCount(0)
				end
				weapon:getModData().IPPJPresetType = 1
				ImprovedProjectile:initExploInfoPreset(player, weapon, true)
			end
		else
			local savedInfo = weapon:getModData().IPPJSaveInfo
			if savedInfo then
				weapon:setMinRange(savedInfo[1])
				weapon:setMaxRange(savedInfo[2])
				weapon:setMaxHitCount(savedInfo[3])
				weapon:setSwingSound(savedInfo[4])
				weapon:getModData().IPPJSaveInfo = nil
			end
			ImprovedProjectile:initExploInfoPreset(player, weapon, false)
			weapon:getModData().IPPJPresetType = nil
		end
	end
end

local drawTrajectory = {}
local drawLevelCoords = nil
local drawCurve = TextDrawObject.new()
drawCurve:setOutlineColors(0, 0, 0, 1)
drawCurve:ReadString(UIFont.Medium, ".", -1)
local drawLevel = TextDrawObject.new()
drawLevel:setDefaultColors(1, 1, 1)
drawLevel:setOutlineColors(0, 0, 0, 1)
drawLevel:setAllowAnyImage(true)
drawLevel:setHorizontalAlign("left")
local fontMHeight = getTextManager():getFontHeight(UIFont.Medium) * 0.3
local function drawTrajectoryFunc()
	for i, v in pairs(drawTrajectory) do
		drawCurve:AddBatchedDraw(v[1], v[2], 1, 1, 1, v[3], true)
	end
	if drawLevelCoords then
		drawLevel:AddBatchedDraw(drawLevelCoords[1], drawLevelCoords[2], true)
	end
end

--*************************************************************************************--
--** Handle command from server
--*************************************************************************************--
local function createExploServer(module, command, arguments)
	if module ~= "IPPJ" or getPlayer():getOnlineID() == arguments[1] then return end

	if command == "createExplosive"  then
		local others = arguments[2]
		others[10] = getPlayerByOnlineID(arguments[1])
		others[13] = false
		table.insert(ImprovedProjectile.activeExplosives, others)
	elseif command == "clearPhysicsObject" then
		local player = getPlayerByOnlineID(arguments[1])
		local weapon = nil
		if player then
			weapon = player:getPrimaryHandItem()
		end

		if weapon and weapon:getFullType() == arguments[2] then
			weapon:setPhysicsObject(nil)
		end
	end
end

--*************************************************************************************--
--** Create projectile at square
--*************************************************************************************--
function ImprovedProjectile.createExploProjectile(square, projName, angle, coord, tex, item)
	if square:getZ() > 7 then return end
	local xOff, yOff, zOff = coord[1] - math.floor(coord[1]), coord[2] - math.floor(coord[2]), coord[3] - math.floor(coord[3])
	local invItem = item or InventoryItemFactory.CreateItem(projName)
	if not item and projName == "Base.IPPJDummyProjectile" and tex then
		invItem:setTexture(tex)
	end
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
--** Caculate explosive max range
--*************************************************************************************--
local function calcExplosiveRange(weapon, player)
	if ImprovedProjectile.exploInfo["exploRange"] then
		return ImprovedProjectile.exploInfo["exploRange"] + (ImprovedProjectile.Strength * 0.7) - player:getMoodleLevel(MoodleType.Endurance) + ImprovedProjectile.exploInfo["rangeMod"]
	elseif weapon:getSwingAnim() == "Throw" then
		return weapon:getMaxRange() + (ImprovedProjectile.Strength * 0.7) - player:getMoodleLevel(MoodleType.Endurance)
	else
		return weapon:getMaxRange()
	end
end

local function checkTarget(player, coord, cosT, sinT, halfSpeed, lastHit, pvp)
	local zombieTable	= {}
	local playerTable	= {}
	local hitBoxX		= halfSpeed * 1.2

	-- Prevent find zombie at same square
	local x = {}
	local y = {}
	local z = math.floor(coord[3])
	if coord[1] - math.floor(coord[1]) > 0.5 then
		table.insert(x, coord[1])
		table.insert(x, coord[1] + 0.5)
	else
		table.insert(x, coord[1] - 0.5)
		table.insert(x, coord[1])
	end
	if coord[2] - math.floor(coord[2]) > 0.5 then
		table.insert(y, coord[2])
		table.insert(y, coord[2] + 0.5)
	else
		table.insert(y, coord[2] - 0.5)
		table.insert(y, coord[2])
	end

	for ix, vx in pairs(x) do
		for jy, vy in pairs(y) do
			local sq = getCell():getOrCreateGridSquare(vx, vy, z)

			if sq:TreatAsSolidFloor() then
				local objects = sq:getMovingObjects()

				for i = 1, objects:size() do
					local movingObject = objects:get(i - 1)
					if instanceof(movingObject, "IsoZombie") and movingObject:isAlive() and movingObject ~= lastHit then
						table.insert(zombieTable, movingObject)
					elseif instanceof(movingObject,"IsoPlayer") and movingObject ~= player then
						if not isClient() then
						-- Singleplayer NPC Mods
							if pvp then
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

	local distance			= 0
	local zombieDataTable	= {nil, 10 , 0.2}	-- {{zombie, distance, multiplier}, ...}
	local playerCheck		= {nil, 10 , 0.2}	-- player / distance / multiplier

	for i, v in pairs(zombieTable) do
		local movX	= v:getX() - coord[1]
		local movY	= v:getY() - coord[2]
		local rotX	= math.abs((cosT * movX) + (sinT * movY))
		local rotY	= math.abs((cosT * movY) - (sinT * movX))
		local zData	= {false, 10, 0}

		if rotX <= hitBoxX and rotY <= 0.6 then
			distance = movX^2 + movY^2
			if distance < zombieDataTable[2] then
				zombieDataTable = {v, distance, 1}
			end
		end
	end

	for i, v in pairs(playerTable) do
		local movX	= v:getX() - coord[1]
		local movY	= v:getY() - coord[2]
		local rotX	= math.abs((cosT * movX) + (sinT * movY))
		local rotY	= math.abs((cosT * movY) - (sinT * movX))

		if rotX <= hitBoxX and rotY <= 0.6 then
			distance = movX^2 + movY^2
			if distance < playerCheck[2] then
				playerCheck = {v, distance, 1}
			end
		end
	end

	return zombieDataTable, playerCheck
end

local function addExplosion(trap, square)
	if not IPPJSettings.ExplosionEffect then return end

	local explosive = trap:getItem()

	if explosive and string.find(explosive:getPhysicsObject(), "Noise") then return end

	if trap:getExplosionRange() and trap:getExplosionRange() > 0 then
		local explodeIdx = square:getObjects():indexOf(trap)
		local dummy = nil
		if isClient() then
			dummy = IsoObject.new(square, "")
			square:AddTileObject(dummy, explodeIdx)
		end
		local explosion = {square, 1, dummy, trap:getExplosionRange()}
		table.insert(ImprovedProjectile.explosions, explosion)
	end
end

local function drawEffects()
	local explosions = ImprovedProjectile.explosions
	local mult = getGameTime():getMultiplier()

	for i, v in pairs(explosions) do
		if v[2] > 17 then
			--v[1]:transmitRemoveItemFromSquare(v["object"])
			v[1]:RemoveTileObject(v["object"])
			getCell():removeLamppost(v["light"])

			if v[3] then
				--v[1]:transmitRemoveItemFromSquare(v[3])
				v[1]:RemoveTileObject(v[3])
			end

			explosions[i] = nil
		else
			if not v["object"] then
				v["object"] = IsoObject.new(v[1], "")
				if v[4] > 4 then
					v["object"]:setOffsetX(240)
					v["object"]:setOffsetY(240)
					v["texOffset"] = 0
				elseif v[4] > 2 then
					v["object"]:setOffsetX(140)
					v["object"]:setOffsetY(140)
					v["texOffset"] = 17
				else
					v["object"]:setOffsetX(60)
					v["object"]:setOffsetY(60)
					v["texOffset"] = 34
				end
				v[1]:AddSpecialObject(v["object"])
				v["light"] = IsoLightSource.new(v[1]:getX() + 0.5, v[1]:getY() + 0.5, v[1]:getZ(), 1, 0.7, 0.1, 15, 28)
				getCell():addLamppost(v["light"])
			end

			if not v["delay"] or v["delay"] < 0 then
				v["object"]:getSprite():LoadFrameExplicit(texturetable[v[2] + v["texOffset"]])
				v["delay"] = 2.5
				v[2] = v[2] + 1
			else
				v["delay"] = v["delay"] - mult
			end
		end
	end
end

local pUpdateTick = 0
function ImprovedProjectile:playerOnTickExplo()
	if not SandboxVars.ImprovedProjectile.IPPJEnableExplo then return end

	local player = getPlayer()
	if not player then return end

	local weapon = player:getPrimaryHandItem()

	if player:isAiming() and self.isValidExplo and self.exploInfo["weaponName"] == weapon:getFullType() then
		pUpdateTick = pUpdateTick - 1
		Mouse.setCursorVisible(false)
		weapon:setMaxHitCount(0)

		if not self.aimExplo.instance then
			getCore():setIsoCursorVisibility(0)
			self.aimExplo.instance = ISExplosiveCursor:new("", "", player)
		end

		if pUpdateTick < 1 then
			if self.exploInfo["wTexture"] and self.exploInfo["exploName"] ~= "Base.IPPJDummyProjectile" and self.exploInfo["wTexture"] ~= weapon:getTexture() then
				self.exploInfo["exploName"] = "Base.IPPJDummyProjectile"
				self.exploInfo["wTexture"] = weapon:getTexture()
			end

			drawTrajectory = {}
			drawLevelCoords = nil
			local mouseX, mouseY = getMouseXScaled(), getMouseYScaled()
			local playerZ = player:getZ()
			local aimX, aimY = ISCoordConversion.ToWorld(mouseX, mouseY, playerZ)
			aimX = aimX + 1.5
			aimY = aimY + 1.5
			local distance = math.sqrt((player:getX() - aimX)^2 + (player:getY() - aimY)^2)
			distance = math.max(distance, 1)

			local range = calcExplosiveRange(weapon, player)
			range = math.min(range, distance)

			local zOff = 0
			if player:getVariableBoolean("isCrawling") then
				zOff = 0.15
			elseif player:getVariableBoolean("IsCrouchAim") then
				zOff = 0.35
			else
				zOff = 0.5
			end
			playerZ = playerZ + zOff

			local exploDir	= player:getForwardDirection():getDirection()
			local exploDirX	= math.cos(exploDir)
			local exploDirY	= math.sin(exploDir)
			local angle = (exploDir * 180) / math.pi
			local speed = 0.35 - angleOff * 0.01

			-- Control shoot angle
			local shootAngle = 0
			if self.exploInfo["exploType"] ~= "Rocket" then
				shootAngle = (1 + 0.4 * angleOff) / (range * 4)
				range = range * (1 - 0.01 * angleOff)
			else
				speed = 0.8
			end

			self.aimExplo.instance:setDisable(false)
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
					self.aimExplo.instance:setDisable(true)
					pUpdateTick = 4
					return
				else
					self.blockVehicleShoot = false
				end

				BaseVehicle.releaseVector2(vec2V)
				BaseVehicle.releaseVector2(vec2T)
				BaseVehicle.releaseVector3f(vec3f)
			else
				self.blockVehicleShoot = false
			end

			local travel = speed
			local curve = {player:getX(), player:getY(), playerZ}
			local zoom = getCore():getZoom(0)
			local nextZ = playerZ
			local A = 1
			local blockCheck = false
			self.aimExplo.instance:setOk(true)
			while true do -- Draw trajectory
				local square = getCell():getOrCreateGridSquare(curve[1], curve[2], curve[3])
				nextZ = playerZ - (shootAngle * travel * (travel - range))
				--print(string.format("[IPPJ] nextZ : %.3f", nextZ))
				if self.exploInfo["exploType"] == "Rocket" and travel >= range then
					self.aimExplo.instance:setCoord(curve[1], curve[2], square:getZ())
					getCell():setDrag(self.aimExplo.instance, 0)
					break
				end

				local check1, check2 = ImprovedProjectile.checkBlockedCurve(square, angle, curve, {exploDirX * speed, exploDirY * speed, nextZ}, player)

				if check2 then
					local zDiff = square:getZ() - math.floor(player:getZ())
					local txt = ""
					if zDiff ~= 0 then
						if zDiff > 0 then txt = "[img=media/ui/VanillaArrowUp.png] " .. tostring(zDiff)
						else txt = "[img=media/ui/VanillaArrowDown.png] " .. tostring(math.abs(zDiff))
						end
						drawLevel:ReadString(UIFont.Medium, txt, -1)

						local tx, ty = ISCoordConversion.ToScreen(square:getX(), square:getY(), square:getZ())
						tx = tx / zoom
						ty = ty / zoom
						--drawLevel:AddBatchedDraw(tx - 25, ty + 80 / zoom, true)
						drawLevelCoords = {tx - 25, ty + 80 / zoom}
					end
					self.aimExplo.instance:setCoord(curve[1], curve[2], square:getZ())
					if square:getProperties():Is(IsoFlagType.water) then
						self.aimExplo.instance:setOk(false)
					end
					getCell():setDrag(self.aimExplo.instance, 0)
					break
				elseif check1 then
					self.aimExplo.instance:setOk(false)
					blockCheck = true
					--getCell():setDrag(nil, 0)
					--break
				end

				if SandboxVars.ImprovedProjectile.IPPJExploTrajectory and not blockCheck and travel > speed then
					local x, y = ISCoordConversion.ToScreen(curve[1], curve[2], curve[3])
					x = x / zoom
					y = y / zoom
					if self.exploInfo["exploType"] == "Rocket" then
						--drawCurve:AddBatchedDraw(x, y - fontMHeight, 1, 1, 1, A, true)
						if A > 0 then
							table.insert(drawTrajectory, {x, y - fontMHeight, A})
							A = math.max(0, A - 0.05)
						end
					else
						if square:isCouldSee(0) then
							--drawCurve:AddBatchedDraw(x, y - fontMHeight, 1, 1, 1, 1, true)
							table.insert(drawTrajectory, {x, y - fontMHeight, 1})
						else
							--drawCurve:AddBatchedDraw(x, y - fontMHeight, 1, 1, 1, 0.5, true)
							table.insert(drawTrajectory, {x, y - fontMHeight, 0.5})
						end
					end
				end

				curve[1] = curve[1] + exploDirX * speed
				curve[2] = curve[2] + exploDirY * speed
				curve[3] = nextZ
				travel = travel + speed
			end

			pUpdateTick = 4
		end
	elseif self.aimExplo.instance then
		getCore():setIsoCursorVisibility(UserIsoCursorVis)
		getCell():setDrag(nil, 0)
		self.aimExplo.instance = nil
		angleOff = 0
		pUpdateTick = 0
		drawTrajectory = {}
		drawLevelCoords = nil
	end
end

--*************************************************************************************--
--** Check explosive on tick
--*************************************************************************************--
local function explosiveOnTick()
	ImprovedProjectile:playerOnTickExplo()
	drawEffects()

	local exploTable = ImprovedProjectile.activeExplosives
	local checkRemoveProjectile = SandboxVars.ImprovedProjectile.IPPJRemoveProjectile	-- Remove projectile?
	local gMult = math.max(0.7, getGameTime():getMultiplier() / 0.3)

	for iv, v in pairs(exploTable) do
		v[3] = getCell():getOrCreateGridSquare(v[6][1], v[6][2], v[6][3])

		if v[3] then
			local checkExplo = true

			v[8][1] = math.min(0.95, v[8][2] * gMult)
			-----------------------------------------------------------------------------
			-- Create explosive ---------------------------------------------------------
			-----------------------------------------------------------------------------
			ImprovedProjectile.removeProjectile(v[1])
			if checkRemoveProjectile ~= 3 and getCore():isOption3DGroundItem() and v[3]:IsOnScreen() then
				v[1] = ImprovedProjectile.createExploProjectile(v[3], v[2], v[12], v[6], v[18], v[1])
				if v[16] == "Rocket" then
					if v["light"] then getCell():removeLamppost(v["light"]) end
					v["light"] = IsoLightSource.new(v[6][1], v[6][2], v[6][3], 1, 0.7, 0.1, 3, 1)
					getCell():addLamppost(v["light"])
				end
			end

			local nextZ = v[6][3]
			if v[14][1] > 0 then
				nextZ = v[6][3] - v[14][1] * v[8][1]
			--[[elseif v[14][1] < 0 then
				nextZ = -(v[15] * v[7][2] * (v[7][2] - v[7][1]))]]
			elseif not (v[16] == "Rocket") then
				nextZ = v[5][3] - (v[15] * v[7][2] * (v[7][2] - v[7][1]))
				--print("[IPPJ] ", nextZ)
			end

			-----------------------------------------------------------------------------
			-- Check projectile hits zombie ---------------------------------------------
			-----------------------------------------------------------------------------
			local hitCheck = false
			if not v[17][1] then
				local zombie, hitPlayer = checkTarget(v[10], v[6], v[4][2], v[4][3], v[8][1] * 0.5, v["lastHit"], SandboxVars.ImprovedProjectile.IPPJFriendlyFire)
				if zombie[1] then
					if ImprovedProjectile.checkHitOverWallExplo(zombie[1], v[6], v[10], v[11], v[13]) then
						hitCheck = true
						if v[13] then
							local hitDamage = v[17][2][1] + ZombRandFloat(0, v[17][2][2])
							local critical = false
							if ZombRand(20) < 3 then
								critical = true
								hitDamage = hitDamage * 2.5
							end

							local weapon = InventoryItemFactory.CreateItem(v[9])
							local zModData = zombie[1]:getModData()

							triggerEvent("OnWeaponHitCharacter", v[10], zombie[1], weapon, hitDamage)
							zombie[1]:setAttackedBy(v[10])
							zombie[1]:setTarget(v[10])

							zombie[1]:setHealth(zombie[1]:getHealth() - hitDamage)

							local zombieReaction = ""
							if zombie[1]:isDead() then
								zombie[1]:setHitReaction("ShotBelly")
								zombie[1]:Kill(v[10])
								v[10]:setZombieKills(v[10]:getZombieKills() + 1)

								zModData.stuck_Body01 = nil
								zModData.stuck_Body02 = nil
								zModData.stuck_Body03 = nil
								zModData.stuck_Body04 = nil
								zModData.stuck_Body05 = nil
								zModData.stuck_Body06 = nil
							else
								if SandboxVars.ImprovedProjectile.IPPJEnableZombieHitReact then
									if zombie[1]:isProne() then
										zombieReaction = "FloorBack"
									elseif critical then
										zombieReaction = zombieMidReactCrit[ZombRand(3) + 1]
									else
										zombieReaction = zombieMidReact[ZombRand(3) + 1]
									end
									zombie[1]:setHitReaction(zombieReaction)
								end
								zombie[1]:addBlood(20)
								v["lastHit"] = zombie[1]
							end
							getSoundManager():PlayWorldSoundWav("IPPJBallHit", zombie[1]:getCurrentSquare(), 1, 1, 1, true)
							v["lastTreeCar"] = nil

							if isClient() then
								sendClientCommand("IPPJ", "hitZombie", {v[10]:getOnlineID(), zombie[1]:getOnlineID(), {zombie[1]:getX(), zombie[1]:getY(), zombie[1]:getZ()}, v[9], hitDamage, zombieReaction})
							end
						end
					end
				elseif hitPlayer[1] and not isClient() then
					if ImprovedProjectile.checkHitOverWallExplo(hitPlayer[1], v[6], v[10], v[11], v[13]) then
						hitCheck = true
						if v[13] then
							local hitDamage = v[17][2][1] + ZombRandFloat(0, v[17][2][2])
							local critical = false
							if ZombRand(20) < 3 then
								critical = true
								hitDamage = hitDamage * 2.5
							end

							local headShot = {
								BodyPartType.Neck,			BodyPartType.Head
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

							local heightDiff = v[6][3] - hitPlayer[1]:getZ()

							if heightDiff > 0.6 then
								hitPart = headShot[ZombRand(2) + 1]
							elseif heightDiff > 0.2 then
								hitPart = bodyShot[ZombRand(17) + 1]
							else
								hitPart = terminalShot[ZombRand(4) + 1]
							end

							local hitPlayerPart = hitPlayer[1]:getBodyDamage():getBodyPart(hitPart)
							local defenseBullet	= hitPlayer[1]:getBodyPartClothingDefense(hitPart:index(), false, true)
							local defenseBite	= hitPlayer[1]:getBodyPartClothingDefense(hitPart:index(), true, false)
							local finalDefense	= (100 + (defenseBullet * 0.5) + (defenseBite * 0.3)) / 100

							hitDamage = hitDamage / finalDefense

							local weapon = InventoryItemFactory.CreateItem(v[9])

							triggerEvent("OnWeaponHitCharacter", v[10], hitPlayer[1], weapon, hitDamage)
							hitPlayer[1]:addBlood(20)
							hitPlayerPart:ReduceHealth(hitDamage)
						end
					end
				end
			end

			if hitCheck then
				-- Bounce
				if v[17][3] and v[17][3][3] then
					local bounceAngle = 0
					if v[4][1] >= 0 then bounceAngle = -180 + v[4][1]
					else bounceAngle = 180 + v[4][1] end

					bounceAngle = bounceAngle + (v[14][2] - 0.5) * 90

					if bounceAngle < -180 then
						bounceAngle = 360 + bounceAngle
					elseif bounceAngle > 180 then
						bounceAngle = bounceAngle - 360
					end
					local angleRad = (bounceAngle * math.pi) / 180

					v[4] = {bounceAngle, math.cos(angleRad), math.sin(angleRad)}
					v[8][2] = math.max(0.02, v[8][2] * 0.6)
					v[12] = bounceAngle
					v[14][2] = (v[14][2] * 10) - math.floor(v[14][2] * 10)
					v[17][2] = {math.max(0.02, v[17][2][1] * 0.5), math.max(0.02, v[17][2][2] * 0.5)}
					v["blocked"] = "Zombie"
				-- Not bounce
				elseif v[17][4] then -- Fall item
					if v[13] then
						local square = v[3]
						local fallItem = InventoryItemFactory.CreateItem(v[2])
						if square:TreatAsSolidFloor() then
							local objs = square:getObjects()
							local surface = 0
							for i = 1, objs:size() do
								local obj = objs:get(i - 1)
								if obj:getSurfaceOffsetNoTable() > surface then
									surface = obj:getSurfaceOffsetNoTable()
								end
							end
							local xOff = v[6][1] - math.floor(v[6][1])
							local yOff = v[6][2] - math.floor(v[6][2])
							square:AddWorldInventoryItem(fallItem, xOff, yOff, surface * 0.01)
						end
					end
					ImprovedProjectile.removeProjectile(v[1])
					if v["light"] then getCell():removeLamppost(v["light"]) end
					exploTable[iv] = nil
					checkExplo = false
				end
			end

			if checkExplo then
				-----------------------------------------------------------------------------
				-- Check explosive hit Window / Wall / Door / Vehicle -----------------------
				-----------------------------------------------------------------------------
				local checkBlocked, bounceAngle, isHitCeilorTree, lastTreeCar = ImprovedProjectile.checkBlockedExplo(v[3], v[4][1], v[6],
																				{(v[8][1] * v[4][2]), (v[8][1] * v[4][3]), nextZ}, {0, 20, 0, 20},
																				v[10], v[11], v[9], v[13], v[14][2], v["lastTreeCar"], v[17][5])
				-- Blocked by object
				if bounceAngle then
					v["lastHit"] = nil
					v["lastTreeCar"] = lastTreeCar
					-- Rocket always explode when blocked
					if v[16] == "Rocket" then
						if v[13] then
							local square = v[3]
							if isHitCeilorTree == 2 then
								square = getCell():getOrCreateGridSquare(v[6][1] - v[4][2] * v[8][1], v[6][2] - v[4][3] * v[8][1], v[6][3])
							end
							local tempExplo = InventoryItemFactory.CreateItem(v[9])
							tempExplo:setTriggerExplosionTimer(0)
							if isClient() then
								tempExplo:setSmokeRange(0)
								square:syncIsoTrap(tempExplo)
							end
							local explode = IsoTrap.new(tempExplo, square:getCell(), square)
							square:AddTileObject(explode)
							explode:triggerExplosion(false)
						end
						ImprovedProjectile.removeProjectile(v[1])
						if v["light"] then getCell():removeLamppost(v["light"]) end
						exploTable[iv] = nil
						checkExplo = false
					-- Hit floor
					elseif bounceAngle == true then
						if not v[17][1] then	-- Not explo, bounce check
							v[14][1] = 0
							if not v["blocked"] then
								v[7][1] = v[7][1] * 0.3
								v[15] = v[15] * 3
							elseif v["blocked"] == "Zombie" then
								v[7][1] = v[7][1] * 0.1
								v[15] = v[15] * 6
							elseif v["blocked"] == "WallTree" then
								v[7][1] = v[7][1] * 0.2
								v[15] = v[15] * 4
							end
							v[8][2] = math.max(0.02, v[8][2] * 0.5)
							if v[3]:getProperties():Is(IsoFlagType.water) then	-- Fall in water
								ImprovedProjectile.removeProjectile(v[1])
								if v["light"] then getCell():removeLamppost(v["light"]) end
								exploTable[iv] = nil
								checkExplo = false
							elseif v[7][1] > v[8][2] * 6 and v[17][3] and v[17][3][2] then	-- Bounce
								v[7][2] = 0
								if v[17][2] then
									v[17][2] = {math.max(0.02, v[17][2][1] * 0.5), math.max(0.01, v[17][2][2] * 0.5)}
								end
								v[5][3] = v[3]:getZ()
								nextZ = v[3]:getZ()
							elseif v[17][4] then	-- Fall item
								if v[13] then
									local square = v[3]
									local fallItem = InventoryItemFactory.CreateItem(v[2])
									if square:TreatAsSolidFloor() then
										local objs = square:getObjects()
										local surface = 0
										for i = 1, objs:size() do
											local obj = objs:get(i - 1)
											if obj:getSurfaceOffsetNoTable() > surface then
												surface = obj:getSurfaceOffsetNoTable()
											end
										end
										local xOff = v[6][1] - math.floor(v[6][1])
										local yOff = v[6][2] - math.floor(v[6][2])
										square:AddWorldInventoryItem(fallItem, xOff, yOff, surface * 0.01)
										addSound(v[10], square:getX(), square:getY(), square:getZ(), 5, 1)
									end
								end
								ImprovedProjectile.removeProjectile(v[1])
								if v["light"] then getCell():removeLamppost(v["light"]) end
								exploTable[iv] = nil
								checkExplo = false
							end
						else	-- Explode
							if v[13] and not v[3]:getProperties():Is(IsoFlagType.water) then
								local square = v[3]
								if isHitCeilorTree == 2 then
									square = getCell():getOrCreateGridSquare(v[6][1] - v[4][2] * v[8][1], v[6][2] - v[4][3] * v[8][1], v[6][3])
								end
								local tempExplo = InventoryItemFactory.CreateItem(v[9])
								tempExplo:setTriggerExplosionTimer(0)
								if isClient() then
									tempExplo:setSmokeRange(0)
									square:syncIsoTrap(tempExplo)
								end
								local explode = IsoTrap.new(tempExplo, square:getCell(), square)
								square:AddTileObject(explode)
								explode:triggerExplosion(false)
							end
							ImprovedProjectile.removeProjectile(v[1])
							if v["light"] then getCell():removeLamppost(v["light"]) end
							exploTable[iv] = nil
							checkExplo = false
						end
					-- Hit ceil / wall / tree
					elseif v[17][3] and v[17][3][1] then
						if isHitCeilorTree == 1 then	-- Hit ceil
							v[14][1] = (v[6][3] - v[5][3]) / (v[7][2] * 0.6)
							nextZ = v[6][3] - v[14][1] * v[8][1]
						else	-- Hit wall / tree / car
							local angleRad = (bounceAngle * math.pi) / 180
							if bounceAngle < -180 then
								bounceAngle = 360 + bounceAngle
							elseif bounceAngle > 180 then
								bounceAngle = bounceAngle - 360
							end
							v[4] = {bounceAngle, math.cos(angleRad), math.sin(angleRad)}
							v[8][2] = math.max(0.02, v[8][2] * 0.7)
							v[12] = bounceAngle
							v[14][2] = (v[14][2] * 10) - math.floor(v[14][2] * 10)
						end
						v["blocked"] = "WallTree"
					else
						-- ## TODO
					end
				end
			end

			if checkExplo then
				v[6][1] = v[6][1] + v[4][2] * v[8][1]	-- Change current X
				v[6][2] = v[6][2] + v[4][3] * v[8][1]	-- Change current Y
				v[6][3] = nextZ							-- Change current Y
				v[7][2] = v[7][2] + v[8][1]

				if v[16] == "Rocket" and v[7][2] >= v[7][1] then
					if v[13] then
						-- Explode
						local square = v[3]
						local tempExplo = InventoryItemFactory.CreateItem(v[9])
						tempExplo:setTriggerExplosionTimer(0)
						if isClient() then
							tempExplo:setSmokeRange(0)
							square:syncIsoTrap(tempExplo)
						end
						local explode = IsoTrap.new(tempExplo, square:getCell(), square)
						square:AddTileObject(explode)
						explode:triggerExplosion(false)
					end
					ImprovedProjectile.removeProjectile(v[1])
					if v["light"] then getCell():removeLamppost(v["light"]) end
					exploTable[iv] = nil
				end

				--[[v[12] = v[12] + 20
				if v[12] < -180 then
					v[12] = 360 + v[12]
				elseif v[12] > 180 then
					v[12] = v[12] - 360
				end]]
			end
		end
	end
end

--*************************************************************************************--
--** On player shoot or throw explosive, create projectile
--*************************************************************************************--
function ImprovedProjectile:onShootExplosive(player, weapon)
	local exploObject		= nil
	local exploName			= self.exploInfo["exploName"]
	local exploType			= self.exploInfo["exploType"]
	local exploSquare		= nil
	local playerX			= player:getX()
	local playerY			= player:getY()
	local playerZ			= player:getZ()
	local exploDirection	= player:getForwardDirection():getDirection()
	local exploDirectionX	= math.cos(exploDirection)
	local exploDirectionY	= math.sin(exploDirection)
	local exploRange		= calcExplosiveRange(weapon, player)
	local speedMult			= self.exploInfo["exploType"] == "Rocket" and 1 or 1 - angleOff * 0.05
	local travelRange		= self.exploInfo["exploSpeed"] * speedMult
	local exploSpeed		= self.exploInfo["exploSpeed"] * speedMult
	local exploSpeedOrigin	= self.exploInfo["exploSpeed"] * speedMult
	local weaponName		= self.exploInfo["weaponName"]
	local bPassThrough		= {ZombRand(5) + 1, ZombRand(4) + 1}
	local fakeAngle			= 0
	local isMine			= true
	local zBounce			= {0, ZombRandFloat(0, 1)}
	local shootAngle		= 0.02
	local otherInfo			= {
		self.exploInfo["isExplo"], self.exploInfo["extraDamage"],
		self.exploInfo["isBounce"], self.exploInfo["fallItem"],
		self.exploInfo["blockSound"]
	}
	local weaponTexture		= self.exploInfo["wTexture"] or nil

	local exploInfo = {
		exploObject,					-- [1]
		exploName,						-- [2]
		exploSquare,					-- [3]
		{exploDirection,				-- [4] [1]
		exploDirectionX,				-- [4] [2]
		exploDirectionY},				-- [4] [3]
		{playerX, playerY, playerZ},	-- [5]
		{playerX, playerY, playerZ},	-- [6]
		{exploRange, travelRange},		-- [7] [1-2]
		{exploSpeed, exploSpeedOrigin},	-- [8] [1-2]
		weaponName,						-- [9]
		player,							-- [10]
		bPassThrough,					-- [11]
		fakeAngle,						-- [12]
		isMine,							-- [13]
		zBounce,						-- [14] [1-2]
		shootAngle,						-- [15]
		exploType,						-- [16]
		otherInfo,						-- [17]
		weaponTexture					-- [18]
	}

	--exploInfo[6][1]	= exploInfo[6][1] + (exploInfo[4][2] * 0.7)
	--exploInfo[6][2]	= exploInfo[6][2] + (exploInfo[4][3] * 0.7)
	local zOff = 0.5
	if player:getVariableBoolean("isCrawling") then
		zOff = 0.15
	elseif player:getVariableBoolean("IsCrouchAim") then
		zOff = 0.35
	end
	exploInfo[5][3]	= exploInfo[5][3] + zOff
	exploInfo[6][3]	= exploInfo[6][3] + zOff

	exploInfo[3] = getCell():getGridSquare(exploInfo[6][1], exploInfo[6][2], exploInfo[6][3])
	if exploInfo[3] == nil then return end

	local distToTarget = 0
	local mouseX, mouseY = getMouseXScaled(), getMouseYScaled()
	local aimX, aimY = ISCoordConversion.ToWorld(mouseX, mouseY, playerZ)
	aimX = aimX + 1.5
	aimY = aimY + 1.5

	distToTarget = math.sqrt((aimX - exploInfo[6][1])^2 + (aimY - exploInfo[6][2])^2)
	distToTarget = math.max(distToTarget, 1)
	exploInfo[7][1] = math.min(distToTarget, exploInfo[7][1])

	exploInfo[15] = (1 + 0.4 * angleOff) / (exploInfo[7][1] * 4)
	exploInfo[7][1] = exploInfo[7][1] * (1 - 0.01 * angleOff)

	exploInfo[4][1] = (exploInfo[4][1] * 180) / math.pi
	exploInfo[12] = exploInfo[4][1]

	--exploInfo[8] = exploInfo[8] * SandboxVars.ImprovedProjectile.IPPJExploSpeedMult --## TODO

	if exploInfo[16] == "Preset" and exploInfo[17][1] then
		exploInfo[9] = self.exploInfo["exploName"]
	end

	if isClient() and SandboxVars.ImprovedProjectile.IPPJRemoveProjectile == 1 then
		sendClientCommand("IPPJ", "createExplosive", {player:getOnlineID(), exploInfo})
	end
	table.insert(self.activeExplosives, self.createInfoTable(exploInfo))

	if weapon:isUseSelf() then
		self.isValidExplo = false
		self.exploInfo = {}
	end
end

local function findPhysicsObj(item, name)
	return item:getFullType() == name
end

local function onSwingExplosive(player, weapon)
	if SandboxVars.ImprovedProjectile.IPPJEnableExplo then
		if player ~= getPlayer() then return end

		if not ImprovedProjectile.isValidExplo or ImprovedProjectile.exploInfo["weaponName"] ~= weapon:getFullType() then return end

		if ImprovedProjectile.exploInfo["physicsObject"] and weapon:getPhysicsObject() then
			weapon:getModData().IPPJPhysicObjSave = weapon:getPhysicsObject()
			weapon:setPhysicsObject(nil)
		end

		if ImprovedProjectile.exploInfo["exploType"] == "Preset" then
			local inv = player:getInventory()
			local proj = inv:getFirstEvalArgRecurse(findPhysicsObj, ImprovedProjectile.exploInfo["exploName"])

			if proj then
				proj:getContainer():DoRemoveItem(proj)
				ImprovedProjectile.exploInfo["PresetSwing"] = true
				if ImprovedProjectile.exploInfo["swingHit"] then
					weapon:setSwingSound(ImprovedProjectile.exploInfo["swingHit"])
				end
			else
				local name = ScriptManager.instance:getItem(ImprovedProjectile.exploInfo["exploName"]):getDisplayName()
				player:Say(name .. " X")
				if ImprovedProjectile.exploInfo["swingAir"] then
					weapon:setSwingSound(ImprovedProjectile.exploInfo["swingAir"])
				end
			end
		end
	end
end

local function onShootExplosive(player, weapon)
	if SandboxVars.ImprovedProjectile.IPPJEnableExplo then
		if player ~= getPlayer() then return end

		if not ImprovedProjectile.isValidExplo or ImprovedProjectile.exploInfo["weaponName"] ~= weapon:getFullType() then return end
		if ImprovedProjectile.exploInfo["exploType"] == "Preset" and not ImprovedProjectile.exploInfo["PresetSwing"] then return end
		if ImprovedProjectile.blockVehicleShoot == true then return end

		ImprovedProjectile:onShootExplosive(player, weapon)
	end
end

local function onShootExplosiveFinished(player, weapon)
	if SandboxVars.ImprovedProjectile.IPPJEnableExplo then
		if player ~= getPlayer() or not weapon then return end

		if ImprovedProjectile.exploInfo["physicsObject"] and ImprovedProjectile.exploInfo["weaponName"] == weapon:getFullType() then
			weapon:setPhysicsObject(ImprovedProjectile.exploInfo["physicsObject"])
		end
		if ImprovedProjectile.exploInfo["PresetSwing"] then
			ImprovedProjectile.exploInfo["PresetSwing"] = nil
		end
	end
end

--*************************************************************************************--
--** Update explosive info
--*************************************************************************************--
function ImprovedProjectile:initExploInfo(player, weapon)
	self.isValidExplo = false
	self.exploInfo = {}

	if not weapon or not instanceof(weapon, "HandWeapon") or not (weapon:getPhysicsObject() or weapon:getModData().IPPJPhysicObjSave)
	or not weapon:isInstantExplosion() or weapon:getPhysicsObject() == "Ball" then
		return
	end

	--[[local pObject = weapon:getPhysicsObject()
	if pObject and weapon:getSwingAnim() == "Throw"
	and (string.find(pObject, "ball") or string.find(pObject, "Ball")) then
		return
	end]]

	if weapon:getSwingAnim() == "Throw" then
		self.exploInfo["weaponName"] = weapon:getFullType()
		self.exploInfo["exploCurv"] = 0.02
		self.exploInfo["exploName"] = self.exploInfo["weaponName"]
		self.exploInfo["exploType"] = "Throw"
		self.exploInfo["exploSpeed"] = 0.15
		self.exploInfo["isExplo"] = true
		self.exploInfo["isBounce"] = {true, false, false}
		self.exploInfo["physicsObject"] = weapon:getPhysicsObject() or weapon:getModData().IPPJPhysicObjSave
		self.isValidExplo = true

		if isDebugEnabled() then
			player:Say("Use " .. weapon:getDisplayName())
		end
		--print("[IPPJ EXPLO]")
	elseif weapon:isRanged() and weapon:isAimedFirearm() and weapon:isUseSelf() == false and weapon:getMaxHitCount() == 0 then
		if (not weapon:getExplosionRange() or weapon:getExplosionRange() == 0) and (not weapon:getFireRange() or weapon:getFireRange() == 0) then
			return
		end
		self.exploInfo["weaponName"] = weapon:getFullType()
		self.exploInfo["exploCurv"] = 0.02
		self.exploInfo["isExplo"] = true
		self.exploInfo["isBounce"] = {true, false, false}
		self.exploInfo["exploName"] = "Base.IPPJ40RoundProjectile"
		self.exploInfo["exploType"] = "Launcher"
		self.exploInfo["exploSpeed"] = 0.25

		local customTable	= luautils.split(SandboxVars.ImprovedProjectile.IPPJFlatTrajectory, ";")
		local customTmp		= {}
		for _, v in pairs(customTable) do
			if v == weapon:getFullType() then
				--self.exploInfo["exploName"] = "Base.IPPJRocketProjectile"
				self.exploInfo["exploType"] = "Rocket"
				self.exploInfo["exploSpeed"] = 0.35
			end
		end

		self.exploInfo["wTexture"] = weapon:getTexture()
		--[[if weapon:getAmmoType() then
			local grAmmo = InventoryItemFactory.CreateItem(weapon:getAmmoType())
			if grAmmo and grAmmo:getModData().SwitchIcon then
				self.exploInfo["exploName"] = grAmmo:getModData().SwitchIcon
			end
		end]]

		--[[local customTable2	= luautils.split(SandboxVars.ImprovedProjectile.IPPJCustomExplo, ";")
		local customTmp2	= {}
		for i, v in pairs(customTable2) do
			customTmp2 = luautils.split(v, "=")
			if weapon:getFullType() == customTmp2[1] then
				if customTmp2[2] and customTmp2[2] ~= "" then
					local itemCheck = InventoryItemFactory.CreateItem(customTmp2[2])
					if itemCheck then
						self.exploInfo["exploName"] = customTmp2[2]
					end
				end
			end
		end]]

		self.exploInfo["physicsObject"] = weapon:getPhysicsObject() or weapon:getModData().IPPJPhysicObjSave
		self.isValidExplo = true

		if isDebugEnabled() then
			player:Say("Use " .. weapon:getDisplayName())
		end
	else
		self.isValidExplo = false
		self.exploInfo = {}
	end
end

function ImprovedProjectile:initExploInfoPreset(player, weapon, flag)
	self.isValidExplo = false
	self.exploInfo = {}

	if not flag then return end

	local preset = nil
	if weapon then
		preset = IPPJPreset[weapon:getFullType()][1]
	end

	if preset then
		self.exploInfo["weaponName"] = weapon:getFullType()
		self.exploInfo["exploCurv"] = 0.02
		self.exploInfo["exploName"] = preset[1]
		self.exploInfo["exploType"] = "Preset"
		self.exploInfo["exploSpeed"] = preset[2]
		self.exploInfo["exploRange"] = preset[3]
		self.exploInfo["swingAir"] = preset[4]
		self.exploInfo["swingHit"] = preset[5]
		self.exploInfo["isExplo"] = preset[6]
		self.exploInfo["extraDamage"] = {preset[7][1] * (1 + self.Strength * 0.05), preset[7][2]}
		self.exploInfo["isBounce"] = {preset[8][1], preset[8][2], preset[8][3]}
		self.exploInfo["fallItem"] = preset[9]
		self.exploInfo["rangeMod"] = 0
		self.exploInfo["blockSound"] = {preset[11][1], preset[11][2], preset[11][3]}
		if preset[10] and player:HasTrait(preset[10]) then
			--self.exploInfo["extraDamage"] = {preset[7][1] * 1.5, preset[7][2]}
			self.exploInfo["extraDamage"][1] = self.exploInfo["extraDamage"][1] * 1.5
			self.exploInfo["rangeMod"] = 3
		end
		local name = ScriptManager.instance:getItem(self.exploInfo["exploName"]):getDisplayName()
		player:Say("Use " .. name)
		self.isValidExplo = true
	else
		self.isValidExplo = false
		self.exploInfo = {}
	end
end

local function initExploInfo(player, weapon)
	if player:isLocalPlayer() then
		if weapon and ImprovedProjectile.exploInfo["weaponName"] and ImprovedProjectile.exploInfo["weaponName"] == weapon:getFullType() then
			if isClient() and (weapon:getModData().SpriteCLOSED and weapon:getWeaponSprite() == weapon:getModData().SpriteCLOSED) then
				sendClientCommand("IPPJ", "clearPhysicsObject", {player:getOnlineID(), weapon:getFullType()})
			end
			return
		end

		if weapon and instanceof(weapon, "HandWeapon") then
			local savedInfo = weapon:getModData().IPPJSaveInfo
			if savedInfo then
				weapon:setMinRange(savedInfo[1])
				weapon:setMaxRange(savedInfo[2])
				weapon:setMaxHitCount(savedInfo[3])
				weapon:setSwingSound(savedInfo[4])
				weapon:getModData().IPPJSaveInfo = nil
				weapon:getModData().IPPJPresetType = nil
			end
		end

		ImprovedProjectile:initExploInfo(player, weapon)
		if isClient() and ImprovedProjectile.isValidExplo and ImprovedProjectile.exploInfo["physicsObject"] then
			sendClientCommand("IPPJ", "clearPhysicsObject", {player:getOnlineID(), weapon:getFullType()})
		end
	end
end

local function initExploInfoOnLoad()
	for i, v in pairs(texturetable) do
		getTexture(v)
	end

	local player = getPlayer()
	if not player then return end

	initExploInfo(player, player:getPrimaryHandItem())
end

Events.OnKeyKeepPressed.Add(onKeyKeepPressed)
Events.OnKeyPressed.Add(onKeyPressed)
Events.OnServerCommand.Add(createExploServer)
Events.OnRenderTick.Add(drawTrajectoryFunc)
Events.OnTick.Add(explosiveOnTick)
Events.OnWeaponSwing.Add(onSwingExplosive)
Events.OnWeaponSwingHitPoint.Add(onShootExplosive)
Events.OnPlayerAttackFinished.Add(onShootExplosiveFinished)
Events.OnEquipPrimary.Add(initExploInfo)
Events.OnLoad.Add(initExploInfoOnLoad)
Events.OnThrowableExplode.Add(addExplosion)