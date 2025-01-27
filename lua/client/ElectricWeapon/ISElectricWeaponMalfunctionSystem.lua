-- ISElectricWeaponMalfunctionSystem.lua
-- Author: MyrnaCarrie
-- Date: 2025-01-27 12:58:06

ISElectricWeaponMalfunctionSystem = {
-- 获取沙盒设置
function ISElectricWeaponMalfunctionSystem.getSandboxOptions()
    local options = SandboxVars.ElectricWeapon or {}
    return {
        enabled = options.ElectricWeaponMalfunction ~= false,
        baseRiskPerUse = options.ElectricWeaponBaseRiskPerUse or 0.02,
        maxRiskIncrease = options.ElectricWeaponMaxRiskIncrease or 0.15,
        criticalRiskThreshold = options.ElectricWeaponCriticalRiskThreshold or 0.50,
        lowRiskMultiplier = options.ElectricWeaponLowRiskMultiplier or 0.10,
        mediumRiskMultiplier = options.ElectricWeaponMediumRiskMultiplier or 0.30,
        highRiskMultiplier = options.ElectricWeaponHighRiskMultiplier or 0.60,
        riskIncreaseThreshold = options.ElectricWeaponRiskIncreaseThreshold or 1.5
    }
end

-- 故障检查函数
function ISElectricWeaponMalfunctionSystem.checkMalfunction(weapon)
        -- 检查故障系统是否启用
        local options = ISElectricWeaponMalfunctionSystem.getSandboxOptions()
        if not options.enabled then return false end
        
        if not weapon or not weapon:getModData() then return false end
        local modData = weapon:getModData()
        
        -- 如果已经故障，直接返回
        if modData.malfunctioned then return true end
        
        -- 获取当前累积风险
        local currentRisk = modData.accumulatedRisk or 0
        
        -- 如果风险值低于15%，直接返回false，不会发生故障
        if currentRisk < 0.15 then
            return false
        end
        
        -- 计算故障概率
        local malfunctionChance = 0
        if currentRisk < 0.25 then
            -- 15%-25%风险阶段
            malfunctionChance = (currentRisk - 0.15) * options.lowRiskMultiplier
        elseif currentRisk < options.criticalRiskThreshold then
            -- 25%-50%风险阶段
            malfunctionChance = 0.025 + (currentRisk - 0.25) * options.mediumRiskMultiplier
        else
            -- 50%以上风险阶段
            malfunctionChance = 0.1 + (currentRisk - options.criticalRiskThreshold) * options.highRiskMultiplier
        end
        
        -- 添加调试输出
        if ISElectricWeaponMalfunctionSystem.DEBUG then
            print(string.format("Malfunction check - Risk: %.2f%%, Chance: %.2f%%", 
                currentRisk * 100, malfunctionChance * 100))
        end
        
        -- 随机检查是否故障
        if ZombRand(0, 100) < malfunctionChance * 100 then
            modData.malfunctioned = true
            return true
        end
        
        return false
    end,
    
-- 计算使用风险增加
function ISElectricWeaponMalfunctionSystem.calculateRiskIncrease(weapon)
        local options = ISElectricWeaponMalfunctionSystem.getSandboxOptions()
        if not options.enabled then return 0 end
        
        if not weapon or not weapon:getModData() then return 0 end
        local modData = weapon:getModData()
        
        -- 基础风险增加
        local riskIncrease = options.baseRiskPerUse
        
        -- 根据当前累积风险调整增加值
        local currentRisk = modData.accumulatedRisk or 0
        if currentRisk > options.criticalRiskThreshold then
            -- 超过临界值后风险增加更快
            riskIncrease = riskIncrease * options.riskIncreaseThreshold
        end
        
        -- 确保不超过单次最大风险增加值
        return math.min(riskIncrease, options.maxRiskIncrease)
    end,
    
-- 使用武器时增加风险
function ISElectricWeaponMalfunctionSystem.addRisk(weapon)
        local options = ISElectricWeaponMalfunctionSystem.getSandboxOptions()
        if not options.enabled then return false end
        
        if not weapon or not weapon:getModData() then return false end
        local modData = weapon:getModData()
        
        -- 计算风险增加值
        local riskIncrease = ISElectricWeaponMalfunctionSystem.calculateRiskIncrease(weapon)
        
        -- 更新累积风险
        local oldRisk = modData.accumulatedRisk or 0
        modData.accumulatedRisk = oldRisk + riskIncrease
        
        -- 限制最大累积风险为100%
        modData.accumulatedRisk = math.min(modData.accumulatedRisk, 1.0)
        
        -- 添加调试输出
        if ISElectricWeaponMalfunctionSystem.DEBUG then
            print(string.format("Risk increased: %.2f%% -> %.2f%% (+%.2f%%)", 
                oldRisk * 100, modData.accumulatedRisk * 100, riskIncrease * 100))
        end
        
        -- 检查是否故障
        return ISElectricWeaponMalfunctionSystem.checkMalfunction(weapon)
    end,
    
-- 获取风险信息
function ISElectricWeaponMalfunctionSystem.getRiskInfo(weapon)
        local options = ISElectricWeaponMalfunctionSystem.getSandboxOptions()
        if not options.enabled then 
            return {currentRisk = 0, isMalfunctioned = false}
        end
        
        if not weapon or not weapon:getModData() then return nil end
        local modData = weapon:getModData()
        
        -- 返回当前风险信息
        return {
            currentRisk = modData.accumulatedRisk or 0,
            isMalfunctioned = modData.malfunctioned or false
        }
    end,
    
-- 处理故障
function ISElectricWeaponMalfunctionSystem.handleMalfunction(weapon, character)
        if not weapon or not weapon:getModData() then return end
        local modData = weapon:getModData()
        
        -- 设置故障状态
        modData.malfunctioned = true
        
        -- 关闭电击模式
        modData.electricModeOn = false
        
        -- 通知玩家
        if character then
            character:Say(getText("UI_ElectricWeapon_Malfunction"))
        end
        
        -- 播放故障音效
        if ElectricWeaponConfig.GlobalSounds and ElectricWeaponConfig.GlobalSounds.malfunction then
            character:getEmitter():playSound(ElectricWeaponConfig.GlobalSounds.malfunction)
        end
    end,
    
-- 处理维修
function ISElectricWeaponMalfunctionSystem.handleRepair(weapon)
        local options = ISElectricWeaponMalfunctionSystem.getSandboxOptions()
        if not options.enabled then return end
        
        if not weapon or not weapon:getModData() then return end
        local modData = weapon:getModData()
        
        -- 重置故障状态和风险值
        modData.malfunctioned = false
        modData.accumulatedRisk = 0
        
        -- 重置使用次数（如果有的话）
        if modData.useCount then
            modData.useCount = 0
        end
        
        -- 添加调试输出
        if ISElectricWeaponMalfunctionSystem.DEBUG then
            print("Weapon repaired successfully")
        end
    end,
    
-- 初始化武器数据
function ISElectricWeaponMalfunctionSystem.initializeWeapon(weapon)
        if not weapon or not weapon:getModData() then return end
        local modData = weapon:getModData()
        
        -- 初始化必要的数据
        if modData.accumulatedRisk == nil then
            modData.accumulatedRisk = 0
        end
        if modData.malfunctioned == nil then
            modData.malfunctioned = false
        end
        if modData.useCount == nil then
            modData.useCount = 0
        end
    end,
    
-- 调试模式标志
ISElectricWeaponMalfunctionSystem.DEBUG = false
}

return ISElectricWeaponMalfunctionSystem