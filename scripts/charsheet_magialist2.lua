-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Create Item", "insert", 5);
end


function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local link = draginfo.getShortcutData();
		local sourcenode = draginfo.getDatabaseNode();
		
		if link == "powerdesc" then
			CharSheetCommon.addPowerToWeaponDB(window.getDatabaseNode(), sourcenode);
			return true;
		elseif link == "referenceweapon" then
			CharSheetCommon.addItemDB(window.getDatabaseNode(), sourcenode, link);
			return true;
		elseif link == "referenceequipment" then
			local itemtype = sourcenode.getChild("type").getValue();
			if itemtype == "Implement" then
				CharSheetCommon.addItemDB(window.getDatabaseNode(), sourcenode, link);
				return true;
			end
		elseif link == "referencemagicitem" or link == "item" then
			local itemclass = NodeManager.getSafeChildValue(sourcenode, "class", "");
			if itemclass == "Weapon" or itemclass == "Implement" then
				CharSheetCommon.addItemDB(window.getDatabaseNode(), draginfo.getDatabaseNode(), link);
				return true;
			end
		end
	end
end
