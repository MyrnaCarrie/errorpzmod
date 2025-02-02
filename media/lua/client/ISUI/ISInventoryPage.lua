-- LEMMY/ROBERT JOHNSON *thank you*

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "ISUI/ISResizeWidget"
require "ISUI/ISMouseDrag"
require "ISUI/ISLayoutManager"
require "Definitions/ContainerButtonIcons"
require "defines"

ISInventoryPage = ISPanel:derive("ISInventoryPage");

local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
--local BUTTON_HGT = 35
local BUTTON_HGT = FONT_HGT_MEDIUM + 6

ISInventoryPage.bagSoundDelay = 2
ISInventoryPage.bagSoundTime = 0

function ISInventoryPage:initialise()
	ISPanel.initialise(self);
end

function ISInventoryPage:titleBarHeight(selected)
	return math.max(self.buttonSize * 1.5 + BUTTON_HGT, self.titleFontHgt + 1)
end

function ISInventoryPage:createChildren()
	self.minimumHeight = 50;
	self.minimumWidth = 225;
	self.render3DItemRot = 0;
	
	local titleBarHeight = self:titleBarHeight()

--	ISInventoryPane.lua (all visible items)
	local panel2 = ISInventoryPane:new(0, self.buttonSize * 1.5 + BUTTON_HGT, self.width + 1, self.height - self.buttonSize * 1.5 - BUTTON_HGT + 1, self.inventory, self.zoom);
	panel2.anchorBottom = true;
	panel2.anchorRight = true;
	panel2.player = self.player;
	panel2:initialise();
	panel2.inventoryPage = self;
	self:addChild(panel2);
	self.inventoryPane = panel2;

	local measuredWidth = math.max(getTextManager():MeasureStringX(UIFont.Medium, "<<  " .. getText("IGUI_invpage_Transfer_all")), getTextManager():MeasureStringX(UIFont.Medium, getText("IGUI_invpage_Transfer_all")))
	
	self.transferOrLootAll = ISButton:new(0, 60, 150, 35, getText("IGUI_invpage_Transfer_all"), self, ISInventoryPage.transferOrLootChoice);
	self.transferOrLootAll:initialise();
	self.transferOrLootAll:setFont(UIFont.Medium)
	self.transferOrLootAll.width = measuredWidth + 30
	self.transferOrLootAll.borderColor.a = 0;
	self.transferOrLootAll.backgroundColor = {r=0.29, g=0.25, b=0.2, a=1.0};
	self.transferOrLootAll.backgroundColorMouseOver = {r=0.29, g=0.25, b=0.2, a=1.0};
	self.transferOrLootAll.mode = "transfer"
	self:addChild(self.transferOrLootAll);
	self.transferOrLootAll:setVisible(false);

    if not self.onCharacter then
		self.removeAll = ISButton:new(90, self.buttonSize * 1.5, BUTTON_HGT, BUTTON_HGT, getText("IGUI_invpage_RemoveAll"), self, ISInventoryPage.removeAll);
		self.removeAll:initialise();
		self.removeAll:setImage(self.deleteAllButton)
		self.removeAll.textColor = {r=0.0, g=0.0, b=0.0, a=0.0};
		self.removeAll.borderColor.a = 0;
		self.removeAll.backgroundColor.a = 0;
		self.removeAll.backgroundColorMouseOver.a = 0.0;
		self:addChild(self.removeAll);
		self.removeAll:setVisible(false);
	
		self.toggleStove = ISButton:new(90, self.buttonSize * 1.5, BUTTON_HGT, BUTTON_HGT, getText("ContextMenu_Turn_On"), self, ISInventoryPage.toggleStove);
		self.toggleStove:initialise();
		self.toggleStove:setImage(self.stoveOff)
		self.toggleStove.textColor = {r=0.0, g=0.0, b=0.0, a=0.0};
		self.toggleStove.borderColor.a = 0;
		self.toggleStove.backgroundColor.a = 0;
		self.toggleStove.backgroundColorMouseOver.a = 0.0;
		self:addChild(self.toggleStove);
		self.toggleStove:setVisible(false);
		
		self.lootAll = ISButton:new(0, 60, 150, 35, "", self, ISInventoryPage.lootAll);
        self.lootAll:initialise();
        self:addChild(self.lootAll);
        self.lootAll:setVisible(false);
	else
		self.transferAll = ISButton:new(0, 60, 150, 35, "", self, ISInventoryPage.transferAll);
		self.transferAll:initialise();
		self:addChild(self.transferAll);
		self.transferAll:setVisible(false);
	end

    local rh = BUTTON_HGT/2+1
	local resizeWidget = ISResizeWidget:new(self.width-rh, self.height-rh, rh, rh, self);
	resizeWidget:initialise();
	self:addChild(resizeWidget);

	self.resizeWidget = resizeWidget;

	self.closeButton = ISButton:new(0, 60, 35, 35, "", self, ISInventoryPage.close);
	self.closeButton:initialise();
	self:addChild(self.closeButton);
	self.closeButton:setVisible(false)

	self.infoButton = ISButton:new(0, 60, 35, 35, "", self, ISInventoryPage.onInfo);
	self.infoButton:initialise();
	self:addChild(self.infoButton);
	self.infoButton:setVisible(false);

	self.pinButton = ISButton:new(0, 60, 35, 35, "", self, ISInventoryPage.setPinned);
	self.pinButton:initialise();
	self:addChild(self.pinButton);
	self.pinButton.backgroundColor.a = 0
	self.pinButton.borderColor.a = 0
	self.pinButton.backgroundColorMouseOver.a = 0
	self.pinButton:setImage(self.pinbutton);
	self.pinButton:setVisible(false);

	self.collapseButton = ISButton:new(0, 60, 35, 35, "", self, ISInventoryPage.collapse);
	self.collapseButton:initialise();
	self:addChild(self.collapseButton);
	self.collapseButton.backgroundColor.a = 0
	self.collapseButton.borderColor.a = 0
	self.collapseButton.backgroundColorMouseOver.a = 0
	self.collapseButton:setImage(self.collapsebutton);
	self.collapseButton:setVisible(true)

	self.totalWeight	=	ISInventoryPage.loadWeight(self.inventory);
	self.totalItems		=	0;

	self:refreshBackpacks();

	--self:collapse();
end

function ISInventoryPage:transferOrLootChoice(button)
	if button.mode == "loot" then
		self.inventoryPane:lootAll();
	elseif button.mode == "transfer" then
		self.inventoryPane:transferAll();
	end
end

local TurnOnOff = {
	ClothingDryer = {
		isPowered = function(object)
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
			if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
				ISTimedActionQueue.add(ISToggleClothingDryer:new(getPlayer(), object))
			end
		end
	},
	ClothingWasher = {
		isPowered = function(object)
			if object:getWaterAmount() <= 0 then return false end
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
			if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
				ISTimedActionQueue.add(ISToggleClothingWasher:new(getPlayer(), object))
			end
		end
	},
	CombinationWasherDryer = {
		isPowered = function(object)
			if object:isModeWasher() and (object:getWaterAmount() <= 0) then return false end
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
			if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
				ISTimedActionQueue.add(ISToggleComboWasherDryer:new(getPlayer(), object))
			end
		end
	},
	Stove = {
		isPowered = function(object)
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:Activated()
		end,
		toggle = function(object)
			if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
				ISTimedActionQueue.add(ISToggleStoveAction:new(getPlayer(), object))
			end
		end
	}
}

function ISInventoryPage:toggleStove()
	if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then
		return
	end

	local object = self.inventoryPane.inventory:getParent()
	if not object then return end
	local className = object:getObjectName()
	TurnOnOff[className].toggle(object)
end

function ISInventoryPage:syncToggleStove()
	if self.onCharacter then return end
	local isVisible = self.toggleStove:getIsVisible()
	local shouldBeVisible = false
	local stove = nil
	if self.inventoryPane.inventory then
		stove = self.inventoryPane.inventory:getParent()
		if stove then
			local className = stove:getObjectName()
			if TurnOnOff[className] and TurnOnOff[className].isPowered(stove) then
				shouldBeVisible = true
			end
		end
	end
	local containerButton
	for _,cb in ipairs(self.backpacks) do
		if cb.inventory == self.inventoryPane.inventory then
			containerButton = cb
			break
		end
	end
	if not containerButton then
		shouldBeVisible = false
	end
	if isVisible ~= shouldBeVisible and getCore():getGameMode() ~= "Tutorial" then
		self.toggleStove:setVisible(shouldBeVisible)
	end
	if shouldBeVisible then
		local className = stove:getObjectName()
		if TurnOnOff[className].isActivated(stove) then
			self.toggleStove:setImage(self.stoveOn)
			self.toggleStove:setX(getTextManager():MeasureStringX(UIFont.Medium, self.title) + 5 + self.pinButton.width)
			self.toggleStove:setTooltip(getText("ContextMenu_Turn_Off"))
			self.toggleStove:setTitle(getText("ContextMenu_Turn_Off"))
		else
			self.toggleStove:setImage(self.stoveOff)
			self.toggleStove:setX(getTextManager():MeasureStringX(UIFont.Medium, self.title) + 5 + self.pinButton.width)
			self.toggleStove:setTooltip(getText("ContextMenu_Turn_On"))
			self.toggleStove:setTitle(getText("ContextMenu_Turn_On"))
		end
	end
end

