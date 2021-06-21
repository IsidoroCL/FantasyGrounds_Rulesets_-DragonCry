-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function getPowerType(sourcenode)
	-- Default power type is Situational
	local targettype = "a0-situational";
	
	-- Look up the power source and recharge value
	local powersource = string.lower(NodeManager.getSafeChildValue(sourcenode, "source", ""));
	local powerrecharge = string.lower(NodeManager.getSafeChildValue(sourcenode, "recharge", ""));

	-- Determine the power type
	if string.match(powersource, "cantrip") then
		targettype = "a2-cantrip";
	elseif string.match(powersource, "utility") then
		targettype = "d-utility";
	elseif string.match(powersource, "item") then
		if string.match(powerrecharge, "daily") then
			targettype = "e-itemdaily";
		elseif string.match(powerrecharge, "encounter") then
			targettype = "b1-encounter";
		elseif string.match(powerrecharge, "consumable") then
			targettype = "a11-atwillspecial";
		elseif string.match(powerrecharge, "healing surge") then
			targettype = "a1-atwill";
		elseif string.match(powerrecharge, "/day", 1, true) then
			targettype = "a11-atwillspecial";
		else
			targettype = "a1-atwill";
		end
	elseif string.match(powerrecharge, "at%-will") then
		if string.match(powerrecharge, "special") then
			targettype = "a11-atwillspecial";
		else
			targettype = "a1-atwill";
		end
	elseif string.match(powerrecharge, "encounter") then
		if string.match(powerrecharge, "special") then
			targettype = "b11-encounterspecial";
		else
			local powername = string.lower(NodeManager.getSafeChildValue(sourcenode, "name", ""));
			if string.match(powername, "channel divinity: ") then
				targettype = "b2-channeldivinity";
			else
				targettype = "b1-encounter";
			end
		end
	elseif string.match(powerrecharge, "daily") then
		targettype = "c-daily";
	end

	-- Return the power type
	return targettype;
end

function addPowerDB(charnode, sourcenode, powertype)
	-- Validate parameters
	if not charnode or not sourcenode then
		return;
	end

	-- Make sure we have a powertype
	if not powertype then
		powertype = CharSheetCommon.getPowerType(sourcenode);
	end

	-- Get the powers node
	local powersnode = NodeManager.createSafeChild(charnode, "powers");
	local powertypenode = NodeManager.createSafeChild(powersnode, powertype);
	local powerlistnode = NodeManager.createSafeChild(powertypenode, "power");
	local newpower = NodeManager.createSafeChild(powerlistnode);
							
	-- Change the power mode so that all powers are shown
	NodeManager.setSafeChildValue(charnode, "powermode", "string", "standard");

	-- Make sure the type node is visible on the character sheet, now that we're adding a power to it
	if powertype == "a11-atwillspecial" then
		NodeManager.setSafeChildValue(charnode.getChild("powershow"), "atwillspecial", "number", 1);
	elseif powertype == "a2-cantrip" then
		NodeManager.setSafeChildValue(charnode.getChild("powershow"), "cantrip", "number", 1);
	elseif powertype == "b11-encounterspecial" then
		NodeManager.setSafeChildValue(charnode.getChild("powershow"), "encounterspecial", "number", 1);
	elseif powertype == "b2-channeldivinity" then
		NodeManager.setSafeChildValue(charnode.getChild("powershow"), "channeldivinity", "number", 1);
	end
	
	-- Set up the basic power fields
  	local name = NodeManager.getSafeChildValue(sourcenode, "name", "");
  	local source = NodeManager.getSafeChildValue(sourcenode, "source", "");
  	if source == "Item" then
  		name = string.gsub(name, " Power - ", " ");
  	end
  	NodeManager.setSafeChildValue(newpower, "name", "string", name);
  	NodeManager.setSafeChildValue(newpower, "source", "string", source);
  	NodeManager.setSafeChildValue(newpower, "recharge", "string", NodeManager.getSafeChildValue(sourcenode, "recharge", "-"));
  	NodeManager.setSafeChildValue(newpower, "keywords", "string", NodeManager.getSafeChildValue(sourcenode, "keywords", "-"));
  	NodeManager.setSafeChildValue(newpower, "range", "string", NodeManager.getSafeChildValue(sourcenode, "range", "-"));
	NodeManager.setSafeChildValue(newpower, "shortdescription", "string", NodeManager.getSafeChildValue(sourcenode, "shortdescription", ""));

	-- Set up the action field
	local poweraction = NodeManager.getSafeChildValue(sourcenode, "action", "-");
	if poweraction == "Standard Action" then
		poweraction = "Standard";
	elseif poweraction == "Move Action" then
		poweraction = "Move";
	elseif poweraction == "Minor Action" then
		poweraction = "Minor";
	elseif poweraction == "Free Action" then
		poweraction = "Free";
	elseif poweraction == "Immediate Interrupt" then
		poweraction = "Interrupt";
	elseif poweraction == "Immediate Reaction" then
		poweraction = "Reaction";
	end
	NodeManager.setSafeChildValue(newpower, "action", "string", poweraction);

	-- Set the shortcut
	local refnode = NodeManager.createSafeChild(newpower, "shortcut", "windowreference");
	refnode.setValue("powerdesc", sourcenode.getNodeName());
	
	-- Finally, parse the description
	parseDescription(newpower);
	
	-- Make sure that the power will be visible in the power list

	-- Add any linked powers
	
	-- Return the new power created
	return newpower, powertype;
end

