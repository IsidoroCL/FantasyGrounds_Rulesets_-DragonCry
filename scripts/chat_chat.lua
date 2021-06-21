-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ChatManager.registerControl(self);
	
	if User.isHost() then
		Module.onActivationRequested = moduleActivationRequested;
	end

	Module.onUnloadedReference = moduleUnloadedReference;

	deliverLaunchMessage()
end

function deliverLaunchMessage()
    local msg = {sender = "", font = "narratorfont"};
    msg.text = "DragonCry 4ªEd. Revisada. Reglas por Isidoro Campaña Lozano y Alfonso García Martín. Adaptación para Fantasy Grounds II por Isidoro Campaña Lozano."
    addMessage(msg);
    msg.text = "Artwork derived from the 'd20' ruleset is copyright of SmiteWorks Ltd.";
    addMessage(msg);
end

function onClose()
	ChatManager.registerControl(nil);
end

function onReceiveMessage(msg)
	-- Special handling for client-host behind the scenes communication
	if ChatManager.processSpecialMessage(msg) then
		return true;
	end
	
	-- Otherwise, let FG know to do standard processing
	return false;
end

function onDiceLanded(draginfo)
	local dragtype = draginfo.getType();
	if dragtype == "attack" or dragtype == "damage" or dragtype == "init" or
	  dragtype == "skill" or dragtype == "dice" then
		processDiceLanded(draginfo);
		return true;
	elseif dragtype == "save" then
		processSaveRoll(draginfo);
		return true;
	elseif dragtype == "recharge" then
		processRechargeRoll(draginfo);
		return true;
	end
end

function onDrop(x, y, draginfo)
	if draginfo.getType() == "effect" then
		draginfo.setSlot(2);
		local eff_nodename = draginfo.getStringData();
		if eff_nodename then
			local eff_node = DB.findNode(eff_nodename);
			if eff_node then
				ChatManager.reportEffect(eff_node);
			end
		end
		return true;
	end
end

function moduleActivationRequested(module)
	local msg = {};
	msg.text = "Players have requested permission to load '" .. module .. "'";
	msg.font = "systemfont";
	msg.icon = "indicator_moduleloaded";
	addMessage(msg);
end

function moduleUnloadedReference(module)
	local msg = {};
	msg.text = "Could not open sheet with data from unloaded module '" .. module .. "'";
	msg.font = "systemfont";
	addMessage(msg);
end

function checkDie(roll, sides, limit_brutal, prop_vorpal, bonus, reroll_str, add_str)
	-- Handle vorpal property
	if roll == sides then
		if prop_vorpal then
			-- Roll a new die
			local new_die = math.random(sides);

			-- Check the new roll
			new_die, bonus, reroll_str, add_str = checkDie(new_die, sides, limit_brutal, prop_vorpal, bonus, reroll_str, add_str);

			-- Add the final die result to the bonus
			add_str = " " .. new_die .. add_str;
			bonus = bonus + new_die;
		end
		
	-- Handle brutal property
	elseif roll <= limit_brutal then
		if limit_brutal >= sides - 1 then
			-- Add error to output
			reroll_str = reroll_str .. " Brutal too high";
		else
			-- Add failed roll to the output
			reroll_str = reroll_str .. " " .. roll;

			-- Roll a new die
			local new_die = math.random(sides);

			-- Check die again
			roll, bonus, reroll_str, add_str = checkDie(new_die, sides, limit_brutal, prop_vorpal, bonus, reroll_str, add_str);
		end
	end
	
	-- Return the results of the die check
	return roll, bonus, reroll_str, add_str;
end

