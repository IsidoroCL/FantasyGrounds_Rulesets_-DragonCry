-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Rest", "lockvisibilityon", 8);
	registerMenuItem("Short Rest", "pointer_cone", 8, 8);
	registerMenuItem("Extended Rest", "pointer_circle", 8, 6);
end

function onMenuSelection(selection, subselection)
	if selection == 8 then
		if subselection == 8 then
			ChatManager.Message("Taking Short Rest", true, {pc = getDatabaseNode()});
			CharSheetCommon.rest(getDatabaseNode());
			
			local ctentry = CombatCommon.getCTFromPC(getDatabaseNode().getNodeName());
			if ctentry then
				CombatCommon.rest(ctentry);
			end
		elseif subselection == 6 then
			ChatManager.Message("Taking Extended Rest", true, {pc = getDatabaseNode()});
			CharSheetCommon.rest(getDatabaseNode(), true);
			
			local ctentry = CombatCommon.getCTFromPC(getDatabaseNode().getNodeName());
			if ctentry then
				CombatCommon.rest(ctentry, true);
			end
		end
	end
end
