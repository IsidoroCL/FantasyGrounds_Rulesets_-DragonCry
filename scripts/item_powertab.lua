-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local idnode = nil;

function onInit()
	idnode = getDatabaseNode().createChild("isidentified", "number");
	if idnode then
		idnode.onUpdate = updateDisplay;
	end

	updateDisplay();
end

function updateDisplay()
	local showlists = true;
	if idnode then
		if idnode.getValue() == 0 then
			showlists = false;
		end
	end
	if User.isHost() then
		showlists = true;
	end

	powerlabel.setVisible(showlists);
	powerlist.setVisible(showlists);
	power_scroller.setVisible(showlists);
end

function onClick(list)
	local allowcreate = true;
	if not User.isHost() then
		allowcreate = false;
	end

	if allowcreate then
		if not list.getNextWindow(nil) then
			local wnd = list.createWindow();
			if wnd then
				wnd.name.setFocus();
			end
		end
	end
end
