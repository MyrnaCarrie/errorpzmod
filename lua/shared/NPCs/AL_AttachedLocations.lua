local group = AttachedLocations.getGroup("Human")
group:getOrCreateLocation("Bow on Back"):setAttachmentName("Bow_Back")
group:getOrCreateLocation("Crossow on Back"):setAttachmentName("Crossbow_Back")

TweakModelData = {}

function TweakWeaponModelAttachments()
	local model;
	for k,v in pairs(TweakModelData) do 
		for t,y in pairs(v) do 
			model = ScriptManager.instance:getModelScript(k)
			if model ~= nil then
				local name = model:getName()
				model:Load(name, "{" ..t.. "\n{".."\n"..y.."\n}\n")
			end
		end
	end
end

function TweakWeaponModelAttachment(modelName, modelProperty, propertyValue)
	if not TweakModelData[modelName] then
		TweakModelData[modelName] = {}
	end
	TweakModelData[modelName][modelProperty] = propertyValue
end

Events.OnGameBoot.Add(TweakWeaponModelAttachments)		
			
TweakWeaponModelAttachment("Base.FemaleBody", "attachment bow_back", "offset = -0.0020 -0.0760 0.1040, rotate = -170.0000 -80.0000 -73.0000,bone = Bip01_BackPack,")
TweakWeaponModelAttachment("Base.MaleBody", "attachment bow_back", "offset = -0.0020 -0.0760 0.1040, rotate = -170.0000 -80.0000 -73.0000,bone = Bip01_BackPack,")


