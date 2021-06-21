-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

disablecheck = false;

function onInit()
	if not getNextWindow(nil) then
		setVisible(false);
	end
end

function checkForEmpty()
	super.checkForEmpty();
	window.checkUseLimit();
end

function onSortCompare(w1, w2)
	local name1 = w1.name.getValue();
	local name2 = w2.name.getValue();

	if name1 == "" then
		return true;
	elseif name2 == "" then
		return false;
	else
		return name1 > name2;
	end
end

function onFilter(w)
	-- Set the mode for each power type
	local mode = window.windowlist.window.mode.getSourceValue();
	
	-- Get the power type that this node is a part of
	local nodename = getDatabaseNode().getParent().getName();
	
	-- Handle the special preparation mode changes first
	if mode == "preparation" then
		w.usedcounter.setVisible(false);
		w.prepared.setVisible(true);
		w.name.setAnchor("left", "prepared", "right", "absolute", 15);
	else
		w.usedcounter.setVisible(true);
		w.prepared.setVisible(false);
		w.name.setAnchor("left", "usedcounter", "right", "absolute", 17);
	end
	
	-- If we're in combat mode then hide the powers that are unavailable
	if mode == "combat" then
		if w.usedcounter.getValue() >= w.usedcounter.getMaxValue() then
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

function onEnter()
	local wnd = NodeManager.createSafeWindow(self);
	if wnd then
		wnd.name.setFocus();
	end
end

function onCheckDeletePermission(w)
	if #getWindows() == 1 then
		setVisible(false);
		window.icon.setState(false);
	end
	
	return true;
end

function addPower(sourcenode)
	-- Parameter validation
	if not sourcenode then
		return;
	end
	
	-- Add the power to the chaarcter database
	CharSheetCommon.addPowerDB(getDatabaseNode().getParent().getParent().getParent(), sourcenode, getDatabaseNode().getParent().getName())

	-- Change our list state to visible, since we just added a power
	window.forceActive();
	
	-- Add any other powers linked to this power
	if sourcenode.getChild("linkedpowers") then
		for k,v in pairs(sourcenode.getChild("linkedpowers").getChildren()) do
			local powerclass, powernodename = v.getChild("link").getValue();
			if powerclass == "powerdesc" then
				window.windowlist.addPower(DB.findNode(powernodename));
			end
		end
	elseif sourcenode.getChild("link") then
		local powerclass, powernodename = sourcenode.getChild("link").getValue();
		if powerclass == "powerdesc" then
			window.windowlist.addPower(DB.findNode(powernodename));
		end
	end
end
