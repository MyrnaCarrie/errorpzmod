-- LEMMY/ROBERT JOHNSON *thank you*

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISMouseDrag"
require "ISUI/ISInventoryItem"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISEatFoodAction"

ISInventoryPane = ISPanel:derive("ISInventoryPane");

ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER = 30
ISInventoryPane.ghc = getCore():getGoodHighlitedColor()

function ISInventoryPane:initialise()
	ISPanel.initialise(self);
end

function ISInventoryPane:createChildren()
	self.headerHgt = 0

	self.nameHeader = ISResizableButton:new(self.column2, 0, (self.column3 - self.column2), 0, " ", self, ISInventoryPane.SaveLayout)
	self.nameHeader:initialise()
	self.nameHeader:setVisible(false)
	self:addChild(self.nameHeader)

	self.typeHeader = ISResizableButton:new(self.column3-1, 0, self.column4 - self.column3 + 1, 0, " ", self, ISInventoryPane.SaveLayout)
	self.typeHeader:initialise();
	self.typeHeader:setVisible(false)
	self:addChild(self.typeHeader);
end

ISInventoryPane.itemSortByCatInc = function(a,b)
	if a.equipped and not b.equipped then return false end
	if b.equipped and not a.equipped then return true end
	return (a.cat < b.cat)
end

function ISInventoryPane:selectIndex(index)
	local listItem = self.items[index]
	if not listItem then return end
	self.selected[index] = listItem
	if not instanceof(listItem, "InventoryItem") and not self.collapsed[listItem.name] then
		for i=2,#listItem.items do
			self.selected[index+i-1] = listItem.items[i]
			if i == ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER + 1 then break end
		end
	else
		local v = self.items[index-1]
		if v ~= nil and not instanceof(v, "InventoryItem") and not self.collapsed[v.name] and #v.items == 2 then
			self.selected[index-1] = v
		end
	end
end

function ISInventoryPane:onMouseMoveOutside(dx, dy)
	local x = self:getMouseX();
	local y = self:getMouseY();
	self.buttonOption = 0;
	self.mouseOverOption = 0

	if(self.draggingMarquis) then

		local x2 = self.draggingMarquisX;
		local y2 = self.draggingMarquisY;

		if y2 < y then y , y2 = y2 , y end 
		if x2 < x then x , x2 = x2 , x end 

		y = math.ceil(y / self.itemHgt)
		x = math.ceil(x / self.itemHgt)
		y2 = math.ceil(y2 / self.itemHgt)
		x2 = math.ceil(x2 / self.itemHgt)
		
		self.selected = {}
		for i, v in ipairs(self.grid.xCell) do
			if v >= x and v <= x2 and self.grid.yCell[i] >= y and self.grid.yCell[i] <= y2 then 
				self:selectIndex(i);
			end
		end
	end

	if self.dragging and not self.dragStarted and (math.abs(x - self.draggingX) > 4 or math.abs(y - self.draggingY) > 4) then
		self.dragStarted = true
	end
end


function ISInventoryPane:toggleStove()
	local stove = self.inventory:getParent();
	stove:Toggle();
	return stove:Activated();
end

function ISInventoryPane:sortItemsByType(items)
	table.sort(items, function(a,b)
		if a:getContainer() and a:getContainer() == b:getContainer() and a:getDisplayName() == b:getDisplayName() then
			return a:getContainer():getItems():indexOf(a) < b:getContainer():getItems():indexOf(b)
		end
		return not string.sort(a:getType(), b:getType())
	end)
end

function ISInventoryPane:sortItemsByWeight(items)
	table.sort(items, function(a,b)
		if a:getContainer() and a:getContainer() == b:getContainer() and a:getDisplayName() == b:getDisplayName() then
			return a:getContainer():getItems():indexOf(a) < b:getContainer():getItems():indexOf(b)
		end
		return a:getUnequippedWeight() < b:getUnequippedWeight()
	end)
end

function ISInventoryPane:sortItemsByTypeAndWeight(items)
	local indexMap = {}
	local containers = {}
	local allIndexMap = {}
	for index,item in ipairs(items) do
		local container = item:getContainer()
		if container and not containers[container] then
			containers[container] = true
			local containerItems = container:getItems()
			for i=1,containerItems:size() do
				indexMap[containerItems:get(i-1)] = i
			end
		end
		allIndexMap[item] = index
	end

	local itemsByName = {}
	for _,item in ipairs(items) do
		local key = item:getDisplayName()
		itemsByName[key] = itemsByName[key] or {}
		table.insert(itemsByName[key], item)
	end

	local sorted = {}
	for _,itemList in pairs(itemsByName) do
		timSort(itemList, function(a,b)
			if a:getContainer() and (a:getContainer() == b:getContainer()) then
				-- this sometimes catches items that have the same parent container
				-- returned by :getContainer() but parent:getItems() failed to return
				-- both of them (some desync issue elsewhere?). In which case it doesnt
				-- matter which gets sorted first.
				if not indexMap[a] or not indexMap[b] then return false end
				return indexMap[a] < indexMap[b]
			end
			return allIndexMap[a] < allIndexMap[b]
		end)
		table.insert(sorted, itemList)
	end
	timSort(sorted, function(a,b)
		local wa = a[1]:getUnequippedWeight()
		local wb = b[1]:getUnequippedWeight()
		if wa < wb then
			return true
		end
		if wa == wb then
			return allIndexMap[a[1]] < allIndexMap[b[1]]
		end
		return false
	end)
	table.wipe(items)
	local count = 1
	for _,itemList in ipairs(sorted) do
		for _,item in ipairs(itemList) do
			items[count] = item
			count = count + 1
		end
	end
end

function ISInventoryPane:transferItemsByWeight(items, container)
	local playerObj = getSpecificPlayer(self.player)
	if true then
		self:sortItemsByTypeAndWeight(items)
	else
		self:sortItemsByType(items)
		self:sortItemsByWeight(items)
	end
	for _,item in ipairs(items) do
		if not container:isItemAllowed(item) then
			-- 
		elseif container:getType() == "floor" then
			ISInventoryPaneContextMenu.dropItem(item, self.player)
		else
			ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), container))
		end
	end
end

function ISInventoryPane:removeAll(player)
	if self.removeAllDialog then
		self.removeAllDialog:destroy()
	end
	local width = 350;
	local x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - width) / 2
	local height = 120;
	local y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - height) / 2
	local modal = ISModalDialog:new(x,y, width, height, getText("IGUI_ConfirmDeleteItems"), true, self, ISInventoryPane.onConfirmDelete, player);
	modal:initialise()
	self.removeAllDialog = modal
	modal:addToUIManager()
	if JoypadState.players[player+1] then
		modal.prevFocus = JoypadState.players[player+1].focus
		setJoypadFocus(player, modal)
	end
end

function ISInventoryPane:onConfirmDelete(button)
	if button.internal == "YES" then
		local object = self.inventory:getParent()
		local playerObj = getSpecificPlayer(self.player)
		local args = { x = object:getX(), y = object:getY(), z = object:getZ(), index = object:getObjectIndex() }
		sendClientCommand(playerObj, 'object', 'emptyTrash', args)
	end
	self.removeAllDialog = nil
end

function ISInventoryPane:lootAll()
	local playerObj = getSpecificPlayer(self.player)
	local playerInv = getPlayerInventory(self.player).inventory
	local items = {}
	local it = self.inventory:getItems();
	local heavyItem = nil
	if luautils.walkToContainer(self.inventory, self.player) then
		for i = 0, it:size()-1 do
			local item = it:get(i);
			if isForceDropHeavyItem(item) then
				heavyItem = item
			else
				table.insert(items, item)
			end
		end
		if heavyItem and it:size() == 1 then
			ISInventoryPaneContextMenu.equipHeavyItem(playerObj, heavyItem)
			return
		end
		self:transferItemsByWeight(items, playerInv)
	end
	self.selected = {};
	getPlayerLoot(self.player).inventoryPane.selected = {};
	getPlayerInventory(self.player).inventoryPane.selected = {};
end

function ISInventoryPane:transferAll()
	local playerObj = getSpecificPlayer(self.player)
	local playerLoot = getPlayerLoot(self.player).inventory
	local hotBar = getPlayerHotbar(self.player)
	local it = self.inventory:getItems();
	local items = {}
	if luautils.walkToContainer(self.inventory, self.player) then
		local toFloor = getPlayerLoot(self.player).inventory:getType() == "floor"
		for i = 0, it:size()-1 do
			local item = it:get(i);
			local ok = not item:isEquipped() and item:getType() ~= "KeyRing" and not item:hasTag( "KeyRing") and not hotBar:isInHotbar(item)
			if item:isFavorite() then
				ok = false
			end
			if toFloor and instanceof(item, "Moveable") and item:getSpriteGrid() == nil and not item:CanBeDroppedOnFloor() then
				ok = false
			end
			if ok then
				table.insert(items, item)
			end
		end
		self:transferItemsByWeight(items, playerLoot)
	end
	self.selected = {};
	getPlayerLoot(self.player).inventoryPane.selected = {};
	getPlayerInventory(self.player).inventoryPane.selected = {};
