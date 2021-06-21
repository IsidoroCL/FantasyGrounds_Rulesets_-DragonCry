-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local attacks = {};
local damages = {};
local effects = {};

local dragging = nil;
local hoverx = nil;
local hovery = nil;

local hoverAttack = nil;
local hoverDamage = nil;
local hoverEffect = nil;

local clickAttack = nil;
local clickDamage = nil;
local clickEffect = nil;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	
	Input.onControl = onControl;
	
	if gmonly and not User.isHost() then
		setReadOnly(true);
	end
end

function onControl(pressed)
	if hoverAttack or hoverDamage or hoverEffect then
		onHoverUpdate(hoverx, hovery);
	end
end

function onEnter()
	if window.windowlist and window.windowlist.onEnter then
		window.windowlist.onEnter();
	end
end

function onHover(oncontrol)
	if dragging then
		return;
	end

	-- Reset selection when the cursor leaves the control
	if not oncontrol then
		hoverAttack = nil;
		hoverDamage = nil;
		hoverEffect = nil;
		
		--setCursorPosition(0);
		setSelectionPosition(0);
	end
end

function parseComponents()
	attacks, damages, effects = PowersManager.parsePowerDescription(getValue());
end

function onHoverUpdate(x, y)
	hoverx, hovery = x, y;

	-- If we're typing or draggin, then exit
	if dragging then
		return;
	end

	-- Compute the locations of the relevant phrases, and the mouse
	parseComponents();
	local mouse_index = getIndexAt(x, y);

	-- Clear any memory of the last hover update
	hoverAttack = nil;
	hoverDamage = nil;
	hoverEffect = nil;

	-- Hilight attack or damage hovered on
	for i = 1, #attacks do
		if attacks[i].startpos <= mouse_index and attacks[i].endpos > mouse_index then
			setCursorPosition(attacks[i].startpos);
			setSelectionPosition(attacks[i].endpos);

			hoverAttack = i;			

			setHoverCursor("hand");

			return;
		end
	end
	for i = 1, #damages do
		if damages[i].startpos <= mouse_index and damages[i].endpos > mouse_index then
			setCursorPosition(damages[i].startpos);
			setSelectionPosition(damages[i].endpos);

			hoverDamage = i;			
			
			setHoverCursor("hand");
			
			return;
		end
	end
	for i = 1, #effects do
		if effects[i].startpos <= mouse_index and effects[i].endpos > mouse_index then
			setCursorPosition(effects[i].startpos);
			setSelectionPosition(effects[i].endpos);

			hoverEffect = i;			
			
			setHoverCursor("hand");
			
			return;
		end
	end

	setHoverCursor("arrow");
	--setCursorPosition(0);
end

function buildAttackRoll(rAttack)
	local s = "";
	local dice = {"d20"};
	local modifier = 0;
	
	if rAttack.bonus then
		local bonus = tonumber(rAttack.bonus) or 0;
		modifier = modifier + bonus;
	end
	
	s = "[ATTACK] " .. window.name.getValue();
	if rAttack.defense then
		local defense = "-";
		if rAttack.defense == "ac" then
			defense = "AC";
		elseif rAttack.defense == "fortitude" then
			defense = "Fort";
		elseif rAttack.defense == "reflex" then
			defense = "Ref";
		elseif rAttack.defense == "will" then
			defense = "Will";
		end
		s = s .. " (vs. " .. defense .. ")";
	end

	if rAttack.atkstat and rAttack.atkstat ~= "" then	
		if self.getAbilityCheck then
			modifier = modifier + self.getAbilityCheck(rAttack.atkstat);
		end
	end
		
	if string.match(string.lower(window.keywords.getValue()), "weapon") then
		if self.getWeaponAttackBonus then
			modifier = modifier + self.getWeaponAttackBonus();
		end
	end
	if string.match(string.lower(window.keywords.getValue()), "implement") then
		if self.getImplementAttackBonus then
			modifier = modifier + self.getImplementAttackBonus();
		end
	end
	
	return s, dice, modifier;
end

