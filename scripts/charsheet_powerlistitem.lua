-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Get the power type name
	local nodename = getDatabaseNode().getParent().getParent().getName();
	
	-- Determine which buttons to show
	if nodename == "a0-situational" or nodename == "a1-atwill" or nodename == "a2-cantrip" then
		usedcounter.setVisible(false);
	else
		useatwill.setVisible(false);
		name.setAnchor("left", "usedcounter", "right", "absolute", 17);
	end
	
	local rechargeval = recharge.getValue() or "";
	if rechargeval == "" then
		if nodename == "a0-situational" then
			recharge.setValue("-");
		elseif nodename == "a1-atwill" or nodename == "a2-cantrip" then
			recharge.setValue("At-Will");
		elseif nodename == "a11-atwillspecial" then
			recharge.setValue("At-Will (Special)");
		elseif nodename == "b1-encounter" or nodename == "b2-channeldivinity" then
			recharge.setValue("Encounter");
		elseif nodename == "b11-encounterspecial" then
			recharge.setValue("Encounter (Special)");
		elseif nodename == "c-daily" or nodename == "e-itemdaily" then
			recharge.setValue("Daily");
		end
	end
	
	local namevalue = name.getValue() or "";
	if namevalue == "" then
		activatedetail.setValue(true);
	end
	
	-- Update the power display
	toggleAttack();
	toggleDetail();
	
	-- Build our own delete item menu
	registerMenuItem("Delete Item", "delete", 6);
end

function onMenuSelection(selection)
	if selection == 6 then
		if windowlist.onCheckDeletePermission(self) then
			attacks.reset(false);
			effects.reset(false);
			
			windowlist.deleteChild(self, false);
		end
	end
end

function getShortString()
	-- Include the power name
	local str = "Power [" .. name.getValue() .. "]";
	
	-- Add in the action requirement
	local actval = string.lower(action.getValue());
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
		str = str .. " - " .. shortdesc;
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

function setSpacerState()
	if activatedetail.getValue() or activateattack.getValue() then
		spacer.setVisible(true);
	else
		spacer.setVisible(false);
	end
end

function toggleAttack()
	local status = activateattack.getValue();

	-- Make the attack list visible
	attackicon.setVisible(status);
	attacks.setVisible(status);

	-- Make the effect list visible
	effecticon.setVisible(status);
	effects.setVisible(status);

	-- NOTE: Disabled, since it causes infinite loop when powerlistitem deleted after drop when client connected
	--attacks.checkForEmpty();
	--effects.checkForEmpty();

	-- Update the individual attack windows based on the type of power
	for k, w in pairs(attacks.getWindows()) do
		w.updateDisplay();
	end
	
	-- Set the spacer visibility to match
	setSpacerState();
end

function toggleDetail()
	local status = activatedetail.getValue();

	-- Show the power details
	action.setVisible(status);
	recharge.setVisible(status);
	keywords.setVisible(status);
	range.setVisible(status);
	shortdescription.setVisible(status);
	
	-- Set the spacer visibility to match
	setSpacerState();
end