function processDiceLanded(draginfo)
	-- Figure out what type of roll we're handling
	local dragtype = draginfo.getType();
	
	-- Get any custom data about this roll
	local custom = draginfo.getCustomData();
	if not custom then
		local class, nodename = draginfo.getShortcutData();
		if nodename then
			local node = DB.findNode(nodename);
			if class == "charsheet" then
				custom = {pc = node};
			else
				custom = {npc = node};
			end
		else
			custom = {};
		end
	end

	-- Apply any modifiers
	ModifierStack.applyToRoll(draginfo);

	-- Build the basic message to deliver
	local entry = ChatManager.createBaseMessage(custom);
	entry.text = entry.text .. draginfo.getDescription();
	entry.dice = draginfo.getDieList();
	entry.diemodifier = draginfo.getNumberData();
	
	-- If this is a roll from TheBox, then it should always be secret
	if OptionsManager.isOption("TBOX", "on") then
		local boxindex = string.find(draginfo.getDescription(), "[BOX]", 1, true);
		if boxindex then
			entry.dicesecret = true;
		end
	end
	
	-- If the CTRL key is held down, then reverse the number
	-- Assumption: CTRL key negates diemodifier and provides CTRL hot key bar access
	-- It doesn't make sense that CTRL should negate diemodifier on dice rolls
	if Input.isControlPressed() then
		entry.diemodifier = 0 - draginfo.getNumberData();
	end

	-- Determine if any special dice handling is required
	local prop_brutal, prop_brutal_dice = string.match(draginfo.getDescription(), " %[BRUTAL (%d) %((%d+)D%)%]");
	local limit_brutal = tonumber(prop_brutal) or -1;
	local limit_brutal_dice = tonumber(prop_brutal_dice) or 0;
	local prop_vorpal = string.match(draginfo.getDescription(), " %[VORPAL%]"); 
	
	-- Iterate through the dice to handle some features
	local max_die_used = false;
	local reroll_string = "";
	local add_string = "";
	local total = 0;
	if dragtype == "damage" then
		for i,d in ipairs(entry.dice) do
			if string.sub(d.type, 1, 3) == "max" then
				max_die_used = true;
			else
				local str_die = string.match(d.type, "d(%d+)");
				local die_sides = tonumber(str_die) or 0;
				if die_sides > 0 then
					local die_reroll_str = "";
					local die_add_str = "";
					local die_bonus = 0;
					
					local local_brutal = -1;
					if i <= limit_brutal_dice then
						local_brutal = limit_brutal;
					end
					
					d.result, die_bonus, die_reroll_str, die_add_str = checkDie(d.result, die_sides, local_brutal, prop_vorpal, die_bonus, die_reroll_str, die_add_str);
					entry.diemodifier = entry.diemodifier + die_bonus;

					if die_reroll_str ~= "" then
						if reroll_string ~= "" then
							reroll_string = reroll_string .. ",";
						end
						reroll_string = reroll_string .. " Die " .. i .. ":" .. die_reroll_str;
					end
					if die_add_str ~= "" then
						if add_string ~= "" then
							add_string = add_string .. ",";
						end
						add_string = add_string .. " Die " .. i .. ":" .. die_add_str;
					end
				end
			end

			-- Build the total
			total = total + d.result;
		end
	else
		for i,d in ipairs(entry.dice) do
			if string.sub(d.type, 1, 3) == "max" then
				max_die_used = true;
			end

			-- Build the total
			total = total + d.result;
		end
	end
	
	-- Add the roll modifier to the total
	total = total + entry.diemodifier;

	-- Check for special attack results
	local add_total = true;
	local result_str = "";
	if dragtype == "attack" then
		-- If we have a target, then calculate the defense we need to exceed
		local defenseval = nil;
		if User.isHost() or OptionsManager.isOption("PATK", "on") then
			local defense = string.match(draginfo.getDescription(), "%(vs%.? (%a+)%)");
			if custom["targetpc"] then
				defenseval = CombatCommon.getDefenseValue("pc", custom["targetpc"], defense);
			elseif custom["targetct"] then
				defenseval = CombatCommon.getDefenseValue("ct", custom["targetct"], defense);
			end
		end

		-- Check for the result of the attack roll based on the die roll and the defense
		local isSpecialHit = false;
		local first_die = entry.dice[1].result or 0;
		local crit_threshold = 20;
		if first_die >= crit_threshold then
			isSpecialHit = true;
			if not custom["pc"] and OptionsManager.isOption("REVL", "off") then
				ChatManager.Message("[GM] Original attack = " .. first_die .. "+" .. entry.diemodifier .. "=" .. total, false);
				entry.diemodifier = 0;
				add_total = false;
			end
			if defenseval then
				if total >= defenseval then
					result_str = " [CRITICAL HIT]";
				else
					result_str = " [AUTOMATIC HIT]";
				end
			else
				result_str = " [AUTOMATIC HIT, CHECK FOR CRITICAL]";
			end
		elseif first_die == 1 then
			isSpecialHit = true;
			if not custom["pc"] and OptionsManager.isOption("REVL", "off") then
				entry.diemodifier = 0;
				add_total = false;
			end
			result_str = " [AUTOMATIC MISS]";
		elseif defenseval then
			if total >= defenseval then
				result_str = " [HIT]";
			else
				result_str = " [MISS]";
			end
		end
	end
			
	-- If we have a target, then add their name and portrait to the message (if available)
	if custom["targetpc"] then
		-- If so, add their name portrait to the message
		if dragtype == "attack" then
			entry.text = entry.text .. " [at " .. NodeManager.getSafeChildValue(DB.findNode(custom["targetpc"]), "name", "") .. "]";
		elseif dragtype == "damage" then
			entry.text = entry.text .. " [to " .. NodeManager.getSafeChildValue(DB.findNode(custom["targetpc"]), "name", "") .. "]";
		end
		entry.icon = "portrait_" .. custom["targetpc"] .. "_targetportrait";
	elseif custom["targetct"] then
		if dragtype == "attack" then
			local node = DB.findNode(custom["targetct"] .. ".name");
			if node then
				entry.text = entry.text .. " [at " .. NodeManager.getSafeChildValue(DB.findNode(custom["targetct"]), "name", "") .. "]";
			end
		elseif dragtype == "damage" then
			entry.text = entry.text .. " [to " .. NodeManager.getSafeChildValue(DB.findNode(custom["targetct"]), "name", "") .. "]";
		end
	end

	-- Report any brutal rerolls or vorpal adding rolls
	if reroll_string ~= "" then
		result_str = result_str .. " [REROLL " .. reroll_string .. "]";
	end
	if add_string ~= "" then
		result_str = result_str .. " [ADD " .. add_string .. "]";
	end
	
	-- Report any use of max dice outside of criticals
	if max_die_used and (not string.match(draginfo.getDescription(), "[CRITICAL]", 0, true)) then
		result_str = result_str .. " [MAX DIE USED]";
	end
	
	-- Add the total, if the auto-total option is on
	if OptionsManager.isOption("TOTL", "on") and add_total then
		result_str = result_str .. " [" .. total .. "]";
	end
	
	-- Add any special results
	if result_str ~= "" then
		entry.text = entry.text .. result_str;
	end

	-- Deliver the chat entry
	deliverMessage(entry);

	-- Special handling of final results
	if dragtype == "damage" then
		-- Apply damage to the PC or combattracker entry referenced
		if User.isHost() or OptionsManager.isOption("PDMG", "on") then
			if custom["targetpc"] then
				ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_APPLYDMG, {total, "pc", custom["targetpc"]});
			elseif custom["targetct"] then
				ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_APPLYDMG, {total, "ct", custom["targetct"]});
			end
		end

	elseif dragtype == "init" then
		-- Set the initiative for this creature in the combat tracker
		local ct_node = DB.findNode("combattracker");
		if ct_node then
			local custom_nodename = nil;
			if custom then
				if custom["pc"] then
					custom_nodename = custom["pc"].getNodeName()
				end
				if custom["npc"] then
					custom_nodename = custom["npc"].getNodeName()
				end
			end
			if custom_nodename then
				-- Check for exact CT match
				for k, v in pairs(ct_node.getChildren()) do
					if v.getNodeName() == custom_nodename then
						v.getChild("initresult").setValue(total);
					end
				end
				-- Otherwise, check for link match
				for k, v in pairs(ct_node.getChildren()) do
					local node_class, node_ref = v.getChild("link").getValue();
					if node_ref == custom_nodename then
						v.getChild("initresult").setValue(total);
					end
				end
			end
		end
	end
