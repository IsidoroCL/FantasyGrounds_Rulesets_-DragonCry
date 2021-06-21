-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Set the label to the correct value
	local shownode = nil;
	local nodename = getDatabaseNode().getName();
	if nodename == "a1-atwill" then
		label.setValue("At-Will");
	elseif nodename == "a0-situational" then
		label.setValue("Situational");
	elseif nodename == "a11-atwillspecial" then
		label.setValue("At-Will (Special)");
		shownode = NodeManager.createSafeChild(getDatabaseNode(), "...powershow.atwillspecial", "number");
	elseif nodename == "a2-cantrip" then
		label.setValue("Cantrips");
		shownode = NodeManager.createSafeChild(getDatabaseNode(), "...powershow.cantrip", "number");
	elseif nodename == "b1-encounter" then
		label.setValue("Encounter");
	elseif nodename == "b11-encounterspecial" then
		label.setValue("Encounter (Special)");
		shownode = NodeManager.createSafeChild(getDatabaseNode(), "...powershow.encounterspecial", "number");
	elseif nodename == "b2-channeldivinity" then
		label.setValue("Channel Divinity");
		shownode = NodeManager.createSafeChild(getDatabaseNode(), "...powershow.channeldivinity", "number");
	elseif nodename == "c-daily" then
		label.setValue("Daily");
	elseif nodename == "d-utility" then
		label.setValue("Utility");
	elseif nodename == "e-itemdaily" then
		label.setValue("Item (Daily)");
	end
	
	-- Check to see if these are potentially limited use power types
	if nodename == "b2-channeldivinity" or nodename == "c-daily" or nodename == "d-utility" or nodename == "e-itemdaily" then
		usesavailable.setVisible(true);
		availablelabel.setVisible(true);
	end

	-- If this is the last power type entry, then make sure the anti-jump spacer is on
	-- The spacer will prevent the list from jumping around when attack and detail sections are opened on a power
	if nodename == "e-itemdaily" then
		antijump_spacer.setVisible(true);
	end
	
	-- Set the icon to the correct value
	icon.setState(powerlist.isVisible());

	-- Notify of mode change to make sure everything is set up right
	if shownode then
		shownode.onUpdate = onShowChange;
		onShowChange(shownode);
	end
	
	-- Check limited use power types
	checkUseLimit();
end

function getUsesAvailable()
	return NodeManager.getSafeChildValue(getDatabaseNode(), "usesavailable", 0);
end

function getPowersUsed()
	local powersused = 0;
	for k,v in pairs(powerlist.getWindows()) do
		powersused = powersused + v.usedcounter.getValue();
	end
	return powersused;
end

function getAvailablePowerCount()
	-- Cycle through each power, counting the ones used and available
	local powercount = 0;
	local powerused = 0;
	for k,v in pairs(powerlist.getWindows()) do
		if v.usedcounter.getValue() < v.usedcounter.getMaxValue() then
			powercount = powercount + 1;
		end
		powerused = powerused + v.usedcounter.getValue();
	end
	
	-- If this is a limited use power type, then we have zero powers if we are over the uses available
	local nodename = getDatabaseNode().getName();
	if nodename == "b2-channeldivinity" or nodename == "c-daily" or nodename == "d-utility" or nodename == "e-itemdaily" then
		local max = getUsesAvailable();
		if max > 0 then
			if powerused >= max then
				powercount = 0;
			end
		end
	end
	
	-- Return the power count
	return powercount;
end

function onPowerClick()
	checkUseLimit();

	if NodeManager.getSafeChildValue(getDatabaseNode(), "...powermode", "standard") == "combat" then
		powerlist.applyFilter();
	end
end

function checkUseLimit()
	local count = getAvailablePowerCount();

	for k,v in pairs(powerlist.getWindows()) do
		if count > 0 then
			v.usedcounter.enable();
		else
			v.usedcounter.disable();
		end
	end
end

function onShowChange(source)
	-- Set the visibility based on the checkbox it is connected to
	setVisible(source.getValue());
end

function setVisible(value)
	if value == 1 or value == true then
		icon.setVisible(true);
		label.setVisible(true);
		powerlist.setVisible(true);
		
		local nodename = getDatabaseNode().getName();
		if nodename == "b2-channeldivinity" or nodename == "c-daily" or nodename == "d-utility" or nodename == "e-itemdaily" then
			usesavailable.setVisible(true);
			availablelabel.setVisible(true);
		end
	else
		icon.setVisible(false);
		label.setVisible(false);
		powerlist.setVisible(false);
		usesavailable.setVisible(false);
		availablelabel.setVisible(false);
	end
end

function onDrop(x, y, draginfo)
	return powerlist.onDrop(x, y, draginfo);
end

function forceActive()
	powerlist.setVisible(true);
	icon.setState(true);
	if shownode then
		shownode.setValue(1);
	end
end