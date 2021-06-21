-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onDeliverMessage(messagedata, mode)
	local icon = nil;
	
	if User.isHost() then
		gmid, isgm = GmIdentityManager.getCurrent();

		if messagedata.hasdice then
			icon = "portrait_gm_token";
			messagedata.sender = gmid;
			messagedata.font = "systemfont";
		elseif mode == "chat" then
			icon = "portrait_gm_token";
			messagedata.sender = gmid;
			
			if isgm then
				messagedata.font = "dmfont";
			else
				messagedata.font = "npcchatfont";
			end
		elseif mode == "story" then
			messagedata.sender = "";
			messagedata.font = "narratorfont";
		elseif mode == "emote" then
			messagedata.text = gmid .. " " .. messagedata.text;
			messagedata.sender = "";
			messagedata.font = "emotefont";
		end
	elseif mode == "chat" then
		icon = "portrait_" .. User.getCurrentIdentity() .. "_chat";
	end
	
	if OptionsManager.isOption("PCHT", "on") then
		messagedata.icon = icon
	end
	
	return messagedata;
end

function onTab()
	ChatManager.doAutocomplete();
end

function onInit()
	ChatManager.registerEntryControl(self);
end
