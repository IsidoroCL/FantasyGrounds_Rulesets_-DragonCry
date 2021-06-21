-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--


--
--  GENERAL
--

function getDefenseValue(nodetype, nodename, defense)
	local defenseval = nil;
	
	if nodetype and nodename and defense then
		local shortdef = string.sub(string.lower(defense), 1, 2);
		local defnodename = nil;
		
		if nodetype == "ct" then
			if shortdef == "ac" then
				defnodename = "ac";
			elseif shortdef == "fo" then
				defnodename = "fortitude";
			elseif shortdef == "re" then
				defnodename = "reflex";
			elseif shortdef == "wi" then
				defnodename = "will";
			end
		elseif nodetype == "pc" then
			if shortdef == "ac" then
				defnodename = "defenses.ac.total";
			elseif shortdef == "fo" then
				defnodename = "defenses.fortitude.total";
			elseif shortdef == "re" then
				defnodename = "defenses.reflex.total";
			elseif shortdef == "wi" then
				defnodename = "defenses.will.total";
			end
		end

		local defnode = nil;
		if defnodename then
			defnode = DB.findNode(nodename .. "." .. defnodename);
		end
		if defnode then
			defenseval = defnode.getValue();
		end
	end
	
	return defenseval;
end


--
--  NODE TRANSLATION
--

function getActiveCT()
	local node_list = DB.findNode("combattracker");
	for k,v in pairs(node_list.getChildren()) do
		if NodeManager.getSafeChildValue(v, "active", 0) == 1 then
			return v;
		end
	end
end

function getCTFromPC(charnodename)
	-- Make sure we have a CT to browse through
	local ctnode = DB.findNode("combattracker");
	if not ctnode then
		return;
	end
	
	-- Iterate through CT nodes to find this PC
	for k,v in pairs(ctnode.getChildren()) do
		local link = v.getChild("link");
		if link then
			local refclass, refname = link.getValue();
			if refname == charnodename then
				return v;
			end
		end
	end
	
	-- If no match, then return nil
	return nil;
end

function getUserFromCT(ctentrynode)
	-- Get the link field from the entry
	local link = ctentrynode.getChild("link");
	if not link then
		return;
	end
	
	-- Get the class and name from the link
	local refclass, refname = link.getValue();
	
	-- If this is not a PC entry, then there is no owner
	if refclass ~= "charsheet" then
		return;
	end
	
	-- Get the node for the target PC reference
	local pcnode = DB.findNode(refname);
	if not pcnode then
		return;
	end
	
	-- Get the user for the target PC
	return pcnode.getOwner();
end

--
-- DROP HANDLING
--

function onDrop(nodetype, nodename, draginfo)
	local dragtype = draginfo.getType();
	
	-- ATTACK ROLLS
	if dragtype == "attack" then
		onAttackDrop(nodetype, nodename, draginfo);
		return true;
	end
	
	-- DAMAGE ROLLS
	if dragtype == "damage" then
		onDamageDrop(nodetype, nodename, draginfo);
		return true;
	end

	-- EFFECT (LABEL DRAG)
	if dragtype == "effect" then
		onEffectClassDrop(nodetype, nodename, draginfo);
		return true;
	end
	
	-- NUMBER DROPS
	if dragtype == "number" then
		onNumberDrop(nodetype, nodename, draginfo);
		return true;
	end
end

function onNumberDrop(nodetype, nodename, draginfo)
	-- Check for attack strings
	if string.match(draginfo.getDescription(), "%[ATTACK") then
		onAttackResultDrop(nodetype, nodename, draginfo);
		return;
	end

	-- Check for damage strings
	if string.match(draginfo.getDescription(), "%[DAMAGE") then
		onDamageResultDrop(nodetype, nodename, draginfo);
		return;
	end

	-- Check for effect strings
	if string.match(draginfo.getDescription(), "%[EFFECT") then
		onEffectResultDrop(nodetype, nodename, draginfo);
		return;
	end
