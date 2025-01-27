require "TimedActions/ISBaseTimedAction"

ISRemoveBatteryAction = ISBaseTimedAction:derive("ISRemoveBatteryAction")

function ISRemoveBatteryAction:isValid()
    return self.character:getInventory():contains(self.weapon)
end

function ISRemoveBatteryAction:waitToStart()
    if self.character:isSeatedInVehicle() then
        return false
    end
    return false
end

function ISRemoveBatteryAction:update()
    self.weapon:setJobDelta(self:getJobDelta())
end

function ISRemoveBatteryAction:start()
    self:setActionAnim(CharacterActionAnims.Disassemble)
    self.weapon:setJobType(getText("IGUI_ElectricWeapon_RemovingBattery"))
    self.weapon:setJobDelta(0.0)
	 -- 在动作开始时播放声音
    getSoundManager():PlayWorldSound("RemoveBattery", self.character:getCurrentSquare(), 0, 0, 0, true)
end

function ISRemoveBatteryAction:stop()
    self.weapon:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function ISRemoveBatteryAction:perform()
    self.weapon:setJobDelta(0.0)
    
    local modData = self.weapon:getModData()
    if modData.totalCharge and modData.totalCharge > 0 then
        -- 保存当前电量
        local currentCharge = modData.totalCharge

        -- 重置武器状态
        modData.totalCharge = 0
        modData.hasBattery = false
        modData.electricModeOn = false

        -- 添加电池到库存并设置电量
        local battery = self.character:getInventory():AddItem("Base.Battery")
        if battery then
            battery:setCurrentUsesFloat(currentCharge / 100)
            -- 提示信息
            self.character:Say(getText("UI_ElectricWeapon_BatteryRemoved_WithCharge", math.floor(currentCharge)))
        end

        -- 更新武器属性
        ISElectricWeapon.updateWeaponDamage(self.weapon)
    else
        -- 如果没有电量，显示对应提示
        self.character:Say(getText("UI_ElectricWeapon_BatteryDepleted"))
    end
    
    ISBaseTimedAction.perform(self)
end

function ISRemoveBatteryAction:new(character, weapon)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.weapon = weapon
    o.maxTime = 80
    o.stopOnWalk = true
    o.stopOnRun = true
    o.forceProgressBar = true
    if character:isTimedActionInstant() then
        o.maxTime = 1
    end
    return o
end