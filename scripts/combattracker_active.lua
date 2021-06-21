-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	activewidget = addBitmapWidget(activeicon[1]);
	activewidget.setVisible(false);

	source = NodeManager.createSafeChild(window.getDatabaseNode(), getName(), "number");
	source.onUpdate = onValueChanged;
	
	updateDisplay();
end

function onValueChanged()
	updateDisplay();
end

function updateDisplay()
	local state = getState();

	activewidget.setVisible(state);
	
	window.token.setActive(state);
	window.setActiveVisible(state);
end

function setState(state)
	local datavalue = 1;
	if state == nil or state == false or state == 0 then
		datavalue = 0;
	end
	
	source.setValue(datavalue);
end

function getState()
	local datavalue = source.getValue();
	return datavalue ~= 0;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if not getState() and User.isHost() then
		window.windowlist.requestActivation(window);
	end
	return true;
end

function onDrag(button, x, y, draginfo)
	draginfo.setType("combattrackeractivation");
	draginfo.setIcon(activeicon[1]);

	activewidget.setVisible(false);

	return true;
end

function onDragEnd(draginfo)
	if getState() then
		activewidget.setVisible(true);
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("combattrackeractivation") then
		window.windowlist.requestActivation(window);
		return true;
	end
end