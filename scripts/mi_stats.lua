function onInit()
	
	-- Update the display based on the creature type
	updateDisplay();
	
	-- Set up the type field, and lock it down if static
	local val = mitype.getValue();
	if val == "weapon" then
		itemtype_radio.setIndex(1, true);
	else
		if val == "armor" then
			itemtype_radio.setIndex(2, true);
		else
			itemtype_radio.setIndex(3, true);
		end
	end
	if mitype.getDatabaseNode().isStatic() then
		itemtype_radio.setVisible(false);
	end
end
function updateDisplay()
	-- Determine the type of magic item and toggle the display as needed
	local isarmor = false;
	local isweapon = false;

	if mitype.getValue() == "weapon" then
		isweapon = true;
	end
	if mitype.getValue() == "armor" then
		isarmor = true;
	end

	-- Do not display these if not  weapon
	critical.updateVisibility(isweapon);
	profbonus.updateVisibility(isweapon);
	damage.updateVisibility(isweapon);
	range.updateVisibility(isweapon);
	group.updateVisibility(isweapon);
	properties.updateVisibility(isweapon);

	critical_label.updateVisibility(isweapon);
	profbonus_label.updateVisibility(isweapon);
	damage_label.updateVisibility(isweapon);
	range_label.updateVisibility(isweapon);
	group_label.updateVisibility(isweapon);
	properties_label.updateVisibility(isweapon);

	-- Do not display these if not armor
	ac.updateVisibility(isarmor);
	min_enhance.updateVisibility(isarmor);
	checkpenalty.updateVisibility(isarmor);
	speed.updateVisibility(isarmor);

	ac_label.updateVisibility(isarmor);
	min_enhance_label.updateVisibility(isarmor);
	checkpenalty_label.updateVisibility(isarmor);
	speed_label.updateVisibility(isarmor);

end