end

function ISInventoryPane:onMouseMove(dx, dy)
	if self.player ~= 0 then return end

	local x = self:getMouseX();
	local y = self:getMouseY();

	if(self.draggingMarquis) then

		local x2 = self.draggingMarquisX;
		local y2 = self.draggingMarquisY;

		if y2 < y then y , y2 = y2 , y end 
		if x2 < x then x , x2 = x2 , x end 

		y = math.ceil(y / self.itemHgt)
		x = math.ceil(x / self.itemHgt)
		y2 = math.ceil(y2 / self.itemHgt)
		x2 = math.ceil(x2 / self.itemHgt)
		
		self.selected = {}
		for i, v in ipairs(self.grid.xCell) do
			if v >= x and v <= x2 and self.grid.yCell[i] >= y and self.grid.yCell[i] <= y2 then 
				self:selectIndex(i);
			end
		end
	else
		local selected = 0
		if self.grid.xCell == nil then
		else
			if self.dragging == nil and x >= 0 and y >= 0 then
				x = math.ceil((x - 4)/ self.itemHgt)
				y = math.ceil((y - 3) / self.itemHgt)
				
				for i, v in ipairs(self.grid.xCell) do
					if v == x and self.grid.yCell[i] == y then
						selected = i
					else
					end
				end
			else
			end
		end
		
		self.mouseOverOption = selected
	end
	if self.dragging and not self.dragStarted and (math.abs(x - self.draggingX) > 4 or math.abs(y - self.draggingY) > 4) then
		self.dragStarted = true
	end
end

function ISInventoryPane:updateTooltip()
	if not self:isReallyVisible() then
		return
	end
	local item = nil
	if self.doController and self.joyselection then
		if self.joyselection < 1 then self.joyselection = 1 end
		if self.joyselection > #self.items then self.joyselection = #self.items end
		item = self.items[self.joyselection]
	end

		local selected = 1
		if not self.doController and not self.dragging and not self.draggingMarquis and self:isMouseOver() then
			item = self.items[self.mouseOverOption]
		end
	local weightOfStack = 0.0
	if item and not instanceof(item, "InventoryItem") then
		if #item.items > 2 then
			weightOfStack = item.weight
		end
		item = item.items[1]
	end
	if getPlayerContextMenu(self.player):isAnyVisible() then
		item = nil
	end
	if item and self.toolRender and (item == self.toolRender.item) and
			(weightOfStack == self.toolRender.tooltip:getWeightOfStack()) and
			self.toolRender:isVisible() then
		return
	end
	if item then
		if self.toolRender then
			self.toolRender:setItem(item)
			self.toolRender:setVisible(true)
			self.toolRender:addToUIManager()
			self.toolRender:bringToTop()
			self.toolRender.anchorBottomLeft = { x = self.inventoryPage.x, y = self.inventoryPage.y }
		else
			self.toolRender = ISToolTipInv:new(item)
			self.toolRender:initialise()
			self.toolRender:addToUIManager()
			self.toolRender:setVisible(true)
			self.toolRender:setOwner(self)
			self.toolRender:setCharacter(getSpecificPlayer(self.player))
			self.toolRender.anchorBottomLeft = { x = self.inventoryPage.x, y = self.inventoryPage.y }
		end
		self.toolRender.followMouse = not self.doController
		self.toolRender.tooltip:setWeightOfStack(weightOfStack)
		if not self.doController then
		end
	elseif self.toolRender then
		self.toolRender:removeFromUIManager()
		self.toolRender:setVisible(false)
	end

--	Hack for highlighting doors when a Key tooltip is displayed.
	if self.parent.onCharacter then
		if not self.toolRender or not self.toolRender:getIsVisible() then
			item = nil
		end
		Key.setHighlightDoors(self.player, item)
	end

	local inventoryPage = getPlayerInventory(self.player)
	local inventoryTooltip = inventoryPage and inventoryPage.inventoryPane.toolRender
	local lootPage = getPlayerLoot(self.player)
	local lootTooltip = lootPage and lootPage.inventoryPane.toolRender
	UIManager.setPlayerInventoryTooltip(self.player,
		inventoryTooltip and inventoryTooltip.javaObject or nil,
		lootTooltip and lootTooltip.javaObject or nil)
end

function ISInventoryPane:onMouseDownOutside(x, y)
	self.dragging = nil;
	self.draggedItems:reset()
	if self:isMouseOverScrollBar() then
		self.clickedScrollBar = true;
	else
		self.clickedScrollBar = false;
		self.selected = {};
	end
end

function ISInventoryPane:onMouseUpOutside(x, y)
	self.previousMouseUp = self.mouseOverOption;
	if self.draggingMarquis then
		self:onMouseUp(x, y);
	elseif not self.clickedScrollBar then
		self.selected = {};
	end;
	self.draggingMarquis = false;
	self.clickedScrollBar = false;
end

function ISInventoryPane.getActualItems(items)
	local ret = {}
	local contains = {}
	for _,item in ipairs(items) do
		if instanceof(item, "InventoryItem") then
			if not contains[item] then
--				The top-level group and its children might both be selected.
				table.insert(ret, item)
				contains[item] = true
			end
		else
--			The first item is a dummy duplicate, skip it.
			for i=2,#item.items do
				local item2 = item.items[i]
				if not contains[item2] then
					table.insert(ret, item2)
					contains[item2] = true
				end
			end
		end
	end
	return ret
end

function ISInventoryPane:doContextualDblClick(item)
	local playerObj = getSpecificPlayer(self.player);
	if instanceof(item, "HandWeapon") then
		if playerObj:isHandItem(item) then
			ISInventoryPaneContextMenu.unequipItem(item, self.player);
		elseif item:getCondition() > 0 then
			ISInventoryPaneContextMenu.equipWeapon(item, true, item:isTwoHandWeapon(), self.player);
		end
	end
	if instanceof(item, "Clothing") then
		if playerObj:isEquipped(item) then
			ISInventoryPaneContextMenu.onUnEquip({item}, self.player);
		else
			ISInventoryPaneContextMenu.onWearItems({item}, self.player);
		end
	end
	if instanceof(item, "InventoryContainer") and item:canBeEquipped() ~= nil and item:canBeEquipped() ~= "" then
		if playerObj:isEquipped(item) then
			ISInventoryPaneContextMenu.onUnEquip({item}, self.player);
		else
			ISInventoryPaneContextMenu.onWearItems({item}, self.player);
		end
	elseif instanceof (item, "InventoryContainer") and item:getItemReplacementSecondHand() ~= nil then
		if playerObj:isEquipped(item) then
			ISInventoryPaneContextMenu.onUnEquip({item}, self.player);
		else
			ISInventoryPaneContextMenu.equipWeapon(item, false, false, self.player);
		end
	end
	if instanceof(item, "Food") and item:getHungChange() < 0 and not item:getScriptItem():isCantEat() then
		if playerObj:getMoodles():getMoodleLevel(MoodleType.FoodEaten) < 3 or playerObj:getNutrition():getCalories() < 1000 then
			ISInventoryPaneContextMenu.onEatItems({item}, 1, self.player);
		end

	end
end

function ISInventoryPane:onMouseDoubleClick(x, y)
	if self.items and self.mouseOverOption and self.previousMouseUp == self.mouseOverOption then
		if getCore():getGameMode() == "Tutorial" then
			if TutorialData.chosenTutorial.doubleClickInventory(self, x, y, self.mouseOverOption) then
				return
			end
		end
		local playerObj = getSpecificPlayer(self.player)
		local playerInv = getPlayerInventory(self.player).inventory;
		local lootInv = getPlayerLoot(self.player).inventory;
		local item = self.items[self.mouseOverOption];
		local doWalk = true
		local shiftHeld = isShiftKeyDown()
		if item and not instanceof(item, "InventoryItem") then
			if item.items then
				for k, v in ipairs(item.items) do
					if k ~= 1 and v:getContainer() ~= playerInv then
						if isForceDropHeavyItem(v) then
							ISInventoryPaneContextMenu.equipHeavyItem(playerObj, v)
							break
						end
						if doWalk then
							if not luautils.walkToContainer(v:getContainer(), self.player) then
								break
							end
							doWalk = false
						end
						ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, v, v:getContainer(), playerInv))
						if instanceof(v, "Clothing") and not v:isBroken() and shiftHeld then
							ISTimedActionQueue.add(ISWearClothing:new(playerObj, v))
						end
					elseif k ~= 1 and v:getContainer() == playerInv then
						local tItem = v;
						self:doContextualDblClick(tItem);
						break
					end
				end
			end
		elseif item and item:getContainer() ~= playerInv then
			if isForceDropHeavyItem(item) then
				ISInventoryPaneContextMenu.equipHeavyItem(playerObj, item)
			elseif luautils.walkToContainer(item:getContainer(), self.player) then
				ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), playerInv))
			end
		elseif item and item:getContainer() == playerInv then -- double click do some basic action, equip weapon/wear clothing...
			self:doContextualDblClick(item);
		end
		self.previousMouseUp = nil;
	end