function ISInventoryPage:collapse()
    if ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
        return;
    end
    self.pin = false;
    self.collapseButton:setVisible(false);
    self.pinButton:setVisible(true);
    self.pinButton:bringToTop();
    self.inventoryPane:clearWorldObjectHighlights();
end

function ISInventoryPage:isRemoveButtonVisible()
	if self.onCharacter then return false end
	if self.inventory:isEmpty() then return false end
	if isClient() and not getServerOptions():getBoolean("TrashDeleteAll") then return false end
	local obj = self.inventory:getParent()
	if not instanceof(obj, "IsoObject") then return false end
	local sprite = obj:getSprite()
	return sprite and sprite:getProperties() and sprite:getProperties():Is("IsTrashCan")
end

function ISInventoryPage:update()
	local playerObj = getSpecificPlayer(self.player)
	if self.inventory:getEffectiveCapacity(playerObj) ~= self.capacity then
		self.capacity = self.inventory:getEffectiveCapacity(playerObj)
	end

	if self.coloredInv and (self.inventory ~= self.coloredInv or self.isCollapsed) then
		if self.coloredInv:getParent() then
			self.coloredInv:getParent():setHighlighted(false)
			self.coloredInv:getParent():setOutlineHighlight(false);
			self.coloredInv:getParent():setOutlineHlAttached(false);
		end
		self.coloredInv = nil;
	end

	if not self.isCollapsed then
		if self.inventory:getParent() and ((not instanceof(self.inventory:getParent(), "IsoPlayer")) or instanceof(self.inventory:getParent(), "IsoDeadBody")) then
			self.inventory:getParent():setHighlighted(true, false);
			if getCore():getOptionDoContainerOutline() then -- TODO RJ: this make the player blink, not sure what was wanted here?
				self.inventory:getParent():setOutlineHighlight(true);
				self.inventory:getParent():setOutlineHlAttached(true);
				self.inventory:getParent():setOutlineHighlightCol(getCore():getObjectHighlitedColor():getR(), getCore():getObjectHighlitedColor():getG(), getCore():getObjectHighlitedColor():getB(), 1);
			end
			self.inventory:getParent():setHighlightColor(getCore():getObjectHighlitedColor());
			self.coloredInv = self.inventory;
		end
	end
	
	if (ISMouseDrag.dragging ~= nil and #ISMouseDrag.dragging > 0) or self.pin then
		self.collapseCounter = 0;
		if isClient() and self.isCollapsed then
			self.inventoryPane.inventory:requestSync();
		end
		self.isCollapsed = false;
		--self:clearMaxDrawHeight();
		self.collapseCounter = 0;
	end

	if not self.onCharacter then
--		"remove all" button for trash can/bins
		self.removeAll:setVisible(self:isRemoveButtonVisible())
		self.removeAll:setX(getTextManager():MeasureStringX(UIFont.Medium, self.title) + 2)
		self.removeAll:setTooltip(getText("IGUI_invpage_RemoveAll"))

		local playerObj = getSpecificPlayer(self.player)
		if self.lastDir ~= playerObj:getDir() then
			self.lastDir = playerObj:getDir()
			self:refreshBackpacks()
		elseif self.lastSquare ~= playerObj:getCurrentSquare() then
			self.lastSquare = playerObj:getCurrentSquare()
			self:refreshBackpacks()
		end

--		currently-selected container is locked to the player, select another container.
		local object = self.inventory and self.inventory:getParent() or nil
		if #self.backpacks > 1 and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
			local currentIndex = self:getCurrentBackpackIndex()
			local unlockedIndex = self:prevUnlockedContainer(currentIndex, false)
			if unlockedIndex == -1 then
				unlockedIndex = self:nextUnlockedContainer(currentIndex, false)
			end
			if unlockedIndex ~= -1 then
				if playerObj:getJoypadBind() ~= -1 then
					self.backpackChoice = unlockedIndex
				end
				self:selectContainer(self.backpacks[unlockedIndex])
			end
		end
	end

	self.totalItems = luautils.countItemsRecursive({luautils.findRootInventory(self.inventoryPane.inventory)});

	self:syncToggleStove()
end

function ISInventoryPage:setForceSelectedContainer(container)
	self.forceSelectedContainer = container
	self.forceSelectedContainerTime = getTimestampMs() + 1000
end

function ISInventoryPage:drawTextureTiled(texture, x, y, w, h, r, g, b, a)
	if self.javaObject ~= nil then
		if not r then
			r,g,b,a = 1,1,1,1
		end
		self.javaObject:DrawTextureTiled(texture, x, y, w, h, r, g, b, a);
	end
end

function ISInventoryPage:prerender()

	local titleBarHeight = self:titleBarHeight()
	local height = self:getHeight();
	if self.isCollapsed then
		height = titleBarHeight;
	end
--		header background
		self:drawTextureTiled(self.headerTexture, 0, self.buttonSize * 1.5, self.width, BUTTON_HGT, 1, 1, 1, 0.9)

--	title text inventory
	if self.title and self.onCharacter and self.width > 230 then
		self:drawText(self.title, self.pinButton.width, self.buttonSize * 1.5 + 2, 1,1,1,1);
	end

	local weightLabel;
	local buttonOffset = 1 + (5-getCore():getOptionFontSizeReal())*2

--	load the current weight of the container
	self.totalWeight = ISInventoryPage.loadWeight(self.inventoryPane.inventory);
--	used handle characters being in seats
	local occupied;
	local roundedWeight = round(self.totalWeight, 2)

	if self.capacity then
		local inventory = self.inventoryPane.inventory
		local part = inventory:getVehiclePart()
		if inventory == getSpecificPlayer(self.player):getInventory() then
--			weight / max weight inventory panel
			self:drawTextRight(roundedWeight .. " / " .. getSpecificPlayer(self.player):getMaxWeight(), self.width - 12, self.buttonSize * 1.5 + 2, 1,1,1,1);
--		if a vehicle seat is occupied, display it's max maximum capacity at 25%/5 units
		elseif part and part:getId():contains("Seat") and part:getVehicle():getCharacter(part:getContainerSeatNumber()) then
--			weight
			self:drawTextRight(roundedWeight .. " / " .. (self.capacity/4), self.width - 12, self.buttonSize * 1.5 + 2, 1,1,1,1);
			occupied = true;
		else
--			display the item total and limit per container in MP
			if isClient() then
				local itemLimit = getServerOptions():getInteger("ItemNumbersLimitPerContainer");
				local itemNumber = luautils.countItemsRecursive({luautils.findRootInventory(self.inventoryPane.inventory)});
				if itemLimit > 0 then
					weightLabel = roundedWeight .. " / " .. self.capacity .. " (" .. itemNumber .. " / " .. itemLimit .. ")";
				else
					weightLabel = roundedWeight .. " / " .. self.capacity;
				end;
			else
				weightLabel = roundedWeight .. " / " .. self.capacity;
			end;
		end;
	else
		weightLabel = roundedWeight .. "";
	end;
--	weight / max weight loot
	self:drawTextRight(weightLabel, self.width - 12, self.buttonSize * 1.5 + 2, 1,1,1,1);

	local weightWid = getTextManager():MeasureStringX(UIFont.Small, "9999.99 / 9999") + 30;
	if not self.onCharacter or self.width < 370 then
	elseif "Tutorial" ~= getCore():getGameMode() then
	end

	local buttonHeight = titleBarHeight-2
	local textButtonOffset = buttonOffset * 3
	local textWid = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_invpage_Transfer_all"))

--	title text loot
	if self.title and not self.onCharacter and self.width > 230 then
		local fontHgt = getTextManager():getFontHeight(self.font)
		if occupied then
			self:drawText((self.title .. " " .. getText("IGUI_invpage_Occupied")), 12, self.buttonSize * 1.5 + 2, 1,1,1,1);
		else
			self:drawText(self.title, self.pinButton.width, self.buttonSize * 1.5 + 2, 1,1,1,1);
		end
	end

	self:setStencilRect(0,0,self.width+1, self.height);

	local playerObj = getSpecificPlayer(self.player)
	if playerObj and playerObj:isInvPageDirty() then
		playerObj:setInvPageDirty(false);
		ISInventoryPage.renderDirty = false;
		ISInventoryPage.dirtyUI();
	end
	if ISInventoryPage.renderDirty then
		ISInventoryPage.renderDirty = false;
		ISInventoryPage.dirtyUI();
	end
end

function ISInventoryPage:drawTextRight(str, x, y, r, g, b, a, font)
	if self.javaObject ~= nil and str ~= nil then
		if font ~= nil then
			self.javaObject:DrawTextRight(font, str, x, y, r, g, b, a);
		else
			self.javaObject:DrawTextRight(UIFont.Medium, str, x, y, r, g, b, a);
		end
	end
end

function ISInventoryPage:drawText(str, x, y, r, g, b, a, font)
	if self.javaObject ~= nil then
		if font ~= nil then
			self.javaObject:DrawText(font, str, x, y, r, g, b, a);
		else
			self.javaObject:DrawText(UIFont.Medium, str, x, y, r, g, b, a);
		end
	end
end

function ISInventoryPage:close()
	ISPanel.close(self)
	if JoypadState.players[self.player+1] then
		setJoypadFocus(self.player, nil)
		local playerObj = getSpecificPlayer(self.player)
		playerObj:setBannedAttacking(false)
	end
	self.inventoryPane:clearWorldObjectHighlights();
end

function ISInventoryPage:onToggleVisible()
	self.inventoryPane:clearWorldObjectHighlights();
end

function ISInventoryPage:onLoseJoypadFocus(joypadData)
	ISPanel.onLoseJoypadFocus(self, joypadData)

	self.inventoryPane.doController = false;
	local inv = getPlayerInventory(self.player);
	if not inv then
		return;
	end
	local loot = getPlayerLoot(self.player);
	if inv.joyfocus or loot.joyfocus then
		return;
	end

	if getFocusForPlayer(self.player) == nil then
		inv:setVisible(false);
		loot:setVisible(false);
		local playerObj = getSpecificPlayer(self.player)
		playerObj:setBannedAttacking(false)
		if playerObj:getVehicle() and playerObj:getVehicle():isDriver(playerObj) then
			getPlayerVehicleDashboard(self.player):addToUIManager()
		end
	end

end

function ISInventoryPage:onGainJoypadFocus(joypadData)
	ISPanel.onGainJoypadFocus(self, joypadData)

	local inv = getPlayerInventory(self.player);
	local loot = getPlayerLoot(self.player);
	inv:setVisible(true);
	loot:setVisible(true);
	getPlayerVehicleDashboard(self.player):removeFromUIManager()
	self.inventoryPane.doController = true;
end

function ISInventoryPage:getCurrentBackpackIndex()
	for index,backpack in ipairs(self.backpacks) do
		if backpack.inventory == self.inventory then
			return index
		end
	end
	return -1
end

function ISInventoryPage:prevUnlockedContainer(index, wrap)
	local playerObj = getSpecificPlayer(self.player)
	for i=index-1,1,-1 do
		local backpack = self.backpacks[i]
		local object = backpack.inventory:getParent()
		if not (instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj)) then
			return i
		end
	end
	return wrap and self:prevUnlockedContainer(#self.backpacks + 1, false) or -1
end

function ISInventoryPage:nextUnlockedContainer(index, wrap)
	if index < 0 then -- User clicked a container that isn't displayed
		return wrap and self:nextUnlockedContainer(0, false) or -1
	end
	local playerObj = getSpecificPlayer(self.player)
	for i=index+1,#self.backpacks do
		local backpack = self.backpacks[i]
		local object = backpack.inventory:getParent()
		if not (instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj)) then
			return i
		end
	end
	return wrap and self:nextUnlockedContainer(0, false) or -1
