-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		registerMenuItem("Delete Item", "delete", 6);
	end
end

function onMenuSelection(selection)
	if selection == 6 then
		getDatabaseNode().delete();
	end
end

function getShortString()
	-- Include the power name
	local str = "Item Power [" .. NodeManager.getSafeChildValue(getDatabaseNode(), "...name", "") .. "]";
	
	-- Add in the action requirement
	local actval = string.lower(NodeManager.getSafeChildValue(getDatabaseNode(), "action", ""));
	if actval == "minor" or actval == "minor action" then
		str = str .. " [min]";
	elseif actval == "move" or actval == "move action" then
		str = str .. " [mov]";
	elseif actval == "standard" or actval == "standard action" then
		str = str .. " [std]";
	elseif actval == "free" or actval == "free action" then
		str = str .. " [free]";
	elseif actval == "interrupt" or actval == "immediate interrupt" then
		str = str .. " [imm]";
	elseif actval == "reaction" or actval == "immediate reaction" then
		str = str .. " [imm]";
	end

	-- Return the short string
	return str;
end

function getFullString()
	-- Start with the short string
	local str = getShortString();

	-- Add everything else in the notes
	local shortdesc = NodeManager.getSafeChildValue(getDatabaseNode(), "shortdescription", "");
	if shortdesc == "-" then
		shortdesc = "";
	end
	if shortdesc ~= "" then
		str = str .. " -> " .. shortdesc;
	end

	-- Return the full string
	return str;
end

function activatePower(showfullstr)
	local desc = "";
	if showfullstr == true then
		desc = getFullString();
	else
		desc = getShortString();
	end
	ChatManager.Message(desc, true, {pc = getDatabaseNode().getParent().getParent().getParent().getParent()});
end