end

function ISInventoryPane:onMouseUp(x, y)
	if self.player ~= 0 then return end

	local playerObj = getSpecificPlayer(self.player)

	self.previousMouseUp = self.mouseOverOption;
	if (not isShiftKeyDown() and not isCtrlKeyDown() and x >= self.column2 and  x == self.downX and y == self.downY) and  self.mouseOverOption ~= 0 and self.items[self.mouseOverOption] ~= nil then
		self.selected = {};
		self:selectIndex(self.mouseOverOption);
	end

	if ISMouseDrag.dragging ~= nil and ISMouseDrag.draggingFocus ~= self and ISMouseDrag.draggingFocus ~= nil then
		if getCore():getGameMode() ~= "Tutorial" then
			if self:canPutIn() then
				local doWalk = true
				local items = {}
				local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
				for i,v in ipairs(dragging) do
					local transfer = v:getContainer() and not self.inventory:isInside(v)
					if v:isFavorite() and not self.inventory:isInCharacterInventory(playerObj) then
						transfer = false
					end
					if transfer then
--						only walk for the first item
						if doWalk then
							if not luautils.walkToContainer(self.inventory, self.player) then
								break
							end
							doWalk = false
						end
						table.insert(items, v)
					end
				end
				self:transferItemsByWeight(items, self.inventory)
				self.selected = {};
				getPlayerLoot(self.player).inventoryPane.selected = {};
				getPlayerInventory(self.player).inventoryPane.selected = {};
			end
		end
		if ISMouseDrag.draggingFocus then
			ISMouseDrag.draggingFocus:onMouseUp(0,0);
		end
		ISMouseDrag.draggingFocus = nil;
		ISMouseDrag.dragging = nil;
		return;
	end

	self.dragging = nil;
	self.draggedItems:reset();
	ISMouseDrag.dragging = nil;
	ISMouseDrag.draggingFocus = nil;
	self.draggingMarquis = false;

	return true;
end

function ISInventoryPane:canPutIn()
	local playerObj = getSpecificPlayer(self.player)

	if self.inventory == nil then
		return false;
	end
	if self.inventory:getType() == "floor" then
		return true;
	end

	if self.inventory:getParent() == playerObj then
		return true;
	end

	local items = {}
--	If the lightest item fits, allow the transfer.
	local minWeight = 100000
	local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
	for i,v in ipairs(dragging) do
		local itemOK = true
		if v:isFavorite() and not self.inventory:isInCharacterInventory(playerObj) then
			itemOK = false
		end
--		you can't draw the container in himself
		if (self.inventory:isInside(v)) then
			itemOK = false;
		end
		if self.inventory:getType() == "floor" and v:getWorldItem() then
			itemOK = false
		end
		if v:getContainer() == self.inventory then
			itemOK = false
		end
		local inv = self.inventory;
		if not inv:isItemAllowed(v) then
			itemOK = false;
		end
		if itemOK then
			table.insert(items, v)
		end
		if v:getUnequippedWeight() < minWeight then
			minWeight = v:getUnequippedWeight()
		end
	end
	if #items == 1 then
		return self.inventory:hasRoomFor(playerObj, items[1])
	end
	return self.inventory:hasRoomFor(playerObj, minWeight)
end

ISInventoryPaneDraggedItems = {}
local DraggedItems = ISInventoryPaneDraggedItems

function DraggedItems:getDropContainer()
	local playerInv = getPlayerInventory(self.playerNum)
	local playerLoot = getPlayerLoot(self.playerNum)
	if not playerInv or not playerLoot then
		return nil
	end
	if playerInv.mouseOverButton then
		return playerInv.mouseOverButton.inventory, "button"
	end
	if playerInv.inventoryPane:isMouseOver() then
		return playerInv.inventoryPane.inventory, "inventory"
	end
	if playerLoot.mouseOverButton then
		return playerLoot.mouseOverButton.inventory, "button"
	end
	if playerLoot.inventoryPane:isMouseOver() then
		return playerLoot.inventoryPane.inventory, "loot"
	end

	local mx = getMouseX()
	local my = getMouseY()
	local uis = UIManager.getUI()
	local mouseOverUI = nil
	for i=0,uis:size()-1 do
		local ui = uis:get(i)
		if ui:isPointOver(mx, my) then
			mouseOverUI = ui
			break
		end
	end
	if not mouseOverUI then
		return ISInventoryPage.GetFloorContainer(self.playerNum), "floor"
	end

	return nil
end

function DraggedItems:update()
	self.playerNum = self.inventoryPane.player
	local playerObj = getSpecificPlayer(self.playerNum)

	if not self.items then
		self.items = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
		self.inventoryPane:sortItemsByTypeAndWeight(self.items)
	end

--	Try to detect changes to the destination container.
	if self.mouseOverContainer and (self.mouseOverItemCount ~= self.mouseOverContainer:getItems():size()) then
		self.mouseOverContainer = nil
	end

	local container, what = self:getDropContainer()
	if (container == self.mouseOverContainer) and (what == self.mouseOverWhat) then
		return
	end
	self.mouseOverContainer = container
	self.mouseOverWhat = what
	self.mouseOverItemCount = container and container:getItems():size() or 0
	table.wipe(self.itemNotOK)

	if #self.items == 0 then
		return
	end

	if not container then
		return
	end

	local containerInInventory = container:isInCharacterInventory(playerObj)

--	Items may always be dragged to the floor (except favorited items).
	if container:getType() == "floor" then
		for _,item in ipairs(self.items) do
			if item:isFavorite() and not containerInInventory then
				self.itemNotOK[item] = true
			end
			if what ~= "loot" and item:getWorldItem() then
				self.itemNotOK[item] = true
			end
		end
		return
	end

--	Dragging from ourself to ourself does nothing, but don't show as prevented.
	if what ~= "button" and container == self.inventoryPane.inventory then
		return
	end

	local totalWeight = 0
	local overWeight = false
	local validItems = {}
	for _,item in ipairs(self.items) do
		local itemOK = true
		if container:isInside(item) then
			itemOK = false
		end
		if item:isFavorite() and not containerInInventory then
			itemOK = false
		end
		if item:getContainer() == container then
			itemOK = false
		end
		if not container:isItemAllowed(item) then
			itemOK = false
		end
--		Items are sorted by weight (see above)
		if itemOK then
			totalWeight = totalWeight + item:getUnequippedWeight()
		end
		if overWeight then
			itemOK = false
		else
			if not container:hasRoomFor(playerObj, totalWeight) then
				itemOK = false
				overWeight = true
			end
		end
		if itemOK then
			table.insert(validItems, item)
		else
			self.itemNotOK[item] = true
		end
	end

--	Hack: Allow any single item on a vehicle seat regardless of weight (ex, Generator)
	if #validItems == 1 then
		local item = validItems[1]
		self.itemNotOK[item] = not container:hasRoomFor(playerObj, item)
	end
end

function DraggedItems:cannotDropItem(item)
	if not item then return false end
	return self.itemNotOK[item] == true
end

function DraggedItems:reset()
	self.mouseOverContainer = nil
	self.mouseOverWhat = nil
	self.items = nil
	table.wipe(self.itemNotOK)
end

function DraggedItems:new(inventoryPane)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.inventoryPane = inventoryPane
	o.mouseOverContainer = nil
	o.mouseOverWhat = nil
	o.items = nil
	o.itemNotOK = {}
	return o
end

-- function for expand or collapse stacks of items
function ISInventoryPane:doJoypadExpandCollapse(mode)

	local selected = 1

	if mode == "mouse" then
		selected = self.mouseOverOption
	elseif mode == "joypad" then
		selected = self.joyselection
	else
		return
	end

	if #self.items > 0 then
	local nItem = self.items[selected]
--		one item >>> don't expand
		if nItem.count ~= nil and nItem.count > 2 then
			if not selected then return end
			if not self.items or not nItem then return end
			if not instanceof(nItem, "InventoryItem") then
				if self.collapsed[nItem.name] == true then
