local Crossbow = {}
Crossbow.Run = function(player, weapon, shouldLoad)
	local baseItem = weapon:getScriptItem()
	local weaponID = weapon:getType()
	local held = player:getPrimaryHandItem()
	local attachmentString = weapon:getAmmoType()
	attachmentString = string.gsub(attachmentString, "ArcherLib.", "ArcherLib.Loaded")
	local factoryItem = instanceItem(attachmentString);
	if shouldLoad then
		held:clearWeaponPart(factoryItem) -- ensure its empty
		held:setWeaponSprite(weaponID.."_loaded")
		held:attachWeaponPart(factoryItem);
	else
		held:clearWeaponPart(factoryItem) -- ensure its empty
		held:setWeaponSprite(weaponID.."_empty")
	end
	player:resetEquippedHandsModels()
end

Crossbow.CheckCrossbow = function(weapon)
	if weapon == nil then return false end
	if weapon:hasTag("IsCrossbow") then
		return true
	end
	return false
end

Crossbow.CheckHasAmmo = function(weapon)
	if weapon:getCurrentAmmoCount() > 0 then
		return true
	end
	return false
end

Crossbow.OnPressReloadButton = function(player, weapon)
	if not Crossbow.CheckCrossbow(weapon) then return end
	if not Crossbow.CheckHasAmmo(weapon) then return end
	Crossbow.Run(player, weapon, true)
end

Crossbow.OnWeaponSwing = function(player, weapon)
	if not Crossbow.CheckCrossbow(weapon) then return end
	if Crossbow.CheckHasAmmo(weapon) then
		Crossbow.Run(player, weapon, false)	
	end
end

Crossbow.OnEquipPrimary = function(player, weapon)
	if not Crossbow.CheckCrossbow(weapon) then return end
	Crossbow.Run(player, weapon, Crossbow.CheckHasAmmo(weapon))	
end

Crossbow.OnGameStart = function(player, weapon)
	if not Crossbow.CheckCrossbow(weapon) then return end
	Crossbow.Run(player, weapon, Crossbow.CheckHasAmmo(weapon))	
end

Events.OnPressReloadButton.Add(Crossbow.OnPressReloadButton)
Events.OnWeaponSwing.Add(Crossbow.OnWeaponSwing)
Events.OnEquipPrimary.Add(Crossbow.OnEquipPrimary)

Events.OnGameStart.Add(function()
	local player = getPlayer()
	Crossbow.OnGameStart(player, player:getPrimaryHandItem())
end)
	
