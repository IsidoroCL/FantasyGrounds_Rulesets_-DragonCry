-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onIntegrityChange()
	if window.getDatabaseNode().isIntact() then
		resetMenuItems();
		integritywidget.setBitmap("indicator_intactmodule");
	else
		registerMenuItem("Revert Changes", "shuffle", 8);
		integritywidget.setBitmap("indicator_nonintactmodule");
	end
end

function onInit()
	if window.getDatabaseNode().getModule() then
		integritywidget = addBitmapWidget("indicator_intactmodule");
		integritywidget.setPosition("center", 3, 0);
		integritywidget.setVisible(true);
		
		setTooltipText(window.getDatabaseNode().getModule());
		
		window.getDatabaseNode().onIntegrityChange = onIntegrityChange;
		onIntegrityChange();
	end
end

function onMenuSelection(selection)
	if selection == 8 then
		window.getDatabaseNode().revert();
	end
end

function onDrag(button, x, y, draginfo)
	draginfo.setType("shortcut");
	draginfo.setIcon(icon[1].normal[1]);
	draginfo.setShortcutData(getValue());
	draginfo.setDescription(getTargetDatabaseNode().getChild("name").getValue());

	return true;
end
