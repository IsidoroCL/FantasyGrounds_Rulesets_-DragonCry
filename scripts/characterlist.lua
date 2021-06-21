-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function findControlForIdentity(identity)
	return self["ctrl_" .. identity];
end

function controlSortCmp(t1, t2)
	return t1.name < t2.name;
end

function layoutControls()
	local identitylist = {};
	
	for key, val in pairs(User.getAllActiveIdentities()) do
		table.insert(identitylist, { name = val, control = findControlForIdentity(val) });
	end
	
	table.sort(identitylist, controlSortCmp);

	local n = 0;
	for key, val in pairs(identitylist) do
		val.control.sendToBack();
	end
	
	anchor.sendToBack();
end

function onLogin(username, activated)
	NodeManager.addWatcher("options", username);
	NodeManager.addWatcher("combattracker", username);
	NodeManager.addWatcher("combattracker_props", username);
	NodeManager.addWatcher("modifiers", username);
	NodeManager.addWatcher("effects", username);
end

function onUserStateChange(username, statename, state)
	if username ~= "" and User.getCurrentIdentity(username) then
		local ctrl = findControlForIdentity(User.getCurrentIdentity(username));
		if ctrl then
			ctrl.stateChange(statename, state);
		end
	end
end

function onIdentityActivation(identity, username, activated)
	if activated then
		do
			if not findControlForIdentity(identity) then
				createControl("characterlist_entry", "ctrl_" .. identity);
				
				userctrl = findControlForIdentity(identity);
				userctrl.createWidgets(identity);
				
				layoutControls();
			end
		end
		
		if not User.isHost() then
			TheBoxManager.activate();
		end
	else
		findControlForIdentity(identity).destroy();
		layoutControls();
	end
end

function onIdentityStateChange(identity, username, statename, state)
	local ctrl = findControlForIdentity(identity);
	if ctrl then
		ctrl.stateChange(statename, state);
	end
end

function onInit()
	if User.isHost() then
		User.onLogin = onLogin;
	end
	User.onUserStateChange = onUserStateChange;
	User.onIdentityActivation = onIdentityActivation;
	User.onIdentityStateChange = onIdentityStateChange;
end
