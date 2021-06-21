-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onSortCompare(w1, w2)
	return w1.name.getValue() > w2.name.getValue();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local class, datasource = draginfo.getShortcutData();
		local source = draginfo.getDatabaseNode();

		if source and class == "referencemagicitem" then
			local newnode = NodeManager.copyNode(source, getDatabaseNode(), true);

			-- Set the magic item type
			local itemclass = NodeManager.getSafeChildValue(newnode, "class", "");
			local itemtype = "other";
			if itemclass == "Weapon" or itemclass == "Implement" then
				itemtype = "weapon";
			elseif itemclass == "Armor" then
				itemtype = "armor";
			end
			NodeManager.setSafeChildValue(newnode, "mitype", "string", itemtype);
		end

		return true;
	end
end
