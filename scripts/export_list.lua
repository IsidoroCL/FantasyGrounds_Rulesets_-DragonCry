-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

entrymap = {};

function addCategories()
	local w = NodeManager.createSafeWindow(self);
	w.setExportName("encounter");
	w.setExportClass("encounter");
	w.label.setValue("Story");
	
	w = NodeManager.createSafeWindow(self);
	w.setExportName("image");
	w.setExportClass("imagewindow");
	w.label.setValue("Images & Maps");
	
	w = NodeManager.createSafeWindow(self);
	w.setExportName("battle");
	w.setExportClass("battle");
	w.label.setValue("Encounters");
	
	w = NodeManager.createSafeWindow(self);
	w.setExportName("npc");
	w.setExportClass("npc");
	w.label.setValue("Personalities");
	
	w = NodeManager.createSafeWindow(self);
	w.setExportName("item");
	w.setExportClass("item");
	w.label.setValue("Items");
end

function onInit()
	getNextWindow(nil).close();

	addCategories();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		for k,v in ipairs(getWindows()) do
			local class, recordname = draginfo.getShortcutData();
		
			-- Find matching export category
			if string.find(recordname, v.exportsource) == 1 then
				-- Check duplicates
				for l,c in ipairs(v.entries.getWindows()) do
					if c.getDatabaseNode().getNodeName() == recordname then
						return true;
					end
				end
			
				-- Create entry
				local w = v.entries.createWindow(draginfo.getDatabaseNode());
				w.open.setValue(class, recordname);
				
				v.all.setState(false);
				break;
			end
		end
		
		return true;
	end
end
