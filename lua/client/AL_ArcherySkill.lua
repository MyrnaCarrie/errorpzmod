local ArcheryCombat = {}

ArcheryCombat.debug = false --for troublshooting, will remove after I'm done with the mods updates eventually

ArcheryCombat.OnWeaponSwing = function(player, weapon)
	if weapon:hasTag("Archery") and not player:isDoShove()then
		local skill = player:getPerkLevel(Perks["Archery"])
		local baseWeapon = instanceItem(weapon:getFullType())
		if ArcheryCombat.debug then
			print("<<< Archery Before >>>")
			print("Weapon Accuracy: "..weapon:getHitChance())
			print("Weapon CritChance: "..weapon:getCriticalChance())
			print("Weapon Range: "..weapon:getMinRange().." to "..weapon:getMaxRange())
			print("Weapon Minimum Angle: "..weapon:getMinAngle())
			print("Weapon AimingTime: "..weapon:getAimingTime())
		end
		weapon:setHitChance(baseWeapon:getHitChance() + (4 * skill))
		weapon:setCriticalChance(baseWeapon:getCriticalChance() + (4 * skill))
		weapon:setMaxRange(baseWeapon:getMaxRange() + (2 * skill))
		weapon:setMinAngle(baseWeapon:getMinAngle() + (0.06 * skill))
		weapon:setAimingTime(baseWeapon:getAimingTime() + (2 * skill))
	end
end

ArcheryCombat.OnWeaponSwingHitPoint = function(player, weapon)
	if weapon:hasTag("Archery") and not player:isDoShove() then
		print("<<< Archery After >>>")
		print("Weapon Accuracy: "..weapon:getHitChance())
		print("Weapon CritChance: "..weapon:getCriticalChance())
		print("Weapon Range: "..weapon:getMinRange().." to "..weapon:getMaxRange())
		print("Weapon Minimum Angle: "..weapon:getMinAngle())
		print("Weapon AimingTime: "..weapon:getAimingTime())
	end
end

Events.OnWeaponSwing.Add(ArcheryCombat.OnWeaponSwing)

if ArcheryCombat.debug then
	Events.OnWeaponSwingHitPoint.Add(ArcheryCombat.OnWeaponSwingHitPoint)
end