--					not too many items >>> expand
					if self.countCollapsed + nItem.count <= self.MAX_ITEMS_IN_STACK_TO_RENDER + 1 then
						self.countCollapsed = self.countCollapsed + nItem.count - 1
						self.collapsed[nItem.name] = false
					else
--						total expanded items maxed >>> collapse all except current
						for item, condition in pairs(self.collapsed) do
							self.collapsed[item] = true
						end
						self.countCollapsed = 0 + nItem.count - 1
						self.collapsed[nItem.name] = false
--						position changed >>> find new position
						for position, item in pairs(self.itemslist) do
							if item.name == nItem.name then
								selected = position
							end
						end
					end
--				expanded >>> collapse
				elseif self.collapsed[nItem.name] == false then
					self.countCollapsed = self.countCollapsed - nItem.count + 1
					self.collapsed[nItem.name] = true
				end
				
			end
--		one of expanded group >>> collapse group
		else
			if mode == "joypad" then
				while self.items[selected].count == nil do
					selected = selected - 1
				end
				if self.items[selected].count > 2 then
					self.countCollapsed = self.countCollapsed - self.items[selected].count - 1
					self.collapsed[self.items[selected].name] = true
				end
			end
		end
	end

	self:refreshContainer();

end

function ISInventoryPane:doGrabOnJoypadSelected()
	if self.joyselection == nil then return end
	if not self.doController then return end

	local playerObj = getSpecificPlayer(self.player)
	if playerObj:isAsleep() then return end
	if #self.items == 0 then return end

	self.selected = {};
	self:selectIndex(self.joyselection);
	local items = {}
	for k, v in ipairs(self.items) do
		if self.selected[k] ~= nil then
			if instanceof(v, "InventoryItem") then
				if not self.parent.onCharacter and isForceDropHeavyItem(v) then
					ISInventoryPaneContextMenu.equipHeavyItem(playerObj, v)
					return
				end
				table.insert(items, v);
			elseif self.collapsed[v.name] then
				if not self.parent.onCharacter and isForceDropHeavyItem(v.items[1]) then
					ISInventoryPaneContextMenu.equipHeavyItem(playerObj, v.items[1])
					return
				end
				table.insert(items, v);
			end
		end
	end
	if self.parent.onCharacter then
		ISInventoryPaneContextMenu.onPutItems(items, self.player);
	else
		ISInventoryPaneContextMenu.onGrabItems(items, self.player);
	end
end

function ISInventoryPane:doContextOnJoypadSelected()
	if JoypadState.disableInvInteraction then
		return;
	end
	if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then
		return;
	end

	local playerObj = getSpecificPlayer(self.player)
	if playerObj:isAsleep() then return end

	local isInInv = self.inventory:isInCharacterInventory(playerObj)

	if #self.items == 0 then
		local menu = ISInventoryPaneContextMenu.createMenuNoItems(self.player, not isInInv, self:getAbsoluteX()+64, self:getAbsoluteY()+64)
		if menu then
			menu.origin = self.inventoryPage
			menu.mouseOver = 1
			setJoypadFocus(self.player, menu)
		end
		return
	end

	if self.joyselection == nil then return end
	if not self.doController then return end

	self:selectIndex(self.joyselection);
	local item = self.items[self.joyselection];

	local contextMenuItems = {}
	for k, v in ipairs(self.items) do
		if self.selected[k] ~= nil then
			if instanceof(v, "InventoryItem") or self.collapsed[v.name] then
				table.insert(contextMenuItems, v);
			end
		end
	end
	
	local menu = nil;
	if getCore():getGameMode() == "Tutorial" then
		menu = Tutorial1.createInventoryContextMenu(self.player, isInInv, contextMenuItems, self:getAbsoluteX()+64, self:getAbsoluteY()+8+(self.joyselection*self.itemHgt)+self:getYScroll());
	else
		menu = ISInventoryPaneContextMenu.createMenu(self.player, isInInv, contextMenuItems, self:getAbsoluteX()+64, self:getAbsoluteY()+8+(self.joyselection*self.itemHgt)+self:getYScroll());
	end
	menu.origin = self.inventoryPage;
	menu.mouseOver = 1;
	if menu.numOptions > 1 then
		setJoypadFocus(self.player, menu)
	end
end

function ISInventoryPane:onRightMouseUp(x, y)

	if self.player ~= 0 then return end

	local isInInv = self.inventory:isInCharacterInventory(getSpecificPlayer(self.player))
	
	if #self.items == 0 then
		local menu = ISInventoryPaneContextMenu.createMenuNoItems(self.player, not isInInv, self:getAbsoluteX()+x, self:getAbsoluteY()+y+self:getYScroll())
		if menu and menu.numOptions > 1 and JoypadState.players[self.player+1] then
			menu.origin = self.inventoryPage
			menu.mouseOver = 1
			setJoypadFocus(self.player, menu)
		end
		return
	end

	if self.selected == nil then
		self.selected = {}
	end

	if self.mouseOverOption ~= 0 and self.items[self.mouseOverOption] ~= nil and self.selected[self.mouseOverOption] == nil then
		self.selected = {};
		self:selectIndex(self.mouseOverOption);
	end

	local contextMenuItems = {}
	for k, v in ipairs(self.items) do
	   if self.selected[k] ~= nil then
		   if instanceof(v, "InventoryItem") or self.collapsed[v.name] then
				table.insert(contextMenuItems, v);
		   end
	   end
	end

	if self.toolRender then
		self.toolRender:setVisible(false)
	end

	local menu = ISInventoryPaneContextMenu.createMenu(self.player, isInInv, contextMenuItems, self:getAbsoluteX()+x, self:getAbsoluteY()+y+self:getYScroll());
	if menu and menu.numOptions > 1 and JoypadState.players[self.player+1] then
		menu.origin = self.inventoryPage
		menu.mouseOver = 1
		setJoypadFocus(self.player, menu)
	end

	return true;
end

function ISInventoryPane:onMouseDown(x, y)

	if self.player ~= 0 then return true end

	getSpecificPlayer(self.player):nullifyAiming();

	local count = 0;

	self.downX = x;
	self.downY = y;
	
	if self.selected == nil then
		self.selected = {}
	end

	if self.mouseOverOption ~= 0 and self.items[self.mouseOverOption] ~= nil then
		if not isShiftKeyDown() and not isCtrlKeyDown() and self.selected[self.mouseOverOption] == nil then
			self.selected = {};
			self.firstSelect = nil;
		end

		if not isShiftKeyDown() then
			self.firstSelect = self.mouseOverOption;
			if isCtrlKeyDown() then
				if self.selected[self.mouseOverOption] then
					self.selected[self.mouseOverOption] = nil;
				else
					self.selected[self.mouseOverOption] =  self.items[self.mouseOverOption];
				end
			else
				self:doJoypadExpandCollapse("mouse")
				
					self.selected[self.mouseOverOption] = self.items[self.mouseOverOption];
				
				if not instanceof(self.items[self.mouseOverOption], "InventoryItem") and self.items[self.mouseOverOption].items[1] == self.selected[self.mouseOverOption + 1] then
					self.selected[self.mouseOverOption + 1] = nil
				end
			end
		end
		if isShiftKeyDown() then
		   if self.firstSelect then
			   self.selected = {};
			   if self.firstSelect < self.mouseOverOption then
					for i=self.firstSelect, self.mouseOverOption do
						self.selected[i] =  self.items[i];
					end
			   else
				   for i=self.mouseOverOption, self.firstSelect do
					   self.selected[i] =  self.items[i];
				   end
			   end
		   else
			   self.firstSelect = self.mouseOverOption;
			   self.selected[self.mouseOverOption] = self.items[self.mouseOverOption];
		   end
		end
		self.dragging = self.mouseOverOption;
		self.draggingX = x;
		self.draggingY = y;
		self.dragStarted = false
		ISMouseDrag.dragging = {}
		for i,v in ipairs(self.items) do
			if self.selected[count+1] ~= nil then
				table.insert(ISMouseDrag.dragging, v);
			end
			count = count + 1;
		end
		ISMouseDrag.draggingFocus = self;
		return;
	end

	if not isShiftKeyDown() and not isCtrlKeyDown() then
		self.selected = {};
		self.firstSelect = nil;
	end

	if self.dragging == nil and x >= 0 and y >= 0 and (x<=self.column3 and y <= self:getScrollHeight() - self.itemHgt) then

	elseif count == 0 then
		self.draggingMarquis = true;
		self.draggingMarquisX = x;
		self.draggingMarquisY = y;
		self.dragging = nil;
		self.draggedItems:reset()
		ISMouseDrag.dragging = nil;
		ISMouseDrag.draggingFocus = nil;
	end

	return true;
end

function ISInventoryPane:getScrollAreaHeight()
	return self:getHeight()
end

function ISInventoryPane:updateSmoothScrolling()
end

