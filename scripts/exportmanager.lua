-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		ChatManager.registerSlashHandler("/export", processExport);
	end
end

function processExport(params)
	Interface.openWindow("export", "");
end

