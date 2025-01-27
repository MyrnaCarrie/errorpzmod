require "ElectricWeaponConfig"
require "ISInsertBatteryAction"
require "ISRemoveBatteryAction"
require "ElectricWeapon/ISElectricWeaponMalfunctionSystem"  -- 确保路径正确

local MalfunctionSystem = require "ElectricWeapon/ISElectricWeaponMalfunctionSystem"

ISElectricWeaponContextMenu = {}

-- 工具提示函数
function ISElectricWeaponContextMenu.createTooltip(item)
    if not item then return nil end
    
    -- 创建工具提示
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setName(item:getDisplayName())
    
    local modData = item:getModData()
    if not modData then return tooltip end
    
    local description = ""
    local chargeLevel = math.floor(modData.totalCharge or 0)

    -- 显示电量信息
    if chargeLevel > 65 then
        description = string.format("<RGB:0,1,0>%s %d%%", getText("Tooltip_ElectricWeapon_Charge"), chargeLevel)
    elseif chargeLevel > 25 then
        description = string.format("<RGB:1,1,0>%s %d%%", getText("Tooltip_ElectricWeapon_Charge"), chargeLevel)
    else
        description = string.format("<RGB:1,0,0>%s %d%%", getText("Tooltip_ElectricWeapon_Charge"), chargeLevel)
    end

    -- 显示故障状态或风险信息
    if modData.malfunctioned then
        description = description .. "\n<RGB:1,0,0>" .. getText("Tooltip_ElectricWeapon_Malfunctioned")
    else
        -- 使用本地变量而不是直接访问模块
        local riskInfo = MalfunctionSystem.getRiskInfo(item)
        if riskInfo and riskInfo.currentRisk then
            local riskPercent = math.floor(riskInfo.currentRisk * 100)
            if riskPercent < 10 then
                description = description .. string.format("\n<RGB:0,1,0>%s %d%%", 
                    getText("Tooltip_ElectricWeapon_Risk"), riskPercent)
            elseif riskPercent < 25 then
                description = description .. string.format("\n<RGB:1,1,0>%s %d%%", 
                    getText("Tooltip_ElectricWeapon_Risk"), riskPercent)
            else
                description = description .. string.format("\n<RGB:1,0,0>%s %d%%", 
                    getText("Tooltip_ElectricWeapon_Risk"), riskPercent)
            end
        end
    end

    tooltip.description = description
    return tooltip
end
-- 核心功能函数
function ISElectricWeaponContextMenu.findBattery(playerObj)
    local containerList = ISInventoryPaneContextMenu.getContainers(playerObj)
    if not containerList then return nil end
    
    for i=1, containerList:size() do
        local container = containerList:get(i-1)
        local items = container:getItems()
        for j=0, items:size()-1 do
            local item = items:get(j)
            if item:getFullType() == "Base.Battery" then
                return item
            end
        end
    end
    return nil
end

function ISElectricWeaponContextMenu.onToggleElectricMode(playerObj, weapon)
    if not playerObj or not weapon then return end
    ISElectricWeapon.toggleElectricMode(playerObj:getPlayerNum())
end

function ISElectricWeaponContextMenu.onRepairMalfunction(playerObj, weapon)
    if not playerObj or not weapon then return end
    ISTimedActionQueue.add(ISRepairElectricWeaponAction:new(playerObj, weapon))
end

function ISElectricWeaponContextMenu.onAddBattery(playerObj, weapon)
    if not playerObj or not weapon then return end
    
    local battery = ISElectricWeaponContextMenu.findBattery(playerObj)
    if not battery then 
        playerObj:Say(getText("IGUI_PlayerText_NoBattery"))
        return 
    end
    
    if battery:getContainer() ~= playerObj:getInventory() then
        if not battery:getContainer() or not battery:getContainer():isExistYet() then
            return
        end
        
        local transferAction = ISInventoryTransferAction:new(
            playerObj,
            battery,
            battery:getContainer(),
            playerObj:getInventory(),
            nil
        )
        
        transferAction:setOnComplete(function()
            ISTimedActionQueue.add(ISInsertBatteryAction:new(playerObj, weapon, battery))
        end)
        
        ISTimedActionQueue.add(transferAction)
    else
        ISTimedActionQueue.add(ISInsertBatteryAction:new(playerObj, weapon, battery))
    end