end

function buildCustomRollArray(nodetype, nodename, draginfo)
	local custom = {};

	local class = draginfo.getShortcutData();
	if class == "charsheet" then
		custom["pc"] = draginfo.getDatabaseNode();
	else
		custom["npc"] = draginfo.getDatabaseNode();
	end
	if nodetype == "pc" then
		custom["targetpc"] = nodename;
	elseif nodetype == "ct" then
		custom["targetct"] = nodename;
	end

	return custom;
end

function onAttackDrop(nodetype, nodename, draginfo)
	if User.isHost() or not OptionsManager.isOption("PATK", "off") then
		local custom = buildCustomRollArray(nodetype, nodename, draginfo);

		ChatManager.d20Check("attack", draginfo.getNumberData(), draginfo.getDescription(), custom);
	end
end

function onDamageDrop(nodetype, nodename, draginfo)
	if User.isHost() or not OptionsManager.isOption("PDMG", "off") then
		local custom = buildCustomRollArray(nodetype, nodename, draginfo);

		local dice = {};
		if draginfo.getDieList() then
			for k, v in pairs(draginfo.getDieList()) do
				table.insert(dice, v["type"]);
			end
		else
			table.insert(dice, "d0");
		end

		ChatManager.DieControlThrow("damage", draginfo.getNumberData(), draginfo.getDescription(), custom, dice);
	end
end

function onEffectClassDrop(nodetype, nodename, draginfo)
	-- Get the effect database node
	draginfo.setSlot(2);
	local eff_node = nil;
	if draginfo.getStringData() then
		eff_node = DB.findNode(draginfo.getStringData());
	end
	if not eff_node then
		return;
	end

	-- Get the basic effect information
	local eff_name = NodeManager.getSafeChildValue(eff_node, "label", "");
	local eff_exp = NodeManager.getSafeChildValue(eff_node, "expiration", "");
	local eff_savemod = NodeManager.getSafeChildValue(eff_node, "effectsavemod", "");
	local eff_init = NodeManager.getSafeChildValue(eff_node, "effectinit", 0);
	local eff_appliedby = NodeManager.getSafeChildValue(eff_node, "source_name", "");
	
	-- If source field not explicitly set, then check the database node for a PC source
	if eff_appliedby == "" then
		draginfo.setSlot(1);
		local class, drag_nodename = draginfo.getShortcutData();
		if class and drag_nodename then
			local node = DB.findNode(drag_nodename);
			if node then
				if class == "charsheet" then
					eff_appliedby = NodeManager.getSafeChildValue(node, "name", "");

					local ctnode = CombatCommon.getCTFromPC(drag_nodename);
					eff_init = NodeManager.getSafeChildValue(ctnode, "initresult", 0);
				end
			end
		end
	end

	-- Call the general effect drop code
	onEffectDrop(nodetype, nodename, eff_name, eff_exp, eff_savemod, eff_init, eff_appliedby);
end

function onAttackResultDrop(nodetype, nodename, draginfo)
	if User.isHost() or OptionsManager.isOption("PATK", "on") then
		-- Get the target defense
		local defense = string.match(draginfo.getDescription(), "%(vs%.? (%a+)%)");
		local defenseval = getDefenseValue(nodetype, nodename, defense);

		-- If we found a defense value, then compare to the number and output
		if defenseval then
			local targetname = "";
			if nodetype == "ct" then
				targetname = NodeManager.getSafeChildValue(DB.findNode(nodename), "name", "");
			elseif nodetype == "pc" then
				targetname = NodeManager.getSafeChildValue(DB.findNode(nodename), "name", "");
			end
			
			local result_str = "Attack drop [" .. draginfo.getNumberData() .. "] [to " .. targetname .."]";
			if draginfo.getNumberData() >= defenseval then
				result_str = result_str .. " [HIT]";
			else
				result_str = result_str .. " [MISS]";
			end

			if User.isHost() then
				ChatManager.Message(result_str);
			else
				ChatManager.Message(result_str, true);
			end
		end
	end
