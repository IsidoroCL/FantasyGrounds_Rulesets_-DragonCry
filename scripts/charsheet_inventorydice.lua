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

function checkSource()
	source = window.getDatabaseNode().getChild("dice");
	if source then
		enable(true);
	end
end
				
function setSourceValue(value)
	local dietypetable = {};

	--[[ Allow both dragdata style and database style die lists ]]
	for k,v in ipairs(value) do
		if type(v) == "table" then
			table.insert(dietypetable, v.type);
		else
			table.insert(dietypetable, v);
		end
	end

	if source then
		source.setValue(dietypetable);
	end
end

function onInit()
	registerMenuItem("Delete dice", "delete", 4);
					
	--[[ Set up monitoring for the creation of the data node ]]
	window.getDatabaseNode().onChildAdded = checkSource;
	checkSource();
end

function enable(state)
	if state then
		source = window.getDatabaseNode().createChild("dice", "dice");
		source.onDelete = onDelete;
		source.onUpdate = onUpdate;
		setDice(source.getValue());
	else
		source.delete();
		source = nil;
	end

	setVisible(state);
end

function onUpdate()
	if source then
		setDice(source.getValue());
	end
end
			
function onValueChanged()
	if source then
		source.setValue(getValue());
	end
end

function onDelete()
	source = nil;
	setVisible(false);
end
				
function onMenuSelection(selection)
	if selection == 4 then
		enable(false);
	end
end

function getDescriptionString()
	local desc = "Item [" .. window.name.getValue() .. "]";
	return desc;
end

function onDrag(button, x, y, draginfo)
	if source then
		draginfo.setType("dice");
		draginfo.setDescription(getDescriptionString());
		draginfo.setDieList(getDice());
		draginfo.setNumberData(window.bonus.getValue());
		draginfo.setShortcutData("charsheet", window.getDatabaseNode().getParent().getParent().getNodeName());
		return true;
	end
end

function onDoubleClick(x,y)
	if source then
		ChatManager.DoubleClickDieControl("dice", window.bonus.getValue(), getDescriptionString(), {pc = window.getDatabaseNode().getParent().getParent()}, getDice());
		return true;
	end
end			
