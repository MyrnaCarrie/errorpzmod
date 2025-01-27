require "ElectricWeaponConfig"
local config = require "ElectricWeaponModOption"
require "ElectricWeapon/ISElectricWeaponMalfunctionSystem"

ISElectricWeapon = {}
ISElectricWeapon.WeaponPower = nil

-- 获取用于显示的电量值（取整）
ISElectricWeapon.getDisplayCharge = function(charge)
    if not charge then return 0 end
    return math.floor(charge + 0.5) -- 四舍五入到最近的整数
end

-- 更新武器属性的函数
ISElectricWeapon.updateWeaponDamage = function(weapon)
    if not ISElectricWeapon.isElectricWeapon(weapon) then 
        print("Not an electric weapon")
        return 
    end

    local modData = weapon:getModData()
    local weaponStats = ElectricWeaponConfig.getWeaponStats(weapon:getFullType())

    if not weaponStats then 
        print("No weapon stats found for: " .. weapon:getFullType())
        return 
    end

    print("Updating weapon: " .. weapon:getFullType())

    -- 检查是否处于故障状态
    if modData.malfunctioned then
        print("Weapon malfunctioned - restoring original stats")
        if modData.originalStats then
            weapon:setMaxDamage(modData.originalStats.maxDamage)
            weapon:setMaxRange(modData.originalStats.maxRange)
            weapon:setCriticalChance(modData.originalStats.criticalChance)
            weapon:setMaxHitCount(modData.originalStats.maxHitCount)
        end
        return
    end

    if modData.hasBattery and modData.totalCharge and modData.totalCharge > 0 and modData.electricModeOn then
        print("Electric mode ON - applying new stats")

        if not modData.originalStats then
            -- 保存原始属性
            modData.originalStats = {
                maxDamage = weapon:getMaxDamage(),
                maxRange = weapon:getMaxRange(),
                criticalChance = weapon:getCriticalChance(),
                maxHitCount = weapon:getMaxHitCount()
            }
            print("Saved original stats")
        end

        -- 应用电击模式属性
        if weaponStats.MaxDamage then weapon:setMaxDamage(weaponStats.MaxDamage) end
        if weaponStats.MaxRange then weapon:setMaxRange(weaponStats.MaxRange) end
        if weaponStats.CriticalChance then weapon:setCriticalChance(weaponStats.CriticalChance) end
        if weaponStats.MaxHitCount then weapon:setMaxHitCount(weaponStats.MaxHitCount) end

        print(string.format("Applied new stats - MaxDamage: %f", weapon:getMaxDamage()))
    else
        print("Electric mode OFF - restoring original stats")
        -- 恢复原始属性
        if modData.originalStats then
            weapon:setMaxDamage(modData.originalStats.maxDamage)
            weapon:setMaxRange(modData.originalStats.maxRange)
            weapon:setCriticalChance(modData.originalStats.criticalChance)
            weapon:setMaxHitCount(modData.originalStats.maxHitCount)
            print("Restored original stats")
        end
    end
end

-- 检查并关闭未装备的电击武器
ISElectricWeapon.checkInventoryElectricWeapons = function(player)
    if not player then return end
    
    local inventory = player:getInventory()
    if not inventory then return end
    
    local items = inventory:getItems()
    if not items then return end
    
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and ISElectricWeapon.isElectricWeapon(item) then
            -- 检查这个物品是否正在装备
            local isEquipped = item == player:getPrimaryHandItem()
            
            -- 如果没有装备且处于激活状态，则关闭它
            if not isEquipped then
                local modData = item:getModData()
                if modData and modData.electricModeOn then
                    modData.electricModeOn = false
                    ISElectricWeapon.updateWeaponDamage(item)
                    
                    -- 播放关闭音效
                    if ElectricWeaponConfig.GlobalSounds.toggleOff then
                        player:getEmitter():playSound(ElectricWeaponConfig.GlobalSounds.toggleOff)
                    end
                    
                    print("Deactivated electric mode for: " .. item:getFullType())
                end
            end
        end
    end
end

-- 装备武器时的处理
ISElectricWeapon.OnEquipPrimary = function(player, item)
    if not player then return end

    -- 检查新装备的物品
    if item and ISElectricWeapon.isElectricWeapon(item) then
        ISElectricWeapon.updateWeaponDamage(item)
    end

    -- 延迟一帧检查背包中的电击武器
    Events.OnTick.Add(function()
        Events.OnTick.Remove(this)
        ISElectricWeapon.checkInventoryElectricWeapons(player)
    end)
end

-- 玩家更新事件处理
ISElectricWeapon.OnPlayerUpdate = function(player)
    if not player then return end
    
    -- 如果主手没有装备物品，检查背包中的电击武器
    if not player:getPrimaryHandItem() then
        ISElectricWeapon.checkInventoryElectricWeapons(player)
    end
end