end

function ISInventoryPage:selectPrevContainer()
	local currentIndex = self:getCurrentBackpackIndex()
	local unlockedIndex = self:prevUnlockedContainer(currentIndex, true)
	if unlockedIndex == -1 then
		return
	end
		self.backpackChoice = unlockedIndex
	self:selectContainer(self.backpacks[unlockedIndex])
end

function ISInventoryPage:selectNextContainer()
	local currentIndex = self:getCurrentBackpackIndex()
	local unlockedIndex = self:nextUnlockedContainer(currentIndex, true)
	if unlockedIndex == -1 then
		return
	end
	local playerObj = getSpecificPlayer(self.player)
		self.backpackChoice = unlockedIndex
	self:selectContainer(self.backpacks[unlockedIndex])
end

function ISInventoryPage:onJoypadDown(button)
	ISContextMenu.globalPlayerContext = self.player;
	local playerObj = getSpecificPlayer(self.player)

	if button == Joypad.AButton then
		self.inventoryPane:doContextOnJoypadSelected();
	end

	if button == Joypad.BButton then
		if isPlayerDoingActionThatCanBeCancelled(playerObj) then
			stopDoingActionThatCanBeCancelled(playerObj)
			return
		end
		self.inventoryPane:doJoypadExpandCollapse("joypad")
	end
	if button == Joypad.XButton and not JoypadState.disableGrab then
		self.inventoryPane:doGrabOnJoypadSelected();
	end
	if button == Joypad.YButton and not JoypadState.disableYInventory then
		setJoypadFocus(self.player, nil);
	end

	-- 1: left button affects inventory, right button affects loot
	-- 2: both buttons affect same window
	-- 3: left + d-pad affects inventory, right + dpad affects loot
	local shoulderSwitch = getCore():getOptionShoulderButtonContainerSwitch()
	if getCore():getGameMode() == "Tutorial" then shoulderSwitch = 1 end
	if button == Joypad.LBumper then
		if shoulderSwitch == 1 then
			getPlayerInventory(self.player):selectNextContainer()
		elseif shoulderSwitch == 2 then
			self:selectPrevContainer()
		elseif shoulderSwitch == 3 then
			setJoypadFocus(self.player, getPlayerInventory(self.player))
		end
	end
	if button == Joypad.RBumper then
		if shoulderSwitch == 1 then
			getPlayerLoot(self.player):selectNextContainer()
		elseif shoulderSwitch == 2 then
			self:selectNextContainer()
		elseif shoulderSwitch == 3 then
			setJoypadFocus(self.player, getPlayerLoot(self.player))
		end
	end
	
		local playerObj = getSpecificPlayer(self.player)
		playerObj:setBannedAttacking(false)	
		

end

function ISInventoryPage:drawTextureTiledX(texture, x, y, w, h, r, g, b, a)
	if self.javaObject ~= nil then
		if not r then
			r,g,b,a = 1,1,1,1
		end
		self.javaObject:DrawTextureTiledX(texture, x, y, w, h, r, g, b, a);
	end
end

function ISInventoryPage:onJoypadDirUp(joypadData)
	
	local firstItems = self.inventoryPane.grid.firstItem
	
--	not empty
	if #self.inventoryPane.items < 2 then
	else
--		not first >>> go up closest
		if self.nRow > 1 then
			local target = self.inventoryPane.joyselection - firstItems[self.nRow] + firstItems[self.nRow - 1]
			local lastItem = firstItems[self.nRow] - 1
			self.inventoryPane.joyselection = math.min(target, lastItem)
		else
