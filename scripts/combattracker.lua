-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

enableglobaltoggle = true;
ct_active_name = "";

function onInit()
	Interface.onHotkeyActivated = onHotkey;

	-- Make sure all the clients can see the combat tracker
	for k,v in ipairs(User.getAllActiveIdentities()) do
		local username = User.getIdentityOwner(v);
		if username then
			NodeManager.addWatcher("combattracker", username);
			NodeManager.addWatcher("combattracker_props", username);
		end
	end

	-- Create a blank window if one doesn't exist already
	if not getNextWindow(nil) then
		NodeManager.createSafeWindow(self);
	end

	-- Register a menu item to create a CT entry
	registerMenuItem("Create Item", "insert", 5);
end

function onSortCompare(w1, w2)
	if w1.initresult.getValue() == w2.initresult.getValue() then
		return w1.init.getValue() < w2.init.getValue();
	end
	
	return w1.initresult.getValue() < w2.initresult.getValue();
end

function onMenuSelection(selection)
	if selection == 5 then
		NodeManager.createSafeWindow(self);
	end
end

function onHotkey(draginfo)
	if draginfo.isType("combattrackernextactor") then
		nextActor();
		return true;
	end
	if draginfo.isType("combattrackernextround") then
		nextRound();
		return true;
	end
end

function toggleSpacing()
	if not enableglobaltoggle then
		return;
	end
	
	local spacingon = window.button_global_spacing.getValue();
	for k,v in pairs(getWindows()) do
		if spacingon ~= v.activatespacing.getValue() then
			v.activatespacing.setValue(spacingon);
			v.setSpacingVisible(v.activatespacing.getValue());
		end
	end
end

function toggleDefensive()
	if not enableglobaltoggle then
		return;
	end
	
	local defensiveon = window.button_global_defensive.getValue();
	for k,v in pairs(getWindows()) do
		if defensiveon ~= v.activatedefensive.getValue() then
			v.activatedefensive.setValue(defensiveon);
			v.setDefensiveVisible(v.activatedefensive.getValue());
		end
	end
end

function toggleActive()
	if not enableglobaltoggle then
		return;
	end
	
	local activeon = window.button_global_active.getValue();
	for k,v in pairs(getWindows()) do
		if activeon ~= v.activateactive.getValue() then
			v.activateactive.setValue(activeon);
			v.setActiveVisible(v.activateactive.getValue());
		end
	end
end

function toggleEffects()
	if not enableglobaltoggle then
		return;
	end
	
	local effectson = window.button_global_effects.getValue();
	for k,v in pairs(getWindows()) do
		if effectson ~= v.activateeffects.getValue() then
			v.activateeffects.setValue(effectson);
			v.setEffectsVisible(v.activateeffects.getValue());
			v.effects.checkForEmpty();
		end
	end
end

function onEntrySectionToggle()
	local anySpacing = false;
	local anyDefensive = false;
	local anyActive = false;
	local anyEffects = false;

	for k,v in pairs(getWindows()) do
		if v.activatespacing.getValue() then
			anySpacing = true;
		end
		if v.activatedefensive.getValue() then
			anyDefensive = true;
		end
		if v.activateactive.getValue() then
			anyActive = true;
		end
		if v.activateeffects.getValue() then
			anyEffects = true;
		end
	end

	enableglobaltoggle = false;
	window.button_global_spacing.setValue(anySpacing);
	window.button_global_defensive.setValue(anyDefensive);
	window.button_global_active.setValue(anyActive);
	window.button_global_effects.setValue(anyEffects);
	enableglobaltoggle = true;
end

function addPc(source)
	-- Parameter validation
	if not source then
		return nil;
	end

	-- Create a new combat tracker window
	local wnd = NodeManager.createSafeWindow(self);
	if not wnd then
		return nil;
	end

	-- Shortcut
	wnd.link.setValue("charsheet", source.getNodeName());

	-- Type
	-- NOTE: Set to PC after link set, so that fields are linked correctly
	wnd.type.setValue("pc");

	-- Token
	local tokenval = NodeManager.getSafeChildValue(source, "combattoken", nil);
	if tokenval then
		wnd.token.setPrototype(tokenval);
	end

	-- FoF
	wnd.friendfoe.setSourceValue("friend");
	
	return wnd;