end

function onDamageResultDrop(nodetype, nodename, draginfo)
	if User.isHost() or OptionsManager.isOption("PDMG", "on") then
		local targetname = "";
		if nodetype == "ct" then
			targetname = NodeManager.getSafeChildValue(DB.findNode(nodename), "name", "");
		elseif nodetype == "pc" then
			targetname = NodeManager.getSafeChildValue(DB.findNode(nodename), "name", "");
		end

		local result_str = "Damage drop [" .. draginfo.getNumberData() .. "] [to " .. targetname .."]";
		if User.isHost() then
			ChatManager.Message(result_str);
		else
			local appliedby = nil;
			local class, drag_nodename = draginfo.getShortcutData();
			if class and drag_nodename then
				local node = DB.findNode(drag_nodename);
				if node then
					appliedby = NodeManager.getSafeChildValue(node, "name", "");
				end
			end
			if appliedby then
				result_str = result_str .. " [by " .. appliedby .. "]";
			end
			ChatManager.Message(result_str, "");
		end

		ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_APPLYDMG, {draginfo.getNumberData(), nodetype, nodename});
	end
end

function onEffectResultDrop(nodetype, nodename, draginfo)
	-- Parse the effect information
	local eff_name, eff_exp = string.match(draginfo.getDescription(), "%[EFFECT%] (.+) EXPIRES ?(%a*)");
	if eff_name and eff_exp then
		-- Default source settings are empty
		local eff_savemod = draginfo.getNumberData();
		local eff_appliedby = "";
		local eff_init = 0;
		
		-- If appliedby field not explicitly set, then check the database node for a PC source
		if eff_appliedby == "" then
			local class, drag_nodename = draginfo.getShortcutData();
			if class and drag_nodename then
				local node = DB.findNode(drag_nodename);
				if node then
					if class == "charsheet" then
						eff_appliedby = NodeManager.getSafeChildValue(node, "name", "");

						local ctnode = CombatCommon.getCTFromPC(drag_nodename);
						eff_init = NodeManager.getSafeChildValue(ctnode, "initresult", 0);
					end
				end
			end
		end

		-- Call the general effect drop code
		onEffectDrop(nodetype, nodename, eff_name, eff_exp, eff_savemod, eff_init, eff_appliedby);
	end
end

function onEffectDrop(nodetype, nodename, eff_name, eff_exp, eff_savemod, eff_init, eff_appliedby)
	-- Special handling for reduced client feature access
	if not User.isHost() then
		-- No work, if client access disabled
		if OptionsManager.isOption("PEFF", "off") then
			return;
		end
		
		-- Report only, if client access set to report
		if OptionsManager.isOption("PEFF", "report") then
			local targetname = "";
			if nodetype == "ct" then
				targetname = NodeManager.getSafeChildValue(DB.findNode(nodename), "name", "");
			elseif nodetype == "pc" then
				targetname = NodeManager.getSafeChildValue(DB.findNode(nodename), "name", "");
			end

			ChatManager.reportEffectFull(eff_name, eff_exp, eff_savemod, targetname);
			return;
		end
	end

	-- If we dropped on character portrait, make sure that character exists in the CT
	if nodetype == "pc" then
		local ctnode = CombatCommon.getCTFromPC(nodename);
		if ctnode then
			nodename = ctnode.getNodeName();
		else
			ChatManager.SystemMessage("[ERROR] Effect dropped on PC which is not listed in the combat tracker.");
			return;
		end
	end
	
	-- If still no source setting, then determine who is applying the effect by current active
	if eff_appliedby == "" then
		local ctnode = nil;
		if User.isHost() then
			ctnode = CombatCommon.getActiveCT();
		else
			ctnode = CombatCommon.getCTFromPC("charsheet." .. User.getCurrentIdentity());
		end
		eff_appliedby = NodeManager.getSafeChildValue(ctnode, "name", "");
		eff_init = NodeManager.getSafeChildValue(ctnode, "initresult", 0);
	end

	-- Add the effect
	ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_APPLYEFF, {nodename, eff_name, eff_exp, eff_savemod, eff_init, eff_appliedby});
