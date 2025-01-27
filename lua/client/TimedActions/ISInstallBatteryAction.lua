-- ISInsertBatteryAction.lua
require "TimedActions/ISBaseTimedAction"

ISInsertBatteryAction = ISBaseTimedAction:derive("ISInsertBatteryAction");

function ISInsertBatteryAction:isValid()
    -- 检查角色背包中是否有电池
    return self.battery:getContainer() == self.character:getInventory();
end

function ISInsertBatteryAction:update()
    -- 更新进度条
    self.item:setJobDelta(self:getJobDelta())
end

function ISInsertBatteryAction:start()
    -- 设置动作名称
    self.item:setJobType(getText("ContextMenu_Insert_Battery"))
    self.item:setJobDelta(0.0)
    
    -- 设置动画和相关参数
    self:setActionAnim(CharacterActionAnims.Disassemble)
    
    -- 播放音效
    getSoundManager():PlayWorldSound("InsertBattery", self.character:getCurrentSquare(), 0, 0, 0, true)
end

function ISInsertBatteryAction:stop()
    self.item:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function ISInsertBatteryAction:perform()
    -- 关键修改：在开始时重置进度条
    self.item:setJobDelta(0.0)
    
    -- 完成动作时更新物品状态
    local modData = self.item:getModData()
    modData.hasBattery = true
    -- 获取电池的实际电量并转换为百分比
    modData.totalCharge = self.battery:getCurrentUsesFloat() * 100
    
    -- 移除已使用的电池
    self.character:getInventory():Remove(self.battery)
	
	 -- 添加电量提示信息
    self.character:Say(getText("UI_ElectricWeapon_BatteryInstalled_WithCharge", math.floor(modData.totalCharge)))
    
    -- 触发事件
    self.character:reportEvent("EventInsertBattery")
    
    -- 完成动作
    ISBaseTimedAction.perform(self)
end

function ISInsertBatteryAction:new(character, item, battery)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.battery = battery
    o.maxTime = 100
    
    -- 设置动作属性
    o.stopOnWalk = true
    o.stopOnRun = true
    o.ignoreHandsWounds = false
    -- 添加强制显示进度条
    o.forceProgressBar = true
    
    -- 如果角色有即时动作特性
    if character:isTimedActionInstant() then 
        o.maxTime = 1
    end
    
    return o
end

return ISInsertBatteryAction