function parseDescription(powernode)
	-- Parse the clauses, and perform special handling on the target/attack/hit clauses
	local clauses = PowersManager.parseClauses(NodeManager.getSafeChildValue(powernode, "shortdescription", ""));
	
	-- Clear the attack and effect entries
	local attacks_node = NodeManager.createSafeChild(powernode, "attacks");
	for k,v in pairs(attacks_node.getChildren()) do
		v.delete();
	end
	local effects_node = NodeManager.createSafeChild(powernode, "effects");
	for k,v in pairs(effects_node.getChildren()) do
		v.delete();
	end
	
	-- Cycle through the attack clauses, and add them to the attacks list
	local finalstr = "";
	local effects_created = {};
	local attack_entry = nil;
	local attack_order = 1;
	local attack_entries = {};
	local last_attack_set = 0;
	for k, v in ipairs(clauses) do
		local addstr = v.label .. ": " .. v.value;
		
		if v.label == "Target" then
			if v.value == "One creature" then
				addstr = "";
			end
		else
			local attackslist, damageslist, effectslist = PowersManager.parsePowerDescription(v.value);
			
			for i = 1, #attackslist do
				local attack_entry = NodeManager.createSafeChild(attacks_node);
				table.insert(attack_entries, attack_entry);
				
				NodeManager.setSafeChildValue(attack_entry, "order", "number", #attack_entries);

				NodeManager.setSafeChildValue(attack_entry, "attackstat", "string", attackslist[i].atkstat);
				NodeManager.setSafeChildValue(attack_entry, "attackdef", "string", attackslist[i].defense);
				NodeManager.setSafeChildValue(attack_entry, "attackstatmodifier", "number", attackslist[i].bonus);
			end
			if #attackslist > 0 then
				last_attack_set = #attackslist;
			end
			
			local atk_index = #attack_entries + 1 - last_attack_set;
			if #damageslist > 0 then
				last_attack_set = 0;
			end
			for i = 1, #damageslist do
				local attack_entry = attack_entries[atk_index];
				if not attack_entry then
					attack_entry = NodeManager.createSafeChild(attacks_node);
					table.insert(attack_entries, attack_entry);
					
					NodeManager.setSafeChildValue(attack_entry, "order", "number", #attack_entries);
				end
				
				NodeManager.setSafeChildValue(attack_entry, "damagestat", "string", damageslist[i].dmgstat);
				NodeManager.setSafeChildValue(attack_entry, "damagestat2", "string", damageslist[i].dmgstat2);
				NodeManager.setSafeChildValue(attack_entry, "damagetype", "string", damageslist[i].dmgtype);

				if damageslist[i].damage then
					local dice, modifier = ChatManager.parseDiceString(damageslist[i].damage);
					NodeManager.setSafeChildValue(attack_entry, "damagebasicdice", "dice", dice);
					NodeManager.setSafeChildValue(attack_entry, "damagestatmodifier", "number", modifier);
				end
				if damageslist[i].damagemult then
					NodeManager.setSafeChildValue(attack_entry, "damageweaponmult", "number", damageslist[i].damagemult);
				end
				atk_index = atk_index + 1;
			end
			for i = 1, #effectslist do
				local effect_key = effectslist[i].name .. effectslist[i].expire .. effectslist[i].savemod;
				if not effects_created[effect_key] then
					effects_created[effect_key] = true;

					local effect_entry = NodeManager.createSafeChild(effects_node);

					NodeManager.setSafeChildValue(effect_entry, "label", "string", effectslist[i].name);
					NodeManager.setSafeChildValue(effect_entry, "expiration", "string", effectslist[i].expire);
					NodeManager.setSafeChildValue(effect_entry, "effectsavemod", "number", effectslist[i].savemod);
				end
			end
			
			if #attackslist == 1 and (v.label == "Attack" or v.label == "Secondary Attack" or v.label == "Tertiary Attack") then
				if attackslist[1].endpos > #v.value then
					addstr = "";
				end
			elseif #damageslist >= 1 and (v.label == "Hit") then
				if damageslist[1].startpos == 1 then
					local sRemainder = string.sub(v.value, damageslist[1].endpos);
					local sSep = string.sub(sRemainder, 1, 1);
					if sSep == "," or sSep == "." then
						sRemainder = string.sub(sRemainder, 3);
						if string.sub(sRemainder, 1, 4) == "and " then
							sRemainder = string.upper(string.sub(sRemainder, 5, 5)) .. string.sub(sRemainder, 6);
						end

						local sDisplay = string.sub(v.value, 1, damageslist[1].startpos - 1) .. sRemainder;
						if sDisplay == "" then
							addstr = "";
						else
							addstr = v.label .. ": " .. sDisplay;
						end
					elseif sSep == "" then
						addstr = "";
					end
				end
			end			
		end
		
		if addstr ~= "" then
			if finalstr ~= "" then
				finalstr = finalstr .. "; ";
			end
			finalstr = finalstr .. addstr;
		end
	end
	
	-- Make sure that the attack and effect lists have something in them
	if attacks_node.getChildCount() == 0 then
		NodeManager.createSafeChild(attacks_node);
	end
	if effects_node.getChildCount() == 0 then
		NodeManager.createSafeChild(effects_node);
	end
	
	-- Space savers
	finalstr = string.gsub(finalstr, "vs. Fortitude", "vs. Fort");
	finalstr = string.gsub(finalstr, "vs. Reflex", "vs. Ref");
	finalstr = string.gsub(finalstr, "Strength vs.", "STR vs.");
	finalstr = string.gsub(finalstr, "Constitution vs.", "CON vs.");
	finalstr = string.gsub(finalstr, "Dexterity vs.", "DEX vs.");
	finalstr = string.gsub(finalstr, "Intelligence vs.", "INT vs.");
	finalstr = string.gsub(finalstr, "Wisdom vs.", "WIS vs.");
	finalstr = string.gsub(finalstr, "Charisma vs.", "CHA vs.");
	finalstr = string.gsub(finalstr, "Strength modifier", "STR");
	finalstr = string.gsub(finalstr, "Constitution modifier", "CON");
	finalstr = string.gsub(finalstr, "Dexterity modifier", "DEX");
	finalstr = string.gsub(finalstr, "Intelligence modifier", "INT");
	finalstr = string.gsub(finalstr, "Wisdom modifier", "WIS");
	finalstr = string.gsub(finalstr, "Charisma modifier", "CHA");

	-- Finally, set the description string to its new value
	if finalstr == "" then
		finalstr = "-";
	end
	NodeManager.setSafeChildValue(powernode, "shortdescription", "string", finalstr);
end

function addPowerToWeaponDB(charnode, sourcenode)
	-- Parameter validation
	if not charnode or not sourcenode then
		return nil;
	end
	
	-- Create the new weapon entry
	local weaponlist = NodeManager.createSafeChild(charnode, "weaponlist");
	if not weaponlist then
		return nil;
	end
	local weaponnode = NodeManager.createSafeChild(weaponlist);
	if not weaponnode then
		return nil;
	end
	
	-- Determine the weapon number
	local order = calcNextWeaponOrder(weaponlist);
	NodeManager.setSafeChildValue(weaponnode, "order", "number", order);

	-- Fill in the basic attributes
	NodeManager.setSafeChildValue(weaponnode, "name", "string", NodeManager.getSafeChildValue(sourcenode, "name", ""));
	
	-- Determine the attack type and range increment
	local range = NodeManager.getSafeChildValue(sourcenode, "range", "");
	local rrangeval = string.match(range, "Ranged (%d+)");
	local brangeval = string.match(range, "Area burst %d+ within (%d+)");
	local wrangeval = string.match(range, "Area wall %d+ within (%d+)");
	if rrangeval then
		NodeManager.setSafeChildValue(weaponnode, "type", "number", 1);
		NodeManager.setSafeChildValue(weaponnode, "rangeincrement", "number", tonumber(rrangeval) or 0);
	elseif brangeval then
		NodeManager.setSafeChildValue(weaponnode, "type", "number", 1);
		NodeManager.setSafeChildValue(weaponnode, "rangeincrement", "number", tonumber(brangeval) or 0);
	elseif wrangeval then
		NodeManager.setSafeChildValue(weaponnode, "type", "number", 1);
		NodeManager.setSafeChildValue(weaponnode, "rangeincrement", "number", tonumber(wrangeval) or 0);
	end

	-- Load up the properties field
	local propstr = "";

	local actionval = NodeManager.getSafeChildValue(sourcenode, "action", "");
	if actionval == "Standard Action" then
		propstr = propstr .. "[s]";
	elseif actionval == "Move Action" then
		propstr = propstr .. "[mo]";
	elseif actionval == "Minor Action" then
		propstr = propstr .. "[mi]";
	elseif actionval == "Free Action" then
		propstr = propstr .. "[f]";
	elseif actionval == "Immediate Interrupt" then
		propstr = propstr .. "[i]";
	elseif actionval == "Immediate Reaction" then
		propstr = propstr .. "[r]";
	end
	
	local rechargeval = NodeManager.getSafeChildValue(sourcenode, "recharge", "");
	if string.sub(rechargeval, 1, 9) == "Encounter" then
		propstr = propstr .. "[e]";
	elseif string.sub(rechargeval, 1, 5) == "Daily" then
		propstr = propstr .. "[d]";
	end

	local keywords = NodeManager.getSafeChildValue(sourcenode, "keywords", "");
	if keywords ~= "" then
		if propstr ~= "" then
			propstr = propstr .. ", ";
		end
		propstr = propstr .. keywords;
	end

	NodeManager.setSafeChildValue(weaponnode, "properties", "string", propstr);

	-- Determine if this is a weapon/implement power
	local tool_node = nil;
	if string.match(string.lower(keywords), "weapon") then
		tool_node = getDefaultFocus(charnode, "weapon");
	elseif string.match(string.lower(keywords), "implement") then
		tool_node = getDefaultFocus(charnode, "implement");
	end

	-- Finally, parse the description string for attack and damage clauses
	local shortdesc = NodeManager.getSafeChildValue(sourcenode, "shortdescription", "");
	local attacks, damages, effects = PowersManager.parsePowerDescription(shortdesc);
	
	if #attacks > 0 then
		NodeManager.setSafeChildValue(weaponnode, "attackstat", "string", attacks[1].atkstat);
		NodeManager.setSafeChildValue(weaponnode, "attackdef", "string", attacks[1].defense);
		local mod = attacks[1].bonus;
		if tool_node then
			mod = mod + NodeManager.getSafeChildValue(tool_node, "bonus", 0);
		end
		NodeManager.setSafeChildValue(weaponnode, "bonus", "number", mod);
	end
	
	if #damages > 0 then
		if damages[1].damage then
			local dice, mod = ChatManager.parseDiceString(damages[1].damage);
			NodeManager.setSafeChildValue(weaponnode, "damagedice", "dice", dice);
			if tool_node then
				mod = mod + NodeManager.getSafeChildValue(tool_node, "damagebonus", 0);

				local critdice = NodeManager.getSafeChildValue(tool_node, "criticaldice", {});
				if not critdice then
					critdice = {};
				end
				local critmod = NodeManager.getSafeChildValue(tool_node, "criticalbonus", 0)
				local critdmgtype = NodeManager.getSafeChildValue(tool_node, "criticaldamagetype", "");
				
				NodeManager.setSafeChildValue(weaponnode, "criticaldice", "dice", critdice);
				NodeManager.setSafeChildValue(weaponnode, "criticalbonus", "number", critmod);
				NodeManager.setSafeChildValue(weaponnode, "criticaldamagetype", "string", critdmgtype);
			end
			NodeManager.setSafeChildValue(weaponnode, "damagebonus", "number", mod);
		elseif damages[1].damagemult then
			if tool_node then
				local dice = {};
				local basedice = NodeManager.getSafeChildValue(tool_node, "damagedice", {});
				if not basedice then
					basedice = {};
				end
				local mod = NodeManager.getSafeChildValue(tool_node, "damagebonus", 0)
				
				for i = 1, damages[1].damagemult do
					for j = 1, #basedice do
						table.insert(dice, basedice[j]);
					end
				end
				
				NodeManager.setSafeChildValue(weaponnode, "damagedice", "dice", dice);
				NodeManager.setSafeChildValue(weaponnode, "damagebonus", "number", mod);
				
				local critdice = NodeManager.getSafeChildValue(tool_node, "criticaldice", {});
				if not critdice then
					critdice = {};
				end
				local critmod = NodeManager.getSafeChildValue(tool_node, "criticalbonus", 0);
				local critdmgtype = NodeManager.getSafeChildValue(tool_node, "criticaldamagetype", "");
				
				NodeManager.setSafeChildValue(weaponnode, "criticaldice", "dice", critdice);
				NodeManager.setSafeChildValue(weaponnode, "criticalbonus", "number", critmod);
				NodeManager.setSafeChildValue(weaponnode, "criticaldamagetype", "string", critdmgtype);
			end
		end
		
		NodeManager.setSafeChildValue(weaponnode, "damagestat", "string", damages[1].dmgstat);
		NodeManager.setSafeChildValue(weaponnode, "damagetype", "string", damages[1].dmgtype);
	end

	-- Set the shortcut fields
	local refnode = NodeManager.createSafeChild(weaponnode, "shortcut", "windowreference");
	refnode.setValue("powerdesc", sourcenode.getNodeName());
	
	-- Return the new weapon node
	return weaponnode;
end

function checkForSecondWind(charnode)
	-- Validate parameters
	if not charnode then
		return nil;
	end
	
	-- Get the powers node
	local powersnode = NodeManager.createSafeChild(charnode, "powers");
	local powertypenode = NodeManager.createSafeChild(powersnode, "b1-encounter");
	local powerlistnode = NodeManager.createSafeChild(powertypenode, "power");
	
	-- Check for an existing Second Wind power
	for k,v in pairs(powerlistnode.getChildren()) do
		if NodeManager.getSafeChildValue(v, "name", "") == "Second Wind" then
			return v;
		end
	end
	
	-- Create a new power node
	local newpower = NodeManager.createSafeChild(powerlistnode);
	
	-- Set up the basic power fields
  	NodeManager.setSafeChildValue(newpower, "name", "string", "Second Wind");
  	NodeManager.setSafeChildValue(newpower, "source", "string", "General");
  	NodeManager.setSafeChildValue(newpower, "recharge", "string", "Encounter");
  	NodeManager.setSafeChildValue(newpower, "keywords", "string", "Healing");
  	NodeManager.setSafeChildValue(newpower, "range", "string", "Personal");
	NodeManager.setSafeChildValue(newpower, "action", "string", "Standard");
	NodeManager.setSafeChildValue(newpower, "shortdescription", "string", "Effect: Spend a healing surge, and gain a +2 bonus to all defenses until the start of your next turn.");
	
	-- Return the new power created
	return newpower;
end

function addItemDB(charnode, sourcenode, nodetype)
	-- Validate parameters
	if not charnode or not sourcenode then
		return nil;
	end

	-- Create the new inventory entry
	local itemlist = NodeManager.createSafeChild(charnode, "inventorylist");
	local itemnode = nil;
	local isCustom = false;
	if itemlist then
		-- Basic item
		if nodetype == "referencearmor" or nodetype == "referenceweapon" or nodetype == "referenceequipment" then
			-- Create the child node
			itemnode = NodeManager.createSafeChild(itemlist);
	
			-- Just copy over the fields we need
			NodeManager.setSafeChildValue(itemnode, "name", "string", NodeManager.getSafeChildValue(sourcenode, "name", ""));
			NodeManager.setSafeChildValue(itemnode, "weight", "number", NodeManager.getSafeChildValue(sourcenode, "weight", 0));
			
			-- Set the shortcut fields
			local refnode = NodeManager.createSafeChild(itemnode, "shortcut", "windowreference");
			refnode.setValue(nodetype, sourcenode.getNodeName());

		-- Custom or magic item
		elseif nodetype == "item" or nodetype == "referencemagicitem" then
			-- Copy over all the item fields, since we are making a personal copy of the item
			--
			-- Fields copied as of 8/31/08
			-- General Magic Item = Name, Class, Subclass, Level, Cost, Bonus, Flavor, Enhancement, Critical, 
			--						Formatted Item Block, Props list, Special, Powers List, Quirks List
			-- Equipment = Name, Weight, Cost, Type, SubType, Description
			-- Armor = Name, AC, Min Enhance, Check Penalty, Speed, Weight, Cost, Type, Prof, Description
			-- Weapon = Name, Type, Prof, Heft, Prof Bonus, Damage, Range, Cost, Weight, Group, Properties, Description
			itemnode = NodeManager.copyNode(sourcenode, itemlist, true);
			
			-- Flag that we made a personal custom item
			isCustom = true;
			
			-- Set the initial item type
			local itemclass = NodeManager.getSafeChildValue(itemnode, "class", "");
			local itemtype = "other";
			if itemclass == "Armor" then
				itemtype = "armor";
			elseif itemclass == "Weapon" or itemclass == "Implement" then
				itemtype = "weapon";
			end
			NodeManager.setSafeChildValue(itemnode, "mitype", "string", itemtype);
			
			-- Set the shortcut fields
			local refnode = NodeManager.createSafeChild(itemnode, "shortcut", "windowreference");
			refnode.setValue("item", itemnode.getNodeName());
		end
	end
	
	-- Create the new weapon entry, if appropriate
	local isWeapon = false;
	local weaponnode1 = nil;
	local weaponnode2 = nil;
	if nodetype == "referenceweapon" then
		isWeapon = true;
	elseif nodetype == "referenceequipment" then
		if NodeManager.getSafeChildValue(sourcenode, "type", "") == "Implement" then
			isWeapon = true;
		end
	elseif nodetype == "item" or nodetype == "referencemagicitem" then
		local itemclass = NodeManager.getSafeChildValue(sourcenode, "class", "");
		if itemclass == "Weapon" or itemclass == "Implement" then
			isWeapon = true;
		end
	end
	if isWeapon then
		if isCustom then
			weaponnode1, weaponnode2 = addWeaponDB(charnode, sourcenode, itemnode, "item");
		else
			weaponnode1, weaponnode2 = addWeaponDB(charnode, sourcenode, sourcenode, nodetype);
		end
	end
	
	return itemnode, weaponnode1, weaponnode2;
end

function removeWeaponDB(charnode, itemnodename)
	-- Parameter validation
	if not charnode or not itemnodename then
		return false;
	end
	
	-- Get the weapon list we are going to remove from
	local weaponlist = NodeManager.createSafeChild(charnode, "weaponlist");
	if not weaponlist then
		return false;
	end

	-- Check to see if any of the weapon nodes linked to this item node should be deleted
	local foundmelee = false;
	local foundranged = false;
	for k, v in pairs(weaponlist.getChildren()) do
		local scnode = v.getChild("shortcut");
		if scnode then
			local refclass, refnode = scnode.getValue();
			if refnode == itemnodename then
				local typeval = NodeManager.getSafeChildValue(v, "type", 0);
				if typeval == 1 and not foundmelee then
					foundmelee = true;
					v.delete();
				elseif typeval == 0 and not foundranged then
					foundranged = true;
					v.delete();
				end
			end
		end
	end
	
	-- We didn't find any linked weapons
	return (foundmelee or foundranged);
end

function calcNextWeaponOrder(weaponlist)
	local order = 1;
	
	if weaponlist then
		local ordertable = {};
		for k,v in pairs(weaponlist.getChildren()) do
			local temp_order = NodeManager.getSafeChildValue(v, "order", 0);
			ordertable[temp_order] = true;
		end

		while ordertable[order] do
			order = order + 1;
		end
	end
	
	return order;
end

function addWeaponDB(charnode, sourcenode, itemnode, nodetype)
	-- Parameter validation
	if not charnode or not sourcenode or not itemnode then
		return nil;
	end
	
	-- Get the weapon list we are going to add to
	local weaponlist = NodeManager.createSafeChild(charnode, "weaponlist");
	if not weaponlist then
		return nil;
	end
	
	-- Grab some information from the sourcenode to populate the new weapon entries
	local type = NodeManager.getSafeChildValue(sourcenode, "type", "");
	local range = NodeManager.getSafeChildValue(sourcenode, "range", 0);
	
	local name = NodeManager.getSafeChildValue(sourcenode, "name", "");
	local properties = NodeManager.getSafeChildValue(sourcenode, "properties", "");
	
	local critical = NodeManager.getSafeChildValue(sourcenode, "critical", "");
	local criticaldice = {};
	local criticalbonus = 0;
	local criticaldmgtype = "";
	if critical ~= "" then
		local starts, ends, dicestr, typestr = string.find(critical, "%+(%d[d%+%d%s]*)%s?(%a*)%scritical%sdamage");
		if starts then
			critical = string.sub(critical, ends+1);
			if string.sub(critical, 1, 5) == ", or " then
				critical = string.sub(critical, 6);
			elseif string.sub(critical, 1, 6) == ", and " then
				critical = string.sub(critical, 7);
			end
			
			criticaldice, criticalbonus = ChatManager.parseDieString(dicestr);
			criticaldmgtype = typestr;
		end
		if critical ~= "" then
			if properties ~= "" then
				properties = properties .. ", ";
			end
			properties = properties .. "Crit: " .. critical;
		end
	end

	local profbonus = NodeManager.getSafeChildValue(sourcenode, "profbonus", 0);
	local enhancebonus = NodeManager.getSafeChildValue(sourcenode, "bonus", 0);

	local damagestring = NodeManager.getSafeChildValue(sourcenode, "damage", "");
	local dice, modifier = ChatManager.parseDieString(damagestring);
	
	local weaponnode = NodeManager.createSafeChild(weaponlist);
	local weaponnode2 = nil;
	if weaponnode then
		-- Set the shortcut fields
		local refnode = NodeManager.createSafeChild(weaponnode, "shortcut", "windowreference");
		refnode.setValue(nodetype, itemnode.getNodeName());

		-- Calculate the order number
		local order = calcNextWeaponOrder(weaponlist);
		NodeManager.setSafeChildValue(weaponnode, "order", "number", order);
		
		-- Fill in the basic, attack and damage fields
		NodeManager.setSafeChildValue(weaponnode, "name", "string", name);
		NodeManager.setSafeChildValue(weaponnode, "properties", "string", properties);
		NodeManager.setSafeChildValue(weaponnode, "bonus", "number", profbonus + enhancebonus);
		NodeManager.setSafeChildValue(weaponnode, "damagedice", "dice", dice);
		NodeManager.setSafeChildValue(weaponnode, "damagebonus", "number", modifier + enhancebonus);
		NodeManager.setSafeChildValue(weaponnode, "criticaldice", "dice", criticaldice);
		NodeManager.setSafeChildValue(weaponnode, "criticalbonus", "number", criticalbonus);
		NodeManager.setSafeChildValue(weaponnode, "criticaldamagetype", "string", criticaldmgtype);

		if type == "Melee" then
			-- Fill in the melee specific fields
			NodeManager.setSafeChildValue(weaponnode, "type", "number", 0);
			NodeManager.setSafeChildValue(weaponnode, "attackdef", "string", "ac");

			if string.match(string.lower(properties), "heavy thrown") or string.match(string.lower(properties), "light thrown") then
				weaponnode2 = NodeManager.createSafeChild(weaponlist);
				if weaponnode2 then
					-- Set the shortcut fields
					local refnode = NodeManager.createSafeChild(weaponnode2, "shortcut", "windowreference");
					refnode.setValue(nodetype, itemnode.getNodeName());

					-- Calculate the order number
					local order = calcNextWeaponOrder(weaponlist);
					NodeManager.setSafeChildValue(weaponnode2, "order", "number", order);

					-- Fill in the basic, attack and damage fields
					NodeManager.setSafeChildValue(weaponnode2, "type", "number", 1);
					NodeManager.setSafeChildValue(weaponnode2, "name", "string", name);
					NodeManager.setSafeChildValue(weaponnode2, "properties", "string", properties);

					NodeManager.setSafeChildValue(weaponnode2, "rangeincrement", "number", range);
					NodeManager.setSafeChildValue(weaponnode2, "bonus", "number", profbonus + enhancebonus);
					NodeManager.setSafeChildValue(weaponnode2, "attackdef", "string", "ac");

					NodeManager.setSafeChildValue(weaponnode2, "damagedice", "dice", dice);
					NodeManager.setSafeChildValue(weaponnode2, "damagebonus", "number", modifier + enhancebonus);
					NodeManager.setSafeChildValue(weaponnode2, "criticaldice", "dice", criticaldice);
					NodeManager.setSafeChildValue(weaponnode2, "criticalbonus", "number", criticalbonus);
					NodeManager.setSafeChildValue(weaponnode2, "criticaldamagetype", "string", criticaldmgtype);
				end
			end

		elseif type == "Ranged" then
			-- Fill in the ranged specific fields
			NodeManager.setSafeChildValue(weaponnode, "type", "number", 1);
			NodeManager.setSafeChildValue(weaponnode, "rangeincrement", "number", range);
			NodeManager.setSafeChildValue(weaponnode, "attackdef", "string", "ac");

		elseif type == "Implement" then
			-- Fill in the implement specific fields
			NodeManager.setSafeChildValue(weaponnode, "type", "number", 1);

		else
			-- Fill in the general magic weapon fields
			NodeManager.setSafeChildValue(weaponnode, "type", "number", 0);
			NodeManager.setSafeChildValue(weaponnode, "attackdef", "string", "ac");
		end
	end
	
	return weaponnode, weaponnode2;
end

function getWeaponAttack(weaponnode)
	local text = "";
	local mod = 0;
	
	-- Validate parameters
	if not weaponnode then
		return text, mod;
	end
	
	-- Add the attack type to the output
	text = text .. "[ATTACK] ";
	
	-- Add the weapon's name to the output
	text = text .. NodeManager.getSafeChildValue(weaponnode, "name", "");
	
	-- Add the weapon's target defense to the output
	local defval = NodeManager.getSafeChildValue(weaponnode, "attackdef", "");
	if defval == "ac" then
		text = text .. " (vs. AC)";
	elseif defval == "fortitude" then
		text = text .. " (vs. Fort)";
	elseif defval == "reflex" then
		text = text .. " (vs. Ref)";
	elseif defval == "will" then
		text = text .. " (vs. Will)";
	end
	
	-- Add in the base modifiers
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "...levelbonus", 0);
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "...attacks.base.misc", 0);
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "...attacks.base.temporary", 0);
	
	-- Determine the weapon's attack stat bonus, if any
	local type = NodeManager.getSafeChildValue(weaponnode, "type", 0);
	local statval = NodeManager.getSafeChildValue(weaponnode, "attackstat", "");
	if statval == "" then
		if type ~= 0 then
			statval = NodeManager.getSafeChildValue(weaponnode, "...attacks.ranged.abilityname", "");
			if statval == "" then
				statval = "dexterity";
			end
		else
			statval = NodeManager.getSafeChildValue(weaponnode, "...attacks.melee.abilityname", "");
			if statval == "" then
				statval = 0;
			end
		end
	end
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "...abilities." .. statval .. ".bonus", 0);
	
	-- Determine the attack type modifiers
	if type ~= 0 then
		mod = mod + NodeManager.getSafeChildValue(weaponnode, "...attacks.ranged.misc", 0);
		mod = mod + NodeManager.getSafeChildValue(weaponnode, "...attacks.ranged.temporary", 0);
	else
		mod = mod + NodeManager.getSafeChildValue(weaponnode, "...attacks.melee.misc", 0);
		mod = mod + NodeManager.getSafeChildValue(weaponnode, "...attacks.melee.temporary", 0);
	end
	
	-- Determine the weapon's attack bonus, if any
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "bonus", 0);
	
	-- Return the attack information
	return text, mod;