end


--
-- DAMAGE APPLICATION
--

function applyDamage(nodetype, node, dmg)
	-- Initialize variables
	local totalhp = 0;
	local temphp = 0;
	local wounds = 0;
	local result = "";
	
	-- Get the correct hit point fields
	if nodetype == "pc" then
		totalhp = NodeManager.getSafeChildValue(node, "hp.total", 0);
		temphp = NodeManager.getSafeChildValue(node, "hp.temporary", 0);
		wounds = NodeManager.getSafeChildValue(node, "hp.wounds", 0);
	elseif nodetype == "ct" then
		totalhp = NodeManager.getSafeChildValue(node, "hp", 0);
		temphp = NodeManager.getSafeChildValue(node, "hptemp", 0);
		wounds = NodeManager.getSafeChildValue(node, "wounds", 0);
	else
		return result;
	end
	
	-- Track the original wounds value
	orig_wounds = wounds;

	-- Apply the damage
	-- Only account for temporary hit points if damage is a positive number, otherwise we're healing
	if dmg > 0 and temphp > 0 then
		if dmg > temphp then
			wounds = wounds + dmg - temphp;
			temphp = 0;
			result = result .. " [PARTIALLY ABSORBED]";
		else
			temphp = temphp - dmg;
			result = result .. " [ABSORBED]";
		end
	else
		wounds = wounds + dmg;
		if wounds < 0 then
			wounds = 0;
		end
	end

	-- Set the correct hit point fields with the new values
	if nodetype == "pc" then
		NodeManager.setSafeChildValue(node, "hp.temporary", "number", temphp);
		NodeManager.setSafeChildValue(node, "hp.wounds", "number", wounds);
	else
		NodeManager.setSafeChildValue(node, "hptemp", "number", temphp);
		NodeManager.setSafeChildValue(node, "wounds", "number", wounds);
	end

	-- Add to the result is damage positive and status changed
	if dmg > 0 then
		local bloodied = totalhp / 2;
		if (orig_wounds < totalhp) and (wounds >= totalhp) then
			result = result .. " [DYING]";
		elseif (orig_wounds < bloodied) and (wounds >= bloodied) then
			result = result .. " [BLOODIED]";
		end
	end
	
	-- Return the result text
	if result ~= "" then
		local msg = {font = "msgfont"};
		msg.text = NodeManager.getSafeChildValue(node, "name", "") .. " ->" .. result;
		ChatManager.deliverMessage(msg);
	end
end

--
-- EFFECTS
--

function parseEffect(s)
	local effectlist = {};
	
	local eff_clause;
	for eff_clause in string.gmatch(s, "([^;]*);?") do
		if eff_clause ~= "" then
			local eff_type, eff_valstr, eff_remainder = string.match(eff_clause, "(%a+): ?(%d+) ?(.*)");
			if eff_type and eff_valstr then
				local eff_val = tonumber(eff_valstr) or 0;
				table.insert(effectlist, {type = eff_type, val = eff_val, remainder = eff_remainder});
			else
				table.insert(effectlist, {type = "", val = 0, remainder = eff_clause});
			end
		end
	end
	
	return effectlist;
end

function removeEffect(node_ctentry, eff_name)
	-- Parameter validation
	if not node_ctentry or not eff_name then
		return;
	end

	-- Make sure we can get to the effects list
	local node_list_effects = NodeManager.createSafeChild(node_ctentry, "effects");
	if not node_list_effects then
		return;
	end

	-- Cycle through the effects list, and compare names
	for k,v in pairs(node_list_effects.getChildren()) do
		local s = NodeManager.getSafeChildValue(v, "label", "");
		if string.match(s, eff_name) then
			v.delete();
			return;
		end
	end
