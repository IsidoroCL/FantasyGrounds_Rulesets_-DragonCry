-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function clearSelection()
	for k, w in ipairs(getWindows()) do
		w.base.setFrame(nil);
	end
end

function addIdentity(id, label, localdatabasenode)
	for k, v in ipairs(activeidentities) do
		if v == id then
			return;
		end
	end

	local wnd = NodeManager.createSafeWindow(self);
	if wnd then
		wnd.setId(id);
		wnd.label.setValue(label);

		wnd.setLocalNode(localdatabasenode);

		if id then
			wnd.portrait.setIcon("portrait_" .. id .. "_charlist");
		end
	end
end

function onInit()
	activeidentities = User.getAllActiveIdentities();

	getWindows()[1].close();
	createWindowWithClass("identityselection_newentry");

	localIdentities = User.getLocalIdentities();
	for n, v in ipairs(localIdentities) do
		local label_val = NodeManager.getSafeChildValue(v.databasenode, "name", "");
		addIdentity(v.id, label_val, v.databasenode);
	end

	User.getRemoteIdentities("charsheet", "name", addIdentity);
end