end

function addBattle(source)
	-- Parameter validation
	if not source then
		return nil;
	end

	-- Cycle through the NPC list, and add them to the tracker
	local npclistnode = source.getChild("npclist");
	if npclistnode then
		for k,v in pairs(npclistnode.getChildren()) do
			local n = NodeManager.getSafeChildValue(v, "count", 0);
			for i = 1, n do
				if v.getChild("link") then
					local npcclass, npcnodename = v.getChild("link").getValue();
					local npcnode = DB.findNode(npcnodename);
					
					local wnd = addNpc(npcnode, NodeManager.getSafeChildValue(v, "name", ""));
					if wnd then
						local npctoken = NodeManager.getSafeChildValue(v, "token", "");
						if npctoken ~= "" then
							wnd.token.setPrototype(npctoken);
						end
					else
						ChatManager.SystemMessage("Could not add '" .. NodeManager.getSafeChildValue(v, "name", "") .. "' to combat tracker");
					end
				end
			end
		end
	end
end

function addNpc(source, name)
	-- Parameter validation
	if not source then
		return nil;
	end

	-- Determine the options relevant to adding NPCs
	local opt_nnpc = OptionsManager.getOption("NNPC");
	local opt_init = OptionsManager.getOption("INIT");

	-- Create a new NPC window to hold the data
	local wnd = NodeManager.createSafeWindow(self);
	if not wnd then
		return nil;
	end

	-- Shortcut
	wnd.link.setValue("npc", source.getNodeName());

	-- Type
	wnd.type.setValue("npc");

	-- Name
	local namelocal = name;
	if not namelocal then
		namelocal = NodeManager.getSafeChildValue(source, "name", "");
	end
	local namecount = 0;
	local highnum = 0;
	local last_init = 0;
	wnd.name.setValue(namelocal);

	-- If multiple NPCs of same name, then figure out what initiative they go on and potentially append a number
	if string.len(namelocal) > 0 then
		for k, v in ipairs(getWindows()) do
			if wnd.name.getValue() == getWindows()[k].name.getValue() then
				namecount = 0;
				for l, w in ipairs(getWindows()) do
					local check = null;
					if getWindows()[l].name.getValue() == namelocal then
						check = 0;
					elseif string.sub(getWindows()[l].name.getValue(), 1, string.len(namelocal)) == namelocal then
						check = tonumber(string.sub(getWindows()[l].name.getValue(), string.len(namelocal)+2));
					end
					if check then
						namecount = namecount + 1;
						local cur_init = getWindows()[l].initresult.getValue();
						if cur_init ~= 0 then
							last_init = cur_init;
						end
						if highnum < check then
							highnum = check;
						end
					end
				end 
				if opt_nnpc == "append" then
					getWindows()[k].name.setValue(wnd.name.getValue().." "..highnum+1); 
				elseif opt_nnpc == "random" then
					getWindows()[k].name.setValue(randomName(getWindows(), wnd.name.getValue())); 
				end
			end
		end
	end
	if namecount < 2 then
        wnd.name.setValue(namelocal);
	end
	
	-- Space/reach
	local space = 1;
	local reach = 1;
	local typestr = NodeManager.getSafeChildValue(source, "type", "");
	local sizestr = string.match(typestr, "(%w*)");
	if sizestr then
		sizestr = string.lower(sizestr);
		if sizestr == "tiny" then
			space = 1;
			reach = 0;
		elseif sizestr == "small" then
			space = 1;
			reach = 1;
		elseif sizestr == "medium" then
			space = 1;
			reach = 1;
		elseif sizestr == "large" then
			space = 2;
			reach = 1;
		elseif sizestr == "huge" then
			space = 3;
			reach = 2;
		elseif sizestr == "gargantuan" then
			space = 4;
			reach = 3;
		end
	end
	wnd.space.setValue(space);
	wnd.reach.setValue(reach);

	-- Token
	local tokenval = NodeManager.getSafeChildValue(source, "token", nil);
	if tokenval then
		wnd.token.setPrototype(tokenval);
	end
	
	-- FoF
	local alignment = string.lower(NodeManager.getSafeChildValue(source, "alignment", ""));
	if string.match(alignment, "good") then
		wnd.friendfoe.setSourceValue("friend");
	elseif string.match(alignment, "evil") then
		wnd.friendfoe.setSourceValue("foe");
	else
		wnd.friendfoe.setSourceValue("neutral");
	end
		
	-- HP
	local hp = NodeManager.getSafeChildValue(source, "hp", "");
	local npchp = string.match(hp, "(%d*)");
	local numhp = tonumber(npchp) or 0;
	wnd.hp.setValue(numhp);
	
	-- Defensive properties
	wnd.ac.setValue(NodeManager.getSafeChildValue(source, "ac", 0));
	wnd.fortitude.setValue(NodeManager.getSafeChildValue(source, "fortitude", 0));
	wnd.reflex.setValue(NodeManager.getSafeChildValue(source, "reflex", 0));
	wnd.will.setValue(NodeManager.getSafeChildValue(source, "will", 0));
	local numsave = tonumber(NodeManager.getSafeChildValue(source, "saves", "")) or 0;
	wnd.save.setValue(numsave);
	wnd.specialdef.setValue(NodeManager.getSafeChildValue(source, "specialdefenses", ""));

	-- Active properties
	wnd.init.setValue(NodeManager.getSafeChildValue(source, "init", 0));
	
	local speed = NodeManager.getSafeChildValue(source, "speed", "");
	local npcspeed = string.match(speed, "(%d*)");
	local numspeed = tonumber(npcspeed) or 0;
	wnd.speed.setValue(numspeed);

	local ap = tonumber(NodeManager.getSafeChildValue(source, "actionpoints", "")) or 0;
	wnd.actionpoints.setValue(ap);

	if source.getChild("powers") then
		local atk = "";
		local powerchildren = source.getChild("powers").getChildren();
		local numpowers = 0;
		for key, val in pairs(powerchildren) do
			numpowers = numpowers + 1;
		end
		local powercount = 0;
		local k = 1;
		while powercount < numpowers do
			local v = powerchildren["id-" .. string.format("%05d", k)];
			
			if v then
				powercount = powercount + 1;
				local powerstr = "";

				-- Pull the main clause to parse
				local main_clause = NodeManager.getSafeChildValue(v, "shortdescription", "");

				-- Get the attack, damage and effect clauses
				local attacks, damages, effects = PowersManager.parsePowerDescription(main_clause);
				local special_attack_flag = false;
				local special_damage_flag = false;
				if #attacks > 0 then
					if attacks[1].atkstat ~= "" then
						special_attack_flag = true;
					else
						powerstr = powerstr .. "(+" .. attacks[1].bonus .. " vs. ";
						local defense = attacks[1].defense;
						if defense == "ac" then
							powerstr = powerstr .. "AC";
						elseif defense == "reflex" then
							powerstr = powerstr .. string.upper(string.sub(defense, 1, 1)) .. string.sub(defense, 2, 3);
						elseif defense == "will" or defense == "fortitude" then
							powerstr = powerstr .. string.upper(string.sub(defense, 1, 1)) .. string.sub(defense, 2, 4);
						else
							powerstr = powerstr .. "-";
						end
							
						powerstr = powerstr .. ")";
					end
					if #attacks > 1 then
						special_attack_flag = true;
					end
				end
				if #damages > 0 then
					if damages[1].dmgstat ~= "" or damages[1].damagemult ~= 0 or damages[1].damage == "" then
						special_damage_flag = true;
					else
						powerstr = powerstr .. "(" .. damages[1].damage;
						if damages[1].dmgtype ~= "" then
							powerstr = powerstr .. " " .. damages[1].dmgtype;
						end
						powerstr = powerstr .. ")";
					end
					if #damages > 1 then
						special_damage_flag = true;
					end
				end

				if special_attack_flag then
					powerstr = powerstr .. "[SA]";
				end
				if special_damage_flag then
					powerstr = powerstr .. "[SD]";
				end
				if #effects > 0 then
					powerstr = powerstr .. "[EFF]";
				end

				-- Determine the action required to use this power, and add a note if it is not standard
				local action = string.lower(NodeManager.getSafeChildValue(v, "action", ""));
				if action == "move" then
					powerstr = powerstr .. "[mo]";
				elseif action == "minor" then
					powerstr = powerstr .. "[mi]";
				elseif action == "reaction" or action == "immediate reaction" then
					powerstr = powerstr .. "[r]";
				elseif action == "interrupt" or action == "immediate interrupt" then
					powerstr = powerstr .. "[i]";
				end

				-- Determine the recharge of this power, and add a note if it is not at-will
				local recharge = string.lower(NodeManager.getSafeChildValue(v, "recharge", ""));
				if recharge == "encounter" then
					powerstr = powerstr .. "[e]";
				elseif recharge == "daily" then
					powerstr = powerstr .. "[d]";
				elseif string.sub(recharge,1,8) == "recharge" then
					powerstr = powerstr .. "[R:" .. string.sub(recharge,10,10) .. "]";
				end

				-- Add the power name
				local powername = NodeManager.getSafeChildValue(v, "name", "");
				if powerstr ~= "" then
					powerstr = " " .. powerstr;
				end
				powerstr = powername .. powerstr;

				local powertype = NodeManager.getSafeChildValue(v, "powertype", "");
				if powertype == "m" or powertype == "r" then
					powerstr = "*" .. powerstr;
				end

				-- Add this attack to the combat tracker power string
				if atk ~= "" then
					atk = atk .. "\r";
				end
				atk = atk .. powerstr;
			end
			
			-- Cycle to the next power
			k = k + 1;
		end
		
		-- Add the combat tracker power string to the new entry
		wnd.atk.setValue(atk);
	end
	
	-- If the NPC has regeneration then, add an effect for it
	local regen_val = string.match(wnd.specialdef.getValue(), "Regeneration (%d+)");
	if regen_val then
		CombatCommon.addEffect("", "", wnd.getDatabaseNode(), "REGEN: " .. regen_val);
	end
	
	--Roll initiative and sort
	if opt_init == "group" then
		if (namecount < 2) or (last_init == 0) then
			wnd.initresult.setValue(math.random(20) + wnd.init.getValue());
		else
			wnd.initresult.setValue(last_init);
		end
		applySort();
	elseif opt_init == "all" then
		wnd.initresult.setValue(math.random(20) + wnd.init.getValue());
		applySort();
	end

	return wnd;
