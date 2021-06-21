-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function addMIWeapon(source)
	-- Add the data to the magic item
	local statwindow = window.getDatabaseNode()

	NodeManager.setSafeChildValue(statwindow, "damage", "string", NodeManager.getSafeChildValue(source, "damage", "") .. " damage");
	NodeManager.setSafeChildValue(statwindow, "profbonus", "number", NodeManager.getSafeChildValue(source, "profbonus", 0));
	NodeManager.setSafeChildValue(statwindow, "weight", "number", NodeManager.getSafeChildValue(source, "weight", 0));
	NodeManager.setSafeChildValue(statwindow, "range", "number", NodeManager.getSafeChildValue(source, "range", 0));
	NodeManager.setSafeChildValue(statwindow, "group", "string", NodeManager.getSafeChildValue(source, "group", ""));
	NodeManager.setSafeChildValue(statwindow, "properties", "string", NodeManager.getSafeChildValue(source, "properties", ""));
	NodeManager.setSafeChildValue(statwindow, "type", "string", NodeManager.getSafeChildValue(source, "type", ""));
	
	local srcname = NodeManager.getSafeChildValue(source, "name", "");
	local dstname = NodeManager.getSafeChildValue(statwindow, "name", "");
	dstname = string.gsub(dstname, " Weapon ", " " .. srcname .. " ");
	NodeManager.setSafeChildValue(statwindow, "name", "string", dstname);
end

function addMIArmor(source)
	-- Add the data to the magic item
	local statwindow = window.getDatabaseNode()

	NodeManager.setSafeChildValue(statwindow, "ac", "number", NodeManager.getSafeChildValue(source, "ac", 0));
	NodeManager.setSafeChildValue(statwindow, "min_enhance", "number", NodeManager.getSafeChildValue(source, "min_enhance", 0));
	NodeManager.setSafeChildValue(statwindow, "weight", "number", NodeManager.getSafeChildValue(source, "weight", 0));
	NodeManager.setSafeChildValue(statwindow, "checkpenalty", "number", NodeManager.getSafeChildValue(source, "checkpenalty", 0));
	NodeManager.setSafeChildValue(statwindow, "speed", "number", NodeManager.getSafeChildValue(source, "speed", 0));
	NodeManager.setSafeChildValue(statwindow, "type", "string", NodeManager.getSafeChildValue(source, "type", ""));
	
	local srcname = NodeManager.getSafeChildValue(source, "name", "");
	local dstname = NodeManager.getSafeChildValue(statwindow, "name", "");
	dstname = string.gsub(dstname, " Armor ", " " .. srcname .. " ");
	NodeManager.setSafeChildValue(statwindow, "name", "string", dstname);
end

function addMIEquipment(source)
	-- Add the data to the magic item
	local statwindow = window.getDatabaseNode()

	NodeManager.setSafeChildValue(statwindow, "weight", "number", NodeManager.getSafeChildValue(source, "weight", 0));
end

function onDrop(x, y, draginfo)
	if User.isHost() then
		if draginfo.isType("shortcut") then
			local class, datasource = draginfo.getShortcutData();
			local source = draginfo.getDatabaseNode();

			if source then
				if class == "referenceweapon" then
					addMIWeapon(source);
				elseif class == "referencearmor" then
					addMIArmor(source);
				elseif class == "referenceequipment" then
					addMIEquipment(source);
				end
			end

			return true;
		end
	end
end

