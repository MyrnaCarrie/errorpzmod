if not ElectricWeaponConfig then ElectricWeaponConfig = {} end

-- 全局音效配置（开关音效）
ElectricWeaponConfig.GlobalSounds = {
    toggleOn = "electric_mode_on",     -- 开启电击模式音效
    toggleOff = "electric_mode_off",    -- 关闭电击模式音效
	malfunction = "electric_malfunction",    -- 添加故障音效
    repair = "electric_repair"               -- 添加修理音效
}

--故障概率
ElectricWeaponConfig.MalfunctionConfig = {
    baseMalfunctionChance = 0.05  -- 故障概率
}

ElectricWeaponConfig.WeaponStats = {

--双手武器

    -- 电棒球棍
    ["Base.Electric_Baseball_Bat"] = {
        MaxDamage = 3.0,
        MaxRange = 1.5,
        CriticalChance = 30,
        SwingPowerCost = 2.5, 
		MaxHitCount = 3,
        ElectricHitSounds = {
            hitSound = "Electric_Baseball_Bat_Hit",
            hitFloorSound = "Electric_Baseball_Bat_Hit",
            hitDoorSound = "Electric_Baseball_Bat_Hit"
        },
        NormalHitSounds = {
            hitSound = "SpikedBaseballBatHit",
            hitFloorSound = "SpikedBaseballBatHit",
            hitDoorSound = "SpikedBaseballBatHit"
        }
    },
	
	-- 汽车电池大锤
    ["Base.Car_Battery_Sledge"] = {
        MaxDamage = 5.0,
        MaxRange = 1.2,
        CriticalChance = 30,
        SwingPowerCost = 5, 
		MaxHitCount = 3,
        ElectricHitSounds = {
            hitSound = "Car_Battery_Sledge_Hit",
            hitFloorSound = "Car_Battery_Sledge_Hit",
            hitDoorSound = "Car_Battery_Sledge_Hit"
        },
        NormalHitSounds = {
            hitSound = "SledgehammerHit",
            hitFloorSound = "SledgehammerHit",
            hitDoorSound = "SledgehammerHit"
        }
    },
	
	-- 轨道钉电矛
    ["Base.Electric_RailSpike_Spear"] = {
        MaxDamage = 5.0,
        MaxRange = 1.2,
        CriticalChance = 30,
        SwingPowerCost = 1.8, 
		MaxHitCount = 3,
        ElectricHitSounds = {
            hitSound = "Electric_RailSpike_Spear_Hit",
            hitFloorSound = "Electric_RailSpike_Spear_Hit",
            hitDoorSound = "Electric_RailSpike_Spear_Hit"
        },
        NormalHitSounds = {
            hitSound = "CrudeSpearHit",
            hitFloorSound = "CrudeSpearHit",
            hitDoorSound = "CrudeSpearHit"
        }
    },
	
	-- 电铁铲
    ["Base.Electric_Shovel"] = {
        MaxDamage = 5.0,
        MaxRange = 1.2,
        CriticalChance = 30,
        SwingPowerCost = 2.5, 
		MaxHitCount = 3,
        ElectricHitSounds = {
            hitSound = "Electric_Shovel_Hit",
            hitFloorSound = "Electric_Shovel_Hit",
            hitDoorSound = "Electric_Shovel_Hit"
        },
        NormalHitSounds = {
            hitSound = "ShovelHit",
            hitFloorSound = "ShovelHit",
            hitDoorSound = "ShovelHit"
        }
    },
	
	-- 电刀
    ["Base.Electric_Sword"] = {
        MaxDamage = 5.0,
        MaxRange = 1.2,
        CriticalChance = 30,
        SwingPowerCost = 2.3, 
		MaxHitCount = 3,
        ElectricHitSounds = {
            hitSound = "Electric_Sword_Hit",
            hitFloorSound = "Electric_Sword_Hit",
            hitDoorSound = "Electric_Sword_Hit"
        },
        NormalHitSounds = {
            hitSound = "CrudeSwordHit",
            hitFloorSound = "CrudeSwordHit",
            hitDoorSound = "CrudeSwordHit"
        }
    },
	
	-- 电长柄斧头
    ["Base.Electric_Axe"] = {
        MaxDamage = 5.0,
        MaxRange = 1.2,
        CriticalChance = 30,
        SwingPowerCost = 2.5, 
		MaxHitCount = 3,
        ElectricHitSounds = {
            hitSound = "Electric_Axe_Hit",
            hitFloorSound = "Electric_Axe_Hit",
            hitDoorSound = "Electric_Axe_Hit"
        },
        NormalHitSounds = {
            hitSound = "AxeHit",
            hitFloorSound = "AxeHit",
            hitDoorSound = "AxeHit"
        }
    },
	
--单手武器

    -- 电砍刀
    ["Base.Electric_Machete"] = {
        MaxDamage = 5.0,
        MaxRange = 1.2,
        CriticalChance = 30,
        SwingPowerCost = 1.3, 
		MaxHitCount = 3,
        ElectricHitSounds = {
            hitSound = "Electric_Machete_Hit",
            hitFloorSound = "Electric_Machete_Hit",
            hitDoorSound = "Electric_Machete_Hit"
        },
        NormalHitSounds = {
            hitSound = "MacheteHit",
            hitFloorSound = "MacheteHit",
            hitDoorSound = "MacheteHit"
        }
    },
	
    -- 电蚊拍
    ["Base.Electric_Mosquito_Swatter"] = {
        MaxDamage = 1.5,
        MaxRange = 0.8,
        CriticalChance = 40,
		SwingPowerCost = 1.3, 
		MaxHitCount = 3,
        ElectricHitSounds = {
            hitSound = "Electric_Mosquito_Swatter_Hit",
            hitFloorSound = "Electric_Mosquito_Swatter_Hit",
            hitDoorSound = "Electric_Mosquito_Swatter_Hit"
        },
        NormalHitSounds = {
            hitSound = "TennisRacketHit",
            hitFloorSound = "TennisRacketHit",
            hitDoorSound = "TennisRacketHit"
        }
    }
}

-- 获取武器属性的函数
ElectricWeaponConfig.getWeaponStats = function(weaponFullType)
    return ElectricWeaponConfig.WeaponStats[weaponFullType]
end

return ElectricWeaponConfig