end

function onDrop(x, y, draginfo)
	-- Capture certain drag types meant for the host only
	local dragtype = draginfo.getType();

	-- PC
	if dragtype == "playercharacter" then
		addPc(draginfo.getDatabaseNode());
		return true;
	end

	if dragtype == "shortcut" then
		local class, datasource = draginfo.getShortcutData();

		-- NPC
		if class == "npc" then
			addNpc(draginfo.getDatabaseNode());
			return true;
		end

		-- ENCOUNTER
		if class == "battle" then
			addBattle(draginfo.getDatabaseNode());
			return true;
		end
	end

	-- Capture any drops meant for specific CT entries
	local wnd = getWindowAt(x,y);
	if wnd then
		return CombatCommon.onDrop("ct", wnd.getDatabaseNode().getNodeName(), draginfo);
	end
end

function getActiveEntry()
	for k, v in ipairs(getWindows()) do
		if v.isActive() then
			return v;
		end
	end
	
	return nil;
end

function requestActivation(entry)
	-- Make all the CT entries inactive
	for k, v in ipairs(getWindows()) do
		v.setActive(false);
	end
	
	-- Make the given CT entry active
	entry.setActive(true);

	-- Clear the immediate action checkmark, since its a new round
	entry.immediate_check.setState(false);
	
	-- If we created a new speaker, then remove it
	if ct_active_name ~= "" then
		GmIdentityManager.removeIdentity(ct_active_name);
		ct_active_name = "";
	end

	-- Check the option to set the active CT as the GM voice
	if OptionsManager.isOption("CTAV", "on") then
		-- Set up the current CT entry as the speaker if NPC, otherwise just change the GM voice
		if entry.type.getValue() == "pc" then
			GmIdentityManager.activateGMIdentity();
		else
			local name = entry.name.getValue();
			if GmIdentityManager.existsIdentity(name) then
				GmIdentityManager.setCurrent(name);
			else
				ct_active_name = name;
				GmIdentityManager.addIdentity(name);
			end
		end
	end
