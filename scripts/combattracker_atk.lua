-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local powers = {};

local hoverPower = nil;
local hoverType = nil;
local clickPower = nil;
local clickType = nil;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	
	Input.onControl = onControl;
	
	setUnderline(true);
end

function onControl(pressed)
	if hoverType then
		onHoverUpdate(hoverx, hovery);
	end
end

function onHover(oncontrol)
	if dragging then
		return;
	end

	-- Reset selection when the cursor leaves the control
	if not oncontrol then
		hoverPower = nil;
		hoverType = nil;
		
		--setCursorPosition(0);
		setSelectionPosition(0);
	end
end

function onHoverUpdate(x, y)
	hoverx, hovery = x, y;

	-- If we're typing or draggin, then exit
	if dragging then
		return;
	end

	-- Compute the locations of the relevant phrases, and the mouse
	powers = CombatCommon.parseCTAttackLine(getValue());
	local mouse_index = getIndexAt(x, y);

	-- Clear any memory of the last hover update
	hoverPower = nil;
	hoverType = nil;
	
	-- Capture the power that we're over, so we can name it
	for i = 1, #powers do
		if powers[i].startpos <= mouse_index and powers[i].endpos > mouse_index then
			hoverPower = i;

			if powers[i].name_startpos and (powers[i].name_startpos <= mouse_index and powers[i].name_endpos > mouse_index) then
				hoverType = "name";
				setCursorPosition(powers[i].name_startpos);
				setSelectionPosition(powers[i].name_endpos);
			elseif powers[i].atk_startpos and (powers[i].atk_startpos <= mouse_index and powers[i].atk_endpos > mouse_index) then
				hoverType = "atk";
				setCursorPosition(powers[i].atk_startpos);
				setSelectionPosition(powers[i].atk_endpos);
			elseif powers[i].dmg_startpos and (powers[i].dmg_startpos <= mouse_index and powers[i].dmg_endpos > mouse_index) then
				hoverType = "dmg";
				setCursorPosition(powers[i].dmg_startpos);
				setSelectionPosition(powers[i].dmg_endpos);
			elseif powers[i].usage_startpos and (powers[i].usage_startpos <= mouse_index and powers[i].usage_endpos > mouse_index) then
				hoverType = "usage";
				setCursorPosition(powers[i].usage_startpos);
				setSelectionPosition(powers[i].usage_endpos);
			end
			
			if hoverType then
				if hoverType == "atk" or hoverType == "dmg" then
					setHoverCursor("hand");
				else
					setHoverCursor("arrow");
				end
				
				return;
			end
		end
	end

	setHoverCursor("arrow");
	--setCursorPosition(0);
end

function rechargePower(index)
	if powers[index].usage_val ~= "USED" then
		return;
	end
	
	local s = string.sub(getValue(), 1, powers[index].usage_startpos - 2) .. string.sub(getValue(), powers[index].usage_endpos + 1);
	setValue(s);
	
	CombatCommon.removeEffect(window.getDatabaseNode(), "RCHG:%d " .. string.gsub(powers[index].name, "%*", "%%%*"));
end

function usePower(index)
	if not powers[index].usage_val then
		return;
	end
	if powers[index].usage_val == "USED" then
		return;
	end
	
	local s = string.sub(getValue(), 1, powers[index].usage_endpos) .. "[USED]" .. string.sub(getValue(), powers[index].usage_endpos + 1);
	setValue(s);

	local recharge_val = string.match(powers[index].usage_val, 'R:(%d)');
	if recharge_val then
		CombatCommon.addEffect("", "", window.getDatabaseNode(), "RCHG:" .. recharge_val .. " " .. powers[index].name);
	end
end

