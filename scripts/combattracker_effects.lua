-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

-- NOTE: onListRearranged and checkForEmpty override added to allow clients to 
-- drop effects onto the client combat tracker.  Since combat tracker node is
-- owned by the host, then client can not add nodes, but can edit an existing
-- node.  So, we are making sure that an empty node is always available on the host.
function onListRearranged(listchanged)
	checkForEmpty()
end

function checkForEmpty()
	for k, v in ipairs(getWindows()) do
		if v.label.getValue() == "" then
			return;
		end
	end

	NodeManager.createSafeWindow(self);
end

function getEffectListString()
	local s = "";
	for k, v in pairs(getWindows()) do
		if v.label.getValue() ~= "" and string.sub(v.label.getValue(), 1, 5) ~= "RCHG:" then
			if s ~= "" then
				s = s .. ", ";
			end
			s = s .. v.label.getValue();
		end
	end
	return s;
end

function applyEffectRegen(regen_val)
	-- Make sure we're actually regenerating
	if regen_val <= 0 then
		return;
	end

	-- Build damage notification message
	local msg = {font = "systemfont", icon = "indicator_effect"};
	msg.text = window.name.getValue() .. " regenerates " .. regen_val;
	
	-- Send the message to the correct recipients
	if window.type.getValue() == "pc" then
		ChatManager.deliverMessage(msg);
	else
		msg.text = "[GM] " .. msg.text;
		ChatManager.addMessage(msg);
	end

	-- Apply the damage
	CombatCommon.applyDamage("ct", window.getDatabaseNode(), 0 - regen_val);
end

function applyEffectDamage(dmg_val, dmg_type)
	-- Make sure we're actually taking damage
	if dmg_val <= 0 then
		return;
	end

	-- Build damage notification message
	local msg = {font = "systemfont", icon = "indicator_effect"};
	msg.text = window.name.getValue() .. " takes ongoing " .. dmg_val .. " damage";
	if dmg_type and dmg_type ~= "" then
		msg.text = msg.text .. " [" .. dmg_type .. "]";
	end
	
	-- Send the message to the correct recipients
	if window.type.getValue() == "pc" or window.show_npc.getState() then
		ChatManager.deliverMessage(msg);
	else
		msg.text = "[GM] " .. msg.text;
		ChatManager.addMessage(msg);
	end

	-- Apply the damage
	CombatCommon.applyDamage("ct", window.getDatabaseNode(), dmg_val);
end

function applyEffectRecharge(effectwin, recharge_val, recharge_name)
	-- Parameter validation
	if recharge_val <= 0 then
		return;
	end
	
	-- Build recharge notification message
	local custom = {};
	custom["effect"] = effectwin.getDatabaseNode();
	local recharge_msg = "'" .. recharge_name .. "' recharges on " .. recharge_val .. "+";
	ChatManager.DieControlThrow("recharge", 0, recharge_msg, custom, {"d6"});
end

function notifyEffectSave(effectwin)
	-- Post a notification to the chat window
	local msg = {font = "systemfont", icon = "indicator_effect"};
	msg.text = "Effect '" .. effectwin.label.getValue() .. "' allows a saving throw [on " .. window.name.getValue() .. "]";
	if window.type.getValue() == "pc" or window.show_npc.getState() then
		ChatManager.deliverMessage(msg);
	else
		msg.text = "[GM] " .. msg.text;
		ChatManager.addMessage(msg);
	end
end

function expireEffect(effectwin)
	-- Post a notification to the chat window
	local msg = {font = "systemfont", icon = "indicator_effect"};
	msg.text = "Effect '" .. effectwin.label.getValue() .. "' expired [on " .. window.name.getValue() .. "]";
	if window.type.getValue() == "pc" or window.show_npc.getState() then
		ChatManager.deliverMessage(msg);
	else
		msg.text = "[GM] " .. msg.text;
		ChatManager.addMessage(msg);
	end

	-- Delete the effect
	deleteChild(effectwin, true);
end

function processStartEffect(effectwin)
	-- End effects that end at the start of the turn
	local expval = effectwin.expiration.getSourceValue();
	if expval == "start" then
		expireEffect(effectwin);
	end
end

function processEndEffect(effectwin)
	-- Figure out when the effect should expire
	local expval = effectwin.expiration.getSourceValue();

	-- Check for effects that need saving throws
	if expval == "save" then
		local save_rolled = false;
		if OptionsManager.isOption("ESAV", "on") then
			effectwin.effectsavemod.onDoubleClick(0,0);
			save_rolled = true;
		elseif OptionsManager.isOption("ESAV", "npc") then
			local active = effectwin.windowlist.window;
			if active.type.getValue() == "npc" then
				effectwin.effectsavemod.onDoubleClick(0,0);
				save_rolled = true;
			end
		end
		if not save_rolled then
			notifyEffectSave(effectwin);
		end
	end
	
	-- End effects that end at the end of the turn
	if expval == "end" then
		expireEffect(effectwin);
	end
	
	-- Advance end of next turn effects
	if expval == "endnext" then
		effectwin.expiration.setSourceValue("end");
	end
end

function progressEffects(actor_current, actor_new)
	-- Get the initiative values
	local init_current = 10000;
	if actor_current then
		init_current = actor_current.initresult.getValue();
	end
	local init_new = -10000;
	if actor_new then
		init_new = actor_new.initresult.getValue();
	end
	
	-- Iterate over all the effect windows
	for k, v in pairs(getWindows()) do
		-- Figure out what type of effect we have
		local eff_name = v.label.getValue();
		local eff_exp = v.expiration.getSourceValue();
		local eff_init = v.effectinit.getValue();
		
		-- Process the end of turn effects
		local flag_process_endeffect = false;
		if eff_exp == "end" or eff_exp == "endnext" then
			if eff_init <= init_current and eff_init > init_new then
				flag_process_endeffect = true;
			end
		elseif eff_exp == "save" and actor_current == window then
			flag_process_endeffect = true;
		end
		if flag_process_endeffect then
			processEndEffect(v);
		end

		-- Process the start of turn effects first
		local flag_process_starteffect = false;
		if eff_exp == "start" then
			if eff_init < init_current and eff_init >= init_new then
				flag_process_starteffect = true;
			end
		end
		if flag_process_starteffect then
			processStartEffect(v);
		end
		
		-- Some effects are always addressed at beginning of actor's turn
		if actor_new == window then
			local effectlist = CombatCommon.parseEffect(eff_name);

			for ek,ev in pairs(effectlist) do
				-- Check for ongoing damage effect
				if ev.type == "DMG" then
					applyEffectDamage(ev.val, ev.remainder);
				end

				-- Check for ongoing regeneration effect
				if ev.type == "REGEN" then
					applyEffectRegen(ev.val);
				end

				-- Check for NPC power recharge effects
				if ev.type == "RCHG" then
					applyEffectRecharge(v, ev.val, ev.remainder);
				end
			end
		end
	end
end