end

function nextActor()
	local active = getActiveEntry();
	if active then
		--- Process dying state for this actor first
		if active.hp.getValue() > 0 and active.wounds.getValue() >= active.hp.getValue() then
			if OptionsManager.isOption("ESAV", "on") then
				local custom = {};
				local src = active.link.getTargetDatabaseNode();
				if src then
					if active.type.getValue() == "pc" then
						custom["pc"] = src;
					else
						custom["npc"] = src;
					end
				end

				ChatManager.d20Check("dice", active.save.getValue(), "Death Saving Throw", custom);
			end
		end
		
		-- Find the next actor.  If no next actor, then start the next round
		local nextactor = getNextWindow(active);
		if nextactor then
			for k, v in ipairs(getWindows()) do
				v.effects.progressEffects(active, nextactor);
			end
			
			requestActivation(nextactor);
		else
			nextRound();
		end
	else
		nextRound();
	end
end

function nextRound()
	-- Find the active entry, if available
	local active = getActiveEntry();

	-- Find the next actor, if available
	local nextactor = getNextWindow(nil);
	
	-- Progress the effects on each combat tracker entry over the round boundary
	for k, v in ipairs(getWindows()) do
		if active then
			v.effects.progressEffects(active, nil);
		end
		if nextactor then
			v.effects.progressEffects(nil, nextactor);
		end
	end
	
	-- If we have a next actor, then activate it
	if nextactor then
		requestActivation(nextactor);
	end
	
	-- Increment the combat tracker round counter
	window.roundcounter.setValue(window.roundcounter.getValue() + 1);
