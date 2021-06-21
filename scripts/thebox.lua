-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = DB.createNode("options.TBOX", "string");
	if node then
		node.onUpdate = update;
	end
	node = DB.createNode("options.REVL", "string");
	if node then
		node.onUpdate = update;
	end

	update();
end

function update()
	if OptionsManager.isOption("TBOX", "on") then
		if User.isHost() and OptionsManager.isOption("REVL", "off") then
			setVisible(false);
		else
			setVisible(true);
		end
	else
		setVisible(false);
	end
end

function onDrop(x, y, draginfo)
	if OptionsManager.isOption("TBOX", "on") then
		-- Make sure we add in the modifier stack, if any
		ModifierStack.applyToRoll(draginfo);

		-- Build a dice string by processing the die list
		local dicestr = ChatManager.convertDieListToString(draginfo.getDieList());
		if draginfo.getNumberData() ~= 0 then
			if draginfo.getNumberData() > 0 then
				dicestr = dicestr .. "+" .. draginfo.getNumberData();
			else
				dicestr = dicestr .. draginfo.getNumberData();
			end
		end
		
		-- Get the description
		local base_desc = draginfo.getDescription();
		
		-- Different handling based on whether the dice dropped on the host or the client
		if User.isHost() then
			ChatManager.processDie(dicestr .. " [BOX] GM -> " .. base_desc);
		else
			-- Build the client message
			local clientmsg = {font = "chatfont", sender = "[BOX]", icon = "thebox_icon", text = ""};
			if base_desc ~= "" then
				clientmsg.text = base_desc .. ": ";
			end
			clientmsg.text = clientmsg.text .. dicestr;

			-- Build the host message	
			local hostmsg = {font = "chatfont", sender = "thebox", icon = "thebox_icon", text = ""};
			hostmsg.text = dicestr .. " [BOX] ";
			if User.getIdentityLabel() ~= nil then
				hostmsg.text = hostmsg.text .. User.getIdentityLabel() .. " -> ";
			end
			hostmsg.text = hostmsg.text .. base_desc;

			-- Send both messages
			ChatManager.addMessage(clientmsg);
			ChatManager.deliverMessage(hostmsg, "");
		end

		-- Let FG know that this drop event is handled
		return true;
	end
end