function onDoubleClick(x, y)
	-- Make sure we are highlighting something that is clickable
	if hoverPower and hoverType then

		-- NAME
		if hoverType == "name" then
			local shown = false;
			local lookup_power = string.gsub(powers[hoverPower].name, '*', '');
			local lookup_node = window.link.getTargetDatabaseNode();
			if lookup_node then
				if lookup_node.getChild("powers") then
					local powerchildren = lookup_node.getChild("powers").getChildren();
					for k, v in pairs(powerchildren) do
						if NodeManager.getSafeChildValue(v, "name", "") == lookup_power then
							Interface.openWindow("reference_npcaltpower", v.getNodeName());
							shown = true;
						end
					end
				end
			end
			if not shown then
				ChatManager.Message("[WARNING] Unable to locate power '" .. lookup_power .. "'");
			end

		-- ATTACK
		elseif hoverType == "atk" then
			local bonus = powers[hoverPower].atk_bonus;
			local defense = powers[hoverPower].atk_defense;

			local atk = "[ATTACK] " .. powers[hoverPower].name;
			if defense then
				atk = atk .. " (vs. " .. defense .. ")";
			end

			usePower(hoverPower);

			ChatManager.DoubleClickNPC("attack", bonus, atk, {npc = window.getDatabaseNode()});

		-- DAMAGE
		elseif hoverType == "dmg" then
			local dice, modifier = ChatManager.parseDiceString(powers[hoverPower].dmg_val);
			local dmgtype = powers[hoverPower].dmg_type;

			local dmg = "[DAMAGE] " .. powers[hoverPower].name;
			if dmgtype and dmgtype ~= "" then
				dmg = dmg .. " [" .. dmgtype .. "]";
			end

			if Input.isShiftPressed() then
				local i, die;
				for i, die in ipairs(dice) do
					dice[i] = "max" .. string.sub(die, 2);
				end
				dmg = dmg .. " [CRITICAL]";
			end

			if #dice == 0 then
				dice = { "d0" };
			end

			ChatManager.DoubleClickNPC("damage", modifier, dmg, {npc = window.getDatabaseNode()}, dice);
		
		-- USAGE
		elseif hoverType == "usage" then
			if powers[hoverPower].usage_val == "USED" then
				rechargePower(hoverPower);
			else
				usePower(hoverPower);
			end
		end
		
		return true;
	end
end

function onClickDown(button, x, y)
	-- Suppress default processing to support dragging
	clickPower = hoverPower;
	clickType = hoverType;
	
	return true;
end

function onDrag(button, x, y, draginfo)
	if dragging then
		return true;
	end

	-- Make sure we have a power to grab at
	if clickPower and clickType ~= "" then
		
		-- ATTACK
		if clickType == "atk" then
			local bonus = powers[clickPower].atk_bonus;
			local defense = powers[clickPower].atk_defense;

			local atk = "[ATTACK] " .. powers[clickPower].name;
			if defense then
				atk = atk .. " (vs. " .. defense .. ")";
			end

			draginfo.setType("attack");
			draginfo.setDescription(atk);
			draginfo.setDieList({"d20"});
			draginfo.setNumberData(bonus);
			draginfo.setShortcutData("combattracker_entry", window.getDatabaseNode().getNodeName());

			usePower(clickPower);

			clickPower = nil;
			dragging = true;
		
		-- DAMAGE
		elseif clickType == "dmg" then
			local dice, modifier = ChatManager.parseDiceString(powers[clickPower].dmg_val);
			local dmgtype = powers[clickPower].dmg_type;

			local dmg = "[DAMAGE] " .. powers[clickPower].name;
			if dmgtype and dmgtype ~= "" then
				dmg = dmg .. " [" .. dmgtype .. "]";
			end

			if Input.isShiftPressed() then
				local i, die;
				for i, die in ipairs(dice) do
					dice[i] = "max" .. string.sub(die, 2);
				end
				dmg = dmg .. " [CRITICAL]";
			end

			if #dice == 0 then
				dice = { "d0" };
			end

			draginfo.setType("damage");
			draginfo.setDieList(dice);
			draginfo.setDescription(dmg);
			draginfo.setNumberData(modifier);
			draginfo.setShortcutData("combattracker_entry", window.getDatabaseNode().getNodeName());

			clickPower = nil;
			dragging = true;
		end
	end

	return true;
end

function onDragEnd(dragdata)
	setCursorPosition(0);
	dragging = false;
end

function onClickRelease(button, x, y)
	-- Enable edit mode on mouse release
	setFocus();
	
	local n = getIndexAt(x, y);
	
	setSelectionPosition(n);
	setCursorPosition(n);
	
	return true;
end
