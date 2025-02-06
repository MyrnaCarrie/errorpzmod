local function OnHitZombieWithArchery(target, character, bodyPartType, weapon)
	if target == nil or character == nil or weapon == nil then return end
	if weapon:hasTag("ArrowImpale") then		
		local newItem
		if target and instanceof(target, "IsoZombie") then
            local part = bodyPartType
            local inv = character:getInventory()
			local projectile = weapon:getAmmoType()
            newItem = inv:AddItem(projectile)
            inv:Remove(newItem);
            local location = "Stomach"
            if part == "Torso_Upper" then 
				location = "Knife Shoulder"
            elseif part == "Torso_Lower" then 
				location = "Knife Stomach" 
			end
			--[[if part == "Head" then
				location == "Head"
				end ]]--
            if location == "Knife Stomach" and target:getAttachedItem(location) then 
				location = "Knife Shoulder"
            elseif location == "Knife Shoulder" and target:getAttachedItem(location) then 
				location = "Knife Stomach" 
			end
            if location ~= "Stomach" and target:getAttachedItem(location) then 
				location = "Stomach" 
			end
            if not target:getAttachedItem(location) then
                target:setAttachedItem(location, newItem)
		        target:reportEvent("EventAttachItem");
            else
				local rand = newrandom()
				if rand:random(1,100) > 60 then
					target:addItemToSpawnAtDeath(newItem)
				else
					target:getSquare():AddWorldInventoryItem(newItem, ZombRand(100)/100, ZombRand(100)/100, 0.0)
				end
            end
        end
	end
end

Events.OnHitZombie.Add(OnHitZombieWithArchery)