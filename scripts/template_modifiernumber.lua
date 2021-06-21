-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local emptymodifierWidget = nil;
local modifierWidget = nil;
local modifierFieldNode = nil;

function getModifier()
	return modifierFieldNode.getValue();
end

function setModifier(value)
	modifierFieldNode.setValue(value);
end

function setModifierDisplay(value)
	if value > 0 then
		modifierWidget.setText("+" .. value);
	else
		modifierWidget.setText(value);
	end
	
	if value == 0 then
		modifierWidget.setVisible(false);
		if showemptywidget then
			emptymodifierWidget.setVisible(true);
		else
			emptymodifierWidget.setVisible(false);
		end
	else
		modifierWidget.setVisible(true);
		emptymodifierWidget.setVisible(false);
	end
end

function updateModifier(source)
	setModifierDisplay(modifierFieldNode.getValue());
end

function onInit()
	local widgetsize = "small";
	if modifiersize then
		widgetsize = modifiersize[1];
	end
	
	if widgetsize == "mini" then
		modifierWidget = addTextWidget("sheetlabelsmall", "0");
		modifierWidget.setFrame("tempmodmini", 3, 1, 6, 3);
		modifierWidget.setPosition("topright", 3, 1);
		modifierWidget.setVisible(false);
	else
		modifierWidget = addTextWidget("sheettextsmall", "0");
		modifierWidget.setFrame("tempmodsmall", 6, 3, 8, 5);
		modifierWidget.setPosition("topright", 0, 0);
		modifierWidget.setVisible(false);
	end
	
	emptymodifierWidget = addBitmapWidget("indicator_tempmod");
	emptymodifierWidget.setPosition("topright", 0, 0);
	
	-- By default, the modifier is in a field named based on the parent control.
	local modifierFieldName = getName() .. "modifier";
	if modifierfield then
		-- Use a <modifierfield> override
		modifierFieldName = modifierfield[1];
	end
	
	modifierFieldNode = NodeManager.createSafeChild(window.getDatabaseNode(), modifierFieldName, "number");
	modifierFieldNode.onUpdate = updateModifier;
	addSourceWithOp(modifierFieldName, "+");

	updateModifier(modifierFieldNode);

	super.onInit();
end

function onWheel(notches)
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end

	setModifier(getModifier() + notches);
	return true;
end

function onDrop(x, y, draginfo)
	if draginfo.getType() == "number" then
		setModifier(draginfo.getNumberData());
	end
	return true;
end
