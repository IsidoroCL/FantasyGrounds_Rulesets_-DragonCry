-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Remove Effect", "deletepointer", 3);
end

function onMenuSelection(selection)
	if selection == 3 then
		windowlist.deleteChild(self, true);
	end
end

function onDrag(button, x, y, draginfo)
	if label.getValue() ~= "" then
		draginfo.setType("effect");
		draginfo.setDescription(label.getValue());
		draginfo.setStringData(label.getValue());
		
		draginfo.setSlot(2);
		draginfo.setStringData(getDatabaseNode().getNodeName());
	end

	return true;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("combattrackerentry") then
		if draginfo.getCustomData() == windowlist.window then
			source.setSource("");
		else
			source.setSource(draginfo.getCustomData().name.getValue());
			effectinit.setValue(draginfo.getCustomData().initresult.getValue());
		end
		return true;
	end
end

function getSave()
	local text = "Saving Throw";
	local save_mod = effectsavemod.getValue();
	local bonus = save_mod;

	local extra_str = "";
	if label.getValue() ~= "" then
		extra_str = extra_str .. "vs effect (" .. label.getValue() .. ")";
	end
	if save_mod ~= 0 then
		if extra_str ~= "" then
			extra_str = extra_str .. " ";
		end
		extra_str = extra_str .. "at ";
		if save_mod > 0 then
			extra_str = extra_str .. "+";
		end
		extra_str = extra_str .. save_mod;
	end

	if extra_str ~= "" then
		text = text .. " [" .. extra_str .. "]";
	end

	bonus = bonus + windowlist.window.save.getValue();

	return text, bonus;
end