end

function getWeaponDamage(weaponnode)
	local text = "";
	local dice = {};
	local mod = 0;
	
	-- Validate parameters
	if not weaponnode then
		return text, dice, mod;
	end
	
	-- Determine if this is a critical roll
	local isCritical = Input.isShiftPressed();
	
	-- Add the damage type to the output
	text = text .. "[DAMAGE] ";
	
	-- Add the weapon's name to the output
	text = text .. NodeManager.getSafeChildValue(weaponnode, "name", "");
	
	-- Add the damage type to the output
	local dmgtype = NodeManager.getSafeChildValue(weaponnode, "damagetype", "");
	local critdmgtype = NodeManager.getSafeChildValue(weaponnode, "criticaldamagetype", "");
	if isCritical and critdmgtype ~= "" then
		if dmgtype ~= "" then
			dmgtype = dmgtype .. ",";
		end
		dmgtype = dmgtype .. critdmgtype;
	end
	if dmgtype ~= "" then
		text = text .. " [" .. dmgtype .. "]";
	end

	-- Get the weapon's damage dice
	local baseweapondice = NodeManager.getSafeChildValue(weaponnode, "damagedice", {});
	if not baseweapondice then
		baseweapondice = {};
	end
	
	-- Determine the basic attack damage multiple (1 for L1-20, 2 for L21-30)
	local mult = 1;
	local level = NodeManager.getSafeChildValue(weaponnode, "...level", 0);
	if level > 20 then
		mult = 2;
	end

	-- Note special weapon properties we want to handle
	local properties = string.lower(NodeManager.getSafeChildValue(weaponnode, "properties", ""));
	local prop_highcrit = string.match(properties, "high crit");
	local prop_brutal = string.match(properties, "brutal (%d)");
	local prop_vorpal = string.match(properties, "vorpal");
	
	-- Add the weapon dice to the total dice, taking into account level multiplier
	for i = 1, mult do
		for j, die in ipairs(baseweapondice) do
			table.insert(dice, die);
		end
	end

	-- Add in the base damage modifiers
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "...attacks.damage.misc", 0);
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "...attacks.damage.temporary", 0);

	-- Add the weapon's stat damage bonus
	local statval = NodeManager.getSafeChildValue(weaponnode, "damagestat", "");
	if statval == "" then
		local type = NodeManager.getSafeChildValue(weaponnode, "type", 0);
		if type ~= 0 then
			if string.match(string.lower(properties), "heavy thrown") then
				statval = 0;
			else
				statval = 0;
			end
		else
			statval = 0;
		end
	end
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "...abilities." .. statval .. ".bonus", 0);
	
	-- Add the weapon's damage bonus
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "damagebonus", 0);

	-- If SHIFT is pressed, then make it a critical
	if isCritical then
		-- Check for high crit weapons (1[W] at L1-10, 2[W] at L11-20, 3[W] at L21-30)
		local highcritdice = {};
		if prop_highcrit then
			text = text .. " [HIGH CRIT]";

			local highcritmult = 1;
			if level > 20 then
				highcritmult = 3;
			elseif level > 10 then
				highcritmult = 2;
			end
			
			for i = 1, highcritmult do
				for j, die in ipairs(baseweapondice) do
					table.insert(highcritdice, die);
				end
			end
		end
		
		-- Grab any extra critical dice assigned to weapon
		local extracritdice = NodeManager.getSafeChildValue(weaponnode, "criticaldice", {});
		if not extracritdice then
			extracritdice = {};
		end

		-- Add up all the critical dice 
		local i, die;
		dice = {};
		for i = 1, mult do
			for j, die in ipairs(baseweapondice) do
				local diestring = string.match(die, "d%d+");
				if diestring then
					table.insert(dice, "max" .. string.sub(diestring, 2));
				else
					table.insert(dice, die);
				end
			end
		end
		for i, die in ipairs(highcritdice) do
			table.insert(dice, die);
		end
		for i, die in ipairs(extracritdice) do
			table.insert(dice, die);
		end
		
		-- Grab the critical modifier bonus
		mod = mod + NodeManager.getSafeChildValue(weaponnode, "criticalbonus", 0);
	end
	
	-- Handle vorpal and brutal properties
	if prop_brutal then
		text = text .. " [BRUTAL " .. prop_brutal .. " (" .. #dice .. "D)]";
	end
	if prop_vorpal then
		text = text .. " [VORPAL]";
	end

	-- Add the critical flag last, so it is easily visible
	if isCritical then
		text = text .. " [CRITICAL]";
	end

	-- If dice are empty, put a placeholder in
	-- NOTE: Prevents GM static damage rolls from showing when GM rolls are hidden (i.e. minion damage)
	if #dice == 0 then
		dice = { "d0" };
	end
	
	-- Return the damage information
	return text, dice, mod;