function ISInventoryPane:isMouseOverScrollBar()
	return self:isVScrollBarVisible() and self.vscroll:isMouseOver()
end

function ISInventoryPane:prerender()
	local mouseY = self:getMouseY()
	self:updateSmoothScrolling()
	if mouseY ~= self:getMouseY() and self:isMouseOver() then
		self:onMouseMove(0, self:getMouseY() - mouseY)
	end
	self:setStencilRect(0,0,self.width-1, self.height-1);

	if self.mode == "icons" then
		self:rendericons();
	elseif self.mode == "details" then
		self:renderdetails(false);
	end

	if self.drawBlood == true and self.parent.onCharacter then
		self:drawTexture(self.bloodOverlay, 0, self.height - 278, 1, 1, 1, 1);
	end
end

local function isSelectAllPossible(page)
	if not page then return false end
	if not page:isVisible() then return false end
	if page.isCollapsed then return false end
	if not page:isMouseOver() then return false end
	for _,v in pairs(page.inventoryPane.selected) do
		return true
	end
	return false
end

function ISInventoryPane:update()

	local playerObj = getSpecificPlayer(self.player)
	
	if self.doController then
		if (self.player ~= 0) or (wasMouseActiveMoreRecentlyThanJoypad() == false) then
			table.wipe(self.selected)
		end
		if self.joyselection == nil then
			self.joyselection = 1;
		end
	end
	self:updateTooltip()


	local remove = nil

	for i,v in pairs(self.selected) do
		if instanceof(v, "InventoryItem") then
			if v:getContainer() ~= self.inventory then
				if remove == nil then
					remove = {}
				end
				remove[i] = i;
			end
		end
	end
	if remove ~= nil then
		for i,v in pairs(remove) do
			self.selected[v] = nil;
		end
	end


--	Make it select the header if all sub items in expanded item are selected.
	for i,v in ipairs(self.items) do
		if not instanceof(v, "InventoryItem") and self.selected[i] == nil and not self.collapsed[v.name] then
			local anyNot = false;
			for j=2,#v.items do
				if self.selected[i+j-1] == nil then
					anyNot = true;
					break;
				end
			end
			if not anyNot then
				self.selected[i] = v;
			end
		end
	end

	-- If the user was dragging items from this pane and the mouse wasn't released over a valid drop location,
	-- then we must clear the drag info.  Additionally, if the mouse was released outside any UIElement, then
	-- we will drop the items onto the floor (unless this pane is displaying the floor container).
	-- NOTE: This only works because update() is called after all the mouse-event handling, so other UIElements
	-- have already had a chance to accept the drag.
	if ISMouseDrag.dragging ~= nil and ISMouseDrag.draggingFocus == self and not isMouseButtonDown(0) then
		if getCore():getGameMode() == "Tutorial" then
			if ISMouseDrag.draggingFocus then
				ISMouseDrag.draggingFocus:onMouseUp(0,0);
			end
			ISMouseDrag.draggingFocus = nil;
			ISMouseDrag.dragging = nil;
			return;
		end
		local dragContainsMovables = false;
		local dragContainsNonMovables = false;
		local mx = getMouseX()
		local my = getMouseY()
		local uis = UIManager.getUI()
		local mouseOverUI
		for i=0,uis:size()-1 do
			local ui = uis:get(i)
			if ui:isPointOver(mx, my) then
				mouseOverUI = ui
				break
			end
		end

		local noVehicle = true
		local vehicleNoWindow = true
		local vehicleWindowDestroyed = true
		local vehicleWindowOpen = true

		local vehicle = playerObj:getVehicle()

		if vehicle ~= nil then
			noVehicle = false
			local seat = vehicle:getSeat(playerObj)
			local door = vehicle:getPassengerDoor(seat)
			local windowPart = VehicleUtils.getChildWindow(door)
			if windowPart and (not windowPart:getItemType() or windowPart:getInventoryItem()) then
				vehicleNoWindow = false
				local window = windowPart:getWindow()
				if window:isOpenable() and not window:isOpen() then
					vehicleWindowOpen = false
				end
			end
		end

		if self.inventory:getType() ~= "floor" and not mouseOverUI and (noVehicle or vehicleNoWindow or vehicleWindowOpen) then
			local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
			local dropit = false;
			for i,v in ipairs(dragging) do
				if not self.inventory:isInside(v) and not v:isFavorite() then
					if not instanceof(v, "Moveable") or v:CanBeDroppedOnFloor() then
						ISInventoryPaneContextMenu.dropItem(v, self.player)
						dragContainsNonMovables = true
					else
						dragContainsMovables = dragContainsMovables or v
					end
				end
			end
			self.selected = {}
			getPlayerLoot(self.player).inventoryPane.selected = {}
			getPlayerInventory(self.player).inventoryPane.selected = {}
		end
		self.inventoryPage.selectedSqDrop = nil;
		self.inventoryPage.render3DItems = {};
		self.dragging = nil
		self.draggedItems:reset()
		ISMouseDrag.dragging = nil
		ISMouseDrag.draggingFocus = nil

		if dragContainsMovables and not dragContainsNonMovables then
			local mo = ISMoveableCursor:new(getSpecificPlayer(self.player));
			getCell():setDrag(mo, mo.player);
			mo:setMoveableMode("place");
			mo:tryInitialItem(dragContainsMovables);
		end
	end

-- 	If the user was draggingMarquis from this pane and the mouse wasn't released over a valid location,
-- 	then we must clear the drag info.
	if self.draggingMarquis and not isMouseButtonDown(0) then
		self.draggingMarquis = false;
	end;

	if self.doController then
		return
	end

	local page1 = getPlayerInventory(0)
	local page2 = getPlayerLoot(0)
	if not page1 or not page2 then
		return
	end
	if isCtrlKeyDown() and (isSelectAllPossible(page1) or isSelectAllPossible(page2)) then
		getCore():setIsSelectingAll(true)
	else
		getCore():setIsSelectingAll(false)
	end
	if isCtrlKeyDown() and isKeyDown(Keyboard.KEY_A) and isSelectAllPossible(self.parent) then
		table.wipe(self.selected)
		for k,v in ipairs(self.items) do
			self.selected[k] = v
		end
	end
end

function ISInventoryPane:saveSelection(selected)
	for _,v in pairs(self.selected) do
		if instanceof(v, "InventoryItem") then
			selected[v] = selected[v] or "item"
		else
			selected[v.items[1]] = "group"
		end
	end
--	Hack for the selection being cleared while dragging items.
	if ISMouseDrag.dragging and (ISMouseDrag.draggingFocus == self) then
		for _,v in ipairs(ISMouseDrag.dragging) do
			if instanceof(v, "InventoryItem") then
				selected[v] = selected[v] or "item"
			else
				selected[v.items[1]] = "group"
			end
		end
	end
	return selected
end

function ISInventoryPane:restoreSelection(selected)
	local row = 1
	for _,v in ipairs(self.itemslist) do
		local item = v.items[1]
		if selected[item] == "group" then
			self.selected[row] = item
		end
		row = row + 1
		if not self.collapsed[v.name] then
			for j=2,#v.items do
				local item2 = v.items[j]
				if selected[item2] then
					self.selected[row] = item2
				end
				row = row + 1
			end
		end
	end
end

function ISInventoryPane:refreshContainer()
	self.itemslist = {}
	self.itemindex = {}

	if self.collapsed == nil then
		self.collapsed = {}
	end
	if self.selected == nil then
		self.selected = {}
	end

	local selected = self:saveSelection({})
	table.wipe(self.selected)

	local playerObj = getSpecificPlayer(self.player)

	if not self.hotbar then
		self.hotbar = getPlayerHotbar(self.player);
	end

	local isEquipped = {}
	local isInHotbar = {}
	if self.parent.onCharacter then
		local wornItems = playerObj:getWornItems()
		for i=1,wornItems:size() do
			local wornItem = wornItems:get(i-1)
			isEquipped[wornItem:getItem()] = true
		end
		local item = playerObj:getPrimaryHandItem()
		if item then
			isEquipped[item] = true
		end
		item = playerObj:getSecondaryHandItem()
		if item then
			isEquipped[item] = true
		end
		if self.hotbar and self.hotbar.attachedItems then
			for _,item in pairs(self.hotbar.attachedItems) do
				isInHotbar[item] = true
			end
		end
	end

	local expandedItems = 0;
	for k, v in pairs(self.collapsed) do
		if not self.collapsed[k] then
			expandedItems = 1;
			break
		end
	end

	local it = self.inventory:getItems();
	for i = 0, it:size()-1 do
		local item = it:get(i);
		local add = true;