end

function addEffect(msguser, msgidentity, node_ctentry, eff_name, eff_expire, eff_savemod, eff_init, eff_applied_by)
	-- Parameter validation
	if not node_ctentry or not eff_name then
		return;
	end
	
	-- Make sure we can get to the effects list
	local name_ctentry = NodeManager.getSafeChildValue(node_ctentry, "name", "");
	local node_list_effects = NodeManager.createSafeChild(node_ctentry, "effects");
	if not node_list_effects then
		return;
	end
	
	-- Get the details of the new effect
	local parse_neweffect = parseEffect(eff_name);
	if not eff_expire then
		eff_expire = "";
	end
	if not eff_savemod then
		eff_savemod = 0;
	end
	if not eff_init then
		eff_init = 0;
	end
	local key_neweffect = eff_name .. eff_expire .. eff_savemod;
	
	-- First, check for duplicate effects to overwrite
	-- Or exit if the new effect is weaker
	local target_effect = nil;
	for k, v in pairs(node_list_effects.getChildren()) do
		local label_effect = NodeManager.getSafeChildValue(v, "label", "");
		local key_effect = label_effect .. NodeManager.getSafeChildValue(v, "expiration", "") .. NodeManager.getSafeChildValue(v, "effectsavemod", 0);
		if key_effect == key_neweffect then
			if string.sub(eff_name, 1, 5) ~= "RCHG:" then
				local msg = {font = "systemfont", icon = "indicator_effect"};
				msg.text = "Effect '" .. eff_name .. "' already exists [on " .. name_ctentry .. "]";
				if msguser == "" then
					ChatManager.addMessage(msg);
				else
					ChatManager.deliverMessage(msg, msguser);
				end
			end
			return;
		end
		
		local isDifferent = false;
		local isStronger = false;
		local isWeaker = false;

		local parse_effect = CombatCommon.parseEffect(label_effect);
		if #parse_neweffect == #parse_effect then
			for i = 1, #parse_neweffect do
				if parse_neweffect[i].type == parse_effect[i].type and 
				  parse_neweffect[i].remainder == parse_effect[i].remainder then
				    if parse_neweffect[i].val ~= parse_effect[i].val then
				    	if parse_effect[i].type == "DMG" or parse_effect[i].type == "REGEN" then
				    		if parse_neweffect[i].val > parse_effect[i].val then
				    			isStronger = true;
				    		else
				    			isWeaker = true;
				    		end
				    	else
				    		isDifferent = true;
				    	end
				    end
				else
					isDifferent = true;
				end
			end
		end
		
		if not isDifferent then
			if isStronger then
				target_effect = v;
				break;
			elseif isWeaker then
				local msg = {font = "systemfont", icon = "indicator_effect"};
				msg.text = "Stronger effect already exists [on " .. name_ctentry .. "]";
				if msguser == "" then
					ChatManager.addMessage(msg);
				else
					ChatManager.deliverMessage(msg, msguser);
				end
				return;
			end
		end
	end
	
	-- Next check for blank effects to fill in
	if not target_effect then
		for k, v in pairs(node_list_effects.getChildren()) do
			if NodeManager.getSafeChildValue(v, "label", "") == "" then
				target_effect = v;
				break;
			end
		end
	end
	
	-- Finally, if we haven't found a target, then create a window to hold the effect
	if not target_effect then
		target_effect = NodeManager.createSafeChild(node_list_effects);
	end
	
	-- Add the effect details
	NodeManager.setSafeChildValue(target_effect, "label", "string", eff_name);
	NodeManager.setSafeChildValue(target_effect, "expiration", "string", eff_expire);
	NodeManager.setSafeChildValue(target_effect, "effectsavemod", "number", eff_savemod);
	NodeManager.setSafeChildValue(target_effect, "effectinit", "number", eff_init);
	
	-- Create the message to display
	local msg = {font = "systemfont", icon = "indicator_effect"};
	msg.text = "Effect '" .. eff_name .. "' applied [to " .. name_ctentry .. "]";
	
	-- If the effect applied by someone, then make some changes
	if eff_applied_by and eff_applied_by ~= "" then
		NodeManager.setSafeChildValue(target_effect, "source_name", "string", eff_applied_by);
		msg.text = msg.text .. " [by " .. eff_applied_by .. "]";
	end
	
	-- Send the notification messages
	if (NodeManager.getSafeChildValue(node_ctentry, "type", "") == "pc") or 
	  ((NodeManager.getSafeChildValue(node_ctentry, "show_npc", 0) == 1) and (string.sub(eff_name, 1, 5) ~= "RCHG:")) then
	  	ChatManager.deliverMessage(msg);
	else
		ChatManager.addMessage(msg);
		if msguser ~= "" then
			ChatManager.deliverMessage(msg, msguser);
		end
	end
