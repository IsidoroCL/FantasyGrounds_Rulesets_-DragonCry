-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onSortCompare(w1, w2)
	if w1.initresult.getValue() == w2.initresult.getValue() then
		return w1.init.getValue() < w2.init.getValue();
	end
	
	return w1.initresult.getValue() < w2.initresult.getValue();
end

function onFilter(w)
	if w.type.getValue() == "pc" then
		return true;
	end
	if w.show_npc.getValue() ~= 0 then
		return true;
	end
	return false;
end

function onDrop(x, y, draginfo)
	local wnd = getWindowAt(x,y);
	if wnd then
		return CombatCommon.onDrop("ct", wnd.getDatabaseNode().getNodeName(), draginfo);
	end
end