--		don't add the ZedDmg category, they are just equipped models
		if item:isHidden() then
			add = false;
		end
		if add then
			local itemName = item:getName();
			if item:IsFood() and item:getHerbalistType() and item:getHerbalistType() ~= "" then
				if playerObj:isRecipeActuallyKnown("Herbalist") then
					if item:getHerbalistType() == "Berry" then
						itemName = (item:getPoisonPower() > 0) and getText("IGUI_PoisonousBerry") or getText("IGUI_Berry")
					end
					if item:getHerbalistType() == "Mushroom" then
						itemName = (item:getPoisonPower() > 0) and getText("IGUI_PoisonousMushroom") or getText("IGUI_Mushroom")
					end
				else
					if item:getHerbalistType() == "Berry"  then
						itemName = getText("IGUI_UnknownBerry")
					end
					if item:getHerbalistType() == "Mushroom" then
						itemName = getText("IGUI_UnknownMushroom")
					end
				end
				if itemName ~= item:getDisplayName() then
					item:setName(itemName);
				end
				itemName = item:getName()
			end
			local equipped = false
			local inHotbar = false
			if self.parent.onCharacter then
				if isEquipped[item] then
					itemName = "equipped:"..itemName
					equipped = true
				elseif (item:getType() == "KeyRing" or item:hasTag( "KeyRing")) and playerObj:getInventory():contains(item) then
					itemName = "keyring:"..itemName
					equipped = true
				end
				if self.hotbar then
					inHotbar = isInHotbar[item];
					if inHotbar and not equipped then
						itemName = "hotbar:"..itemName
					end
				end
			end
			if self.itemindex[itemName] == nil then
				self.itemindex[itemName] = {};
				self.itemindex[itemName].items = {}
				self.itemindex[itemName].count = 0
			end
			local ind = self.itemindex[itemName];
			ind.equipped = equipped
			ind.inHotbar = inHotbar;

			ind.count = ind.count + 1
			ind.items[ind.count] = item;
		end
	end

	for k, v in pairs(self.itemindex) do

		if v ~= nil then
			table.insert(self.itemslist, v);
			local count = 1;
			local weight = 0;
			local itemName
			for k2, v2 in ipairs(v.items) do
				if v2 == nil then
					table.remove(v.items, k2);
				else
					count = count + 1;
					weight = weight + v2:getUnequippedWeight();
				end
				itemName = v2
			end
			v.count = count;
			v.invPanel = self;
			v.name = k -- v.items[1]:getName();
			v.cat = getText("IGUI_ItemCat_" .. itemName:getDisplayCategory()) or v.items[1]:getDisplayCategory() or v.items[1]:getCategory();
			v.weight = weight;
			if self.collapsed[v.name] == nil then
				self.collapsed[v.name] = true;
			end
		end
	end

	table.sort(self.itemslist, self.itemSortFunc );

--	Adding the first item in list additionally at front as a dummy at the start, to be used in the details view as a header.
	for k, v in ipairs(self.itemslist) do
		local item = v.items[1];
		table.insert(v.items, 1, item);
	end

	self:restoreSelection(selected);
	table.wipe(selected);

	self.inventory:setDrawDirty(false);

--	Update the buttons
	if self:isMouseOver() then
		self:onMouseMove(0, 0)
	end

	self:updateWorldObjectHighlight();
	
	self.someChange = true

end

ISInventoryPane.highlightItem = nil;
function ISInventoryPane:renderdetails(doDragged)

	if doDragged == false then
		table.wipe(self.items)
		if self.inventory:isDrawDirty() then
			self:refreshContainer()
		end
	end
	
	local player = getSpecificPlayer(self.player)

	local checkDraggedItems = false
	if doDragged and self.dragging ~= nil and self.dragStarted then
		self.draggedItems:update()
		checkDraggedItems = true
	end

-- 	inventory opaque background
	if not doDragged then
		self:drawRectStatic(0, 0, self.width, self.height, 0.3, 0, 0, 0);
	end
	
	local y = 0;
	if self.itemslist == nil then
		self:refreshContainer();
	end

	local equippedLine = false
	local catcheck = nil;
	local echeck = 0
	local shiftY = -1
	local shiftX = 0
	local itemSize = self.itemHgt
	local edgepx = (itemSize-32)/2+4
-- 	go through all the stacks of items.
	for k, v in ipairs(self.itemslist) do 
		local count = 1;
--	go through each item in stack..
		for itemN, item in ipairs(v.items) do
			local doIt = true;
			local xoff = 0;
			local yoff = 0;
			
			if doDragged == false then
--	if it's the first item, then store the category, otherwise the item
				if count == 1 then table.insert(self.items, v) else table.insert(self.items, item) end
				if instanceof(item, 'InventoryItem') then item:updateAge() end
				if instanceof(item, 'Clothing') then item:updateWetness() end
			end
			local isDragging = false
			if self.dragging ~= nil and self.selected[y + 1] ~= nil and self.dragStarted then
				xoff = self:getMouseX() - self.draggingX;
				yoff = self:getMouseY() - self.draggingY;
				
				if not doDragged then
					doIt = true;
				else
					self:suspendStencil();
					isDragging = true
					ISInventoryItem.renderItemIcon(self, item, self.grid.xCell[y+1]*itemSize+edgepx+xoff-64, self.grid.yCell[y+1]*itemSize+edgepx+yoff-64, 1.0, 64, 64);
				end
			else
				if doDragged then
					doIt = false;
				end
			end

			if doIt == true then
--		only do icon if header or dragging sub items without header.
				if catcheck == item:getDisplayCategory() or echeck > 0 then
					if shiftX < 4 then
						shiftX = shiftX + 1;
					else
						shiftY = shiftY + 1;
						shiftX = 0;
					end
				end
				
				if catcheck ~= item:getDisplayCategory() then
					if echeck > 0 then
					else
						shiftY = shiftY + 1;
						shiftX = 0;
					end
				end

				local moveX = shiftX * itemSize
				local moveY = shiftY * itemSize

-- 			clicked/dragged item
				if self.selected [y + 1] ~= nil and not self.highlightItem then 
					if checkDraggedItems and self.draggedItems:cannotDropItem(item) then
					else
--	 		mouse select
						if not doDragged then
							self:drawRect(moveX + 4, moveY + 3, itemSize, itemSize, 0.1, 1.0, 1.0, 1.0);
							self:drawRectBorder(moveX + 3, moveY + 2, itemSize + 2, itemSize + 2, 1.0, 0.6, 0.3, 0);
							self:drawRectBorder(moveX + 4, moveY + 3, itemSize, itemSize, 0.7, 1.0, 1.0, 1.0);
						end
					end
-- 			mouse highlight
				elseif self.mouseOverOption == y + 1 and not self.highlightItem then -- called when you mose over an element
--			self:drawRect(moveX + 4, moveY + 3, itemSize*3, itemSize*3, 0.4, 0, 0, 0);
				else
					if count == 1 then 
							if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() ~= 1) or item:getItemHeat() ~= 1) then
								if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() > 1) or item:getItemHeat() > 1) then
										self:drawRect(moveX + 4, moveY + 3, itemSize, itemSize,  0.2, math.abs(item:getInvHeat()), 0.0, 0.0);
								else
										self:drawRect(moveX + 4, moveY + 3, itemSize, itemSize,  0.2, 0.0, 0.0, math.abs(item:getInvHeat()));
								end
							else
							end
					else
--			temperature highlight 
						if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() ~= 1) or item:getItemHeat() ~= 1) then
							if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() > 1) or item:getItemHeat() > 1) then
								self:drawRect(moveX + 4, moveY + 3, itemSize, itemSize,  0.2, math.abs(item:getInvHeat()), 0.0, 0.0);
							else
								self:drawRect(moveX + 4, moveY + 3, itemSize, itemSize,  0.2, 0.0, 0.0, math.abs(item:getInvHeat()));
							end
--			expanded items background
						else
							self:drawRect(moveX + 4, moveY + 4, itemSize, itemSize, 0.3, 0, 0, 0);
						end
					end
				end
				
				local tex = item:getTex();
				if tex ~= nil then
--			item icons
					if not doDragged then
						if self.mouseOverOption == y + 1 and not self.highlightItem then
							self:drawTextureScaled(self.itemHighlight, moveX-7, moveY-7, itemSize*1.5, itemSize*1.5, 0.3, 1, 1, 1);
						end
						if self.drawTired == false then
							ISInventoryItem.renderItemIcon(self, item, moveX + edgepx, moveY + edgepx, 1.0, 32, 32)
						else
							ISInventoryItem.renderItemIcon(self, item, moveX + edgepx-6, moveY + edgepx, 0.4, 32, 32)
							ISInventoryItem.renderItemIcon(self, item, moveX + edgepx+6, moveY + edgepx, 0.5, 32, 32)
						end
					else
					end
