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

	propertylabel.setVisible(showlists);
	propertylist.setVisible(showlists);
	property_scroller.setVisible(showlists);

	divider.setVisible(showlists);

	quirklabel.setVisible(showlists);
	quirklist.setVisible(showlists);
	quirk_scroller.setVisible(showlists);
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
				wnd.shortdescription.setFocus();
			end
		end
	end
end
