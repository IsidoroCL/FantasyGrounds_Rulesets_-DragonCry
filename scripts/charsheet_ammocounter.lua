-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20
--
-- For information on the Fantasy Grounds d20 Ruleset licensing and
-- the OGL license text, see the d20 ruleset license in the program
-- options.
--
-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above licenses, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.
--
-- Copyright 2007 SmiteWorks Ltd.


slots = {};

maxnode = nil;
countnode = nil;

function updateSlots()
	-- Clear
	for k, v in ipairs(slots) do
		v.destroy();
	end
	
	slots = {};

	-- Construct based on values
	local m = maxnode.getValue();
	local c = countnode.getValue();

	local col = 0;
	local row = 0;

	for i = 1, m do
		local widget = nil;

		if i <= c then
			widget = addBitmapWidget(stateicons[1].on[1]);
		else
			widget = addBitmapWidget(stateicons[1].off[1]);
		end

		local posx = spacing[1].horizontal[1] * (col+0.5);
		local posy = spacing[1].vertical[1] * (row+0.5);
		widget.setPosition("topleft", posx, posy);
		
		row = row + 1;
		if row >= tonumber(slotcount[1].vertical[1]) then
			row = 0;
			col = col + 1;
		end
		
		slots[i] = widget;
	end
	
	if minisheet then
		window.windowlist.applyFilter();
	end
end

function getSlotState(x, y)
	local m = maxnode.getValue();
	local c = countnode.getValue();

	local col = 0;
	local row = 0;
	
	local state = false;

	for i = 1, m do
		local widget = nil;

		if i <= c then
			state = true;
		else
			state = false;
		end

		local posx = spacing[1].horizontal[1] * col;
		local posy = spacing[1].vertical[1] * row;

		if x > posx and x < posx + spacing[1].horizontal[1] and
		   y > posy and y < posy + spacing[1].vertical[1] then
			return state;
		end
		
		row = row + 1;
		if row >= tonumber(slotcount[1].vertical[1]) then
			row = 0;
			col = col + 1;
		end
	end
	
	return state;
end

function checkBounds()
	if countnode.getValue() > maxnode.getValue() then
		countnode.setValue(maxnode.getValue());
	elseif countnode.getValue() < 0 then
		countnode.setValue(0);
	end
end

function onWheel(notches)
	if OptionsManager.isMouseWheelEditEnabled() then
		countnode.setValue(countnode.getValue() + notches);
		checkBounds();
		updateSlots();
		return true;
	end
end

function onClickDown(button, x, y)
	if button == 2 then
		countnode.setValue(0);
	else
		if not getSlotState(x, y) then
			countnode.setValue(countnode.getValue() + 1);
		else
			countnode.setValue(countnode.getValue() - 1);
		end
		checkBounds();
	end
	
	updateSlots();
	return true;
end

function onMenuSelection(...)
	countnode.setValue(0);
	updateSlots();
end

function onInit()
	registerMenuItem("Clear", "erase", 4);
	
	maxnode = window.getDatabaseNode().createChild(fields[1].max[1], "number");
	countnode = window.getDatabaseNode().createChild(fields[1].count[1], "number");
	
	maxnode.onUpdate = updateSlots;
	countnode.onUpdate = updateSlots;
	
	updateSlots();
end