end

function getWeaponCritical(weaponnode)
	local text = "";
	local dice = {};
	local mod = 0;
	
	-- Validate parameters
	if not weaponnode then
		return text, dice, mod;
	end
	
	-- Add the damage type to the output
	text = text .. "[DAMAGE] ";
	
	-- Add the weapon's name to the output
	text = text .. NodeManager.getSafeChildValue(weaponnode, "name", "");
	
	-- Add the damage type to the output
	local critdmgtype = NodeManager.getSafeChildValue(weaponnode, "criticaldamagetype", "");
	if critdmgtype ~= "" then
		text = text .. " [" .. critdmgtype .. "]";
	end

	-- Add a node showing that this is a damage roll
	text = text .. " (Critical Bonus Dice)";
	
	-- Get the weapon's critical damage dice
	dice = NodeManager.getSafeChildValue(weaponnode, "criticaldice", {});
	if not dice then
		dice = {};
	end

	-- Add the weapon's critical damage bonus
	mod = mod + NodeManager.getSafeChildValue(weaponnode, "criticalbonus", 0);

	-- If dice are empty, put a placeholder in
	-- NOTE: Prevents GM static damage rolls from showing when GM rolls are hidden (i.e. minion damage)
	if #dice == 0 then
		dice = { "d0" };
	end
	
	-- Return the damage information
	return text, dice, mod;
