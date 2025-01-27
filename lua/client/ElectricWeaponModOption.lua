local config = {
    toggleKey = nil,
}

-- 创建模组选项，使用 getText() 获取翻译文本
local options = PZAPI.ModOptions:create(
    "ElectricWeapon", 
    getText("UI_optionscreen_binding_ElectricWeapon")
)

-- 添加电击模式切换按键绑定选项（默认不绑定按键）
config.toggleKey = options:addKeyBind(
    "ToggleElectricMode", 
    getText("UI_optionscreen_binding_ElectricWeapon_ToggleMode"), 
    0  -- 0 表示没有按键绑定
)

return config