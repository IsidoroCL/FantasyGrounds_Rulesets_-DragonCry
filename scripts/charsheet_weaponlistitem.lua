-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	setOrder();
	
	local refnamenode = getDatabaseNode().createChild("nodename", "string");
	if refnamenode then
		refnamenode.onUpdate = onReferenceSet;
	end
	onReferenceSet();
end

function onReferenceSet()
	if shortcut.getValue() == "" then
		local nodetype = NodeManager.getSafeChildValue(getDatabaseNode(), "nodetype", "");
		local nodename = NodeManager.getSafeChildValue(getDatabaseNode(), "nodename", "");
		if nodetype ~= "" and nodename ~= "" then
			shortcut.setValue(nodetype, nodename);
		end
	end
end

function setOrder()
	if order.getValue() == 0 then
		local ordertable = {};
		for k,v in pairs(windowlist.getWindows()) do
			ordertable[v.order.getValue()] = true;
		end

		local i = 1;
		while ordertable[i] do
			i = i + 1;
		end

		order.setValue(i);
		orderlabel.setValue("" .. i .. ".");
	end
end