end

function getDefaultFocus(charnode, focustype)
	-- Make sure we have a correct parameter
	local tool_order = 0;
	if focustype == "weapon" then
		tool_order = NodeManager.getSafeChildValue(charnode, "powerfocus.weapon.order", 0);
	elseif focustype == "implement" then
		tool_order = NodeManager.getSafeChildValue(charnode, "powerfocus.implement.order", 0);
	else
		return nil;
	end
	
	-- Look up the weapon node to make sure it is valid
	local weapon_node = nil;
	if tool_order > 0 then
		local weapons_node = charnode.getChild("weaponlist");
		if weapons_node then
			for k, v in pairs(weapons_node.getChildren()) do
				local order = NodeManager.getSafeChildValue(v, "order", 0);
				if order == tool_order then
					weapon_node = v;
				end
			end
		end
	end
	
	-- Return the weapon node found
	return weapon_node;
end

function getPowerFocus(powerattacknode)
	-- Validate parameters
	if not powerattacknode then
		return nil;
	end
	
	-- Get this attack's focus, if any
	local tool_order = NodeManager.getSafeChildValue(powerattacknode, "focus", 0);
	
	-- If no focus specified, then look up the default for this type of power
	if tool_order == 0 then
		local isWeaponPower = false;
		local isImplementPower = false;

		local keywords = string.lower(NodeManager.getSafeChildValue(powerattacknode, "...keywords", ""));
		if string.match(keywords, "weapon") then
			isWeaponPower = true;
		elseif string.match(keywords, "implement") then
			isImplementPower = true;
		end

		if isWeaponPower then
			tool_order = NodeManager.getSafeChildValue(powerattacknode, ".......powerfocus.weapon.order", 0);
		elseif isImplementPower then
			tool_order = NodeManager.getSafeChildValue(powerattacknode, ".......powerfocus.implement.order", 0);
		end
	end
	
	-- Look up the weapon or implement specified
	local weapon_node = nil;
	if tool_order > 0 then
		local weapons_node = powerattacknode.getChild(".......weaponlist");
		if weapons_node then
			for k, v in pairs(weapons_node.getChildren()) do
				local order = NodeManager.getSafeChildValue(v, "order", 0);
				if order == tool_order then
					weapon_node = v;
				end
			end
		end
	end
	
	-- Return the node of the weapon used as a focus for this power
	return weapon_node;