end

function processSaveRoll(draginfo)
	-- Get any custom data about this roll
	local custom = draginfo.getCustomData();
	if not custom then
		custom = {};

		local class, nodename = draginfo.getShortcutData();
		if nodename then
			local node = DB.findNode(nodename);
			if class == "charsheet" then
				custom["pc"] = node;
			else
				custom["npc"] = node;
			end
		end
		
		local eff_nodename = draginfo.getStringData();
		if eff_nodename then
			custom["effect"] = DB.findNode(eff_nodename);
		end
	end
	
	-- Build the basic message to deliver
	local entry = ChatManager.createBaseMessage(custom);
	entry.text = entry.text .. draginfo.getDescription();
	entry.dice = draginfo.getDieList();
	entry.diemodifier = draginfo.getNumberData();
	entry.dicesecret = true;

	-- Calculate the total
	local total = 0;
	for i,d in ipairs(entry.dice) do
		total = total + d.result;
	end
	total = total + entry.diemodifier;
	
	-- Determine success of failure
	if total > 9 then
		entry.text = entry.text .. " [SUCCESS";

		-- Determine whether we should remove
		if OptionsManager.isOption("RSAV", "on") then
			if custom["effect"] then
				-- Make sure we are on the host
				if User.isHost() then
					local eff_exp = NodeManager.getSafeChildValue(custom["effect"], "expiration", "");
					if eff_exp == "save" then
						entry.text = entry.text .. "*";
						local effectlistnode = custom["effect"].getParent();
						custom["effect"].delete();
						if effectlistnode.getChildCount() == 0 then
							NodeManager.createSafeChild(effectlistnode);
						end
					end
				else
					ChatManager.SystemMessage("[ERROR] Received save roll with effect link on client");
				end
			end
		end
		
		entry.text = entry.text .. "]";
	else
		entry.text = entry.text .. " [FAILURE]";
	end

	-- Deliver the message
	deliverMessage(entry);