--			go down
			self.inventoryPane.joyselection = firstItems[#firstItems]
		end
	end
end

function ISInventoryPage:onJoypadDirDown(joypadData)

	local firstItems = self.inventoryPane.grid.firstItem
	
--	not empty
	if #self.inventoryPane.items < 2 then
	else
--		last >>> go to the top
		if self.nRow == #firstItems then	
			self.inventoryPane.joyselection = 1
			self.nRow = 1
		else
			local target = self.inventoryPane.joyselection - firstItems[self.nRow] + firstItems[self.nRow + 1]
			local lastItem = #self.inventoryPane.items
--			higher >>> go down closest
			if self.nRow < #firstItems - 1 then
				lastItem = firstItems[self.nRow + 2] - 1
				self.inventoryPane.joyselection = math.min(target, lastItem)
			else
--			second last >>> go down closest
			self.inventoryPane.joyselection = math.min(target, lastItem)
			end
		end
	end
end


function ISInventoryPage:onJoypadDirLeft()
	
			
	local inv = getPlayerInventory(self.player);
	local loot = getPlayerLoot(self.player);
	
	if self == inv then
--		not first >>> go back one
		if self.inventoryPane.joyselection > 1 then
			self.inventoryPane.joyselection = self.inventoryPane.joyselection - 1
		else
		end
	else
--		first in row >>> go inventory
		if #self.inventoryPane.items == 0 or self.inventoryPane.joyselection == self.inventoryPane.grid.firstItem[self.nRow] then
			setJoypadFocus(self.player, inv);
--		not first >>> go back one
		else
			self.inventoryPane.joyselection = self.inventoryPane.joyselection - 1
		end
	end
end

function ISInventoryPage:onJoypadDirRight()

	local inv = getPlayerInventory(self.player);
	local loot = getPlayerLoot(self.player);
	local lastItem = #self.inventoryPane.items

	if self == inv then
		if lastItem > 1 then
			if self.nRow ~= #self.inventoryPane.grid.firstItem then
				lastItem = self.inventoryPane.grid.firstItem[self.nRow + 1] - 1
			end
--			not last in row >>> go right
			if self.inventoryPane.joyselection ~= lastItem then
				self.inventoryPane.joyselection = self.inventoryPane.joyselection + 1
--			last in row >>> go loot
			else
				setJoypadFocus(self.player, loot);
			end
		else
			setJoypadFocus(self.player, loot);
		end
	else
		if lastItem > 1 then
			if self.nRow ~= #self.inventoryPane.grid.firstItem then
				lastItem = self.inventoryPane.grid.firstItem[self.nRow + 1] - 1
--				go right
				self.inventoryPane.joyselection = self.inventoryPane.joyselection + 1
			else
--				not last item >>> go right
				if self.inventoryPane.joyselection ~= #self.inventoryPane.items then
					self.inventoryPane.joyselection = self.inventoryPane.joyselection + 1
--				last item >>> stop
				else
				end
			end
		else
		end
	end
end

function ISInventoryPage:render()
	local titleBarHeight = self:titleBarHeight()
	local rh = BUTTON_HGT/2+2
	local height = self:getHeight();
	if self.isCollapsed then
		height = titleBarHeight
	end

	self:clearStencilRect();

--	focus border	
	if self.joyfocus then
		local borderOffset = self.backpackChoice - 1
		if self.backpackChoice > 7 then borderOffset = 7 end
--		button border (left, top, right)
		self:drawRect(self.buttonSize * borderOffset, 0, 1, self.buttonSize * 1.5, 1.0, 0.8, 0.6, 0.4)
		self:drawRect(self.buttonSize * borderOffset, 0, 60, 1, 1.0, 0.8, 0.6, 0.4)
		self:drawRect(self.buttonSize * 1.5 + self.buttonSize * borderOffset, 0, 1, 60, 1.0, 0.8, 0.6, 0.4)
		
--		window border (top left, top right, right, bottom, left)
		self:drawRect(0, self.buttonSize * 1.5, self.buttonSize * borderOffset, 1, 1.0, 0.8, 0.6, 0.4)
		self:drawRect(self.buttonSize * 1.5 + self.buttonSize * borderOffset, self.buttonSize * 1.5, self.width - self.buttonSize * 1.5 - self.buttonSize * borderOffset, 1, 1.0, 0.8, 0.6, 0.4)
		self:drawRect(self.width, 0 + self.buttonSize * 1.5, 1, self.height - self.buttonSize * 1.5, 1.0, 0.8, 0.6, 0.4)
		self:drawRect(0, self.height, self.width + 1, 1, 1.0, 0.8, 0.6, 0.4)
		self:drawRect(0, self.buttonSize * 1.5, 1, self.height - self.buttonSize * 1.5, 1.0, 0.8, 0.6, 0.4)
	
	end

	if self.render3DItems and #self.render3DItems > 0 then
		self:render3DItemPreview();
	end

	if #self.backpacks > self.maxButtons and self.backpackChoice < self.maxButtons then
		self:drawText("+", self.maxButtons * self.buttonSize + self.buttonSize / 2 - 9, self.buttonSize / 2 -5, 0, 0, 0, 1, UIFont.Medium);
		self:drawText("+", self.maxButtons * self.buttonSize + self.buttonSize / 2 - 10, self.buttonSize / 2 -6, 0.7, 0.7, 0.7, 1.0, UIFont.Medium);
	end

	if self.backpackChoice >= self.maxButtons and self.backpackChoice ~= #self.backpacks then
		self:drawText("+"..(#self.backpacks - self.backpackChoice).."", (self.maxButtons - 1) * self.buttonSize + self.buttonSize / 2+2,self.buttonSize * 1.5 / 3, 0.0, 0.0, 0.0, 1.0, UIFont.Medium);
		self:drawText("+"..(#self.backpacks - self.backpackChoice).."", (self.maxButtons - 1) * self.buttonSize + self.buttonSize / 2-2,self.buttonSize * 1.5 / 3, 0.0, 0.0, 0.0, 1.0, UIFont.Medium);
		self:drawText("+"..(#self.backpacks - self.backpackChoice).."", (self.maxButtons - 1) * self.buttonSize + self.buttonSize / 2,self.buttonSize * 1.5 / 3+2, 0.0, 0.0, 0.0, 1.0, UIFont.Medium);
		self:drawText("+"..(#self.backpacks - self.backpackChoice).."", (self.maxButtons - 1) * self.buttonSize + self.buttonSize / 2,self.buttonSize * 1.5 / 3-2, 0.0, 0.0, 0.0, 1.0, UIFont.Medium);
		self:drawText("+"..(#self.backpacks - self.backpackChoice).."", (self.maxButtons - 1) * self.buttonSize + self.buttonSize / 2,self.buttonSize * 1.5 / 3, 1.0, 1.0, 1.0, 1.0, UIFont.Medium);
	end
	
	--self:setMaxDrawHeight(300)
end

function ISInventoryPage:dropItemsInContainer(button)
	if self.player ~= 0 then return false end
	if ISMouseDrag.dragging == nil then return false end
	local playerObj = getSpecificPlayer(self.player)
	if (getCore():getGameMode() ~= "Tutorial") and self:canPutIn() then
		local doWalk = true
		local items = {}
		local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
		for i,v in ipairs(dragging) do
			local transfer = v:getContainer() and not button.inventory:isInside(v)
			if v:isFavorite() and not button.inventory:isInCharacterInventory(playerObj) then
				transfer = false
			end
			if not button.inventory:isItemAllowed(v) then
				transfer = false
			end
			if transfer then
--				only walk for the first item
				if doWalk then
					if not luautils.walkToContainer(button.inventory, self.player) then
						break
					end
					doWalk = false
				end
				table.insert(items, v)
			end
		end
		self.inventoryPane:transferItemsByWeight(items, button.inventory)
		self.inventoryPane.selected = {};
		getPlayerLoot(self.player).inventoryPane.selected = {};
		getPlayerInventory(self.player).inventoryPane.selected = {};
	end
	if ISMouseDrag.draggingFocus then
		ISMouseDrag.draggingFocus:onMouseUp(0,0);
		ISMouseDrag.draggingFocus = nil;
		ISMouseDrag.dragging = nil;
	end
	self:refreshWeight();
	return true
end

function ISInventoryPage:selectContainer(button)
	local playerObj = getSpecificPlayer(self.player)

	if button.inventory ~= self.inventoryPane.lastinventory then
		local object = button.inventory and button.inventory:getParent() or nil
		if instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
			return
		end
		if button.inventory:getOpenSound() then
			if ISInventoryPage.bagSoundTime + ISInventoryPage.bagSoundDelay < getTimestamp() then
				local eventInstance = getSpecificPlayer(self.player):playSound(button.inventory:getOpenSound())
				if eventInstance ~= 0 then
					ISInventoryPage.bagSoundTime = getTimestamp()
				end
			end
		end

		if not button.inventory:getOpenSound() and self.inventoryPane.lastinventory:getCloseSound() then
			if ISInventoryPage.bagSoundTime + ISInventoryPage.bagSoundDelay < getTimestamp() then
				ISInventoryPage.bagSoundTime = getTimestamp()
				local eventInstance = getSpecificPlayer(self.player):playSound(self.inventoryPane.lastinventory:getCloseSound())
				if eventInstance ~= 0 then
					ISInventoryPage.bagSoundTime = getTimestamp()
				end
			end
		end
	end

	self.inventoryPane.lastinventory = button.inventory;
	self.inventoryPane.inventory = button.inventory;
	self.inventoryPane.selected = {}
	if not button.inventory:isExplored() then
		if not isClient() then
			ItemPicker.fillContainer(button.inventory, playerObj);
		else
			button.inventory:requestServerItemsForContainer();
		end
		button.inventory:setExplored(true);
	end


	self.title = button.name;
	self.capacity = button.capacity;
	self:refreshBackpacks();
	self.nRow = 1
	self.inventoryPane.joyselection = 1
end

function ISInventoryPage:setNewContainer(inventory)
	self.inventoryPane.inventory = inventory;
	self.inventory = inventory;
	self.inventoryPane:refreshContainer();

	local playerObj = getSpecificPlayer(self.player)
	self.capacity = inventory:getEffectiveCapacity(playerObj);

	for i,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == inventory then
--			containerButton:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0)
			self.title = containerButton.name;
		else
--			containerButton:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0)
		end
	end

	self:syncToggleStove()
end

function ISInventoryPage:selectButtonForContainer(container)
	if self.inventoryPane.inventory == container then
		return
	end
	for index,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == container then
			local playerObj = getSpecificPlayer(self.player)
			local object = container and container:getParent() or nil
			if instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
				return
			end
			if playerObj and playerObj:getJoypadBind() ~= -1 then
				self.backpackChoice = index
			end

			self:selectContainer(containerButton)
			return
		end
	end
end

function ISInventoryPage.loadWeight(inv)
	if inv == nil then return 0; end;

	return inv:getCapacityWeight();
end

function ISInventoryPage:onMouseMove(dx, dy)
	self.mouseOver = true;

	if self.moving then
		self:setX(self.x + dx);
		self:setY(self.y + dy);
	end

	if self:getMouseY() < self.buttonSize * 1.5 + BUTTON_HGT
	and self:getMouseY() > self.buttonSize * 1.5
	and self:getMouseX() < self.width - 12
	and self:getMouseX() > self.width - self.transferOrLootAll.width / 2 then
		self.transferOrLootAll:setVisible(true)
		
		if self.onCharacter then
			self.transferOrLootAll:setTitle(getText("IGUI_invpage_Transfer_all").."  >> ")
			self.transferOrLootAll.mode = "transfer"
		else
			self.transferOrLootAll:setTitle(" <<  "..getText("IGUI_invpage_Loot_all"))
			self.transferOrLootAll.mode = "loot"
		end
	else
		self.transferOrLootAll:setVisible(false)
	end

	if not isGamePaused() then
		if self.isCollapsed and self.player and getSpecificPlayer(self.player) and getSpecificPlayer(self.player):isAiming() then
			return
		end
	end

	if self.isCollapsed and isKeyDown("PanCamera") then
		return
	end

	if not isMouseButtonDown(0) and not isMouseButtonDown(1) and not isMouseButtonDown(2) then

		self.collapseCounter = 0;
		if self.isCollapsed and self:getMouseY() < self:titleBarHeight() then
		   self.isCollapsed = false;
		   	if isClient() and not self.onCharacter then
				self.inventoryPane.inventory:requestSync();
			end
		   self:clearMaxDrawHeight();
		   self.collapseCounter = 0;
		end
	end
end

function ISInventoryPage:onMouseMoveOutside(dx, dy)
	self.mouseOver = false;

	if self.moving then
		self:setX(self.x + dx);
		self:setY(self.y + dy);
	end

	if ISMouseDrag.dragging ~= true and not self.pin and (self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) then
		self.collapseCounter = self.collapseCounter + getGameTime():getMultiplier() / 0.8;
		local bDo = false;
		if ISMouseDrag.dragging == nil then
			bDo = true;
		else
			for i, k in ipairs(ISMouseDrag.dragging) do
			   bDo = true;
			   break;
			end
		end
		local playerObj = getSpecificPlayer(self.player)
		if playerObj and playerObj:isAiming() then
			self.collapseCounter = 1000
		end
		if ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
			bDo = false;
		end
		if self.collapseCounter > 120 and not self.isCollapsed and bDo then

			self.isCollapsed = false;
			--self:setMaxDrawHeight(300);

		end
	end
end

function ISInventoryPage:onMouseUp(x, y)
	if not self:getIsVisible() then
		return;
	end
	self.moving = false;
	self:setCapture(false);
end

function ISInventoryPage:onMouseDown(x, y)

	if not self:getIsVisible() then
		return;
	end

	getSpecificPlayer(self.player):nullifyAiming();

	self.downX = self:getMouseX();
	self.downY = self:getMouseY();
	self.moving = true;
	self:setCapture(true);
end

function ISInventoryPage:onRightMouseDownOutside(x, y)
    if((self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) and  not self.pin) then
        self.isCollapsed = true;
        self:setMaxDrawHeight(self:titleBarHeight());
    end
end
function ISInventoryPage:onMouseDownOutside(x, y)
    if((self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) and  not self.pin) then
        self.isCollapsed = true;
        self:setMaxDrawHeight(self:titleBarHeight());
    end
end

function ISInventoryPage:onMouseUpOutside(x, y)
	if not self:getIsVisible() then
		return;
	end

	self.moving = false;
	self:setCapture(false);
end

function ISInventoryPage:isCycleContainerKeyDown()
	local keyName = getCore():getOptionCycleContainerKey()
	if keyName == "control" then
		return isCtrlKeyDown()
	end
	if keyName == "shift" then
		return isShiftKeyDown()
	end
	if keyName == "control+shift" then
		return isCtrlKeyDown() and isShiftKeyDown()
	end
	error "unknown cycle container key"
end

function ISInventoryPage:onMouseWheel(del)

	local currentIndex = self:getCurrentBackpackIndex()
	local unlockedIndex = -1
	if del < 0 then
		unlockedIndex = self:prevUnlockedContainer(currentIndex, true)
	else
		unlockedIndex = self:nextUnlockedContainer(currentIndex, true)
	end
	if unlockedIndex ~= -1 then
		local playerObj = getSpecificPlayer(self.player)
		self.backpackChoice = unlockedIndex
		self:selectContainer(self.backpacks[unlockedIndex])
	end
	return true
end

ISInventoryPage.dirtyUI = function ()
	for i=0, getNumActivePlayers() -1 do
		local pdata = getPlayerData(i)
		if pdata and pdata.playerInventory then
			pdata.playerInventory:refreshBackpacks()
			pdata.lootInventory:refreshBackpacks()
		end
	end
end

function ISInventoryPage:onBackpackMouseDown(button, x, y)
	ISMouseDrag = {}
	if not isKeyDown("Melee") then
		getSpecificPlayer(self.player):nullifyAiming();
	end
end

function ISInventoryPage:onBackpackClick(button)
	local playerObj = getSpecificPlayer(self.player)

	self:selectContainer(button)
	
	for i,button2 in ipairs(self.backpacks) do
		if button2 == button then
			self.backpackChoice = i
			break
		end
	end
end

function ISInventoryPage:onBackpackMouseUp(x, y)
	if not self.pressed and not ISMouseDrag.dragging then return end
	ISButton.onMouseUp(self, x, y)
	local page = self.parent
	if page:dropItemsInContainer(self) then return end
	page:onBackpackClick(self)
end

function ISInventoryPage:onBackpackRightMouseDown(x, y)
	local page = self.parent
	local container = self.inventory
	local item = container:getContainingItem()
	local context = ISContextMenu.get(page.player, getMouseX(), getMouseY())
	if item then
		context = ISInventoryPaneContextMenu.createMenu(page.player, page.onCharacter, {item}, getMouseX(), getMouseY())
		if context and context.numOptions > 1 and JoypadState.players[page.player+1] then
			context.origin = page
			context.mouseOver = 1
			setJoypadFocus(page.player, context)
		end
		return
	end
	if ISLootZed.cheat or isAdmin() then
		local playerObj = getSpecificPlayer(page.player)
		if not instanceof(container:getParent(), "BaseVehicle") and not (container:getType() == "inventorymale" or container:getType() == "inventoryfemale") then
			context:addOption("Refill container", container, function(container, playerObj)
				if container:getSourceGrid() then
					if isClient() then
						local items = container:getItems()
						local tItems = {}
						for i = items:size()-1, 0, -1 do
							table.insert(tItems, items:get(i))
						end

						for i, v in ipairs(tItems) do
							ISRemoveItemTool.removeItem(v, playerObj)
						end

						local sq = container:getSourceGrid()
						local cIndex = -1
						for i = 0, container:getParent():getContainerCount()-1 do
							if container:getParent():getContainerByIndex(i) == container then
								cIndex = i
							end
						end
						local args = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), index = container:getParent():getObjectIndex(), containerIndex = cIndex }
						sendClientCommand(playerObj, 'object', 'clearContainerExplore', args)
						container:removeItemsFromProcessItems()
						container:clear()
						container:requestServerItemsForContainer()
						container:setExplored(true)
						sendClientCommand(playerObj, 'object', 'updateOverlaySprite', args)
					else
						if container:getSourceGrid():getRoom() and container:getSourceGrid():getRoom():getRoomDef() and container:getSourceGrid():getRoom():getRoomDef():getProceduralSpawnedContainer() then
							container:getSourceGrid():getRoom():getRoomDef():getProceduralSpawnedContainer():clear()
						end
						container:removeItemsFromProcessItems()
						container:clear()
						ItemPicker.fillContainer(container, playerObj)
						if container:getParent() then
							ItemPicker.updateOverlaySprite(container:getParent())
						end
						container:setExplored(true)
					end
				end
			end, playerObj)
		end
		if ISLootZed.cheat then
			context:addOption("Open LootZed", container, function(container, playerObj)
				LootZedTool.SpawnItemCheckerList = {}
				LootZedTool.fillContainer_CalcChances(container, playerObj)

				if ISLootZed.instance ~= nil then
					ISLootZed.instance:updateContent()
					ISLootZed.instance:setVisible(true);
				else
					local ui = ISLootZed:new(750, 800, playerObj);
					ui:initialise();
					ui:addToUIManager();
					ISLootZed.instance:updateContent()
				end
			end, playerObj)
		end
		return
	end
	if context:isReallyVisible() then
		if context and JoypadState.players[page.player+1] then
			context.origin = page
		end
		context:closeAll()
	end
end

local sqsContainers = {}
local sqsVehicles = {}

function ISInventoryPage:addContainerButton(container, texture, name, tooltip)

	local titleBarHeight = self:titleBarHeight()
	local playerObj = getSpecificPlayer(self.player)
	local c = #self.backpacks + 1
	local x = (c - 1) * self.buttonSize
	local y = 0
	local button
	local addY = 1
	local addX = 1
	local addSize = 1

	if #self.buttonPool > 0 then
		button = table.remove(self.buttonPool, 1)
		button:setX(x)
		button:setY(y)
	else
		button = ISButton:new(x, y, self.buttonSize, self.buttonSize, "", self, ISInventoryPage.onBackpackClick, ISInventoryPage.onBackpackMouseDown, false)
		button.anchorLeft = true
		button.anchorTop = false
		button.anchorRight = false
		button.anchorBottom = false
		button:initialise()
		button:forceImageSize(math.min(self.buttonSize - 2, 32), math.min(self.buttonSize - 2, 32))
	end

	button:setBackgroundRGBA(0.36, 0.33, 0.28, 0.8)
	button:setBackgroundColorMouseOverRGBA(0.0, 0.0, 0.0, 0.3)
	button:setBorderRGBA(0.0, 0.0, 0.0, 0.0)
	button:setTextureRGBA(1.0, 1.0, 1.0, 1.0)
	button.textureOverride = nil
	button.inventory = container
	button.onclick = ISInventoryPage.onBackpackClick
	button.onmousedown = ISInventoryPage.onBackpackMouseDown
	button.onMouseUp = ISInventoryPage.onBackpackMouseUp
	button.onRightMouseDown = ISInventoryPage.onBackpackRightMouseDown
	button:setOnMouseOverFunction(ISInventoryPage.onMouseOverButton)
	button:setOnMouseOutFunction(ISInventoryPage.onMouseOutButton)
	button:setSound("activate", nil)
	button.capacity = container:getEffectiveCapacity(playerObj)
	if instanceof(texture, "Texture") then
		button:setImage(texture)
	else
		if ContainerButtonIcons[container:getType()] ~= nil then
			button:setImage(ContainerButtonIcons[container:getType()])
		else
			button:setImage(self.conDefault)
		end
	end
	
	--[[self.maxButtons = math.floor((self.width - self.buttonSize * 1.5) / self.buttonSize)
	if self.backpacks[self.backpackChoice] ~= nil then
		if self.backpacks[self.backpackChoice].inventory ~= self.inventoryPane.inventory then
			for k, v in pairs(self.backpacks) do
				if k.inventory == self.inventoryPane.inventory then
					self.backpackChoice = k
				end
			end
			print(self.backpacks[self.backpackChoice].inventory)
		else
			print("equal")
		end
	end]]--

	if c <= self.maxButtons then
		button:setVisible(true)
		if c == self.backpackChoice then
			button:setWidth(self.buttonSize * 1.5)
			button:setHeight(self.buttonSize * 1.5)
			button:forceImageSize(48, 48)
			button.textureBackground = self.buttonTexture
			button:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0)
		elseif c > self.backpackChoice then
			button:setWidth(self.buttonSize)
			button:setHeight(self.buttonSize)
			button:forceImageSize(32, 32)
			button:setX(x + self.buttonSize/2)
			button:setY(y + self.buttonSize/2)
			button.textureBackground = nil
		else
			button:setWidth(self.buttonSize)
			button:setHeight(self.buttonSize)
			button:forceImageSize(32, 32)
			button:setY(y + self.buttonSize/2)
			button.textureBackground = nil
		end
		if c == self.maxButtons then self.measurements.lastButton = c end
	else
		if c ~= self.backpackChoice then
			button:setVisible(false)
		else
			button:setVisible(true)
			button:setWidth(self.buttonSize * 1.5)
			button:setHeight(self.buttonSize * 1.5)
			button:setX((self.measurements.lastButton - 1) * self.buttonSize)
			button:forceImageSize(48, 48)
		end
	end

	button.name = name
	button.tooltip = tooltip
	self:addChild(button)
	self.backpacks[c] = button
	return button

end

function ISInventoryPage:checkExplored(container, playerObj)
	if container:isExplored() then
		return
	end
	if isClient() then
		container:requestServerItemsForContainer()
	else
		ItemPicker.fillContainer(container, playerObj)
	end
	container:setExplored(true)
	if playerObj and playerObj:isLocalPlayer() then
		playerObj:triggerMusicIntensityEvent("SearchNewContainer")
	end
end

function ISInventoryPage.GetFloorContainer(playerNum)
	if ISInventoryPage.floorContainer == nil then
		ISInventoryPage.floorContainer = {}
	end
	if ISInventoryPage.floorContainer[playerNum+1] == nil then
		ISInventoryPage.floorContainer[playerNum+1] = ItemContainer.new("floor", nil, nil)
		ISInventoryPage.floorContainer[playerNum+1]:setExplored(true)
	end
	return ISInventoryPage.floorContainer[playerNum+1]
end

function ISInventoryPage:refreshBackpacks()
--[[
	self.maxButtons = math.floor((self.width - self.buttonSize * 1.5) / self.buttonSize)
	if self.backpacks[self.backpackChoice] ~= nil then
		if self.backpacks[self.backpackChoice].inventory ~= self.inventoryPane.inventory then
			for k, v in pairs(self.backpacks) do
				if k.inventory == self.inventoryPane.inventory then
					self.backpackChoice = k
				end
			end
			print(self.backpacks[self.backpackChoice].inventory)
		else
			print("equal")
		end
	end]]--
	
	self.maxButtons = math.floor((self.width - self.buttonSize * 1.5) / self.buttonSize)


	ISHandCraftPanel.drawDirty = true;
	self.buttonPool = self.buttonPool or {}
	for i,v in ipairs(self.backpacks) do
		self:removeChild(v)
		table.insert(self.buttonPool, i, v)
	end

	local floorContainer = ISInventoryPage.GetFloorContainer(self.player)

	self.inventoryPane.lastinventory = self.inventoryPane.inventory

	local oldNumBackpacks = #self.backpacks
	table.wipe(self.backpacks)
	
	local containerButton = nil

	local playerObj = getSpecificPlayer(self.player)
	triggerEvent("OnRefreshInventoryWindowContainers", self, "begin")
	
	if self.onCharacter then
		local name = getText("IGUI_InventoryTooltip")
		containerButton = self:addContainerButton(playerObj:getInventory(), self.inventoryIcon, name, nil)
		containerButton.capacity = self.inventory:getMaxWeight()
		if not self.capacity then
			self.capacity = containerButton.capacity
		end
		local it = playerObj:getInventory():getItems()
		for i = 0, it:size()-1 do
			local item = it:get(i)
			if item:getCategory() == "Container" and playerObj:isEquipped(item) or item:getType() == "KeyRing"  or item:hasTag( "KeyRing") then
--				found a container, so create a button for it...
				containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
				if(item:getVisual() and item:getClothingItem()) then
					local tint = item:getVisual():getTint(item:getClothingItem());
					containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0);
				end
			end
		end
	elseif playerObj:getVehicle() then
		local vehicle = playerObj:getVehicle()
		for partIndex=1,vehicle:getPartCount() do
			local vehiclePart = vehicle:getPartByIndex(partIndex-1)
			if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, playerObj) and vehiclePart:getId() ~= "TruckBed" then
				local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
--				changed to include tooltips outside of the player inventory because some people want it
				containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, tooltip)
				self:checkExplored(containerButton.inventory, playerObj)
--				check for bags in seats/trunks
				if vehiclePart:getId() and vehiclePart:getId() ~= "GloveBox" then
					local it = vehiclePart:getItemContainer():getItems()
					for i = 0, it:size()-1 do
						local item = it:get(i)
						if item:getCategory() == "Container"  then
--							found a container, so create a button for it...
							containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
							if(item:getVisual() and item:getClothingItem()) then
								local tint = item:getVisual():getTint(item:getClothingItem());
								containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0);
							end
						end
					end
				end
			end
		end
		for partIndex=1,vehicle:getPartCount() do
			local vehiclePart = vehicle:getPartByIndex(partIndex-1)
			if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, playerObj) and vehiclePart:getId() == "TruckBed" then
				local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
--				changed to include tooltips outside of the player inventory because it matters to some people
				containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, tooltip)