end

function getPowerAttack(powerattacknode)
	local text = "";
	local mod = 0;
	
	-- Validate parameters
	if not powerattacknode then
		return text, mod;
	end
	
	-- Add the power's number to the output
	local order = NodeManager.getSafeChildValue(powerattacknode, "order", "0");
	if order > 1 then
		text = "[ATTACK #" .. order .. "] ";
	else
		text = "[ATTACK] ";
	end
	
	-- Add the power's name to the output
	text = text .. NodeManager.getSafeChildValue(powerattacknode, "...name", "");
	
	-- Add the power's target defense to the output
	local defval = NodeManager.getSafeChildValue(powerattacknode, "attackdef", "");
	if defval == "ac" then
		text = text .. " (vs. AC)";
	elseif defval == "fortitude" then
		text = text .. " (vs. Fort)";
	elseif defval == "reflex" then
		text = text .. " (vs. Ref)";
	elseif defval == "will" then
		text = text .. " (vs. Will)";
	end
	
	-- Add in the base modifiers
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......levelbonus", 0);
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......attacks.base.misc", 0);
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......attacks.base.temporary", 0);
	
	-- Determine the attack type modifiers
	local range = string.lower(NodeManager.getSafeChildValue(powerattacknode, "...range", ""));
	if string.match(range, "melee") then
		mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......attacks.melee.misc", 0);
		mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......attacks.melee.temporary", 0);
	else
		mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......attacks.ranged.misc", 0);
		mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......attacks.ranged.temporary", 0);
	end

	-- Add the power's attack stat modifier
	local statval = NodeManager.getSafeChildValue(powerattacknode, "attackstat", "");
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......abilities." .. statval .. ".bonus", 0);
	
	-- Add the power's attack modifier
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, "attackstatmodifier", 0);
	
	-- If we have an assigned weapon or implement, then determine the focus attack bonus (and possibly add the weapon name)
	local tool_node = getPowerFocus(powerattacknode);
	if tool_node then
		mod = mod + NodeManager.getSafeChildValue(tool_node, "bonus", 0);

		if OptionsManager.isOption("SWPN", "on") then
			text = text .. " (using " .. NodeManager.getSafeChildValue(tool_node, "name", "") .. ")";
		end
	end
	
	-- Return the attack information
	return text, mod;
