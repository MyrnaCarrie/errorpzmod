ArcherLib = ArcherLib or {}

ArcherLib.BoltAttachables = {
	"ArcherLib.LoadedModernBolts",
	"ArcherLib.LoadedPrimitiveBolts",
}

ArcherLib.AddCrossbow = function(xbows)
	if xbows == nil then return end
	for _, bolt in pairs(ArcherLib.BoltAttachables) do
		local item = ScriptManager.instance:getItem(bolt)
		if item then
			local mountOn = table.concat(xbows, ";")	
			item:DoParam(string.format("MountOn = %s", mountOn))
		end
	end
	for _, xbow in pairs(xbows) do
		local item = ScriptManager.instance:getItem(xbow)
		for _, bolt in pairs(ArcherLib.BoltAttachables) do
			local modelName = string.match(bolt, "^.-%.(.*)")
			item:DoParam(string.format("ModelWeaponPart = %s %s projectile projectile", bolt, modelName))
		end
	end
end

ArcherLib.ArrowAttachables = {
	"ArcherLib.LoadedModernArrows",
	"ArcherLib.LoadedPrimitiveArrows",
}

ArcherLib.AddBow = function(bows)
	if bows == nil then return end
	for _, bolt in pairs(ArcherLib.ArrowAttachables) do
		local item = ScriptManager.instance:getItem(bolt)
		if item then
			local mountOn = table.concat(bows, ";")	
			item:DoParam(string.format("MountOn = %s", mountOn))
		end
	end
	for _, bow in pairs(bows) do
		local item = ScriptManager.instance:getItem(bow)
		for _, bolt in pairs(ArcherLib.ArrowAttachables) do
			local modelName = string.match(bolt, "^.-%.(.*)")
			item:DoParam(string.format("ModelWeaponPart = %s %s projectile projectile", bolt, modelName))
		end
	end
end