-- 			controller selection square
					if self.joyselection ~= nil and self.doController then
						if self.joyselection < 1 then self.joyselection = 1; end
						if self.joyselection == y + 1 then
							self.inventoryPage.nRow = shiftY + 1
							self:drawRect(moveX + 4, moveY + 3, itemSize, itemSize, 0.1, 1.0, 1.0, 1.0)
							self:drawRectBorder(moveX + 3, moveY + 2, itemSize + 2, itemSize + 2, 1.0, 0.6, 0.3, 0)
							self:drawRectBorder(moveX + 4, moveY + 3, itemSize, itemSize, 0.7, 1.0, 1.0, 1.0)
						end
					end
					if not self.hotbar then
						self.hotbar = getPlayerHotbar(self.player);
					end
--			corner icons
					local function drawMiniIcon(icon, x, y)
						self:drawTexture(icon, moveX + x, moveY + y, 1, 1, 1, 1);
					end
					if not doDragged then 
						if not player:isEquipped(item) and self.hotbar and self.hotbar:isInHotbar(item) then
							drawMiniIcon(self.equippedInHotbar, itemSize/2, 3)
						end
						if item:isBroken() then
							drawMiniIcon(self.brokenItemIcon, itemSize/2, 4)
						end
						if instanceof(item, "Food") and item:isFrozen() then
							drawMiniIcon(self.frozenItemIcon, itemSize-9, 5)
						end

						if instanceof(item, "Food") and(item:isTainted() and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue()) or player:isKnownPoison(item) or item:hasTag("ShowPoison") then
							drawMiniIcon(self.poisonIcon, 9, itemSize*0.7)
						end
						if item:hasComponent(ComponentType.FluidContainer) and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() and (not item:getFluidContainer():isEmpty()) and (item:getFluidContainer():contains(Fluid.Bleach) or (item:getFluidContainer():contains(Fluid.TaintedWater) and item:getFluidContainer():getPoisonRatio() > 0.1)) then
							drawMiniIcon(self.poisonIcon, 9, itemSize*0.7)
						end
						if (instanceof(item,"Literature") and
								((player:isLiteratureRead(item:getModData().literatureTitle)) or
								(SkillBook[item:getSkillTrained()] ~= nil and item:getMaxLevelTrained() < player:getPerkLevel(SkillBook[item:getSkillTrained()].perk) + 1) or
								(item:getNumberOfPages() > 0 and player:getAlreadyReadPages(item:getFullType()) == item:getNumberOfPages()) or
								(item:getTeachedRecipes() ~= nil and player:getKnownRecipes():containsAll(item:getTeachedRecipes())) or
								(item:getModData().teachedRecipe ~= nil and player:getKnownRecipes():contains(item:getModData().teachedRecipe)))) then
							drawMiniIcon(self.tickMark, itemSize/2+1, 2)
						end
						if item:isFavorite() then
							drawMiniIcon(self.favoriteStar, 7, itemSize-14)
						end
					end
				end

--			only one collapse 
				if count == 1 and v.count < 3 and not self.collapsed[v.name] then
					self.collapsed[v.name] = not self.collapsed[v.name]
				end
--			amount of one stack					
				if count == 1 and v.count > 2 then
					if not doDragged then
						local function drawAmount(x, y, color)
							self:drawTextRight("".. v.count - 1, moveX + itemSize + x, moveY + itemSize / 2 + y - 1, color, color, color, 1.0, self.font);
						end
						drawAmount(2, 0, 0)
						drawAmount(0, 2, 0)
						drawAmount(-2, 0, 0)
						drawAmount(0, -2, 0)
						drawAmount(0, 0, 0.8)
					end
				end

--			equipped background
				if v.equipped then
					if not equippedLine and not isDragging then
						self:drawRect(0, moveY + 4, self.width, self.height - moveY + self.headerHgt + 4, 0.1, 0, 0, 0);
					end
					equippedLine = true
				end
--			action in progress square
				if item:getJobDelta() > 0 and (count > 1 or self.collapsed[v.name]) then
					self:drawRect(moveX + 4, moveY + 4, itemSize, itemSize, 0.4, 0, 0, 0);
					self:drawRect(moveX + 4, (shiftY + 1)*itemSize + 4 + (item:getJobDelta()*-itemSize), itemSize, itemSize * item:getJobDelta(), 0.4, 0.4, 1.0, 0.3);
				end
--			keys no category
				if v.equipped and string.find(item:getName(), "Key Ring") ~= nil then
				else
					if count == 1 then
--			new category
						if catcheck ~= item:getDisplayCategory() then
							if not player:isEquipped(item) then
								if doDragged then
								elseif item:getDisplayCategory() then
									self:drawText(getText("IGUI_ItemCat_" .. item:getDisplayCategory()), self.column2, moveY+10, 1, 0.8, 0.7, 0.7, self.font);
								else
									self:drawText(getText("IGUI_ItemCat_" .. item:getCategory()), self.column2, moveY+10, 1, 0.8, 0.7, 0.7, self.font);
								end
								catcheck = item:getDisplayCategory()
								if shiftY > 0 then
									self:drawRect(0, moveY+3, self.width, 1, 0.1, 1, 1, 1);
								end
--			equipped category
							else
								if not isDragging then
									echeck = echeck + 1
									if echeck < 2 then
										self:drawRect(0, moveY+3, self.width, 1, 0.1, 1, 1, 1);
										self:drawText(getText("IGUI_ItemCat_Equipped"), self.column2, moveY+10, 1, 0.8, 0.7, 0.6, self.font);
									end
								end
							end
						end
					else
						local redDetail = false;
						self:drawItemDetails(item, y, xoff, yoff, redDetail);
					end
				end
				if self.selected ~= nil and self.selected[y+1] ~= nil then
					self:resumeStencil();
				end
			end
			y = y + 1;
			if count == 1 and self.collapsed ~= nil and v.name ~= nil and self.collapsed[v.name] then
				if instanceof(item, "Food") then
					for k3,v3 in ipairs(v.items) do
						v3:updateAge()
					end
				end
				break
			end
			if count == ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER + 1 then
				break
			end
			count = count + 1;
		end
end
--		select area rectangle
	if self.draggingMarquis then
		local w = self:getMouseX() - self.draggingMarquisX;
		local h = self:getMouseY() - self.draggingMarquisY;
		self:drawRectBorder(self.draggingMarquisX, self.draggingMarquisY, w, h, 1, 1, 0, 0);
	end
end

function ISInventoryPane:drawProgressBar(x, y, w, h, f, fg)
	if f < 0.0 then f = 0.0 end
	if f > 1.0 then f = 1.0 end
	local done = math.floor(w * f)
	if f > 0 then done = math.max(done, 1) end
	self:drawRect(x, y, done, h, fg.a, fg.r, fg.g, fg.b);
	local bg = {r=0.25, g=0.25, b=0.25, a=1.0};
	self:drawRect(x + done, y, w - done, h, bg.a, bg.r, bg.g, bg.b);
end

function ISInventoryPane:drawItemDetails(item, y, xoff, yoff, red)

	if item == nil then return; end

	local itemRow = 1
	for rowNumber, itemNumber in ipairs(self.grid.firstItem) do
		if itemNumber - (y + 1) <= 0 then
			itemRow = rowNumber
		end
	end
	local barShiftX = y - self.grid.firstItem[itemRow] + 1
	local barShiftY = itemRow
	
	local headerHeight = self.headerHgt
	local goodColor = getCore():getGoodHighlitedColor()
	local fgBar = {r=goodColor:getR(), g=goodColor:getG(), b=goodColor:getB(), a=0.5}
	local function drawSmallBar(currentLevel, color)
		self:drawRect(barShiftX*self.itemHgt + 7, barShiftY*self.itemHgt+headerHeight - 6, self.itemHgt - 6, 6, 1, 0.2, 0.2, 0.2);
		self:drawProgressBar(barShiftX*self.itemHgt + 9, barShiftY*self.itemHgt+headerHeight - 4, self.itemHgt - 10, 2, currentLevel, color)
	end
	if instanceof(item, "HandWeapon") then
		drawSmallBar(item:getCondition() / item:getConditionMax(), fgBar)
	elseif instanceof(item, "Drainable") then
		drawSmallBar(item:getCurrentUsesFloat(), fgBar)
	elseif item:getMeltingTime() > 0 then
		drawSmallBar(item:getMeltingTime(), fgBar)
	elseif instanceof(item, "Food") then
		if item:isIsCookable() and not item:isFrozen() and item:getHeat() > 1.6 then
			local badColor = getCore():getBadHighlitedColor()
			local ct = item:getCookingTime()
			local mtc = item:getMinutesToCook()
			local mtb = item:getMinutesToBurn()
			local f = ct / mtc;
			if ct > mtb then
			elseif ct > mtc then
				f = (ct - mtc) / (mtb - mtc);
				fgBar = {r=badColor:getR(), g=badColor:getG(), b=badColor:getB(), a=0.5}
			end	
			if item:isBurnt() then return end
			drawSmallBar(f, fgBar)
		elseif item:getFreezingTime() > 0 then
			local freezeColor = {r=0.6, g=0.9, b=1, a=1}
			drawSmallBar(item:getFreezingTime() / 100, freezeColor)
		else
			local hunger = item:getHungerChange();
			if(hunger ~= 0) then
				drawSmallBar((-hunger) / 1.0, fgBar)
			end
		end
   end