end

function getPowerDamage(powerattacknode)
	local text = "";
	local dice = {};
	local mod = 0;
	
	-- Validate parameters
	if not powerattacknode then
		return text, dice, mod;
	end
	
	-- See if this damage roll is supposed to be a critical
	local isCritical = Input.isShiftPressed();
	
	-- Add the power's number to the output
	local order = NodeManager.getSafeChildValue(powerattacknode, "order", "0");
	if order > 1 then
		text = "[DAMAGE #" .. order .. "] ";
	else
		text = "[DAMAGE] ";
	end
	
	-- Add the power's name to the output
	text = text .. NodeManager.getSafeChildValue(powerattacknode, "...name", "");

	-- Add in the base damage modifiers
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......attacks.damage.misc", 0);
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......attacks.damage.temporary", 0);

	-- Add the power's first damage stat modifier
	local statval = NodeManager.getSafeChildValue(powerattacknode, "damagestat", "");
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......abilities." .. statval .. ".bonus", 0);
	
	-- Add the power's second damage stat modifier
	local statval2 = NodeManager.getSafeChildValue(powerattacknode, "damagestat2", "");
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, ".......abilities." .. statval2 .. ".bonus", 0);
	
	-- Add the power's damage modifier
	mod = mod + NodeManager.getSafeChildValue(powerattacknode, "damagestatmodifier", 0);
	
	-- Determine if we have an assigned weapon or implement for this power attack
	local tool_node = getPowerFocus(powerattacknode);
	
	-- Add the power's damage type, if any
	local powerdmgtype = NodeManager.getSafeChildValue(powerattacknode, "damagetype", "");
	local focusdmgtype = NodeManager.getSafeChildValue(tool_node, "damagetype", "");
	local focuscritdmgtype = NodeManager.getSafeChildValue(tool_node, "criticaldamagetype", "");
	local dmgtype = powerdmgtype;
	if focusdmgtype ~= "" then
		if dmgtype ~= "" then
			dmgtype = dmgtype .. ",";
		end
		dmgtype = dmgtype .. focusdmgtype;
	end
	if isCritical and focuscritdmgtype ~= "" then
		if dmgtype ~= "" then
			dmgtype = dmgtype .. ",";
		end
		dmgtype = dmgtype .. focuscritdmgtype;
	end
	if dmgtype ~= "" then
		text = text .. " [" .. dmgtype .. "]";
	end

	-- Handle weapon powers
	local keywords = string.lower(NodeManager.getSafeChildValue(powerattacknode, "...keywords", ""));
	if string.match(keywords, "weapon") then
		-- Note special weapon properties we want to handle
		local properties = string.lower(NodeManager.getSafeChildValue(tool_node, "properties", ""));
		local prop_highcrit = string.match(properties, "high crit");
		local prop_brutal = string.match(properties, "brutal (%d)");
		local prop_vorpal = string.match(properties, "vorpal");

		-- Determine the weapon's base dice
		local baseweapondice = NodeManager.getSafeChildValue(tool_node, "damagedice", {});
		if not baseweapondice then
			baseweapondice = {};
		end

		-- Multiply by the power's weapon damage multiplier
		local mult = NodeManager.getSafeChildValue(powerattacknode, "damageweaponmult", 0);
		local multweapondice = {};
		for i = 1, mult do
			for j, die in ipairs(baseweapondice) do
				table.insert(multweapondice, die);
			end
		end
		if isCritical then
			for i, die in ipairs(multweapondice) do
				local diestring = string.match(die, "d%d+");
				if diestring then
					multweapondice[i] = "max" .. string.sub(diestring, 2);
				end
			end
		end
		
		-- Add the dice to the damage dice list
		for i, die in ipairs(multweapondice) do
			table.insert(dice, die);
		end
		
		-- Get high crit damage, if appropriate
		if isCritical then
			-- Check for high crit weapons (1[W] at L1-10, 2[W] at L11-20, 3[W] at L21-30)
			local highcritdice = {};
			if prop_highcrit then
				text = text .. " [HIGH CRIT]";

				local level = NodeManager.getSafeChildValue(powerattacknode, ".......level", 0);
				local highcritmult = 1;
				if level > 20 then
					highcritmult = 3;
				elseif level > 10 then
					highcritmult = 2;
				end

				for i = 1, highcritmult do
					for j, die in ipairs(baseweapondice) do
						table.insert(highcritdice, die);
					end
				end
			end
		
			-- Add the high crit dice
			for i, die in ipairs(highcritdice) do
				table.insert(dice, die);
			end
		end

		-- Handle brutal and vorpal properties
		if prop_brutal then
			text = text .. " [BRUTAL " .. prop_brutal .. " (" .. #dice .. "D)]";
		end
		if prop_vorpal then
			text = text .. " [VORPAL]";
		end
	end
	
	-- Add any basic damage dice
	local basicdice = NodeManager.getSafeChildValue(powerattacknode, "damagebasicdice", {});
	if not basicdice then
		basicdice = {};
	end
	if isCritical then
		-- Convert the dice to maximum dice
		for i, die in ipairs(basicdice) do
			local diestring = string.match(die, "d%d+");
			if diestring then
				basicdice[i] = "max" .. string.sub(diestring, 2);
			end
		end
	end
	for i,die in ipairs(basicdice) do
		table.insert(dice, die);
	end
	
	-- Add any critical damage dice from power focus
	if isCritical then
		-- Get extra critical dice for focus
		local extracritdice = NodeManager.getSafeChildValue(tool_node, "criticaldice", {});
		if not extracritdice then
			extracritdice = {};
		end

		-- Add any critical dice from focus
		for j = 1, #extracritdice do
			table.insert(dice, extracritdice[j]);
		end
	end

	-- Add the power focus damage bonus if the dice is not empty
	-- (i.e. fixed damage attacks do not gain focus damage bonuses (i.e. Cleave secondary))
	if #dice > 0 then
		mod = mod + NodeManager.getSafeChildValue(tool_node, "damagebonus", 0);
	end

	-- If dice are empty, put a placeholder in
	-- NOTE: Prevents GM static damage rolls from showing when GM rolls are hidden (i.e. minion damage)
	if #dice == 0 then
		dice = { "d0" };
	end
	
	-- Add the critical label, if needed
	if isCritical then
		text = text .. " [CRITICAL]";
	end
	
	-- Add the weapon name to the power damage output, if option enabled
	if tool_node and OptionsManager.isOption("SWPN", "on") then
		text = text .. " (using " .. NodeManager.getSafeChildValue(tool_node, "name", "") .. ")";
	end
	
	-- Return the attack information
	return text, dice, mod;