-- 				containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, nil)
				self:checkExplored(containerButton.inventory, playerObj)
--				check for bags in seats/trunks
				if vehiclePart:getId() and vehiclePart:getId() ~= "GloveBox" then
					local it = vehiclePart:getItemContainer():getItems()
					for i = 0, it:size()-1 do
						local item = it:get(i)
						if item:getCategory() == "Container"  then
--							found a container, so create a button for it...
							containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
							if(item:getVisual() and item:getClothingItem()) then
								local tint = item:getVisual():getTint(item:getClothingItem());
								containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0);
							end
						end
					end
				end
			end
		end
	else
		local cx = playerObj:getX()
		local cy = playerObj:getY()
		local cz = playerObj:getZ()

--		Do floor
		local container = floorContainer
		container:removeItemsFromProcessItems()
		container:clear()

		local sqs = sqsContainers
		table.wipe(sqs)

		local dir = playerObj:getDir()
		local lookSquare = nil
		if self.lookDir ~= dir then
			self.lookDir = dir
			local dx,dy = 0,0
			if dir == IsoDirections.NW or dir == IsoDirections.W or dir == IsoDirections.SW then
				dx = -1
			end
			if dir == IsoDirections.NE or dir == IsoDirections.E or dir == IsoDirections.SE then
				dx = 1
			end
			if dir == IsoDirections.NW or dir == IsoDirections.N or dir == IsoDirections.NE then
				dy = -1
			end
			if dir == IsoDirections.SW or dir == IsoDirections.S or dir == IsoDirections.SE then
				dy = 1
			end
			lookSquare = getCell():getGridSquare(cx + dx, cy + dy, cz)
		end

		local vehicleContainers = sqsVehicles
		table.wipe(vehicleContainers)

		for dy=-1,1 do
			for dx=-1,1 do
				local square = getCell():getGridSquare(cx + dx, cy + dy, cz)
				if square then
					table.insert(sqs, square)
				end
			end
		end

		for _,gs in ipairs(sqs) do
