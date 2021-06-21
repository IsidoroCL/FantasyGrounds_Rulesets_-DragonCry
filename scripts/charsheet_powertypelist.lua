-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	NodeManager.createSafeChild(getDatabaseNode(), "a0-situational");
	NodeManager.createSafeChild(getDatabaseNode(), "a1-atwill");
	NodeManager.createSafeChild(getDatabaseNode(), "a11-atwillspecial");
	NodeManager.createSafeChild(getDatabaseNode(), "a2-cantrip");
	NodeManager.createSafeChild(getDatabaseNode(), "b1-encounter");
	NodeManager.createSafeChild(getDatabaseNode(), "b11-encounterspecial");
	NodeManager.createSafeChild(getDatabaseNode(), "b2-channeldivinity");
	NodeManager.createSafeChild(getDatabaseNode(), "c-daily");
	NodeManager.createSafeChild(getDatabaseNode(), "d-utility");
	NodeManager.createSafeChild(getDatabaseNode(), "e-itemdaily");
	
	CharSheetCommon.checkForSecondWind(window.getDatabaseNode());
end

function onSortCompare(w1, w2)
	local name1 = w1.getDatabaseNode().getName();
	local name2 = w2.getDatabaseNode().getName();

	if name1 == "" then
		return true;
	elseif name2 == "" then
		return false;
	else
		return name1 > name2;
	end
end

function onFilter(w)
	-- Apply the filter to the individual powers too
	w.powerlist.applyFilter();
	
	-- If we are entering preparation mode, then hide the power types that have no
	-- preparation component
	local mode = window.mode.getSourceValue();
	if mode == "preparation" then
		local label = w.label.getValue();
		if label == "At-Will (Special)" or label == "Encounter (Special)" then
			return true;
		elseif (label == "Daily" or label == "Utility") and (w.getUsesAvailable() > 0) then
			return true;
		end
		
		return false;
	-- If combat mode, then hide the power types with no options left
	elseif mode == "combat" then
		local powercount = w.getAvailablePowerCount();
		if powercount <= 0 then
			return false;
		end
	end

	return true;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local class, datasource = draginfo.getShortcutData();
		if class == "powerdesc" then
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
	
	-- Add the power to the chaarcter database
	local newpower, powertype = CharSheetCommon.addPowerDB(getDatabaseNode().getParent(), sourcenode)

	-- Change the appropriate list state to visible, since we just added a power
	for k,v in pairs(getWindows()) do
		if v.getDatabaseNode().getName() == powertype then
			v.forceActive();
		end
	end

	-- Add any other powers linked to this power
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
