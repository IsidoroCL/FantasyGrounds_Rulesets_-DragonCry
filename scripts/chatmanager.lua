-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

SPECIAL_MSGTYPE_WHISPER = "whisper";
SPECIAL_MSGTYPE_THEBOX = "thebox";
SPECIAL_MSGTYPE_REST = "rest";
SPECIAL_MSGTYPE_APPLYDMG = "applydmg";
SPECIAL_MSGTYPE_APPLYEFF = "applyeff";
SPECIAL_MSGTYPE_ENDTURN = "endturn";

-- Initialization
function onInit()
	registerSlashHandler("/whisper", processWhisper);
	registerSlashHandler("/w", processWhisper);
	registerSlashHandler("/wg", processWhisperGM);
	registerSlashHandler("/die", processDie);
	registerSlashHandler("/mod", processMod);
	
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_WHISPER, handleWhisper);
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_THEBOX, handleTheBox);
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_REST, handleRest);
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_APPLYDMG, handleApplyDamage);
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_APPLYEFF, handleApplyEffect);
	registerSpecialMsgHandler(SPECIAL_MSGTYPE_ENDTURN, handleEndTurn);
end

-- Chat window registration for general purpose message dispatching
function registerControl(ctrl)
	control = ctrl;
end

function registerEntryControl(ctrl)
	entrycontrol = ctrl;
	ctrl.onSlashCommand = onSlashCommand;
end

function registerWindowControl(ctrl)
	windowcontrol = ctrl;
end

-- Generic message delivery
function deliverMessage(msg, recipients)
	if control then
		control.deliverMessage(msg, recipients);
	end
end

function addMessage(msg)
	if control then
		control.addMessage(msg);
	end
end


--
--
-- INTERNAL FUNCTIONS
--
--

function debug(str, ...)
	local text = str;
	if text ~= "" then
		text = text .. ": ";
	end
	
	for i = 1, select("#", ...) do
		text = text .. convertVariableToString(select(i, ...)) .. " | ";
	end
	
	Message(text);
end

function convertVariableToString(t, done)
	-- Check for an empty variable
	if t == nil then
		return "nil";
	end

	-- Handle the recursive part
	done = done or {};

	-- Local variables
	local rv = "";
	
	-- Handle basic variables
	if type(t) == "number" then
		rv = "#" .. t;
	elseif type(t) == "string" then
		rv = "s'" .. t .. "'";

	-- Handle complex variables
	else
		rv = string.upper(type(t)) .. " ";

		-- Handle all the different variable types
		if type(t) == "boolean" then
			if t then
				rv = rv .. "= true";
			else
				rv = rv .. "= false";
			end
		elseif type(t) == "table" then
			rv = rv .. "{";
			for key, value in pairs(t) do
				rv = rv .. " " .. tostring(key) .. " = { "
				if type(value) == "table" and not done[value] then
					done[value] = true;
					rv = rv .. convertVariableToString(value, done);
				else
					rv = rv .. convertVariableToString(value, done) .. " \n";
				end
				rv = rv .. " },";
			end
			rv = rv .. " }";
		elseif type(t) == "dragdata" then
			rv = rv .. "{ ";
			rv = rv .. "#slots: " .. convertVariableToString(t.getSlotCount()) ..";";
			rv = rv .. "desc: " .. convertVariableToString(t.getDescription()) ..";";
			rv = rv .. "dice: " .. convertVariableToString(t.getDieList()) ..";";
			rv = rv .. "num: " .. convertVariableToString(t.getNumberData()) ..";";
			rv = rv .. "shortcut:" .. convertVariableToString(t.getShortcutData()) ..";";
			rv = rv .. "slot:" .. convertVariableToString(t.getSlot()) ..";";
			rv = rv .. "string:" .. convertVariableToString(t.getStringData()) ..";";
			rv = rv .. "token:" .. convertVariableToString(t.getTokenData()) ..";";
			rv = rv .. "custom:" .. convertVariableToString(t.getCustomData()) ..";";
			rv = rv .. " }";
		elseif type(t) == "databasenode" then
			rv = rv .. "= " .. t.getNodeName();
		elseif type(t) == "windowinstance" then
			rv = rv .. "= " .. t.getClass();
		elseif type(t) == "stringcontrol" then
			rv = rv .. "= " .. t.getValue();
		else
			rv = rv .. "= " .. tostring(t);
		end
	end

	-- Return what we found
	return rv;
