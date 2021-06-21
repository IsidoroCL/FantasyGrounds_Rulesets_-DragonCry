-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Remove Attack", "deletepointer", 3);
	
	updateDisplay();
end

function onMenuSelection(selection)
	if selection == 3 then
		windowlist.deleteChild(self, true);
	end
end

function isWeaponPower()
	local keywords = string.lower(NodeManager.getSafeChildValue(getDatabaseNode(), "...keywords", ""));
	if string.match(keywords, "weapon") then
		return true;
	end
	return false;
end

function updateDisplay()
	if isWeaponPower() then
		focuslabel.setValue("Wpn:");
	else
		focuslabel.setValue("Imp:");
	end
	
	activateatkdetail.onValueChanged();
	activatedmgdetail.onValueChanged();
	
	onAttackChanged();
	onDamageChanged();
end

function onAttackChanged()
	-- Build the attack display string
	local s = attackstatlabel.getValue();
	if attackstatmodifier.getValue() ~= 0 then
		if s == "-" then
			s = "";
		end
		s = s .. "+" .. attackstatmodifier.getValue();
	end
	s = s .. " vs ";
	s = s .. attackdeflabel.getValue();
	
	-- Set the attack display to the new text
	attackview.setValue(s);
end

function onDamageChanged()
	-- Build the damage display string
	local strtable = {};
	if isWeaponPower() and damageweaponmult.getValue() ~= 0 then
		table.insert(strtable, "" .. damageweaponmult.getValue() .. "[W]");
	end
	if #(damagebasicdice.getDice()) > 0 then
		table.insert(strtable, ChatManager.convertDieFieldToString(damagebasicdice.getDice()));
	end
	if damagestatlabel.getValue() ~= "-" then
		table.insert(strtable, damagestatlabel.getValue());
	end
	if damagestatlabel2.getValue() ~= "-" then
		table.insert(strtable, damagestatlabel2.getValue());
	end
	if damagestatmodifier.getValue() ~= 0 then
		table.insert(strtable, "" .. damagestatmodifier.getValue());
	end
	
	-- Concatenate the damage clauses together
	local s = table.concat(strtable, "+");
	if s == "" then
		s = "0";
	end
	
	-- Add the damage type
	if damagetype.getValue() ~= "" then
		s = s .. " " .. damagetype.getValue();
	end
	
	-- Set the attack display to the new text
	damageview.setValue(s);
end
