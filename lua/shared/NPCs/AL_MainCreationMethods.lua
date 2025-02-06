require('NPCs/MainCreationMethods')

local Archery_Traits = function()
	local Archer = TraitFactory.addTrait(
		"Archer",
		getText("UI_trait_Archer"), 
		8,
		getText("UI_trait_Archerdesc"), 
		false, false
	)
	Archer:addXPBoost(Perks.Archery, 2)
	BaseGameCharacterDetails.SetTraitDescription(Archer)
	
	local Survivalist = TraitFactory.addTrait(
		"Survivalist",
		getText("UI_trait_Survivalist"), 
		3,
		getText("UI_trait_Survivalistdesc"), 
		false, false
	)
	Survivalist:addXPBoost(Perks.Archery, 1)
	Survivalist:getFreeRecipes():add("MakePrimitiveArrows");
	Survivalist:getFreeRecipes():add("MakePrimitiveBolts");
	
	BaseGameCharacterDetails.SetTraitDescription(Survivalist)
	
    TraitFactory.sortList();
end

Events.OnGameBoot.Add(Archery_Traits);