end

--
--  RESTING
--

function rest(ctentrynode, extended)
	local restlength = 0;
	if extended then
		restlength = 1;
	end

	ChatManager.sendSpecialMessage(ChatManager.SPECIAL_MSGTYPE_REST, {restlength, ctentrynode.getNodeName()});
end

--
-- END TURN
--

function endTurn(msguser)
	-- Parameter validation
	if msguser == "" then
		return;
	end
	
	-- Make sure we have a CT to browse through
	local ctnode = DB.findNode("combattracker");
	if not ctnode then
		return;
	end
	
	-- Iterate through CT nodes to find the active entry
	local activeentry = nil;
	for k,v in pairs(ctnode.getChildren()) do
		local active = v.getChild("active");
		if active then
			if active.getValue() == 1 then
				activeentry = v;
				break;
			end
		end
	end
	if not activeentry then
		return;
	end
	
	-- Make sure the active entry is a PC
	local link = activeentry.getChild("link");
	if not link then
		return;
	end
	local refclass, refname = link.getValue();
	if refclass ~= "charsheet" then
		return;
	end
	
	-- Find the PC node
	local pcnode = DB.findNode(refname);
	if not pcnode then
		return;
	end
	
	-- Check if the special message user is the same as the owner of this node
	if msguser ~= pcnode.getOwner() then
		return;
	end
	
	-- Make sure the combat tracker is up on the host
	local wnd = Interface.findWindow("combattracker_window", "combattracker");
	if not wnd then
		local msg = {font = "systemfont"};
		msg.text = "[WARNING] Turns can only be ended when host combat tracker is active";
		deliverMessage(msg, msguser);
		return;
	end
	
	-- Everything checks out, so advance the turn
	wnd.list.nextActor();
end

--
-- PARSE CT ATTACK STYLE
--

function trimCTName(s)
	local pre_starts, pre_ends = string.find(s, "^%s+");
	local post_starts, post_ends = string.find(s, "%s+$");
	
	if pre_ends then
		s = string.gsub(s, "^%s+", "");
	else
		pre_ends = 0;
	end
	if post_starts then
		s = string.gsub(s, "%s+$", "");
	end
	
	return s, pre_ends, #s;
end