end


--
--
-- SLASH COMMAND HANDLER
--
--

slashhandlers = {};

function registerSlashHandler(command, callback)
	slashhandlers[command] = callback;
end

function unregisterSlashHandler(command, callback)
	slashhandlers[command] = nil;
end

function onSlashCommand(command, parameters)
	for c, h in pairs(slashhandlers) do
		if string.find(string.lower(c), string.lower(command), 1, true) == 1 then
			h(parameters);
			return;
		end
	end
end


--
--
-- AUTO-COMPLETE
--
--

function doAutocomplete()
	local buffer = entrycontrol.getValue();
	local spacepos = string.find(string.reverse(buffer), " ", 1, true);
	
	local search = "";
	local remainder = buffer;
	
	if spacepos then
		search = string.sub(buffer, #buffer - spacepos + 2);
		remainder = string.sub(buffer, 1, #buffer - spacepos + 1);
	else
		search = buffer;
		remainder = "";
	end
	
	-- Check identities
	for k, v in ipairs(User.getAllActiveIdentities()) do
		local label = User.getIdentityLabel(v);
		if label and string.find(string.lower(label), string.lower(search), 1, true) == 1 then
			local replacement = remainder .. label .. " ";
			entrycontrol.setValue(replacement);
			entrycontrol.setCursorPosition(#replacement + 1);
			entrycontrol.setSelectionPosition(#replacement + 1);
			return;
		end
	end
end


--
--
-- DICE
--
--

function parseDiceString(dicestr)
	local starts = true;
	local nextindex = 1;

	local modifier = 0;
	local dice = {};

	for v in string.gmatch(dicestr, "[+-]?%d+%w*") do
		local starts, ends, sign, count, die = string.find(v, "([+-]?)(%d+)(%w*)");
		if not starts then
			break;
		end

		local signmultiplier = 1;
		if sign == "-" then
			signmultiplier = -1;
		end

		if #die == 0 then
			modifier = modifier + signmultiplier * count;
		else
			local diecount = tonumber(count) or 1;
			for c = 1, diecount do
				table.insert(dice, die);
			end
		end
	end

	return dice, modifier;
end

function parseDieString(diestring)
	local dice = {};
	local modifier = 0;

	if diestring then
		for clause in string.gmatch(diestring, "(%-?[%dd]+)") do
			starts, ends = string.find(clause, "d");
			if starts then
				-- This function does not handle negative dice clauses, so just force positive
				local numdie = tonumber(string.sub(clause, 1, starts - 1)) or 1;
				numdie = math.abs(numdie);
				local dietype = tonumber(string.sub(clause, ends + 1)) or 0;
				if dietype > 0 then
					for i = 1, numdie do
						table.insert(dice, "d" .. dietype);
						if dietype == 100 then
							table.insert(dice, "d10");
						end
					end
				end
			else
				modifier = modifier + tonumber(clause);
			end
		end
	end
	
	return dice, modifier;
end

function convertDieFieldToString(dicetable)
	local dicestr = "";
	
	if dicetable then
		local diecount = {};

		for k,v in pairs(dicetable) do
			if diecount[v] then
				diecount[v] = diecount[v] + 1;
			else
				diecount[v] = 1;
			end
		end

		for k,v in pairs(diecount) do
			if dicestr ~= "" then
				dicestr = dicestr .. "+";
			end
			dicestr = dicestr .. v .. k;
		end
	end
	
	return dicestr;
end

function convertDieListToString(dicetable)
	local dicestr = "";
	
	if dicetable then
		local diecount = {};

		for k,v in pairs(dicetable) do
			for k2, v2 in pairs(dicetable[k]) do
				if diecount[v2] then
					diecount[v2] = diecount[v2] + 1;
				else
					diecount[v2] = 1;
				end
			end
		end

		for k,v in pairs(diecount) do
			if dicestr ~= "" then
				dicestr = dicestr .. "+";
			end
			dicestr = dicestr .. v .. k;
		end
	end
	
	return dicestr;
end

function processDie(params)
	if control then
		if User.isHost() then
			if params == "reveal" then
				OptionsManager.setOption("REVL", "on");
				SystemMessage("Revealing all die rolls");
				return;
			end
			if params == "hide" then
				OptionsManager.setOption("REVL", "off");
				SystemMessage("Hiding all die rolls");
				return;
			end
		end
	
		local diestring, descriptionstring = string.match(params, "%s*(%S+)%s*(.*)");
		
		if not diestring then
			local msg = {};
			msg.font = "systemfont";
			msg.text = "Usage: /die [dice] [description]";
			addMessage(msg);
			return;
		end
		
		local dice = {};
		local modifier = 0;
		
		dice, modifier = parseDieString(diestring);
		
		if #dice == 0 then
			dice = { "d0" };
		end

		control.throwDice("dice", dice, modifier, descriptionstring);
	end
end

function processMod(params)
	if control then
		local modstring, descriptionstring = string.match(params, "%s*(%S+)%s*(.*)");
		
		local modifier = tonumber(modstring);
		if not modifier then
			local msg = {};
			msg.font = "systemfont";
			msg.text = "Usage: /mod [number] [description]";
			addMessage(msg);
			return;
		end
		
		ModifierStack.addSlot(descriptionstring, modifier);
	end
end


--
--
-- MESSAGES
--
--

function createBaseMessage(custom)
	-- Set up the basic message components
	local msg = {font = "systemfont", text = ""};

	-- Add the character name or identity to the message
	local name = "";
	local opt_shrl = OptionsManager.getOption("SHRL");
	if opt_shrl == "all" then
		if custom then
			if custom["pc"] then
				name = NodeManager.getSafeChildValue(custom["pc"], "name", "");
			elseif custom["npc"] then
				name = NodeManager.getSafeChildValue(custom["npc"], "name", "");
			end
		end
	elseif opt_shrl == "pc" then
		if custom then
			name = NodeManager.getSafeChildValue(custom["pc"], "name", "");
		end
	end
	if name ~= "" then
		msg.text = name .. " -> " .. msg.text;
	else
		if User.isHost() then
			msg.sender = GmIdentityManager.getCurrent();
		else
			msg.sender = User.getIdentityLabel();
		end
	end
	
	-- Set the hidden dice option, if the GM has it set
	if User.isHost() then
		if OptionsManager.isOption("REVL", "on") then
			msg.dicesecret = false;
		end
	end

	-- If portrait chat is on, then add the portrait
	if OptionsManager.isOption("PCHT", "on") then
		if User.isHost() then
			msg.icon = "portrait_gm_token";
		else
			msg.icon = "portrait_" .. User.getCurrentIdentity() .. "_chat";
		end
	end

	-- Return the base message
	return msg;
end

-- Message: prints a message in the Chatwindow
function Message(msgtxt, broadcast, custom)
	local msg = createBaseMessage(custom);
	msg.text = msg.text .. msgtxt;
	if broadcast then
		deliverMessage(msg);
	else
		addMessage(msg);
	end
end

-- SystemMessage: prints a message in the Chatwindow
function SystemMessage(msgtxt)
	local msg = {font = "systemfont"};
	msg.text = msgtxt;
	addMessage(msg);
end


--
--
-- CLICK ROLLING
--
--

-- Handle double-clicks on action fields
function DoubleClickAction(type, bonus, desc, custom)
	local opt_dclk = OptionsManager.getOption("DCLK");
	if opt_dclk == "on" then
		d20Check(type, bonus, desc, custom);
	elseif opt_dclk == "mod" then
		ModifierStack.addSlot(desc, bonus);
	end
end

function DoubleClickNPC(type, bonus, desc, custom, dice)
	if dice then
		DieControlThrow(type, bonus, desc, custom, dice);
	else
		d20Check(type, bonus, desc, custom);
	end
end

function DoubleClickDieControl(type, bonus, name, custom, dice)
	local opt_dclk = OptionsManager.getOption("DCLK");
	if opt_dclk == "on" then
		DieControlThrow(type, bonus, name, custom, dice);
	end
end

-- Auto-roller
function d20Check(type, bonus, desc, custom)
	local dice = {};
	table.insert(dice, "d12");
	DieControlThrow(type, bonus, desc, custom, dice);
end

function d6Check(type, bonus, desc, custom)
	local dice = {};
	table.insert(dice, "d6");
	DieControlThrow(type, bonus, desc, custom, dice);
end

function AtributoCheck(type, bonus, desc, custom)
	local dice = {};
	table.insert(dice, {"d6","d6"});
	DieControlThrow(type, bonus, desc, custom, dice);
end

function DieControlThrow(type, bonus, name, custom, dice)
	if control then
		control.throwDice(type, dice, bonus, name, custom);
	end
end

--
--
-- CHAT REPORTS
--
--

function reportEffect(eff_node, target)
	-- Get the effect fields
	local eff_name = NodeManager.getSafeChildValue(eff_node, "label", "");
	local eff_exp = NodeManager.getSafeChildValue(eff_node, "expiration", "");
	local eff_savemod = NodeManager.getSafeChildValue(eff_node, "effectsavemod", "");

	-- Output the effect
	reportEffectFull(eff_name, eff_exp, eff_savemod, target);
end

function reportEffectFull(eff_name, eff_exp, eff_savemod, target)
	-- Build the basic effect message
	local msg = ChatManager.createBaseMessage({});
	msg.text = "[EFFECT] " .. eff_name .. " EXPIRES " .. eff_exp;
	if target then
		msg.text = msg.text .. " [to " .. target .. "]";
	end
	
	-- Add the save modifier as a number to make the chat entry draggable
	msg.diesecret = true;
	msg.dice = {"d0"};
	if eff_exp == "save" then
		msg.diemodifier = eff_savemod;
	end

	-- Add the message locally, and deliver to host, if needed
	if User.isHost() then
		addMessage(msg);
	else
		-- NOTE: Unable to deliver it to just the host, so distributing to everyone
		deliverMessage(msg);
		
		--local local_msg = ChatManager.createBaseMessage({});
		--local_msg.text = "Effect [" .. eff_name .. "] reported to host.";
		--addMessage(local_msg);
	end
end

function reportModifier(mod_name, mod_bonus)
	-- Build the basic modifier message
	local msg = ChatManager.createBaseMessage({});
	msg.text = mod_name;

	-- Add the save modifier as a number to make the chat entry draggable
	msg.diesecret = true;
	msg.dice = {"d0"};
	msg.diemodifier = mod_bonus;

	-- Deliver the message
	deliverMessage(msg);
end

--
--
-- SPECIAL MESSAGE HANDLING
--
--

SPECIAL_MSG_TAG = "[SPECIAL]";
SPECIAL_MSG_SEP = "|||";

specialmsghandlers = {};

function registerSpecialMsgHandler(msgtype, callback)
	specialmsghandlers[msgtype] = callback;
end

function sendSpecialMessage(msgtype, params)
	-- Hosts go directly to handling the message
	if User.isHost() then
		handleSpecialMessage(msgtype, "", "", params);
	
	-- Clients build a special message to send to the host
	else
		-- Build the special message to send
		local msg = {font = "msgfont", text = ""};
		msg.sender = SPECIAL_MSG_TAG .. SPECIAL_MSG_SEP .. msgtype .. SPECIAL_MSG_SEP .. User.getUsername() .. SPECIAL_MSG_SEP .. User.getIdentityLabel() .. SPECIAL_MSG_SEP;
		for k,v in pairs(params) do
			msg.text = msg.text .. v .. SPECIAL_MSG_SEP;
		end

		-- Deliver to the host
		deliverMessage(msg, "");
	end
end

function processSpecialMessage(msg)
	-- Only the host can process special messages
	if not User.isHost() then
		return false;
	end
	
	-- Make sure the sender this is a special message
	if string.find(msg.sender, SPECIAL_MSG_TAG, 1, true) ~= 1 then
		return false;
	end

	-- Parse out the special message details
	local msg_meta = {};
	local msg_clause;
	local clause_match = "(.-)" .. SPECIAL_MSG_SEP;
	for msg_clause in string.gmatch(msg.sender, clause_match) do
		table.insert(msg_meta, msg_clause);
	end
	local msgtype = msg_meta[2];
	local msguser = msg_meta[3];
	local msgidentity = msg_meta[4];
	
	-- Parse out the special message parameters
	local msg_params = {};
	for msg_clause in string.gmatch(msg.text, clause_match) do
		table.insert(msg_params, msg_clause);
	end
	
	-- Handle the special message
	handleSpecialMessage(msgtype, msguser, msgidentity, msg_params);
	return true;
end

function handleSpecialMessage(msgtype, msguser, msgidentity, paramlist)
	for k,v in pairs(specialmsghandlers) do
		if msgtype == k then
			v(msguser, msgidentity, paramlist);
			return;
		end
	end
	
	SystemMessage("[ERROR] Unknown special message received, Type = " .. msgtype);
end


--
--
-- WHISPERS
--
--

function processWhisper(params)
	-- Find the target user for the whisper, if available
	local lower_msg = string.lower(params);
	local user = nil;
	local recipient = nil;
	for k, v in ipairs(User.getAllActiveIdentities()) do
		local label = User.getIdentityLabel(v);
		local label_match = string.lower(label) .. " ";
		if string.sub(lower_msg, 1, string.len(label_match)) == label_match then
			if user then
				if #recipient < #label then
					recipient = label;
				end
			else
				recipient = label;
			end
		end
	end
	
	-- If no user, then bail out
	if not recipient then
		if User.isHost() then
			SystemMessage("Whisper recipient not found \rUsage: /w [recipient] [message]");
		else
            processWhisperGM(params);
		end
		return;
	end
	
	-- Get the message text
	local msgtext = string.sub(params, string.len(recipient) + 1);
	
	-- If GM then process directly
	sendSpecialMessage(SPECIAL_MSGTYPE_WHISPER, {recipient, msgtext});
end

function processWhisperGM(params)
	if not User.isHost() then
		sendSpecialMessage(SPECIAL_MSGTYPE_WHISPER, {"", params});
	end
end

function handleWhisper(msguser, msgidentity, paramlist)
	-- Get the parameters
	local recipient = paramlist[1];
	local whispertext = paramlist[2];
	
	-- Build the message to deliver
	local msg = {font = "msgfont"};
	msg.text = whispertext;

	-- Cycle through identities to determine user for recipient
	local recipient_user = "";
	for k, v in ipairs(User.getAllActiveIdentities()) do
		local label = User.getIdentityLabel(v);
		if label == recipient then
			recipient_user = User.getIdentityOwner(v);
		end
	end
	
	-- Deliver message to recipient
	if msgidentity == "" then
		msg.sender = "[w] GM";
	else
		msg.sender = "[w] " .. msgidentity;
	end
	if recipient == "" then
		addMessage(msg);
	else
		if recipient_user ~= "" then
			deliverMessage(msg, recipient_user);
		else
			SystemMessage("[ERROR] Unable to resolve owner of identity = " .. recipient);
		end
	end

	-- Also, deliver confirmation to the sender
	if recipient == "" then
		msg.sender = "[w] -> GM";
	else
		msg.sender = "[w] -> " .. recipient;
	end
	if msgidentity == "" then
		addMessage(msg);
	else
		deliverMessage(msg, msguser);
	end
	
	-- Finally, if the GM was not sender or recipient, then see if the show player messages option is on
	if OptionsManager.isOption("SHPW", "on") and msgidentity ~= "" and recipient ~= "" then
		msg.sender = "[w] " .. msgidentity .. " -> " .. recipient;
		addMessage(msg);
	end
end


--
--
--  THE BOX
--
--

function handleTheBox(msguser, msgidentity, paramlist)
	-- Get the parameters
	local droptype = paramlist[1];
	local desc = paramlist[2];
	local dicestr = paramlist[3];
	
	-- Build the description string
	local roll_desc = "[BOX] ";
	if msgidentity ~= "" then
		roll_desc = roll_desc .. msgidentity .. " -> ";
	else
		roll_desc = roll_desc .. "GM -> ";
	end
	roll_desc = roll_desc .. desc;

	-- Roll the dice
	local dice, modifier = parseDieString(dicestr);
	if #dice == 0 then
		dice = { "d0" };
	end
	control.throwDice(droptype, dice, modifier, roll_desc);
	
	-- Return a confirmation to client, if needed
	if msguser ~= "" then
		-- Build the message
		local clientmsg = {font = "chatfont", icon = "thebox_icon", sender = "[BOX]", text = ""};
		if desc ~= "" then
			clientmsg.text = desc .. ": ";
		end
		clientmsg.text = clientmsg.text .. dicestr;
		
		-- Deliver the message
		deliverMessage(clientmsg, msguser);
	end
end


--
--
--  RESTING (CT FIELDS)
--
--

function handleRest(msguser, msgidentity, paramlist)
	-- Get the parameters
	local restlength = paramlist[1];
	local ctentrynodename = paramlist[2];
	
	-- Get the combat tracker node
	local ctentrynode = DB.findNode(ctentrynodename);
	
	-- Reset the CT fields approprate for a rest
	NodeManager.setSafeChildValue(ctentrynode, "apused", "number", 0);
end


--
--
--  APPLY DAMAGE (CT FIELDS)
--
--

function handleApplyDamage(msguser, msgidentity, paramlist)
	-- Get the parameters
	local total = tonumber(paramlist[1]) or 0;
	local nodetype = paramlist[2];
	local nodename = paramlist[3];
	
	-- Get the combat tracker node
	local node = DB.findNode(nodename);
	if not node then
		SystemMessage("[ERROR] Unable to resolve damage application on node = " .. nodename);
		return;
	end
	
	-- Apply the damage
	CombatCommon.applyDamage(nodetype, node, total);
end


--
--
--  APPLY EFFECT (CT FIELDS)
--
--

function handleApplyEffect(msguser, msgidentity, paramlist)
	-- Get the parameters
	local ctentrynodename = paramlist[1];
	local eff_name = paramlist[2];
	local eff_exp = paramlist[3];
	local eff_savemod = paramlist[4];
	local eff_init = paramlist[5];
	local eff_appliedby = paramlist[6];
	
	-- Get the combat tracker node
	local ctentrynode = DB.findNode(ctentrynodename);
	if not ctentrynode then
		SystemMessage("[ERROR] Unable to resolve CT effect application on node = " .. ctentrynodename);
		return;
	end
	
	-- Apply the damage
	CombatCommon.addEffect(msguser, msgidentity, ctentrynode, eff_name, eff_exp, eff_savemod, eff_init, eff_appliedby);
end

--
--
--  END TURN (CT)
--
--

function handleEndTurn(msguser, msgidentity, paramlist)
	CombatCommon.endTurn(msguser);
end