end

function ISElectricWeaponContextMenu.onRemoveBattery(playerObj, weapon)
    if not playerObj or not weapon then return end
    ISTimedActionQueue.add(ISRemoveBatteryAction:new(playerObj, weapon))
end

-- 上下文菜单处理函数
function ISElectricWeaponContextMenu.addBatteryOptions(_player, _context, _items)
    local resItems = {}
    for i, v in ipairs(_items) do
        if not instanceof(v, "InventoryItem") then
            for _, it in ipairs(v.items) do
                resItems[it] = true
            end
        else
            resItems[v] = true
        end
    end

    for item, _ in pairs(resItems) do
        if ISElectricWeapon.isElectricWeapon(item) then
            local playerObj = getSpecificPlayer(_player)
            local modData = item:getModData()
            
            if not modData.totalCharge then
                modData.totalCharge = 0
            end

           if modData.malfunctioned then
    local repairOption = _context:addOption(
        getText("ContextMenu_ElectricWeapon_Repair"),
        playerObj,
        ISElectricWeaponContextMenu.onRepairMalfunction,
        item
    )
    local tooltip = ISElectricWeaponContextMenu.createTooltip(item)
    if tooltip then
        repairOption.toolTip = tooltip
    end
    InventorySetIcon("ContextMenu_ElectricWeapon_Repair", getIconPath, "Repair.png", _context)
end

-- 在电击模式切换选项中
if modData.totalCharge > 0 and modData.hasBattery and not modData.malfunctioned then
    local modeText = modData.electricModeOn and 
        getText("ContextMenu_ElectricWeapon_DeactivateMode") or 
        getText("ContextMenu_ElectricWeapon_ActivateMode")
    
    local toggleOption = _context:addOption(
        modeText,
        playerObj,
        ISElectricWeaponContextMenu.onToggleElectricMode,
        item
    )
    local tooltip = ISElectricWeaponContextMenu.createTooltip(item)
    if tooltip then
        toggleOption.toolTip = tooltip
    end
    
    local modeIcon = modData.electricModeOn and "Electric_Mode_On.png" or "Electric_Mode_Off.png"
    InventorySetIcon(modeText, getIconPath, modeIcon, _context)
end

            -- 电池管理选项
            if modData.totalCharge < 100 and not modData.hasBattery then
                local addBatteryOption = _context:addOption(
                    getText("ContextMenu_ElectricWeapon_AddBattery"), 
                    playerObj, 
                    ISElectricWeaponContextMenu.onAddBattery, 
                    item
                )
                InventorySetIcon("ContextMenu_ElectricWeapon_AddBattery", getIconPath, "Battery_Plus.png", _context)

if not ISElectricWeaponContextMenu.findBattery(playerObj) then
    addBatteryOption.notAvailable = true
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip.description = getText("ContextMenu_ElectricWeapon_NoBattery")
    addBatteryOption.toolTip = tooltip
end
            end

            if modData.totalCharge > 0 then
                local removeBatteryOption = _context:addOption(
                    getText("ContextMenu_ElectricWeapon_RemoveBattery"), 
                    playerObj, 
                    ISElectricWeaponContextMenu.onRemoveBattery, 
                    item
                )
                InventorySetIcon("ContextMenu_ElectricWeapon_RemoveBattery", getIconPath, "Battery_Minus.png", _context)
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ISElectricWeaponContextMenu.addBatteryOptions)

return ISElectricWeaponContextMenu