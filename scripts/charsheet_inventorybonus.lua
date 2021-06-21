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
	source = window.getDatabaseNode().getChild("bonus");
	if source then
		enable(true);
	end
end
				
function setSourceValue(value)
	if source then
		source.setValue(value);
	end
end
				
function onInit()
	registerMenuItem("Delete number value", "delete", 4);

	--[[ Set up monitoring for the creation of the data node ]]
	window.getDatabaseNode().onChildAdded = checkSource;
	checkSource();
end

function update()
	setModifierDisplay(modifiernode.getValue());
end

function enable(state)
	if state then
		source = window.getDatabaseNode().createChild("bonus", "number");
		source.onDelete = onDelete;
		source.onUpdate = onUpdate;
		setValue(source.getValue());
	else
		source.delete();
		source = nil;
		setValue(0);
	end

	setVisible(state);
end

function onUpdate()
	if source then
		setValue(source.getValue());
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

function onDrag(button, x, y, draginfo)
	if window.dice then
		window.dice.onDrag(button, x, y, draginfo);
	end
	return true;
end

