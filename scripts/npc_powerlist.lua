-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onSortCompare(w1, w2)
	local name1 = w1.getDatabaseNode().getNodeName();
	local name2 = w2.getDatabaseNode().getNodeName();

	if name1 == "" then
		return true;
	elseif name2 == "" then
		return false;
	else
		return name1 > name2;
	end
end

function onInit()
	if not getDatabaseNode().isStatic() then
		if not getNextWindow(nil) then
			NodeManager.createSafeWindow(self);
		end
	end
	
	applySort();
end

function onEnter()
	if not getDatabaseNode().isStatic() then
		local wnd = NodeManager.createSafeWindow(self);
		if wnd then
			wnd.name.setFocus();
		end
	end
end

function sizeChanged()
	for k,v in pairs(getWindows()) do
		v.sizeChanged();
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local class = draginfo.getShortcutData();
		if class == "powerdesc" or class == "reference_npcaltpower" then
			addPower(draginfo.getDatabaseNode());
		end
		return true;
	end
end

function addPower(sourcenode)
	-- Parameter validation
	if not sourcenode then
		return;
	end

	-- Create the new power window, and set up the fields
	local wnd = NodeManager.createSafeWindow(self);
	if not wnd then
		return;
	end

	wnd.name.setValue(NodeManager.getSafeChildValue(sourcenode, "name", ""));
	wnd.recharge.setValue(NodeManager.getSafeChildValue(sourcenode, "recharge", "-"));
	wnd.keywords.setValue(NodeManager.getSafeChildValue(sourcenode, "keywords", "-"));

	-- Get action required, and apply space savers
	local srcvalue = NodeManager.getSafeChildValue(sourcenode, "action", "-");
	if srcvalue == "Standard Action" then
		wnd.action.setValue("Standard");
	elseif srcvalue == "Move Action" then
		wnd.action.setValue("Move");
	elseif srcvalue == "Minor Action" then
		wnd.action.setValue("Minor");
	elseif srcvalue == "Free Action" then
		wnd.action.setValue("Free");
	elseif srcvalue == "Immediate Interrupt" then
		wnd.action.setValue("Interrupt");
	elseif srcvalue == "Immediate Reaction" then
		wnd.action.setValue("Reaction");
	else
		wnd.action.setValue(srcvalue);
	end
	
	-- Get range, and determine icon to show also
	srcvalue = NodeManager.getSafeChildValue(sourcenode, "range", "-");
	wnd.range.setValue(srcvalue);
	srcvalue = string.lower(srcvalue);
	if string.match(srcvalue, "melee") then
		wnd.powertype.setSourceValue("M");
	elseif string.match(srcvalue, "ranged") then
		wnd.powertype.setSourceValue("R");
	elseif string.match(srcvalue, "close") then
		wnd.powertype.setSourceValue("C");
	elseif string.match(srcvalue, "area") then
		wnd.powertype.setSourceValue("A");
	else
		wnd.powertype.setSourceValue("X");
	end

	-- Get description, and apply space savers
	srcvalue = NodeManager.getSafeChildValue(sourcenode, "shortdescription", "-");
	srcvalue = string.gsub(srcvalue, "vs. Fortitude", "vs. Fort");
	srcvalue = string.gsub(srcvalue, "vs. Reflex", "vs. Ref");
	srcvalue = string.gsub(srcvalue, "Strength vs.", "STR vs.");
	srcvalue = string.gsub(srcvalue, "Constitution vs.", "CON vs.");
	srcvalue = string.gsub(srcvalue, "Dexterity vs.", "DEX vs.");
	srcvalue = string.gsub(srcvalue, "Intelligence vs.", "INT vs.");
	srcvalue = string.gsub(srcvalue, "Wisdom vs.", "WIS vs.");
	srcvalue = string.gsub(srcvalue, "Charisma vs.", "CHA vs.");
	srcvalue = string.gsub(srcvalue, "Strength modifier", "STR");
	srcvalue = string.gsub(srcvalue, "Constitution modifier", "CON");
	srcvalue = string.gsub(srcvalue, "Dexterity modifier", "DEX");
	srcvalue = string.gsub(srcvalue, "Intelligence modifier", "INT");
	srcvalue = string.gsub(srcvalue, "Wisdom modifier", "WIS");
	srcvalue = string.gsub(srcvalue, "Charisma modifier", "CHA");
	srcvalue = string.gsub(srcvalue, "\r", "");
	wnd.shortdescription.setValue(srcvalue);
	
	-- Check to see if there are any linked powers
	if sourcenode.getChild("linkedpowers") then
		for k,v in pairs(sourcenode.getChild("linkedpowers").getChildren()) do
			local powerclass, powernodename = v.getChild("link").getValue();
			if powerclass == "powerdesc" then
				addPower(DB.findNode(powernodename));
			end
		end
	elseif sourcenode.getChild("link") then
		local powerclass, powernodename = sourcenode.getChild("link").getValue();
		if powerclass == "powerdesc" then
			addPower(DB.findNode(powernodename));
		end
	end
end
