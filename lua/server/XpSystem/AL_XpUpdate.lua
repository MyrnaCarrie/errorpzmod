--hook into XpUpdate and subvert the firearms xp gain
Events.OnWeaponHitXp.Remove(xpUpdate.onWeaponHitXp)

local Old_xpUpdate_onWeaponHitXp = xpUpdate.onWeaponHitXp

xpUpdate.onWeaponHitXp = function(owner, weapon, hitObject, damage, hitCount)
	if weapon:isRanged() and weapon:hasTag("Archery") then
		local xp = hitCount;
		if owner:getPerkLevel(Perks.Archery) < 5 then
			xp = xp * 2.7;
		end
		addXp(owner, Perks.Archery, xp)
		local favModData = owner:getModData();
		if favModData["Fav:"..weapon:getScriptItem():getDisplayName()] == nil then
            favModData["Fav:"..weapon:getScriptItem():getDisplayName()] = 1;
        else
            favModData["Fav:"..weapon:getScriptItem():getDisplayName()] = favModData["Fav:"..weapon:getScriptItem():getDisplayName()] + 1;
        end
		return
	end
    return Old_xpUpdate_onWeaponHitXp(owner, weapon, hitObject, damage, hitCount)
end

Events.OnWeaponHitXp.Add(xpUpdate.onWeaponHitXp)

