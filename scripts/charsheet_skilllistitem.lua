-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

iscustom = true;
sets = {};

function onInit()
	setRadialDeleteOption();

	onStatNameUpdate();
end

function onMenuSelection(item)
	if item == 6 then
		getDatabaseNode().delete();
	end
end

function onStatNameUpdate()
	stat.onStatNameUpdate(statlabel.getSourceValue());
end

-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
function setCustom(state)
	iscustom = state;
	
	if not iscustom then
		label.setEnabled(false);
		label.setFrame(nil);
		
		statlabel.setStateFrame("hover", nil);
		statlabel.lockCycle(true);
	end
	
	setRadialDeleteOption();
end

function setRadialDeleteOption()
	resetMenuItems();

	if iscustom then
		registerMenuItem("Delete", "delete", 6);
	end
end

