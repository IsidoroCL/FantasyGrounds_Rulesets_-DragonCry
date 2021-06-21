-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Create Item", "insert", 5);
end

function onSortCompare(w1, w2)
	local name1 = string.lower(w1.nivelarma.getValue());
	local name2 = string.lower(w2.nivelarma.getValue());
	local loc1 = string.lower(w1.Arma.getValue());
	local loc2 = string.lower(w2.Arma.getValue());

	-- Empty entries at the end of the list
	if name1 == "" then
		return true;
	elseif name2 == "" then
		return false;
	end
	
	-- Name comparison if both locations the same
	if loc1 == loc2 then
		return name1 > name2;
	end

	-- One is located in the other
	if loc1 == name2 then
		return true;
	end
	if loc2 == name1 then
		return false;
	end
	
	-- Different containers
	if loc1 == "" then
		return name1 > loc2;
	elseif loc2 == "" then
		return loc1 > name2;
	else
		return loc1 > loc2;
	end
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