end

function ISInventoryPane:doWorldObjectHighlight(_item)
--	attempt to find the world item, if it doesn't exist we assume it's not on the floor
	if instanceof(_item, "InventoryItem") then
		local worldItem = _item:getWorldItem();
		if (worldItem and worldItem:getChunk() ~= nil) then
--			found the world item, highlight and keep track of it
			if not self.highlightItems[worldItem] then
				worldItem:setHighlighted(true);
			end;
			self.highlightItems[worldItem] = worldItem;
		end;

--		valid item is highlighted
		return true;
	end;

	return false;
end

function ISInventoryPane:clearWorldObjectHighlights()
	for worldItem in pairs(self.highlightItems) do
		if worldItem:getItem() ~= nil then
			worldItem:setHighlighted(false);
		end;
		self.highlightItems[worldItem] = nil;
	end;
end

function ISInventoryPane:findItemForWorldObjectHighlight(_itemTest)
	if _itemTest then
		if not instanceof(_itemTest, "InventoryItem") then
			if _itemTest.items then
				for _, item in ipairs(_itemTest.items) do
--					break on an invalid item
					if not self:doWorldObjectHighlight(item) then
						break;
					end;
				end;
			end;
		else
			self:doWorldObjectHighlight(_itemTest);
		end;
	end;
end

function ISInventoryPane:updateWorldObjectHighlight()
--	reset highlights
	self:clearWorldObjectHighlights();

--	controller selected
	if self.doController and self.joyselection ~= nil then
		self:findItemForWorldObjectHighlight(self.items[self.joyselection]);
	end;

--	selected (clicked or draggingMarquis)
	for _, item in ipairs(self.selected) do
		self:findItemForWorldObjectHighlight(item);
	end;

--	hovering mouse
	if self.mouseOverOption ~= 0 then
		self:findItemForWorldObjectHighlight(self.items[self.mouseOverOption]);
	end;
end

function ISInventoryPane:render()

	if self.mode == "icons" then
		self:rendericons();
	elseif self.mode == "details" then
		self:renderdetails(true);
	end

	self:clearStencilRect();

	local resize = self.nameHeader.resizing or self.nameHeader.mouseOverResize
	if not resize then
		resize = self.typeHeader.resizing or self.typeHeader.mouseOverResize
	end
	if resize then
		self:repaintStencilRect(self.nameHeader:getRight() - 1, self.nameHeader.y, 2, self.height)
		self:drawRectStatic(self.nameHeader:getRight() - 1, self.nameHeader.y, 2, self.height, 0.1, 1, 0, 0)
	end

	if self.someChange == true then
		self:makeItemsGrid()
		self.inventoryPage:autoResize()

		self.someChange = false
	end

	local playerObj = getSpecificPlayer(self.player)
	if playerObj:getHumanVisual():getBlood(BloodBodyPartType.FromIndex(9)) > 0.25 then
		self.drawBlood = true
	else
		self.drawBlood = false
	end
	
	if playerObj:getStats():getFatigue() > 0.8 then
		self.drawTired = true
	else
		self.drawTired = false
	end			

	self:updateWorldObjectHighlight();
end


function ISInventoryPane:makeItemsGrid()

	self.grid = {}
	self.grid.firstItem = {}
	self.grid.xCell = {}
	self.grid.yCell = {}

	local itemHeight = self.itemHgt
	local category = {previous = "", current = ""}
	local position = {x = 0, y = 0}

	for k, v in pairs(self.items) do

		if not v.equipped then
			if not v.items then
				category.current = (getText("IGUI_ItemCat_" .. v:getDisplayCategory()))
			else
				category.current = (getText("IGUI_ItemCat_" .. v.items[1]:getDisplayCategory()))
			end
		else
			category.current = "Equipped"
		end

-- 		no more space or new category >>> next line
		if category.current ~= category.previous or position.x > 4 then
			position.x = 1; position.y = position.y + 1; 
			category.previous = category.current
			table.insert(self.grid.firstItem, k)
		else
			position.x = position.x + 1;
		end

		table.insert(self.grid.xCell, position.x)
		table.insert(self.grid.yCell, position.y)
	end
end

function ISInventoryPane:drawTextAndProgressBar(text, fraction, xoff, top, fgText, fgBar)
end

function ISInventoryPane:rendericons()

end

function ISInventoryPane:hideButtons()
end

function ISInventoryPane:doButtons(y)
end

function ISInventoryPane:SaveLayout(name, layout)
end

function ISInventoryPane:RestoreLayout(name, layout)
	self:refreshContainer()
end

function ISInventoryPane:rowAt(x, y)
	local rowCount = math.floor((self:getScrollHeight() - self.headerHgt) / self.itemHgt)
	if rowCount > 0 then
		return math.floor((y) / self.itemHgt) + 1
	end
	return -1
end

function ISInventoryPane:topOfItem(index)
	local rowCount = math.floor((self:getScrollHeight() - self.headerHgt) / self.itemHgt)
	if rowCount > 0 then
		return (index - 1) * self.itemHgt
	end
	return -1
end

function ISInventoryPane:onResizeColumn(button)

end

function ISInventoryPane:onResize()
	ISPanel.onResize(self)
	self.width = self.inventoryPage.width + 1
	self.height = self.inventoryPage.height - self.inventoryPage.titleHeight - 60 + 1
end

function ISInventoryPane:setMode(mode)
end

function ISInventoryPane:onInventoryFontChanged()
	local font = getCore():getOptionInventoryFont()
	if font == "Large" then
		self.font = UIFont.Large
	elseif font == "Small" then
		self.font = UIFont.Small
	else
		self.font = UIFont.Medium
	end
	self.fontHgt = getTextManager():getFontFromEnum(self.font):getLineHeight()
	self.itemHgt = math.ceil(math.max(18, self.fontHgt) * self.zoom)
	self.texScale = math.min(32, (self.itemHgt - 2)) / 32

end

function ISInventoryPane:new (x, y, width, height, inventory, zoom)
	local o = {}
	o = ISPanel:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.x = x;
	o.y = y;

	o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
	o.backgroundColor = {r=0, g=0, b=0, a=0.5};
	o.width = width;
	o.height = height;
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = true;
	o.anchorBottom = false;
	o.inventory = inventory;
	o.zoom = zoom;
	o.mode = "details";

	o.items = {}
	o.selected = {}
	o.highlightItems = {}
	o.previousMouseUp = nil;
	local font = getCore():getOptionInventoryFont()
	if font == "Large" then
		o.font = UIFont.Large
	elseif font == "Small" then
		o.font = UIFont.Small
	else
		o.font = UIFont.Medium
	end
	if zoom > 1.5 then
		o.font = UIFont.Large;
	end
	o.fontHgt = getTextManager():getFontFromEnum(o.font):getLineHeight()
	o.itemHgt = math.ceil(math.max(18, o.fontHgt) * o.zoom)
	o.texScale = math.min(32, (o.itemHgt - 2)) / 32
	o.draggedItems = DraggedItems:new(o)
	o.column2 = o.itemHgt * 5 + 12;
	o.column3 = 230;
 	o.column4 = o.width;

	o.equippedItemIcon = getTexture("media/ui/icon.png");
	o.equippedInHotbar = getTexture("media/ui/iconInHotbar.png");
	o.brokenItemIcon = getTexture("media/ui/icon_broken.png");
	o.frozenItemIcon = getTexture("media/ui/icon_frozen.png");
	o.poisonIcon = getTexture("media/ui/SkullPoison.png");
	o.favoriteStar = getTexture("media/ui/FavoriteStar.png");
	o.tickMark = getTexture("media/ui/Tick_Mark-10.png")
	o.itemHighlight = getTexture("media/ui/inventoryPanes/Item_Highlight.png")
	o.bloodOverlay = getTexture("media/ui/inventoryPanes/Blood_Overlay.png")

	o.itemSortFunc = ISInventoryPane.itemSortByCatInc;
	
	o.drawTired = false
	o.drawBlood = false
	o.drawSadness = false
	o.countCollapsed = 0;
	o.someChange = true
	o.grid = {}

   return o
end
