-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local option_width = 50;
local readonlyflag = false;

local labels = {};
local values = {};

local datanode = nil;

local labelwidgets = {};
local boxwidgets = {};

local radio_index = 0;

local default_index = 1;

function onInit()
	-- Get any custom fields
	local font = "sheetlabel";
	local labeltext = "";
	local valuetext = "";
	local defaultval = "";
	local srcnodename = "";
	if sourcefields then
		if sourcefields[1].font then
			font = sourcefields[1].font[1];
		end
		if sourcefields[1].optionwidth then
			option_width = tonumber(sourcefields[1].optionwidth[1]);
		end

		if sourcefields[1].labels then
			labeltext = sourcefields[1].labels[1];
		end
		if sourcefields[1].values then
			valuetext = sourcefields[1].values[1];
		end
		if sourcefields[1].defaultindex then
			defaultval = sourcefields[1].defaultindex[1];
		end

		if sourcefields[1].srcnode then
			srcnodename = sourcefields[1].srcnode[1];
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
	
	-- Create a set of widgets for each option
	for k,v in ipairs(labels) do
		-- Create a label widget
		labelwidgets[k] = addTextWidget(font, v);
		local w,h = labelwidgets[k].getSize();
		labelwidgets[k].setPosition("topleft", ((k-1)*option_width)+(w/2)+20, h/2);
		
		-- Create the checkbox widget
		boxwidgets[k] = addBitmapWidget(stateicons[1].off[1]);
		boxwidgets[k].setPosition("topleft", ((k-1)*option_width)+10, h/2);
	end

	-- Set the width of the control
	setAnchoredWidth(#labels*option_width);

	-- Determine the default index value
	default_index = tonumber(defaultval) or 1;
	radio_index = default_index;
	
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
			datanode = node.getChild(srcnodename);
		else
			datanode = NodeManager.createSafeChild(node, srcnodename, "string");
		end
		if datanode then
			datanode.onUpdate = onSourceUpdate;
		end
		synch_index(getSourceValue());
	end
	
	-- Set the right display
	updateDisplay();
end

function synch_index(srcval)
	local match = 0;
	for k, v in pairs(values) do
		if v == srcval then
			match = k;
		end
	end

	if match > 0 then
		radio_index = match;
	else
		radio_index = default_index;
	end
end

function updateDisplay()
	for k,v in ipairs(boxwidgets) do
		if radio_index == k then
			v.setBitmap(stateicons[1].on[1]);
		else
			v.setBitmap(stateicons[1].off[1]);
		end
	end
end

function update(val)
	synch_index(val);
	
	updateDisplay();

	if self.onValueChanged then
		self.onValueChanged();
	end
end

function onSourceUpdate()
	update(datanode.getValue());
end

function setSourceValue(srcval)
	if datanode then
		datanode.setValue(srcval);
	else
		update(srcval);
	end
end

function getSourceValue()
	local srcval = "";

	if datanode then
		srcval = datanode.getValue();
	else
		srcval = values[radio_index];
	end

	return srcval;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	-- If we're in read-only mode, then don't change
	if readonlyflag then
		return true;
	end
	
	-- Determine which area we are clicking in
	local k = math.floor(x / option_width) + 1;
	
	-- If this option is not enabled, then set the option
	if radio_index ~= k then
		setIndex(k);
	end
	
	return true;
end

function getIndex()
	return radio_index;
end

function setIndex(index)
	if index > 0 and index <= #values then
		setSourceValue(values[index]);
	else
		setSourceValue(values[default_index]);
	end
end

function setReadOnly(state)
	readonlyflag = state;
end

