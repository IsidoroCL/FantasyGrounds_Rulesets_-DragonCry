-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20
--
-- For information on the Fantasy Grounds d20 Ruleset licensing and
-- the OGL license text, see the d20 ruleset license in the program
-- options.
--
-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above licenses, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.
--
-- Copyright 2007 SmiteWorks Ltd.

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
	if getDatabaseNode().isStatic() then
		applySort();
	else
		if #getWindows() == 0 then
			createWindow();
		end
	end
end

function onEnter()
	if not getDatabaseNode().isStatic() then
		local new = createWindow();
		new.name.setFocus();
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
		if class == "powerdesc" then
			addPower(draginfo);
		end
		return true;
	end
end

function addPower(draginfo)
	local sourcenode = draginfo.getDatabaseNode();
	
	local newwin = createWindow();

	local srcvalnode = sourcenode.getChild("name");
	local srcvalue = "";
	if srcvalnode then
		srcvalue = srcvalnode.getValue();
	end
	newwin.name.setValue(srcvalue);

	srcvalnode = sourcenode.getChild("recharge");
	srcvalue = "-";
	if srcvalnode then
		srcvalue = srcvalnode.getValue();
	end
	newwin.recharge.setValue(srcvalue);

	srcvalnode = sourcenode.getChild("action");
	srcvalue = "-";
	if srcvalnode then
		srcvalue = srcvalnode.getValue();
	end
	if srcvalue == "Standard Action" then
		newwin.action.setValue("Standard");
	elseif srcvalue == "Move Action" then
		newwin.action.setValue("Move");
	elseif srcvalue == "Minor Action" then
		newwin.action.setValue("Minor");
	elseif srcvalue == "Free Action" then
		newwin.action.setValue("Free");
	elseif srcvalue == "Immediate Interrupt" then
		newwin.action.setValue("Interrupt");
	elseif srcvalue == "Immediate Reaction" then
		newwin.action.setValue("Reaction");
	else
		newwin.action.setValue(srcvalue);
	end
	
	srcvalnode = sourcenode.getChild("range");
	srcvalue = "-";
	if srcvalnode then
		srcvalue = srcvalnode.getValue();
	end
	newwin.range.setValue(srcvalue);
	srcvalue = string.lower(srcvalue);
	if string.find(srcvalue, "melee") then
		newwin.powertype.setSourceValue("M");
	elseif string.find(srcvalue, "ranged") then
		newwin.powertype.setSourceValue("R");
	elseif string.find(srcvalue, "close") then
		newwin.powertype.setSourceValue("C");
	elseif string.find(srcvalue, "area") then
		newwin.powertype.setSourceValue("A");
	end

	srcvalnode = sourcenode.getChild("keywords");
	srcvalue = "-";
	if srcvalnode then
		srcvalue = srcvalnode.getValue();
	end
	newwin.keywords.setValue(srcvalue);

	srcvalnode = sourcenode.getChild("shortdescription");
	srcvalue = "-";
	if srcvalnode then
		srcvalue = srcvalnode.getValue();
	end
	
	-- Space savers
	local tempstr = srcvalue;
	tempstr = string.gsub(tempstr, "vs. Fortitude", "vs. Fort");
	tempstr = string.gsub(tempstr, "vs. Reflex", "vs. Ref");
	tempstr = string.gsub(tempstr, "Strength vs.", "STR vs.");
	tempstr = string.gsub(tempstr, "Constitution vs.", "CON vs.");
	tempstr = string.gsub(tempstr, "Dexterity vs.", "DEX vs.");
	tempstr = string.gsub(tempstr, "Intelligence vs.", "INT vs.");
	tempstr = string.gsub(tempstr, "Wisdom vs.", "WIS vs.");
	tempstr = string.gsub(tempstr, "Charisma vs.", "CHA vs.");
	tempstr = string.gsub(tempstr, "Strength modifier", "STR");
	tempstr = string.gsub(tempstr, "Constitution modifier", "CON");
	tempstr = string.gsub(tempstr, "Dexterity modifier", "DEX");
	tempstr = string.gsub(tempstr, "Intelligence modifier", "INT");
	tempstr = string.gsub(tempstr, "Wisdom modifier", "WIS");
	tempstr = string.gsub(tempstr, "Charisma modifier", "CHA");

	newwin.shortdescription.setValue(tempstr);

end