-- 处理武器挥动时的电量消耗
ISElectricWeapon.OnWeaponSwing = function(character, weapon)
    if not weapon or not ISElectricWeapon.isElectricWeapon(weapon) then return end
    
    local modData = weapon:getModData()
    if not modData or not modData.electricModeOn then return end

    -- 添加故障检测
    if modData.electricModeOn and not modData.malfunctioned then
        -- 首先增加风险值
        ISElectricWeaponMalfunctionSystem.addRisk(weapon)
        
        -- 然后检查是否发生故障
        if ISElectricWeaponMalfunctionSystem.checkMalfunction(weapon) then
            ISElectricWeaponMalfunctionSystem.handleMalfunction(weapon, character)
            ISElectricWeapon.updateWeaponDamage(weapon)
            return
        end
    end
    
    if modData.hasBattery and modData.totalCharge and modData.totalCharge > 0 then
        local weaponStats = ElectricWeaponConfig.getWeaponStats(weapon:getFullType())
        if not weaponStats then return end
        
        -- 获取武器的每次挥动电量消耗
        local swingPowerCost = weaponStats.SwingPowerCost or 1 -- 默认消耗1点电量
        
        -- 消耗电量
        modData.totalCharge = modData.totalCharge - swingPowerCost
        
        -- 检查电量是否耗尽
        if modData.totalCharge <= 0 then
            modData.totalCharge = 0
            modData.hasBattery = false
            modData.electricModeOn = false
            character:Say(getText("UI_ElectricWeapon_Battery_Empty"))
            
            -- 播放关闭音效
            if ElectricWeaponConfig.GlobalSounds.toggleOff then
                character:getEmitter():playSound(ElectricWeaponConfig.GlobalSounds.toggleOff)
            end
            
            -- 更新武器属性
            ISElectricWeapon.updateWeaponDamage(weapon)
        end
        
        print(string.format("Weapon power consumed: %d, Remaining: %d", 
            swingPowerCost, modData.totalCharge))
    end
end

-- 处理武器命中非僵尸角色时的逻辑
local function OnWeaponHitCharacter(attacker, target, weapon, damage)
    if not ISElectricWeapon.isElectricWeapon(weapon) then return end

    -- 检查是否命中目标
    if not target then return end
    
    local modData = weapon:getModData()
    if not modData then return end

    local weaponStats = ElectricWeaponConfig.getWeaponStats(weapon:getFullType())
    if not weaponStats then return end

    if modData.electricModeOn and weaponStats.ElectricHitSounds then
        attacker:getEmitter():playSound(weaponStats.ElectricHitSounds.hitSound)
    elseif weaponStats.NormalHitSounds then
        attacker:getEmitter():playSound(weaponStats.NormalHitSounds.hitSound)
    end
end

-- 处理武器命中物品时的逻辑
local function OnWeaponHitThumpable(attacker, weapon, object)
    if not ISElectricWeapon.isElectricWeapon(weapon) then return end

    -- 检查是否命中目标
    if not object then return end
    
    local modData = weapon:getModData()
    if not modData then return end

    local weaponStats = ElectricWeaponConfig.getWeaponStats(weapon:getFullType())
    if not weaponStats then return end

    if modData.electricModeOn and weaponStats.ElectricHitSounds then
        attacker:getEmitter():playSound(weaponStats.ElectricHitSounds.hitDoorSound)
    elseif weaponStats.NormalHitSounds then
        attacker:getEmitter():playSound(weaponStats.NormalHitSounds.hitDoorSound)
    end
end

-- 电击模式开关功能
ISElectricWeapon.toggleElectricMode = function(playerIndex)
    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj then return end

    local weapon = playerObj:getPrimaryHandItem()
    if not weapon or not ISElectricWeapon.isElectricWeapon(weapon) then return end

    local modData = weapon:getModData()
    if not modData then
        modData = {}
        weapon:setModData(modData)
    end

    -- 检查是否处于故障状态
    if modData.malfunctioned then
        playerObj:Say(getText("UI_ElectricWeapon_Malfunctioned"))
        return
    end

    if modData.hasBattery and modData.totalCharge and modData.totalCharge > 0 then
        modData.electricModeOn = not modData.electricModeOn
        ISElectricWeapon.updateWeaponDamage(weapon)

        -- 播放开关音效
        local toggleSound = modData.electricModeOn and 
            ElectricWeaponConfig.GlobalSounds.toggleOn or 
            ElectricWeaponConfig.GlobalSounds.toggleOff
        
        if toggleSound then
            playerObj:getEmitter():playSound(toggleSound)
        end

        if modData.electricModeOn then
            playerObj:Say(getText("UI_ElectricWeapon_Mode_On"))
        else
            playerObj:Say(getText("UI_ElectricWeapon_Mode_Off"))
        end
    else
        playerObj:Say(getText("UI_ElectricWeapon_No_Battery"))
    end
end

-- 检查物品是否为电击武器
ISElectricWeapon.isElectricWeapon = function(item)
    if not item then return false end
    return item:hasTag("ElectricWeapon")
end

-- 按键监听函数
local function onKeyPressed(key)
    local options = PZAPI.ModOptions:getOptions("ElectricWeapon")
    local toggleKey = options:getOption("ToggleElectricMode"):getValue()
    
    if key == toggleKey then
        local player = getPlayer()
        if player then
            ISElectricWeapon.toggleElectricMode(player:getPlayerNum())
        end
    end
end

-- 事件监听器
Events.OnKeyPressed.Add(onKeyPressed)
Events.OnEquipPrimary.Add(ISElectricWeapon.OnEquipPrimary)
Events.OnPlayerUpdate.Add(ISElectricWeapon.OnPlayerUpdate)
Events.OnWeaponSwing.Add(ISElectricWeapon.OnWeaponSwing)
Events.OnWeaponHitCharacter.Add(OnWeaponHitCharacter)
Events.OnWeaponHitThumpable.Add(OnWeaponHitThumpable)

return ISElectricWeapon