-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function createWidgets(name)
	identityname = name;

	portraitwidget = addBitmapWidget("portrait_" .. name .. "_charlist");

	namewidget = addTextWidget("sheetlabelsmall", "- Unnamed -");
	namewidget.setPosition("center", 0, 27);
	namewidget.setFrame("mini_name", 5, 2, 5, 2);
	namewidget.setMaxWidth(75);
	
	turnwidget = addBitmapWidget("indicator_flag");
	turnwidget.setPosition("center", 30, -20);
	turnwidget.setVisible(false);
	
	typingwidget = addBitmapWidget("indicator_typing");
	typingwidget.setPosition("center", -23, -23);
	typingwidget.setVisible(false);
	idlingwidget = addBitmapWidget("indicator_idling");
	idlingwidget.setPosition("center", -23, -23);
	idlingwidget.setVisible(false);
	
	colorwidget = addBitmapWidget("indicator_pointer");
	colorwidget.setPosition("center", 31, 16);
	colorwidget.setVisible(false);

	resetMenuItems();
	if User.isHost() then
		registerMenuItem("Ring Bell", "bell", 5);
	else
		if User.isOwnedIdentity(name) then
			registerMenuItem("Activate", "turn", 5);
			registerMenuItem("Release", "erase", 4);
		end
	end
end

function stateChange(statename, state)
	if statename == "current" then
		if state then
			namewidget.setFont("sheetlabelsmallbold");
		else
			namewidget.setFont("sheetlabelsmall");
		end
	end
	
	if statename == "label" then
		if state ~= "" then
			namewidget.setText(state);
		else
			namewidget.setText("- Unnamed - ");
		end
	end
	
	if statename == "color" then
		colorwidget.setColor(User.getIdentityColor(identityname));
		colorwidget.setVisible(true);
	end
	
	if statename == "active" then
		typingwidget.setVisible(false);
		idlingwidget.setVisible(false);
	end
	
	if statename == "typing" then
		typingwidget.setVisible(true);
		idlingwidget.setVisible(false);
	end
	
	if statename == "idle" then
		typingwidget.setVisible(false);
		idlingwidget.setVisible(true);
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if User.isHost() or User.isOwnedIdentity(identityname) then
		local wnd = Interface.findWindow("charsheet", "charsheet." .. identityname);
		local index = 1;
		if wnd then
			index = wnd.tabs.getIndex();
			wnd.close();
		end
		local newwnd = Interface.openWindow("charsheet", "charsheet." .. identityname);
		if wnd and newwnd then
			newwnd.tabs.activateTab(index);
		end
	end
	return true;
end

function onDrag(button, x, y, draginfo)
	if User.isHost() or User.isOwnedIdentity(identityname) then
		draginfo.setType("playercharacter");
		draginfo.setTokenData("portrait_" .. identityname .. "_token");
		draginfo.setStringData(identityname);
		draginfo.setShortcutData("charsheet", "charsheet." .. identityname);
		
		local base = draginfo.createBaseData();
		base.setType("token");
		base.setTokenData("portrait_" .. identityname .. "_token");
	
		return true;
	end
end

function onDrop(x, y, draginfo)
	if User.isHost() then
		if CombatCommon.onDrop("pc", "charsheet." .. identityname, draginfo) then
			return true;
		end
		
		-- Default number drop behavior
		if draginfo.isType("number") then
			local msg = {};
			msg.text = draginfo.getDescription() .. " [to " .. User.getIdentityLabel(identityname) .."]";
			msg.font = "systemfont";
			msg.icon = "portrait_" .. identityname .. "_targetportrait";
			msg.dice = {};
			msg.diemodifier = draginfo.getNumberData();
			msg.dicesecret = false;
			
			ChatManager.deliverMessage(msg);
			return true;
		end

		-- Send dropped string as whisper
		if draginfo.isType("string") then
			local msg = {};
			msg.text = draginfo.getStringData();
			msg.font = "msgfont";

			msg.sender = "<whisper>";
			ChatManager.deliverMessage(msg, User.getIdentityOwner(identityname));

			msg.sender = "-> " .. User.getIdentityLabel(identityname);
			ChatManager.addMessage(msg);

			return true;
		end
		
		-- Shortcut shared to single client
		if draginfo.isType("shortcut") then
			local wnd = Interface.openWindow(draginfo.getShortcutData());
			if wnd then
				wnd.share(User.getIdentityOwner(identityname));
			end
		
			return true;
		end
	end

	-- Portrait selection
	if draginfo.isType("portraitselection") then
		User.setPortrait(identityname, draginfo.getStringData());
		return true;
	end
end

function onMenuSelection(selection)
	if User.isOwnedIdentity(identityname) then
		if selection == 5 then
			User.setCurrentIdentity(identityname);
	
			if CampaignRegistry and CampaignRegistry.colortables and CampaignRegistry.colortables[identityname] then
				local colortable = CampaignRegistry.colortables[identityname];
				User.setCurrentIdentityColors(colortable.color or "000000", colortable.blacktext or false);
			end
			
		elseif selection == 4 then
			User.releaseIdentity(identityname);
		end
	end
	
	if User.isHost() then
		if selection == 5 then
			User.ringBell(User.getIdentityOwner(identityname));
		end
	end
end