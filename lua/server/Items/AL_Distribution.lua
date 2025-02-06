require 'Items/SuburbsDistributions'
require 'Items/ProceduralDistributions'

if SandboxVars.ArcherLib.SpawnBooks then
	local bookData = {
		{name = "ArcherLib.BookArchery1", weights = {10, 1, 0.6, 1, 10, 1, 2, 10, 2, 10}},
		{name = "ArcherLib.BookArchery2", weights = {8, 0.8, 0.4, 0.8, 8, 0.8, 1, 8, 1, 8}},
		{name = "ArcherLib.BookArchery3", weights = {6, 0.3, 0.2, 0.6, 6, 0.6, 0.5, 6, 0.5, 6}},
		{name = "ArcherLib.BookArchery4", weights = {4, 0.4, 0.1, 0.4, 4, 0.4, 0.1, 4, 0.1, 4}},
		{name = "ArcherLib.BookArchery5", weights = {2, 0.2, 0.05, 0.2, 2, 0.2, 0.01, 2, 0.05, 2}},
	}

	local targets = {
		"ArmySurplusLiterature",
		"BookstoreBooks",
		"CrateBooks",
		"GarageFirearms",
		"GunStoreLiterature",
		"HuntingLockers",
		"SurvivalGear",
		"BookstoreOutdoors",
		"CampingLockers",
		"CampingStoreBooks",
	}

	for i, distribution in ipairs(targets) do
		local items = ProceduralDistributions["list"][distribution].items
		for _, book in ipairs(bookData) do
			table.insert(items, book.name)
			table.insert(items, book.weights[i])
		end
	end

	local magazineData = {
		{name = "ArcherLib.Shaft&Quiver", weights = {2, 1, 2, 1, 1, 1, 2, 2, 2, 1, 0.1, 0.1, 0.1, 0.1, 1, 1, 0.1, 0.5,  0.1}},
	}

	local magTargets = {
		"BookstoreMisc",
		"CampingLockers",
		"CampingStoreBooks",
		"CrateCamping",
		"CrateMagazines",
		"GarageFirearms",
		"GunStoreLiterature",
		"GunStoreMagazineRack",
		"Hunter",
		"LibraryMagazines",
		"LivingRoomShelf",
		"LivingRoomShelfRedneck",
		"LivingRoomSideTable",
		"LivingRoomSideTableRedneck",
		"MagazineRackMixed",
		"PostOfficeMagazines",
		"RecRoomShelf",
		"SafehouseBookShelf",
		"ShelfGeneric",
	}

	for i, distribution in ipairs(magTargets) do
		local items = ProceduralDistributions["list"][distribution].items
		for _, book in ipairs(magazineData) do
			table.insert(items, book.name)
			table.insert(items, book.weights[i])
		end
	end
end

if SandboxVars.ArcherLib.SpawnAmmo then
	local ammoData = {
		{name = "ArcherLib.BundleOfModernBolts", weights = {10, 10, 15, 10, 10, 10, 10}},
		{name = "ArcherLib.BundleOfModernArrows", weights = {10, 10, 15, 10, 10, 10, 10}},
	}

	local targets = {
		"Hiker",
		"SurvivalGear",
		"CampingStoreTools",
		"CrateRandomJunk",
		"CampingLockers",
		"CampingStoreGear",
		"Hiker",
		"PawnShopGuns",
	}

	for i, distribution in ipairs(targets) do
		local items = ProceduralDistributions["list"][distribution].items
		for _, ammo in ipairs(ammoData) do
			table.insert(items, ammo.name)
			table.insert(items, ammo.weights[i])
		end
	end
end