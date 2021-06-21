-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Lock it down, if it is static
	if getDatabaseNode().isStatic() then
		itemtype_radio.setVisible(false);
	end
	
	-- Update the display
	updateDisplay();
end

function updateDisplay()
	local idval = isidentified.getState();
	if User.isHost() then
		idval = true;
	end
	
	local showweapon = false;
	local showarmor = false;
	local showother = false;

	if itemtype_radio.getSourceValue() == "weapon" and idval then
		showweapon = true;
	end
	if itemtype_radio.getSourceValue() == "armor" and idval then
		showarmor = true;
	end
	if itemtype_radio.getSourceValue() == "other" and idval then
		showother = true;
	end
	
	-- Only display fields when identified
	flavor.setVisible(idval);

	level.updateVisibility(idval);
	bonus.updateVisibility(idval);
	cost.updateVisibility(idval);
	class.updateVisibility(idval);
	subclass.updateVisibility(idval);
	enhancement.updateVisibility(idval);
	weight.updateVisibility(idval);
	special.updateVisibility(idval);
	prerequisite.updateVisibility(idval);

	level_label.updateVisibility(idval);
	bonus_label.updateVisibility(idval);
	cost_label.updateVisibility(idval);
	class_label.updateVisibility(idval);
	subclass_label.updateVisibility(idval);
	enhancement_label.updateVisibility(idval);
	weight_label.updateVisibility(idval);
	special_label.updateVisibility(idval);
	prerequisite_label.updateVisibility(idval);
	
	-- Display these fields only if other
	shield.updateVisibility(showother);
	shield_label.updateVisibility(showother);
	
	-- Display these field only if item is a weapon
	critical.updateVisibility(showweapon);
	profbonus.updateVisibility(showweapon);
	damage.updateVisibility(showweapon);
	range.updateVisibility(showweapon);
	group.updateVisibility(showweapon);
	properties.updateVisibility(showweapon);

	critical_label.updateVisibility(showweapon);
	profbonus_label.updateVisibility(showweapon);
	damage_label.updateVisibility(showweapon);
	range_label.updateVisibility(showweapon);
	group_label.updateVisibility(showweapon);
	properties_label.updateVisibility(showweapon);

	-- Display these field only if item is an armor
	ac.updateVisibility(showarmor);
	min_enhance.updateVisibility(showarmor);
	checkpenalty.updateVisibility(showarmor);
	speed.updateVisibility(showarmor);

	ac_label.updateVisibility(showarmor);
	min_enhance_label.updateVisibility(showarmor);
	checkpenalty_label.updateVisibility(showarmor);
	speed_label.updateVisibility(showarmor);

end