function buildDamageRoll(rDamage)
	local s = "";
	local dice = {};
	local modifier = 0;
	
	if rDamage.damagemult then
		local weapondice = {};
		if self.getWeaponDice then
			weapondice = self.getWeaponDice();
		end

		local mult = tonumber(rDamage.damagemult) or 0;
		for i = 1, mult do
			for j, die in ipairs(weapondice) do
				table.insert(dice, die);
			end
		end
	end

	basedice, modifier = ChatManager.parseDiceString(rDamage.damage);
	for i, die in ipairs(basedice) do
		table.insert(dice, die);
	end

	local dmgtype = rDamage.dmgtype;
	local dmgstat = rDamage.dmgstat;
	local dmgstat2 = rDamage.dmgstat2;
	
	s = "[DAMAGE] " .. window.name.getValue();
	if rDamage.dmgtype and rDamage.dmgtype ~= "" then
		s = s .. " [" .. rDamage.dmgtype .. "]";
	end
	
	if rDamage.dmgstat and rDamage.dmgstat ~= "" then
		if self.getAbilityBonus then
			modifier = modifier + self.getAbilityBonus(rDamage.dmgstat);
		end
	end
		
	if rDamage.dmgstat2 and rDamage.dmgstat2 ~= "" then
		if self.getAbilityBonus then
			modifier = modifier + self.getAbilityBonus(rDamage.dmgstat2);
		end
	end

	if rDamage.damagemult then
		if string.match(string.lower(window.keywords.getValue()), "weapon") then
			if self.getWeaponDamageBonus then
				modifier = modifier + self.getWeaponDamageBonus();
			end
		end
	end
	if #dice > 0 then
		if string.match(string.lower(window.keywords.getValue()), "implement") then
			if self.getImplementDamageBonus then
				modifier = modifier + self.getImplementDamageBonus();
			end
		end
	end
		
	if Input.isShiftPressed() then
		local i, die;
		for i, die in ipairs(dice) do
			dice[i] = "max" .. string.sub(die, 2);
		end
		s = s .. " [CRITICAL]";
	end

	if #dice == 0 then
		dice = { "d0" };
	end

	return s, dice, modifier;
end

function onClickDown(button, x, y)
	-- Suppress default processing to support dragging
	clickDamage = hoverDamage;
	clickAttack = hoverAttack;
	clickEffect = hoverEffect;
	
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

function onDoubleClick(x, y)
	if hoverDamage then
		local dmg, dice, modifier = buildDamageRoll(damages[hoverDamage]);
		
		local custom = {};
		local type = "";
		local node = nil;
		if self.getCreatureType then
			type = self.getCreatureType();
		end
		if self.getCreatureNode then
			node = self.getCreatureNode();
		end
		if type ~= "" and node then
			custom[type] = node;
		end
		
		ChatManager.DoubleClickNPC("damage", modifier, dmg, custom, dice);
		
		return true;
	end
	
	if hoverAttack then
		local atk, dice, modifier = buildAttackRoll(attacks[hoverAttack]);
		
		local custom = {};
		local type = "";
		local node = nil;
		if self.getCreatureType then
			type = self.getCreatureType();
		end
		if self.getCreatureNode then
			node = self.getCreatureNode();
		end
		if type ~= "" and node then
			custom[type] = node;
		end
		
		ChatManager.DoubleClickNPC("attack", modifier, atk, custom, dice);
		
		return true;
	end

	if hoverEffect then
		local eff_name = effects[hoverEffect].name;
		local eff_exp = effects[hoverEffect].expire;
		local eff_savemod = effects[hoverEffect].savemod;
		
		ChatManager.reportEffectFull(eff_name, eff_exp, eff_savemod);
		
		return true;
	end
end

function onDrag(button, x, y, draginfo)
	if dragging then
		return true;
	end

	if clickDamage then
		local dmg, dice, modifier = buildDamageRoll(damages[clickDamage]);

		draginfo.setType("damage");
		draginfo.setDescription(dmg);
		draginfo.setDieList(dice);
		draginfo.setNumberData(modifier);
		
		local class = "";
		local node = nil;
		if self.getCreatureClass then
			class = self.getCreatureClass();
		end
		if self.getCreatureNode then
			node = self.getCreatureNode();
		end
		if class ~= "" and node then
			draginfo.setShortcutData(class, node.getNodeName());
		end
		
		clickDamage = nil;
		dragging = true;
		return true;
	end

	if clickAttack then
		local atk, dice, modifier = buildAttackRoll(attacks[clickAttack]);
		
		draginfo.setType("attack");
		draginfo.setDescription(atk);
		draginfo.setDieList(dice);
		draginfo.setNumberData(modifier);

		local class = "";
		local node = nil;
		if self.getCreatureClass then
			class = self.getCreatureClass();
		end
		if self.getCreatureNode then
			node = self.getCreatureNode();
		end
		if class ~= "" and node then
			draginfo.setShortcutData(class, node.getNodeName());
		end

		clickAttack = nil;
		dragging = true;
		return true;
	end

	if clickEffect then
		local eff_name = effects[clickEffect].name;
		local eff_exp = effects[clickEffect].expire;
		local eff_savemod = effects[clickEffect].savemod;
		
		draginfo.setType("number");
		draginfo.setDescription("[EFFECT] " .. eff_name .. " EXPIRES " .. eff_exp);
		draginfo.setStringData(eff_name);
		draginfo.setNumberData(eff_savemod);

		local class = "";
		local node = nil;
		if self.getCreatureClass then
			class = self.getCreatureClass();
		end
		if self.getCreatureNode then
			node = self.getCreatureNode();
		end
		if class ~= "" and node then
			draginfo.setShortcutData(class, node.getNodeName());
		end
		
		clickEffect = nil;
		dragging = true;
		return true;
	end

	return true;
end

function onDragEnd(dragdata)
	setCursorPosition(0);
	dragging = false;
end

