-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function updateEncumbrance()
	local encumbrancetotal = 0;

	for k, w in pairs(getWindows()) do
		
		encumbrancetotal = encumbrancetotal + w.weight.getValue();
		
	end
	
	if window.TOTALload3 then						
		window.TOTALload3.setValue(encumbrancetotal);
	end
		
end

function onSortCompare(w1, w2)
	local nombreI1 = string.lower(w1.nombreI.getValue());
	local nombreI2 = string.lower(w2.nombreI.getValue());
	
	-- Empty entries at the end of the list
	if nombreI1 == "" then
		return true;
	elseif nombreI2 == "" then
		return false;
	end
	
	
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local link = draginfo.getShortcutData();
		local sourcenode = draginfo.getDatabaseNode();
		
		if link == "referencearmor" or link == "referenceweapon" or link == "referenceequipment" or link == "item" or link == "referencemagicitem" then
			CharSheetCommon.addItemDB(window.getDatabaseNode(), sourcenode, link);
			return true;
		end
	end
end

function onInit()
	updateEncumbrance();
end