end

function useHealingSurge(charnode)
	-- Validate parameters
	if not charnode then
		return;
	end
	
	-- Get the character's current wounds value
	local woundsval = NodeManager.getSafeChildValue(charnode, "hp.wounds", 0);
	
	-- If the character is not wounded, then let the user know and exit
	if woundsval <= 0 then
		ChatManager.Message("Character is unwounded, healing surge not used.");
		return;
	end
	
	-- Determine whether the character has any healing surges remaining
	local expendval = NodeManager.getSafeChildValue(charnode, "hp.surgesused", 0);
	local maxval = NodeManager.getSafeChildValue(charnode, "hp.surgesmax", 0);
	if expendval >= maxval then
		ChatManager.Message("Character has no healing surges remaining.");
		return;
	end
	
	-- Determine the message and amount of healing surge
	local text = "Healing surge used.";
	local surgeval = NodeManager.getSafeChildValue(charnode, "hp.surge", 0);
	if not ModifierStack.isEmpty() then
		text = text .. " (" .. ModifierStack.getDescription(true) .. ")";
		surgeval = surgeval + ModifierStack.getSum();
		ModifierStack.reset();
	end
	
	-- Determine if wounds are greater than hit points.
	-- Applying a healing surge returns the character to zero, before applying healing surge
	local hpval = NodeManager.getSafeChildValue(charnode, "hp.total", 0);
	if woundsval > hpval then
		woundsval = hpval;
	end
	
	-- Apply the healing surge
	NodeManager.setSafeChildValue(charnode, "hp.surgesused", "number", expendval + 1);
	NodeManager.setSafeChildValue(charnode, "hp.wounds", "number", math.max(woundsval - surgeval, 0));
	
	-- Send the message to everyone
	ChatManager.Message(text, true, {pc = charnode});
end

function useActionPoint(charnode)
	-- Validate parameters
	if not charnode then
		return;
	end
	
	-- Get the character's current action point value
	local ap = NodeManager.getSafeChildValue(charnode, "actionpoints", 0);

	-- If the character has no action points, then exit
	if ap <= 0 then
		return;
	end

	-- Decrement an action point
	NodeManager.setSafeChildValue(charnode, "actionpoints", "number", ap - 1);

	-- Send the message to everyone
	local text = "Action point used.";
	ChatManager.Message(text, true, {pc = charnode});
end

function rest(charnode, extended)
	if extended == true then
		resetPowers(charnode, extended);
		resetHealth(charnode, extended);
		resetActionPoints(charnode);
	else
		resetPowers(charnode);
		resetHealth(charnode);
	end
end

function resetPowers(charnode, extended)
	-- Get the overall powernode
	local powersnode = charnode.getChild("powers");
	if not powersnode then
		return;
	end
	
	-- Cycle over each power type
	-- If extended rest, then reset all powers
	-- If short rest, then reset encounter powers only
	for typekey,typenode in pairs(powersnode.getChildren()) do
		local powerhighnode = typenode.getChild("power");
		if powerhighnode then
			for powerkey,powernode in pairs(powerhighnode.getChildren()) do
				if extended == true then
					NodeManager.setSafeChildValue(powernode, "used", "number", 0);
				else
					local rechargeval = string.lower(string.sub(NodeManager.getSafeChildValue(powernode, "recharge", ""),1,3));
					if rechargeval == "enc" then
						NodeManager.setSafeChildValue(powernode, "used", "number", 0);
					end
				end
			end
		end
	end
end

function resetHealth(charnode, extended)
	NodeManager.setSafeChildValue(charnode, "hp.temporary", "number", 0);
	NodeManager.setSafeChildValue(charnode, "hp.secondwind", "number", 0);
	NodeManager.setSafeChildValue(charnode, "hp.faileddeathsaves", "number", 0);
	
	if extended == true then
		NodeManager.setSafeChildValue(charnode, "hp.wounds", "number", 0);
		NodeManager.setSafeChildValue(charnode, "hp.surgesused", "number", 0);
	end
end

function resetActionPoints(charnode)
	NodeManager.setSafeChildValue(charnode, "actionpoints", "number", 1);
end

