-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20
--
-- For information on the Fantasy Grounds d20 Ruleset licensing and
-- the OGL license text, see the d20 ruleset license in the program
-- options.
--
-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above licenses, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.
--
-- Copyright 2007 SmiteWorks Ltd.


skillnames = { "Acrobatics", "Arcana", "Athletics", "Bluff", "Diplomacy", "Dungeoneering", 
               "Endurance", "Heal", "History", "Insight", "Intimidate", 
               "Nature", "Perception", "Religion", "Stealth", "Streetwise", "Thievery" };

function getCompletion(str)
	-- Find a matching completion for the given string
	for i = 1, #skillnames, 1 do
		if string.lower(str) == string.lower(string.sub(skillnames[i], 1, #str)) then
			return string.sub(skillnames[i], #str + 1);
		end
	end
	
	return "";
end

function parseComponents()
	-- Break the string in the control into skills and modifiers, and record their respective positions
	str = getValue();
	components = {};
	
	starts = true;
	nextindex = 1;
	
	while starts do
		-- Find component parts: label with whitespace and modifier, with optional comma and whitespace following
		starts, ends, all, skill, mod  = string.find(str, '(([%w%s\(\)]*[%w\(\)]*)%s*([%+%-]?%d*))%s*,?%s*', nextindex);
		
		-- Adjust label to strip trailing whitespace
		spaces = string.match(string.reverse(skill), '%s*()') - 1;
		skillends = starts + #skill - spaces;
		skill = string.sub(skill, 1, #skill - spaces);

		-- Missing modifier should be treated as 0, a completely empty entry is skipped
		if mod == nil then mod = 0 end;
		if starts > ends then starts = false end;
		
		-- Add component to list
		if starts then
			nextindex = ends+1;
			table.insert(components, { startpos = starts, labelendpos = skillends, endpos = starts + #all, label = skill, bonus = mod });
		end
	end

	return components;
end

function onChar()
	-- When a new character is appeneded to a skill label, autocomplete it if a match is found
	components = parseComponents();

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
	components = parseComponents();
	local index = getIndexAt(x, y);

	for i = 1, #components, 1 do
		if components[i].startpos <= index and components[i].endpos > index then
			setCursorPosition(components[i].startpos);
			setSelectionPosition(components[i].endpos);
			
			dragLabel = components[i].label;
			dragBonus = components[i].bonus;
			
			setHoverCursor("hand");
			
			return;
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