--			stop grabbing thru walls...
			local currentSq = playerObj:getCurrentSquare()
--			if gs ~= currentSq and currentSq and currentSq:isBlockedTo(gs) then
			if gs ~= currentSq and currentSq and not currentSq:canReachTo(gs) then
				gs = nil
			end

--			don't show containers in safehouse if you're not allowed
			if gs then
				if isClient() and not SafeHouse.isSafehouseAllowLoot(gs, playerObj) then
					gs = nil
				end
			end

			if gs ~= nil then
				local numButtons = #self.backpacks

				local wobs = gs:getWorldObjects()
				for i = 0, wobs:size()-1 do
					local o = wobs:get(i)
--					FIXME: An item can be in only one container in coop the item won't be displayed for every player.
					floorContainer:AddItem(o:getItem())
					if o:getItem() and o:getItem():getCategory() == "Container" then
						local item = o:getItem()
--						changed to include tooltips outside of the player inventory because some people want it
						containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
-- 						containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), nil)
						if item:getVisual() and item:getClothingItem() then
							local tint = item:getVisual():getTint(item:getClothingItem());
							containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0);
						end
					end
				end

				local sobs = gs:getStaticMovingObjects()
				for i = 0, sobs:size()-1 do
					local so = sobs:get(i)
					if so:getContainer() ~= nil then
--						added console spam when there's a missing container name translation string
						if getTextOrNull("IGUI_ContainerTitle_" .. so:getContainer():getType()) == nil and isDebugEnabled() then
							print("Missing IGUI_ContainerTitle_ tranlastion string for " .. tostring(so:getContainer():getType()))
						end

