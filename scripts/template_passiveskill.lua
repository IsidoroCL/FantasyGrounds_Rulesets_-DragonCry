-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

skillnodename = nil;

function onInit()
	-- Get any custom fields
	local skillname = "";
	local statnodename = "";
	if sourcefields then
		if sourcefields[1].skillname then
			skillname = sourcefields[1].skillname[1];
		end
		if sourcefields[1].statnodename then
			statnodename = sourcefields[1].statnodename[1];
		end
	end

	-- If we have a skill name, then find or create a skill node
	if skillname ~= "" then
		local listnode = NodeManager.createSafeChild(window.getDatabaseNode(), "skilllist");
		if listnode then
			-- First, look for an existing skill node
			local skilllist = listnode.getChildren();
			for k,v in pairs(skilllist) do
				local name = NodeManager.getSafeChildValue(v, "label", "");
				if name == skillname then
					skillnodename = v.getName();
					break;
				end
			end
			
			-- Or else, create a new skill node
			if not skillnodename then
				local skillnode = NodeManager.createSafeChild(listnode);
				if skillnode then
					skillnodename = skillnode.getName();

					NodeManager.setSafeChildValue(skillnode, "label", "string", skillname);
					NodeManager.setSafeChildValue(skillnode, "trained", "number", 0);
					NodeManager.setSafeChildValue(skillnode, "misc", "number", 0);
				end
			end
		end
	end

	-- Add the sources for this field to the watch list
	addSourceWithOp("levelbonus", "+");
	if statnodename == "strength" or statnodename == "dexterity" or statnodename == "constitution"  or statnodename == "intelligence" or statnodename == "wisdom"  or statnodename == "charisma" then
		addSourceWithOp("abilities." .. statnodename .. ".bonus", "+");
	end
	if skillnodename then
		addSource("skilllist." .. skillnodename .. ".trained");
		addSourceWithOp("skilllist." .. skillnodename .. ".misc", "+");
	end

	-- Call the default linkednumber init handler to make sure the field adds up correctly
	super.onInit();
end

function onSourceUpdate()
	local val = 10 + calculateSources();

	if skillnodename then
		local trainedval = NodeManager.getSafeChildValue(window.getDatabaseNode(), "skilllist." .. skillnodename .. ".trained", 0);
		if trainedval == 1 then
			val = val + 5;
		end
	end

	setValue(val);
end

function onDoubleClick(x,y)
	local skillname = "";
	if sourcefields then
		if sourcefields[1].skillname then
			skillname = sourcefields[1].skillname[1];
		end
	end

	ChatManager.DoubleClickAction("dice", calculateSources(), "Skill [" .. skillname .. "]", {pc = window.getDatabaseNode()});
	return true;
end			
				
