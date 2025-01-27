require 'Items/SuburbsDistributions'
require 'Items/ProceduralDistributions'

-- 定义要分布的物品列表
local MCRweapons = {
    -- 一手武器
    oneHandedWeapons = {
        "Base.Electric_Machete",
        "Base.Electric_Mosquito_Swatter", 
        "Base.Nail_Knife",
        "Base.Pipe_Wrench_Axe",
        "Base.Saw_Blade_Claw",
        "Base.Wrench_Knife",
        "Base.Dagger_HandAxe"
    },
    -- 双手武器
    twoHandedWeapons = {
        "Base.Car_Battery_Sledge",
        "Base.Cleaver_Axe",
        "Base.Dagger_Trident",
        "Base.Electric_Baseball_Bat",
        "Base.Electric_RailSpike_Spear",
        "Base.Electric_Shovel",
        "Base.Electric_Sword",
        "Base.Fire_Extinguisher_Sledge",
        "Base.RailSpike_Spear",
        "Base.Electric_Axe"
    }
}

-- 分布列表
local function addDistributions()
    -- 军事设施武器储存
    local ArmyStorageGuns = ProceduralDistributions.list.ArmyStorageGuns
    if ArmyStorageGuns then
        for _, weapon in ipairs(MCRweapons.oneHandedWeapons) do
            table.insert(ArmyStorageGuns.items, weapon)
            table.insert(ArmyStorageGuns.items, 8.0)
        end
        for _, weapon in ipairs(MCRweapons.twoHandedWeapons) do
            table.insert(ArmyStorageGuns.items, weapon)
            table.insert(ArmyStorageGuns.items, 7.0)
        end
    end

    -- 军事机库工具
    local ArmyHangarTools = ProceduralDistributions.list.ArmyHangarTools
    if ArmyHangarTools then
        for _, weapon in ipairs(MCRweapons.oneHandedWeapons) do
            table.insert(ArmyHangarTools.items, weapon)
            table.insert(ArmyHangarTools.items, 6.0)
        end
        for _, weapon in ipairs(MCRweapons.twoHandedWeapons) do
            table.insert(ArmyHangarTools.items, weapon)
            table.insert(ArmyHangarTools.items, 5.0)
        end
    end

    -- 警察局武器储存
    local PoliceStorageGuns = ProceduralDistributions.list.PoliceStorageGuns
    if PoliceStorageGuns then
        for _, weapon in ipairs(MCRweapons.oneHandedWeapons) do
            table.insert(PoliceStorageGuns.items, weapon)
            table.insert(PoliceStorageGuns.items, 6.0)
        end
        for _, weapon in ipairs(MCRweapons.twoHandedWeapons) do
            table.insert(PoliceStorageGuns.items, weapon)
            table.insert(PoliceStorageGuns.items, 5.0)
        end
    end

    -- 机械工具架
    local MechanicShelfTools = ProceduralDistributions.list.MechanicShelfTools
    if MechanicShelfTools then
        -- 钥匙链螺丝刀特别分布
        table.insert(MechanicShelfTools.items, "Base.Keychain_Screwdriver")
        table.insert(MechanicShelfTools.items, 8.0)
        
        -- 其他工具类武器
        for _, weapon in ipairs(MCRweapons.oneHandedWeapons) do
            table.insert(MechanicShelfTools.items, weapon)
            table.insert(MechanicShelfTools.items, 4.0)
        end
    end
end

-- 初始化分布
Events.OnInitGlobalModData.Add(addDistributions)