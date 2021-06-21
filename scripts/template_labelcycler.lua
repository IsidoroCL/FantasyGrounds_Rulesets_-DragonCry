-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

cycleindex = 0;
labels = {};
values = {};
srcnode = nil;
defaultval = "-";
readonlyflag = false;

function onInit()
	-- Get any custom fields
	local labeltext = "";
	local valuetext = "";
	local srcnodename = "";
	if sourcefields then
		if sourcefields[1].values then
			valuetext = sourcefields[1].values[1];
		end
		if sourcefields[1].labels then
			labeltext = sourcefields[1].labels[1];
		end
		if sourcefields[1].srcnode then
			srcnodename = sourcefields[1].srcnode[1];
		end
		if sourcefields[1].defaultlabel then
			defaultval = sourcefields[1].defaultlabel[1];
		end
	end
	
	-- Parse the labels to determine the options we should show
	for v in string.gmatch(labeltext, "[^|]+") do
		labels[#labels+1] = v;
	end

	-- Parse the labels to determine the options we should show
	for v in string.gmatch(valuetext, "[^|]+") do
		values[#values+1] = v;
	end

	-- See if the control is readonly
	if readonly then
		readonlyflag = true;
	end
	if gmonly and not User.isHost() then
		readonlyflag = true;
	end
	
	-- Get the data node set up and synched
	if srcnodename ~= "" then
		-- Set up
		local node = window.getDatabaseNode();

		-- Determine readonly state
		if node.isStatic() then
			readonlyflag = true;
		elseif not User.isHost() then
			if not (node.isOwner() or User.isLocal()) then
				readonlyflag = true;
			end
		end

		if readonlyflag then
			srcnode = node.getChild(srcnodename);
		else
			srcnode = NodeManager.createSafeChild(node, srcnodename, "string");
		end
		if srcnode then
			srcnode.onUpdate = update;
		end
		synch_index();
	end

	-- Set the label
	updateDisplay();
end

function synch_index()
	local srcval = "";
	if srcnode then
		srcval = srcnode.getValue();
	end
	local match = 0;
	for k,v in pairs(values) do
		if v == srcval then
			match = k;
		end
	end

	if match > 0 then
		cycleindex = match;
	else
		cycleindex = 0;
	end
end

function updateDisplay()
	if cycleindex > 0 and cycleindex <= #labels then
		setValue(labels[cycleindex]);
	else
		setValue(defaultval);
	end
end

function update()
	synch_index();
	updateDisplay();

	if self.onValueChanged then
		self.onValueChanged();
	end
end

function setSourceValue(srcval)
	if srcnode then
		srcnode.setValue(srcval);
	end
end

function getSourceValue()
	if cycleindex > 0 and cycleindex <= #values then
		return values[cycleindex];
	end
	
	return "";
end

function cycleLabel()
	if cycleindex < #labels then
		cycleindex = cycleindex + 1;
	else
		cycleindex = 0;
	end

	if srcnode then
		srcnode.setValue(getSourceValue());
	else
		updateDisplay();
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

	-- Otherwise, cycle the label
	cycleLabel();
	return true;
end

function lockCycle(val)
	if val == true then
		readonlyflag = true;
	else
		readonlyflag = false;
	end
end