end

function resetInit()
	-- Set all CT entries to inactive and reset their init value
	for k, v in ipairs(getWindows()) do
		v.setActive(false);
		v.initresult.setValue(0);
		v.immediate_check.setState(false);
	end
	
	-- Remove the active CT from the speaker list
	if ct_active_name ~= "" then
		GmIdentityManager.removeIdentity(ct_active_name);
		ct_active_name = "";
	end

	-- Reset the round counter
	window.roundcounter.setValue(0);
end

function resetEffects()
	for k, v in ipairs(getWindows()) do
		-- Delete all current effects
		v.effects.reset(true);

		-- Hide the effects sub-section
		v.activateeffects.setValue(false);
		v.setEffectsVisible(false);
	end
	
	-- Clear the global effects toggle
	window.button_global_effects.setValue(false);
end

function stripCreatureNumber(s)
	local starts, ends, creature_number = string.find(s, " ?(%d+)$");
	if not starts then
		return s;
	end
	return string.sub(s, 1, starts), creature_number;
end

function rollEntryInit(ctentry)
	-- For PCs, we always roll unique initiative
	if ctentry.type.getValue() == "pc" then
		ctentry.initresult.setValue(math.random(20) + ctentry.init.getValue());
		return;
	end
	
	-- For NPCs, if NPC init option is not group, then roll unique initiative
	local opt_init = OptionsManager.getOption("INIT");
	if opt_init ~= "group" then
		ctentry.initresult.setValue(math.random(20) + ctentry.init.getValue());
		return;
	end

	-- For NPCs with group option enabled
	
	-- Get the entry's database node name and creature name
	local ctentrynodename = ctentry.getDatabaseNode().getNodeName();
	local ctentryname = stripCreatureNumber(ctentry.name.getValue());
	if ctentryname == "" then
		ctentry.initresult.setValue(math.random(20) + ctentry.init.getValue());
		return;
	end
		
	-- Iterate through list looking for other creature's with same name
	local last_init = 0;
	for k,v in pairs(getWindows()) do
		if ctentrynodename ~= v.getDatabaseNode().getNodeName() then
			local tempentryname = stripCreatureNumber(v.name.getValue());
			if tempentryname == ctentryname then
				local cur_init = v.initresult.getValue();
				if cur_init ~= 0 then
					last_init = cur_init;
				end
			end
			
		end
	end
	
	-- If we found similar creatures with non-zero initiatives, then match the initiative of the last one found
	if last_init == 0 then
		ctentry.initresult.setValue(math.random(20) + ctentry.init.getValue());
	else
		ctentry.initresult.setValue(last_init);
	end
