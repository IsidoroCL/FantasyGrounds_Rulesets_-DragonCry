-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

enabled = true;

function onSortCompare(w1, w2)
	return w1.order.getValue() > w2.order.getValue();
end

function onInit()
	-- Register a menu item to create an attack entry
	registerMenuItem("Add Attack", "pointer", 2);
end

-- See if the user has requested another attack
function onMenuSelection(selection)
	if selection == 2 then
		createWindow();
	end
end

-- Check for an empty list, and make sure we have at least one entry
function checkForEmpty()
	if enabled then
		if #getWindows() == 0 then
			enabled = false;
			createWindow();
			enabled = true;
		end
	end
end

function clearAndDisableCheck()
	enabled = false;
	for k,v in pairs(getWindows()) do
		local node = v.getDatabaseNode();
		v.close();
		node.delete();
	end
end

function enableCheck()
	enabled = true;
	checkForEmpty();
end
