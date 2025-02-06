--[[require "TimedActions/ISRemoveWeaponUpgrade"

old_isValid = ISRemoveWeaponUpgrade.isValid

function ISRemoveWeaponUpgrade:isValid()
    local part = self.weapon:getWeaponPart(self.partType)
	for _, attachment in pairs(forbiddenRemoveWeaponUpgrade) do
		if part:getPartType() == attachment then
			return false
		end
	end
    return old_isValid
end

forbiddenRemoveWeaponUpgrade = {
	"ArcherLib.LoadedModernBolts",
	"ArcherLib.LoadedPrimitiveBolts",
	"ArcherLib.LoadedModernArrows",
	"ArcherLib.LoadedPrimitiveArrows",
}]]-- Disabled due to bug, will update soon.