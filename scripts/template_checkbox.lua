-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

-- The sourceless value is used if the checkbox is used in a window not bound to the database
-- or if the <sourceless /> flag is specifically set

local source = nil;
local sourcelessvalue = false;
local readonlyflag = false;

function onInit()
	-- Set the initial icon to off
	setIcon(stateicons[1].off[1]);

	-- See if the control is readonly
	if readonly then
		readonlyflag = true;
	end
	if gmonly and not User.isHost() then
		readonlyflag = true;
	end
	
	-- Check to see if we have a source
	local node = window.getDatabaseNode();
	local initialnode = nil;
	if not sourceless and node then
		-- Determine readonly state
		if node.isStatic() then
			readonlyflag = true;
		elseif not User.isHost() then
			if not (node.isOwner() or User.isLocal()) then
				readonlyflag = true;
			end
		end

		-- Determine the name we should use for the node
		local srcname = getName();
		if sourcename then
			srcname = sourcename[1];
		end
		
		-- Check to see if the node already exists
		initialnode = node.getChild(srcname);
		
		-- Get the node (create if necessary)
		if readonlyflag then
			source = initialnode;
		else
			source = NodeManager.createSafeChild(node, srcname, "number");
		end

		-- Catch any future node updates
		if source then
			source.onUpdate = update;
		end
	end

	if checked then
		if source then
			if not initialnode and not readonlyflag then
				source.setValue(1);
			end
		else
			sourcelessvalue = true;
		end
	end

	-- Update the display
	updateDisplay();
end

function getState()
	if source then
		local datavalue = source.getValue();
		return datavalue ~= 0;
	else
		return sourcelessvalue;
	end
end

function setState(state)
	local datavalue = 1;
	
	if state == nil or state == false or state == 0 then
		datavalue = 0;
	end
	
	if source then
		source.setValue(datavalue);
	else
		if datavalue == 0 then
			sourcelessvalue = false;
		else
			sourcelessvalue = true;
		end
		
		update();
	end
end

function updateDisplay()
	if source then
		if source.getValue() ~= 0 then
			setIcon(stateicons[1].on[1]);
		else
			setIcon(stateicons[1].off[1]);
		end
	else
		if sourcelessvalue then
			setIcon(stateicons[1].on[1]);
		else
			setIcon(stateicons[1].off[1]);
		end
	end
end

function update()
	updateDisplay();
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	-- If we're in read-only mode, then don't change
	if readonlyflag then
		return true;
	end

	-- Otherwise, change the state
	setState(not getState());
	return true;
end

function setReadOnly(state)
	readonlyflag = state;
end
