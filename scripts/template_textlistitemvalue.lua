-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if gmonly and not User.isHost() then
		setReadOnly(true);
	end
end

function onEnter()
	if isReadOnly() then
		return;
	end
	
	local wnd = NodeManager.createSafeWindow(window.windowlist);
	if wnd then
		wnd[getName()].setFocus();
	end
end

function onNavigateDown()
	local next = window.windowlist.getNextWindow(window);
	if next then
		next[getName()].setFocus();
		next[getName()].setCursorPosition(1);
		next[getName()].setSelectionPosition(1);
	end
end

function onNavigateUp()
	local prev = window.windowlist.getPrevWindow(window);
	if prev then
		prev[getName()].setFocus();
		prev[getName()].setCursorPosition(#prev[getName()].getValue()+1);
		prev[getName()].setSelectionPosition(#prev[getName()].getValue()+1);
	end
end

function onNavigateRight()
	if tabtarget and tabtarget[1] and tabtarget[1].next and tabtarget[1].next[1] then
		local target = window[tabtarget[1].next[1]];

		if type(target) == "stringcontrol" then
			target.setFocus();
			target.setCursorPosition(1);
			target.setSelectionPosition(1);
		end
	end
end

function onNavigateLeft()
	if tabtarget and tabtarget[1] and tabtarget[1].prev and tabtarget[1].prev[1] then
		local target = window[tabtarget[1].prev[1]];

		if type(target) == "stringcontrol" then
			target.setFocus();
			target.setCursorPosition(#target.getValue()+1);
			target.setSelectionPosition(#target.getValue()+1);
		end
	end
end

function onDeleteUp()
	if isReadOnly() then
		return;
	end
	
	if nodelete then
		onNavigationUp();
		return;
	end
	
	local prev = window.windowlist.getPrevWindow(window);
	if prev then
		prev[getName()].setFocus();
		prev[getName()].setCursorPosition(#prev[getName()].getValue()+1);
		prev[getName()].setSelectionPosition(#prev[getName()].getValue()+1);
		
		if getValue() == "" then
			delete();
		end
	elseif getValue() == "" then
		local next = window.windowlist.getNextWindow(window);

		if next then
			next[getName()].setFocus();
			next[getName()].setCursorPosition(1);
			next[getName()].setSelectionPosition(1);
		end
		
		delete();
	end
end

function onDeleteDown()
	if isReadOnly() then
		return;
	end
	
	if nodelete then
		onNavigationDown();
		return;
	end
	
	local next = window.windowlist.getNextWindow(window);
	if next then
		next[getName()].setFocus();
		next[getName()].setCursorPosition(1);
		next[getName()].setSelectionPosition(1);

		if getValue() == "" then
			delete();
		end
	elseif getValue() == "" then
		local prev = window.windowlist.getPrevWindow(window);

		if prev then
			prev[getName()].setFocus();
			prev[getName()].setCursorPosition(#prev[getName()].getValue()+1);
			prev[getName()].setSelectionPosition(#prev[getName()].getValue()+1);
		end
		
		delete();
	end
end

function delete()
	window.getDatabaseNode().delete();
end

function onGainFocus()
	window.setFrame("rowshade");
end

function onLoseFocus()
	window.setFrame(nil);
end
