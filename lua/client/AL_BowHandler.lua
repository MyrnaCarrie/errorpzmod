local Bow = {}

Bow.UpdateBow = function (player, weapon)
	local player = getPlayer()
	local playerData = player:getModData()
	local weaponID = weapon:getType()
	local held = player:getPrimaryHandItem()
	local attachmentString = weapon:getAmmoType()
	attachmentString = string.gsub(attachmentString, "ArcherLib.", "ArcherLib.Loaded")
	local factoryItem = instanceItem(attachmentString)
	if playerData.bowAttackAction then
		held:clearWeaponPart(factoryItem)
		held:setWeaponSprite(weaponID.."_empty")
	elseif playerData.isAiming then
		if Bow.CheckHasAmmo(weapon) or playerData.bowReloadAction then
			held:clearWeaponPart(factoryItem)
			held:setWeaponSprite(weaponID.."_loaded")
			held:attachWeaponPart(factoryItem)
		else
			held:clearWeaponPart(factoryItem)
			held:setWeaponSprite(weaponID.."_empty")
		end
	else
		if Bow.CheckHasAmmo(weapon) or playerData.bowReloadAction then
			held:clearWeaponPart(factoryItem)
			held:setWeaponSprite(weaponID.."_held")
			held:attachWeaponPart(factoryItem)
		else
			held:setWeaponSprite(weaponID.."_held")
			held:clearWeaponPart(factoryItem)
		end
	end
	playerData.bowReloadAction = false
	playerData.bowAttackAction = false
	player:resetEquippedHandsModels()
end

Bow.CheckAiming = function(weapon)
	if weapon:getCurrentAmmoCount() > 0 then
		return true
	end
	return false
end

Bow.CheckHasAmmo = function(weapon)
	if weapon:getCurrentAmmoCount() > 0 then
		return true
	end
	return false
end

Bow.CheckBow = function(weapon)
	if weapon == nil then return false end
	if weapon:hasTag("IsBow") then
		return true
	end
	return false
end

Events.OnEquipPrimary.Add(function(player, weapon)
	local playerData = player:getModData()
	if Bow.CheckBow(weapon) then
		playerData.bowTimer = 5
	end
	
end)

Events.OnWeaponSwing.Add(function(player, weapon)
	local playerData = player:getModData()
	if Bow.CheckBow(weapon) then
		playerData.bowTimer = 5
		playerData.bowAttackAction = true
	end
end)

Events.OnPressReloadButton.Add(function(player, weapon)
	local playerData = player:getModData()
	if Bow.CheckBow(weapon) then
		playerData.bowTimer = weapon:getReloadTime()
		playerData.bowReloadAction = true
	end
end)

Events.OnRightMouseDown.Add(function()
	local player = getPlayer()
	local playerData = player:getModData()
	if Bow.CheckBow(player:getPrimaryHandItem()) then
		playerData.bowTimer = 5
		playerData.isAiming = true
	end
end)

Events.OnRightMouseUp.Add(function()
	local player = getPlayer()
	local playerData = player:getModData()
	if Bow.CheckBow(player:getPrimaryHandItem()) then
		playerData.bowTimer = 5
		playerData.isAiming = false
	end
end)

Events.OnGameStart.Add(function()
	local player = getPlayer()
	local weapon = player:getPrimaryHandItem()
	local playerData = player:getModData()
	if Bow.CheckBow(weapon) then
		playerData.bowTimer = 5
	end
end)

Bow.TickTimer = function (player)
	local playerData = player:getModData()
	if playerData.bowTimer > 0 then
		playerData.bowTimer = playerData.bowTimer - 1
		if playerData.bowTimer == 0 then
			Bow.UpdateBow(player, player:getPrimaryHandItem())
		end
	end
end

Events.OnPlayerUpdate.Add(Bow.TickTimer)

function Bow.OnCustomUIKeyPressed(key)
    if key == 2 then
		local player = getPlayer()
		local held = player:getPrimaryHandItem()
		if held ~= nil and held:hasTag("Archery") then
			local attachmentString = held:getAmmoType()
			attachmentString = string.gsub(attachmentString, "ArcherLib.", "ArcherLib.Loaded")
			local factoryItem = instanceItem(attachmentString)
			held:clearWeaponPart(factoryItem)
		end
	end
end

Events.OnCustomUIKeyPressed.Add(Bow.OnCustomUIKeyPressed)