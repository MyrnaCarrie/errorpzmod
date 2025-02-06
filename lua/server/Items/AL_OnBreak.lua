OnBreak = OnBreak or {}

function OnBreak.ArrowHandler(item, player, breakItem)
    if not item then return end
    local inv
    local cont = item:getContainer()
    if item:getWorldItem() and item:getWorldItem():getSquare() then sq = item:getWorldItem():getSquare() end
    local newItem

    if player and cont == player:getInventory() then
        inv = player:getInventory()
    end
    if inv then
        inv:Remove(item)
    end
    triggerEvent("OnContainerUpdate");
end

function OnBreak.ArrowOrBolt(item, player)
     OnBreak.ArrowHandler(item, player, true)
end