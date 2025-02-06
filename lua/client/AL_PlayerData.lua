ALModVersion = 1 -- If this updates, it resets the player data

local playerdatatable = {}
playerdatatable[0] = { "ALModVersion", ALModVersion }
playerdatatable[1] = { "bowTimer", 0 }
playerdatatable[2] = { "isAiming", false }
playerdatatable[3] = { "bowReloadAction", false }
playerdatatable[3] = { "bowAttackAction", false }


local function InitPlayerData(player)
	local playerdata = player:getModData()
	for i, v in pairs(playerdatatable) do
		if playerdata[v[1]] == nil then
			playerdata[v[1]] = v[2]
		end
	end
end

function AL_OnCreatePlayer(_, player)
	InitPlayerData(player)
end

Events.OnCreatePlayer.Add(AL_OnCreatePlayer);