end

function processRechargeRoll(draginfo)
	-- Make sure we are on the host
	if not User.isHost() then
		ChatManager.SystemMessage("[ERROR] Received recharge roll on client");
		return;
	end
	
	-- Get any custom data about this roll
	local custom = draginfo.getCustomData();
	if not custom then
		local class, nodename = draginfo.getShortcutData();
		if nodename then
			local node = DB.findNode(nodename);
			if class == "charsheet" then
				custom = {pc = node};
			else
				custom = {npc = node};
			end
		else
			custom = {};
		end
	end
	
	-- Build the basic message to deliver
	local entry = ChatManager.createBaseMessage(custom);
	entry.text = entry.text .. draginfo.getDescription();
	entry.dice = draginfo.getDieList();
	entry.diemodifier = draginfo.getNumberData();
	entry.dicesecret = true;

	-- Calculate the total
	local total = 0;
	for i,d in ipairs(entry.dice) do
		total = total + d.result;
	end
	total = total + entry.diemodifier;

	-- Determine whether we have the right references to automatically handle recharge
	if custom["effect"] then
		-- Make sure the target effect is a recharge, and compare the value
		local eff_name = NodeManager.getSafeChildValue(custom["effect"], "label", "");
		local effectlist = CombatCommon.parseEffect(eff_name);
		if #effectlist > 0 then
			if effectlist[1].type == "RCHG" then
				local recharge_val = tonumber(effectlist[1].val) or 6;
				if total >= recharge_val then
					-- If we successfully recharged, note it and remove the effect
					entry.text = entry.text .. " [RECHARGED]";
					local effectlistnode = custom["effect"].getParent();
					custom["effect"].delete();
					if effectlistnode.getChildCount() == 0 then
						NodeManager.createSafeChild(effectlistnode);
					end
					
					-- Also, remove the [USED] marker from Atk line
					local ctentry_node = effectlistnode.getParent();
					local atk_string = NodeManager.getSafeChildValue(ctentry_node, "atk", "");
					local powers = CombatCommon.parseCTAttackLine(atk_string);
					for k,v in pairs(powers) do
						if effectlist[1].remainder == v.name and v.usage_val and v.usage_val == "USED" then
							local s = string.sub(atk_string, 1, v.usage_startpos - 2) .. string.sub(atk_string, v.usage_endpos + 1);
							NodeManager.setSafeChildValue(ctentry_node, "atk", "string", s);
						end
					end
				end
			end
		end
	end
	
	-- Deliver the message
	deliverMessage(entry);
end