--						changed to just show the container type if there's no translation string to make it easier to add the needed string
						local title = getTextOrNull("IGUI_ContainerTitle_" .. so:getContainer():getType()) or "!Needs IGUI_ContainerTitle defined for: " .. so:getContainer():getType()
-- 						local title = getTextOrNull("IGUI_ContainerTitle_" .. so:getContainer():getType()) or ""
--						changed to include tooltips outside of the player inventory because some people want it
						if instanceof(so, "IsoDeadBody") and so:isAnimal() then
							break;
						end
						containerButton = self:addContainerButton(so:getContainer(), nil, title, title)
-- 						containerButton = self:addContainerButton(so:getContainer(), nil, title, nil)
						self:checkExplored(containerButton.inventory, playerObj)
					end
				end

				local obs = gs:getObjects()
				for i = 0, obs:size()-1 do
					local o = obs:get(i)
					for containerIndex = 1,o:getContainerCount() do
						local container = o:getContainerByIndex(containerIndex-1)
--						added console spam when a container type doesn't have a translation string defined
						if getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) == nil and isDebugEnabled() then
							print("Missing IGUI_ContainerTitle_ translation string for " .. tostring(container:getType()))
						end
--						changed to just show the container type if there's no translation string to make it easier to add the needed string
						local title = getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) or "!Needs IGUI_ContainerTitle defined for: " .. container:getType()
-- 						local title = getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) or ""
--						changed to include tooltips outside of the player inventory because some people want it
						containerButton = self:addContainerButton(container, nil, title, title)
-- 						containerButton = self:addContainerButton(container, nil, title, nil)
						if instanceof(o, "IsoThumpable") and o:isLockedToCharacter(playerObj) then
							containerButton.onclick = nil
							containerButton.onmousedown = nil
							containerButton:setOnMouseOverFunction(nil)
							containerButton:setOnMouseOutFunction(nil)
							containerButton.textureOverride = getTexture("media/ui/lock.png")
						end

						if instanceof(o, "IsoThumpable") and o:isLockedByPadlock() and playerObj:getInventory():haveThisKeyId(o:getKeyId()) then
							containerButton.textureOverride = getTexture("media/ui/lockOpen.png")
						end

						self:checkExplored(containerButton.inventory, playerObj)
					end
				end

				local vehicle = gs:getVehicleContainer()
				if vehicle and not vehicleContainers[vehicle] then
					vehicleContainers[vehicle] = true
					for partIndex=1,vehicle:getPartCount() do
						local vehiclePart = vehicle:getPartByIndex(partIndex-1)
						if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, playerObj) then
							local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
--							changed to include tooltips outside of the player inventory because some people want it
							containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, tooltip)
-- 							containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, nil)
							self:checkExplored(containerButton.inventory, playerObj)
--							check for bags in seats/trunks
							if vehiclePart:getId() and vehiclePart:getId() ~= "GloveBox" then
								local it = vehiclePart:getItemContainer():getItems()
								for i = 0, it:size()-1 do
									local item = it:get(i)
									if item:getCategory() == "Container"  then
--										found a container, so create a button for it...
										containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
										if(item:getVisual() and item:getClothingItem()) then
											local tint = item:getVisual():getTint(item:getClothingItem());
											containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0);
										end
									end
								end
							end
						end
					end
				end

				if (numButtons < #self.backpacks) and (gs == lookSquare) then
					self.inventoryPane.inventory = self.backpacks[numButtons + 1].inventory
				end
			end
		end

		triggerEvent("OnRefreshInventoryWindowContainers", self, "beforeFloor")
	
		local title = getTextOrNull("IGUI_ContainerTitle_floor") or ""
		
		if playerObj and playerObj:getSquare():isInARoom() == true then
			containerButton = self:addContainerButton(floorContainer, self.floorIndoors, title, nil)
		else
			containerButton = self:addContainerButton(floorContainer, self.floorOutdoors, title, nil)
		end
		containerButton.capacity = floorContainer:getMaxWeight()
	end

	triggerEvent("OnRefreshInventoryWindowContainers", self, "buttonsAdded")

	local found = false
	local foundIndex = -1
	for index,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == self.inventoryPane.inventory then
			foundIndex = index
			found = true
			break
			
		end
	end

	self.inventoryPane.inventory = self.inventoryPane.lastinventory
	self.inventory = self.inventoryPane.inventory
	if self.backpackChoice ~= nil and playerObj:getJoypadBind() ~= -1 then
		if not self.onCharacter and oldNumBackpacks == 1 and #self.backpacks > 1 then
			self.backpackChoice = 1
		end
		if self.backpacks[self.backpackChoice] ~= nil then
			self.inventoryPane.inventory = self.backpacks[self.backpackChoice].inventory
			self.capacity = self.backpacks[self.backpackChoice].capacity
		end
	else
		if not self.onCharacter and oldNumBackpacks == 1 and #self.backpacks > 1 then
			self.inventoryPane.inventory = self.backpacks[1].inventory
			self.capacity = self.backpacks[1].capacity
		elseif found then
			self.inventoryPane.inventory = self.backpacks[foundIndex].inventory
			self.capacity = self.backpacks[foundIndex].capacity
			self.backpackChoice = foundIndex
		elseif not found and #self.backpacks > 0 then
			if self.backpacks[1] and self.backpacks[1].inventory then
				self.inventoryPane.inventory = self.backpacks[1].inventory
				self.capacity = self.backpacks[1].capacity
			end
		elseif self.inventoryPane.lastinventory ~= nil then
			self.inventoryPane.inventory = self.inventoryPane.lastinventory
		end
	end
	print(self.backpackChoice)

	-- ISInventoryTransferAction sometimes turns the player to face a container.
	-- Which container is selected changes as the player changes direction.
	-- Although ISInventoryTransferAction forces a container to be selected,
	-- sometimes the action completes before the player finishes turning.
	if self.forceSelectedContainer then
		if self.forceSelectedContainerTime > getTimestampMs() then
			for _,containerButton in ipairs(self.backpacks) do
				if containerButton.inventory == self.forceSelectedContainer then
					self.inventoryPane.inventory = containerButton.inventory
					self.capacity = containerButton.capacity
					break
				end
			end
		else
			self.forceSelectedContainer = nil
		end
	end
	
	
	self.inventoryPane:bringToTop()
	self.resizeWidget:bringToTop()
	self.inventory = self.inventoryPane.inventory

	self.title = nil
	local size = self.buttonSize
	for k,containerButton in ipairs(self.backpacks) do
--		background color of the selected contaner and title
		containerButton:setWidth(self.buttonSize)
		containerButton:setHeight(self.buttonSize)
		containerButton:forceImageSize(32, 32)
		containerButton:setY(self.buttonSize/2)
		if containerButton.inventory == self.inventory then
			containerButton:setWidth(self.buttonSize * 1.5)
			containerButton:setHeight(self.buttonSize * 1.5)
			containerButton:forceImageSize(48, 48)
			containerButton.textureBackground = self.buttonTexture
			containerButton:setY(0)
			
			containerButton:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0)
			self.selectedButton = containerButton;
--			containerButton:setBackgroundRGBA(0.0, 0.0, 0.0, 0.9)
			self.title = containerButton.name
			if k < self.maxButtons then
				containerButton:setX((k - 1) * size)
			else
				containerButton:setX((self.maxButtons - 1) * size)
			end
		else
			if k < self.backpackChoice then
				containerButton:setX((k - 1) * size)
			else
				containerButton:setX((k - 1) * size + size/2)
			end
			containerButton:setBackgroundRGBA(0.36, 0.33, 0.28, 0.8)
			containerButton.textureBackground = nil
			if k > self.maxButtons then
				containerButton:setVisible(false)
			end
		end
	end

	if self.inventoryPane ~= nil then
		self.inventoryPane:refreshContainer()
	end
	
	self:refreshWeight()

	self:syncToggleStove()

	triggerEvent("OnRefreshInventoryWindowContainers", self, "end")
end

