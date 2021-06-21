-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function getCompletion(str)
	if senses_only then
		if string.lower(str) == string.lower(string.sub("Perception", 1, #str)) then
			return string.sub("Perception", #str + 1);
		end
	else
		-- Find a matching completion for the given string
		for k, t in pairs(DataCommon.skilldata) do
			if string.lower(str) == string.lower(string.sub(k, 1, #str)) then
				return string.sub(k, #str + 1);
			end
		end
	end
	return "";
end

function parseComponents(s)
	local skills = {};
	
	-- Get the comma-separated strings
	local clauses = StringManager.split(s, ",\r", true);
	
	-- Check each comma-separated string for a potential skill roll or auto-complete opportunity
	for k,v in pairs(clauses) do
		local starts, ends, label_val, sign_val, mod_val = string.find(v.val, "([%w%s\(\)]*[%w\(\)]+)%s*([%+%-–]?)(%d*)");
		if starts then
			-- Calculate modifier based on mod value and sign value, if any
			local allow_roll_val = 0;
			local mod = 0;
			if mod_val ~= "" then
				allow_roll_val = 1;
				mod = tonumber(mod_val) or 0;
				if sign_val == "-" or sign_val == "–" then
					mod = 0 - mod;
				end
			end

			-- Insert the possible skill into the skill list
			table.insert(skills, {startpos = v.startpos, labelendpos = v.startpos + ends, endpos = v.endpos, label = label_val, bonus = mod, allow_roll = allow_roll_val });
		end
	end
	
	return skills;
end

function onChar()
	-- When a new character is appeneded to a skill label, autocomplete it if a match is found
	components = parseComponents(getValue());

	for i = 1, #components, 1 do
		if getCursorPosition() == components[i].labelendpos then
			completion = getCompletion(components[i].label);

			if completion ~= "" then
				value = getValue();
				newvalue = string.sub(value, 1, getCursorPosition()-1) .. completion .. string.sub(value, getCursorPosition());

				setValue(newvalue);
				setSelectionPosition(getCursorPosition() + #completion);
			end

			return;
		end
	end
end

function onHover(oncontrol)
	if dragging then
		return;
	end

	-- Reset selection when the cursor leaves the control
	if not oncontrol then
		dragLabel = nil;
		dragBonus = nil;
		
		--setCursorPosition(0);
		setSelectionPosition(0);
	end
end

function onHoverUpdate(x, y)
	if dragging then
		return;
	end

	-- Hilight skill hovered on
	components = parseComponents(getValue());
	local index = getIndexAt(x, y);

	for i = 1, #components, 1 do
		if components[i].allow_roll == 1 then
			if components[i].startpos <= index and components[i].endpos > index then
				setCursorPosition(components[i].startpos);
				setSelectionPosition(components[i].endpos);

				dragLabel = components[i].label;
				dragBonus = components[i].bonus;

				setHoverCursor("hand");

				return;
			end
		end
	end
	
	dragLabel = nil;
	dragBonus = nil;
	
	setHoverCursor("arrow");
	
	--setCursorPosition(0);
end

function onDoubleClick(x, y)
	if dragLabel then
		ChatManager.DoubleClickNPC("dice", dragBonus, dragLabel, {npc = window.getDatabaseNode()});
		return true;
	end
end

function onDrag(button, x, y, draginfo)
	-- The dragBonus and dragLabel fields keep track of the entry under the cursor
	if not dragLabel then
		return true;
	end

	if not dragging then
		draginfo.setType("dice");
		draginfo.setDescription(dragLabel);
		draginfo.setDieList({ "d20" });
		draginfo.setNumberData(dragBonus);
		draginfo.setShortcutData("npc", window.getDatabaseNode().getNodeName());
	end
	
	dragging = true;
	setCursorPosition(0);
	
	return true;
end

function onDragEnd(dragdata)
	dragging = false;
end

function onClickDown(button, x, y)
	-- Suppress default processing to support dragging
	return true;
end

function onClickRelease(button, x, y)
	-- Enable edit mode on mouse release
	setFocus();
	
	local n = getIndexAt(x, y);
	
	setSelectionPosition(n);
	setCursorPosition(n);
	
	return true;
end

function onInit()
	super.onInit();
end