end

function rollAllInit()
	for k, v in ipairs(getWindows()) do
		if v.type.getValue() == "npc" then
			v.initresult.setValue(0);
		end
	end

	for k, v in ipairs(getWindows()) do
		rollEntryInit(v);
	end
end

function rollPCInit()
	for k, v in ipairs(getWindows()) do
		if v.type.getValue() == "pc" then
			rollEntryInit(v);
		end
	end
end

function rollNPCInit()
	for k, v in ipairs(getWindows()) do
		if v.type.getValue() == "npc" then
			v.initresult.setValue(0);
		end
	end

	for k, v in ipairs(getWindows()) do
		if v.type.getValue() == "npc" then
			rollEntryInit(v);
		end
	end
end

function restShort()
	ChatManager.Message("Party taking short rest", true);
	
	resetInit();

	for k, v in ipairs(getWindows()) do
		if v.type.getValue() == "pc" then
			local vnode = v.link.getTargetDatabaseNode();
			if vnode then
				CharSheetCommon.rest(vnode);
			end
		end

		CombatCommon.rest(v.getDatabaseNode());

		clearEncEffects(v);
	end
end

function restExtended()
	ChatManager.Message("Party taking extended rest", true);

	resetInit();
	
	for k, v in ipairs(getWindows()) do
		if v.type.getValue() == "pc" then
			local vnode = v.link.getTargetDatabaseNode();
			if vnode then
				CharSheetCommon.rest(vnode, true);
			end
		end

		CombatCommon.rest(v.getDatabaseNode(), true);

		clearEncEffects(v);
	end
end

function clearEncEffects(wnd)
	-- Cycle through the effects, and delete the encounter effects
	for k,v in pairs(wnd.effects.getWindows()) do
		if v.expiration.getSourceValue() == "encounter" then
			wnd.effects.deleteChild(v, false);
		end
	end
	
	-- If the effects are now empty, then add one back and hide the effects section
	if #(wnd.effects.getWindows()) == 0 then
		wnd.effects.checkForEmpty();
		wnd.activateeffects.setValue(false);
		wnd.setEffectsVisible(false);
	end
end

function deleteNPCs()
	for k, v in ipairs(getWindows()) do
		if v.type.getValue() == "npc" then
			v.delete();
		end
	end
end

function randomName(wintable, base_name)
	local new_name = base_name .. " " .. math.random(#wintable * 2) + 1	
	for l, w in ipairs(wintable) do
		if wintable[l].name.getValue() == new_name then
			new_name = randomName(wintable,base_name);
		end
	end
	return new_name
end