function ISInventoryPage:autoResize()

	local headerHeight = self.buttonSize * 1.5 + BUTTON_HGT

	if self.inventoryPane.grid.yCell[1] == 1 and self.inventoryPane.grid.yCell[#self.inventoryPane.grid.yCell] > 1 then
		local yCell = self.inventoryPane.grid.yCell
		local itemsList = self.inventoryPane.itemslist
		local firstColumnItems = self.inventoryPane.grid.firstItem
		local gridHeight = yCell[#yCell] * self.inventoryPane.itemHgt
		if self.firstLaunch == true then
			if itemsList and self.inventoryPane.countCollapsed == 0 then
-- 		compare categories
				for i, v in ipairs(firstColumnItems) do
					if #itemsList[v].cat > self.measurements.categoryLength then self.measurements.categoryLength = #itemsList[v].cat end
				end
				local categoryOffset = getTextManager():MeasureStringX(self.inventoryPane.font, string.rep("C", self.measurements.categoryLength))
				self:setWidth(self.inventoryPane.column2 + categoryOffset)
			end
			self.firstLaunch = false
		end
		
		self:setHeight(headerHeight + gridHeight + 8)
		
		
	else
--		set fixed height
		self:setHeight(headerHeight + self.inventoryPane.itemHgt * 2 + 8)
	end
--		fix for last container
	if self.backpackChoice > #self.backpacks then
		self:selectPrevContainer()
		self:selectNextContainer()
	end

	self.transferOrLootAll:setX(self.width - self.transferOrLootAll.width)
end

function ISInventoryPage:setPinned()
	self.pin = true;
	self.collapseButton:setVisible(true)
	self.pinButton:setVisible(false);
	self.collapseButton:bringToTop();
end

function ISInventoryPage:ensureVisible(index)
end

function ISInventoryPage:setBlinkingContainer(blinking, containerType)
end

function ISInventoryPage:setInfo(text)
end

function ISInventoryPage:refreshWeight()
	return;
end

function ISInventoryPage:lootAll()
    self.inventoryPane:lootAll();
end

function ISInventoryPage:transferAll()
    self.inventoryPane:transferAll();
end

function ISInventoryPage:onChangeFilter(selected)
end

function ISInventoryPage:onInfo()
end

function ISInventoryPage:new (x, y, width, height, inventory, onCharacter, zoom)
	local o = {}
	--o.data = {}
	o = ISPanel:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.x = x;
	o.y = y;
	o.anchorLeft = true;
	o.anchorRight = true;
	o.anchorTop = true;
	o.anchorBottom = true;
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
	o.backgroundColor = {r=0, g=0, b=0, a=0.8};
	o.width = width;
	o.height = height;
	o.anchorLeft = true;
	o.backpackChoice = 1;
	o.zoom = zoom;
	o.isCollapsed = true;
	if o.zoom == nil then o.zoom = 1; end

	o.inventory = inventory;
	o.onCharacter = onCharacter;
	o.titlebarbkg = getTexture("media/ui/Panel_TitleBar.png");
	o.statusbarbkg = getTexture("media/ui/Panel_StatusBar.png");
	o.resizeimage = getTexture("media/ui/ResizeIcon.png");
	o.invbasic = getTexture("media/ui/Icon_InventoryBasic.png");
	o.infoBtn = getTexture("media/ui/inventoryPanes/Button_Info.png");
	o.closebutton = getTexture("media/ui/inventoryPanes/Button_Close.png");
	o.collapsebutton = getTexture("media/ui/inventoryPanes/Button_Collapse.png");
	o.pinbutton = getTexture("media/ui/inventoryPanes/Button_Pin.png");
	
	o.conDefault = getTexture("media/ui/Container_Shelf.png");
	o.highlightColors = {r=0.98,g=0.56,b=0.11};
	o.containerIconMaps = ContainerButtonIcons

	o.pin = true;
	o.isCollapsed = true;
	o.backpacks = {}
	o.collapseCounter = 0;
	o.title = nil;
	o.titleFont = UIFont.Medium
	o.titleFontHgt = getTextManager():getFontHeight(o.titleFont)
	local sizes = { 40, 40, 40 }
	o.buttonSize = 40

	o.visibleTarget = o;
	o.visibleFunction = ISInventoryPage.onToggleVisible;

	
	o.headerTexture = getTexture("media/ui/inventoryPanes/Header_Texture.png");
	o.inventoryIcon = getTexture("media/ui/inventoryPanes/Inventory_Icon.png");
	o.buttonTexture = getTexture("media/ui/inventoryPanes/Button_Texture.png");
	o.floorIndoors = getTexture("media/ui/inventoryPanes/Floor_Indoors.png");
	o.floorOutdoors = getTexture("media/ui/inventoryPanes/Floor_Outdoors.png");
	o.deleteAllButton = getTexture("media/ui/inventoryPanes/Button_DeleteAll.png");
	o.stoveOn = getTexture("media/ui/inventoryPanes/Stove_On.png");
	o.stoveOff = getTexture("media/ui/inventoryPanes/Stove_Off.png");
	o.measurements = {previousY = o.y, categoryLength = 4, lastButton = 0}
	o.nRow = 1;
	o.titleHeight = BUTTON_HGT
	o.firstLaunch = true
	o.maxButtons = 8
	
   return o
end

function ISInventoryPage:onMouseOverButton(button,x,y)
	self.mouseOverButton = button;
end

function ISInventoryPage:onMouseOutButton(button,x,y)
	self.mouseOverButton = nil;
end

function ISInventoryPage:canPutIn()
	local playerObj = getSpecificPlayer(self.player)
	local container = self.mouseOverButton and self.mouseOverButton.inventory or nil
	if not container then
		return false
	end
	local items = {}
	local minWeight = 100000
	local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
	for i,item in ipairs(dragging) do
		local itemOK = true
		if item:isFavorite() and not container:isInCharacterInventory(playerObj) then
			itemOK = false
		end
		if container:isInside(item) then
			itemOK = false
		end
		if container:getType() == "floor" and item:getWorldItem() then
			itemOK = false
		end
		if item:getContainer() == container then
			itemOK = false
		end
		if not container:isItemAllowed(item) then
			itemOK = false
		end
		if itemOK then
			table.insert(items, item)
		end
		if item:getUnequippedWeight() < minWeight then
			minWeight = item:getUnequippedWeight()
		end
	end
	if #items == 1 then
		return container:hasRoomFor(playerObj, items[1])
	elseif #items > 0 then
		return container:hasRoomFor(playerObj, minWeight)
	end
	return false
end

function ISInventoryPage:RestoreLayout(name, layout)
	ISLayoutManager.DefaultRestoreWindow(self, layout)
	if layout.pin == 'true' then
		self:setPinned()
	end
end

function ISInventoryPage:SaveLayout(name, layout)
	ISLayoutManager.DefaultSaveWindow(self, layout)
	if self.pin then layout.pin = 'true' else layout.pin = 'false' end
end

ISInventoryPage.onKeyPressed = function(key)
	if getCore():isKey("Toggle Inventory", key) and getSpecificPlayer(0) and getGameSpeed() > 0 and getPlayerInventory(0) and getCore():getGameMode() ~= "Tutorial" then
		getPlayerInventory(0):setVisible(not getPlayerInventory(0):getIsVisible());
		getPlayerLoot(0):setVisible(getPlayerInventory(0):getIsVisible());
	end
end

ISInventoryPage.toggleInventory = function()
	if ISInventoryPage.playerInventory:getIsVisible() then
		ISInventoryPage.playerInventory:setVisible(false);
	else
		ISInventoryPage.playerInventory:setVisible(true);
	end
end

function ISInventoryPage:onInventoryContainerSizeChanged()
	
end

ISInventoryPage.ContainerSizeChanged = function()
	for i=1,getNumActivePlayers() do
		local pdata = getPlayerData(i-1)
		if pdata then
			pdata.playerInventory:onInventoryContainerSizeChanged()
			pdata.lootInventory:onInventoryContainerSizeChanged()
		end
	end
end

ISInventoryPage.onInventoryFontChanged = function()
	for i=1,getNumActivePlayers() do
		local pdata = getPlayerData(i-1)
		if pdata then
			pdata.playerInventory.inventoryPane:onInventoryFontChanged()
			pdata.lootInventory.inventoryPane:onInventoryFontChanged()
		end
	end
end

-- Called when an object with a container is added/removed from the world.
-- Added this to handle campfire containers.
ISInventoryPage.OnContainerUpdate = function(object)
	ISInventoryPage.renderDirty = true
end

ISInventoryPage.ongamestart = function()
	ISInventoryPage.renderDirty = true;
end

function ISInventoryPage:removeAll()
	self.inventoryPane:removeAll(self.player);
end

function ISInventoryPage:render3DItemPreview()
	if isKeyDown("Rotate building") then
		if not self.render3DItemRot then
			self.render3DItemRot = 0;
		end
		local rot = self.render3DItemRot;
		if isKeyDown(Keyboard.KEY_LSHIFT) then
			rot = rot -10;
		else
			rot = rot + 10;
		end
		if rot < 0 then
			rot = 360;
		end
		if rot > 360 then
			rot = 0;
		end
		self.render3DItemRot = rot;
	end
	local playerObj = getSpecificPlayer(self.player)
	local worldX = screenToIsoX(self.player, getMouseX(), getMouseY(), playerObj:getZ())
	local worldY = screenToIsoY(self.player, getMouseX(), getMouseY(), playerObj:getZ())
	local sq = getSquare(worldX, worldY, playerObj:getZ());
	if not sq then
		return;
	end
	self.render3DItemXOffset = worldX - sq:getX();
	self.render3DItemYOffset = worldY - sq:getY();
	self.render3DItemZOffset = 0;
--	check if we have a surface, so we can do a z offset to make items goes on this surface
	for i=0,sq:getObjects():size()-1 do
		local object = sq:getObjects():get(i);
		if object:getProperties():getSurface() and object:getProperties():getSurface() > 0 then
--			the surface is in pixel, set for the 1X texture, so we *2 (192 pixels is 1X texture height)
			self.render3DItemZOffset = (object:getProperties():getSurface() / 192) * 2;
			break;
		end
	end
	self.selectedSqDrop = sq;
	if self.render3DItems then
		for i,v in ipairs(self.render3DItems) do
			Render3DItem(v, sq, worldX, worldY, self.render3DItemZOffset, self.render3DItemRot);
		end
	end
--	print("gonna try to render ", self.render3DItem, worldX, playerObj:getX())
--	Render3DItem(self.render3DItem, sq, worldX, worldY, self.render3DItemZOffset, self.render3DItemRot);
end

Events.OnKeyPressed.Add(ISInventoryPage.onKeyPressed);
Events.OnContainerUpdate.Add(ISInventoryPage.OnContainerUpdate)

--Events.OnCreateUI.Add(testInventory);

Events.OnGameStart.Add(ISInventoryPage.ongamestart);
