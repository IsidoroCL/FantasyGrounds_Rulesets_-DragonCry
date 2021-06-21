-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

cycleindex = 0;
icons = {};
values = {};
tooltips = {};
srcnode = nil;
defaulticon = nil;
defaulttooltip = nil;
readonly = false;

function onInit()
	-- Get any custom fields
	local icontext = "";
	local valuetext = "";
	local tooltiptext = "";
	local srcnodename = "";
	if sourcefields then
		if sourcefields[1].icons then
			icontext = sourcefields[1].icons[1];
		end
		if sourcefields[1].values then
			valuetext = sourcefields[1].values[1];
		end
		if sourcefields[1].tooltips then
			tooltiptext = sourcefields[1].tooltips[1];
		end
		if sourcefields[1].srcnode then
			srcnodename = sourcefields[1].srcnode[1];
		end
		if sourcefields[1].defaulticon then
			defaulticon = sourcefields[1].defaulticon[1];
		end
		if sourcefields[1].defaulttooltip then
			defaulttooltip = sourcefields[1].defaulttooltip[1];
		end
	end
	
	-- Parse the icons
	for v in string.gmatch(icontext, "[^|]+") do
		icons[#icons+1] = v;
	end

	-- Parse the underlying possible values
	for v in string.gmatch(valuetext, "[^|]+") do
		values[#values+1] = v;
	end

	-- Parse the underlying possible values
	for v in string.gmatch(tooltiptext, "[^|]+") do
		tooltips[#tooltips+1] = v;
	end

	-- Get the data node set up and synched
	if srcnodename ~= "" then
		srcnode = NodeManager.createSafeChild(window.getDatabaseNode(), srcnodename, "string");
		if srcnode then
			srcnode.onUpdate = update;
		end
		synch_index();
	end
	
	-- Set the right icon
	updateDisplay();
	
	-- Check for GM only flag
	if gmonly and not User.isHost() then
		lockCycle(true);
	end
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
	if cycleindex > 0 and cycleindex <= #icons then
		setIcon(icons[cycleindex]);
		setTooltipText(tooltips[cycleindex] or "");
	else
		setIcon(defaulticon);
		setTooltipText(defaulttooltip or "");
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

function cycleIcon()
	if cycleindex < #icons then
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
	if not readonly then
		cycleIcon();
	end
	return true;
end

function lockCycle(val)
	if val == true then
		readonly = true;
	else
		readonly = false;
	end
end