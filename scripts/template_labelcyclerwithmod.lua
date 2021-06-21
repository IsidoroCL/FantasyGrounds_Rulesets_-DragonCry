-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

modifierWidget = nil;
modifierFieldNode = nil;

function getModifier()
	local val = 0;
	if modifierFieldNode then
		val = modifierFieldNode.getValue();
	end
	return val;
end

function setModifier(value)
	if modifierFieldNode then
		modifierFieldNode.setValue(value);
	end
end

function onWheel(notches)
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end
	
	if readonly then
		return false;
	end

	setModifier(getModifier() + notches);
	return true;
end

function onDrop(x, y, draginfo)
	if not readonly then
		if draginfo.getType() == "number" then
			setModifier(draginfo.getNumberData());
		end
	end
	return true;
end

function updateModifier()
	value = 0;
	if modifierFieldNode then
		value = tonumber(modifierFieldNode.getValue()) or 0;
	end
	
	if value > 0 then
		modifierWidget.setText("+" .. value);
	else
		modifierWidget.setText(value);
	end

	if value == 0 then
		modifierWidget.setVisible(false);
	else
		modifierWidget.setVisible(true);
	end
end

function onInit()
	super.onInit();

	modifierWidget = addTextWidget("sheetlabelsmall", "0");
	modifierWidget.setFrame("tempmodmini", 3, 1, 6, 3);
	modifierWidget.setPosition("topright", 1, 8);
	modifierWidget.setVisible(false);

	local modnodename = "";
	if sourcefields then
		if sourcefields[1].modnode then
			modnodename = sourcefields[1].modnode[1];
		end
	end
	
	if modnodename ~= "" then
		if readonly then
			modifierFieldNode = window.getDatabaseNode().getChild(modnodename);
		else
			modifierFieldNode = NodeManager.createSafeChild(window.getDatabaseNode(), modnodename, "number");
		end
		if modifierFieldNode then
			modifierFieldNode.onUpdate = updateModifier;
		end
	end

	updateModifier();
end