function parseCTAttackLine(s)
	-- Clear any previous attack/damage parsing
	local powers = {};
	
	-- Prepare some local variables
	local semi_index = 1;
	local attackindex = 1;
	
	while semi_index < #s do
		-- Parse out each semicolon/carriage return phrase of the attack string
		semi_phrase = "";
		semi_starts, semi_ends = string.find(s, '[;\r] ?', semi_index);
		if not semi_starts then
			semi_phrase = string.sub(s, semi_index);
			semi_ends = semi_index + #semi_phrase;
		else
			semi_phrase = string.sub(s, semi_index, semi_ends);
		end
		
		-- Get the name to know we have a valid power entry
		local powerintro_starts, powerintro_ends, powerintro_str = string.find(semi_phrase, '([^%(%[;]*)[%(%[;\r]?');
		--if not powerintro_starts and string.len(semi_phrase) > 0 then
		--	powerintro_starts = 1;
		--	powerintro_ends = string.len(semi_phrase);
		--	powerintro_str = semi_phrase;
		--end
		if powerintro_starts then
			-- Start the power entry
			local power = {};
			power["startpos"] = semi_index;
			power["endpos"] = semi_ends;

			-- Figure out the name
			local name_str, name_starts, name_ends = trimCTName(powerintro_str);
			power["name"] = name_str;
			power["name_startpos"] = semi_index + name_starts;
			power["name_endpos"] = semi_index + name_ends;
			
			-- Set up to pull out remaining sub-clauses
			local phrase_index = powerintro_ends;
			local sub_phrase = string.sub(semi_phrase, phrase_index);

			-- Attack sub-clause
			local atk_starts, atk_ends, psign, pbonus, pdef = string.find(sub_phrase, '%(([%+%-])(%d+) vs.? (%a*)%)');
			if atk_starts then
				if psign == "-" then
					pbonus = "-" .. pbonus;
				end
				power["atk_startpos"] = semi_index + phrase_index + atk_starts - 1;
				power["atk_endpos"] = semi_index + phrase_index + atk_ends - 2;
				power["atk_bonus"] = pbonus;
				power["atk_defense"] = pdef;

				sub_phrase = string.sub(sub_phrase, atk_ends + 1);
				phrase_index = phrase_index + atk_ends;
			end

			local dmg_starts, dmg_ends, pdmgstr, pdmgtype = string.find(sub_phrase, '%(([d%+%-%d%s]*%d)%s?([%a,]*)%)');
			if dmg_starts then
				power["dmg_startpos"] = semi_index + phrase_index + dmg_starts - 1;
				power["dmg_endpos"] = semi_index + phrase_index + dmg_ends - 2;
				power["dmg_val"] = pdmgstr;
				power["dmg_type"] = pdmgtype;

				sub_phrase = string.sub(sub_phrase, dmg_ends + 1);
				phrase_index = phrase_index + dmg_ends;
			end

			-- Check to see if a power has been used up already
			local usage_starts, usage_ends, usage_str = string.find(sub_phrase, '%[(USED)%]');
			if usage_starts then
				power["usage_startpos"] = semi_index + phrase_index + usage_starts - 1;
				power["usage_endpos"] = semi_index + phrase_index + usage_ends - 2;
				power["usage_val"] = usage_str;

				sub_phrase = string.sub(sub_phrase, usage_ends + 1);
				phrase_index = phrase_index + usage_ends;
			-- Otherwise, check to see if it can be used up
			else
				usage_starts, usage_ends, usage_str = string.find(sub_phrase, '%[(R:%d)%]');
				if usage_starts then
					power["usage_startpos"] = semi_index + phrase_index + usage_starts - 1;
					power["usage_endpos"] = semi_index + phrase_index + usage_ends - 2;
					power["usage_val"] = usage_str;

					sub_phrase = string.sub(sub_phrase, usage_ends + 1);
					phrase_index = phrase_index + usage_ends;
				end

				usage_starts, usage_ends, usage_str = string.find(sub_phrase, '%[([de])%]');
				if usage_starts then
					power["usage_startpos"] = semi_index + phrase_index + usage_starts - 1;
					power["usage_endpos"] = semi_index + phrase_index + usage_ends - 2;
					power["usage_val"] = usage_str;

					sub_phrase = string.sub(sub_phrase, usage_ends + 1);
					phrase_index = phrase_index + usage_ends;
				end
			end

			-- Insert the final power entry into the powers table
			table.insert (powers, power);
		end
		
		-- Increment to get the next semicolon phrase
		semi_index = semi_index + #semi_phrase;
	end
	
	return powers;
end
