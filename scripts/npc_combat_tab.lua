-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Capture sizing events, so we can resize the fields 
	self.onSizeChanged = sizeChanged;
	
	-- Update the display based on the creature type
	updateDisplay();
	
	-- Set up the type field, and lock it down if static
	if getDatabaseNode().isStatic() then
		npctype_radio.setVisible(false);
	end
end

-- If the size of the window changes, adjust the widths of abilities and saves
function sizeChanged()
	local winwidth, winheight = getSize();

	local defwidth = math.floor(32 + (winwidth - 235) / 4);

	ac.setAnchoredWidth(defwidth);
	fortitude.setAnchoredWidth(defwidth);
	reflex.setAnchoredWidth(defwidth);
	will.setAnchoredWidth(defwidth);

	local abilitywidth = math.floor(21 + (winwidth - 235) / 6);

	strength.setAnchoredWidth(abilitywidth);
	dexterity.setAnchoredWidth(abilitywidth);
	constitution.setAnchoredWidth(abilitywidth);
	intelligence.setAnchoredWidth(abilitywidth);
	wisdom.setAnchoredWidth(abilitywidth);
	charisma.setAnchoredWidth(abilitywidth);
end


function updateDisplay()
	-- Determine what type of NPC this is
	-- 1 = Creature, 2 = Trap, 3 = Vehicle
	local index = npctype_radio.getIndex();

	-- Show/hide the fields based on the NPC type
	
	-- Creature only fields
	senses.updateVisibility(index == 1);
	senseslabel.updateVisibility();

	specialdefenses.updateVisibility(index == 1);
	specialdefenseslabel.updateVisibility();
	saves.updateVisibility(index == 1);
	saveslabel.updateVisibility();
	actionpoints.updateVisibility(index == 1);
	actionpointslabel.updateVisibility();
	skills.updateVisibility(index == 1);
	skillslabel.updateVisibility();

	abilitieslabel.setVisible(index == 1);
	strength.setVisible(index == 1);
	strengthlabel.updateVisibility();
	constitution.setVisible(index == 1);
	constitutionlabel.updateVisibility();
	dexterity.setVisible(index == 1);
	dexteritylabel.updateVisibility();
	intelligence.setVisible(index == 1);
	intelligencelabel.updateVisibility();
	wisdom.setVisible(index == 1);
	wisdomlabel.updateVisibility();
	charisma.setVisible(index == 1);
	charismalabel.updateVisibility();

	alignment.updateVisibility(index == 1);
	alignmentlabel.updateVisibility();
	languages.updateVisibility(index == 1);
	languageslabel.updateVisibility();
	equipment.updateVisibility(index == 1);
	equipmentlabel.updateVisibility();

	-- Trap only fields
	trapdesc.updateVisibility(index == 2);
	trapdesclabel.updateVisibility();
	flavor.updateVisibility(index == 2);
	flavorlabel.updateVisibility();

	-- Vehicle only fields
	cost.updateVisibility(index == 3);
	cost_label.updateVisibility();
	space.updateVisibility(index == 3);
	space_label.updateVisibility();

	-- Shared fields (Role/Init/XP/HP/Defenses)
	levelrole.updateVisibility(index ~= 3);
	levelrole_label.updateVisibility();
	init.updateVisibility(index ~= 3);
	init_label.updateVisibility();
	xp.updateVisibility(index ~= 3);
	xp_label.updateVisibility();
	hp.updateVisibility(index ~= 2);
	hplabel.updateVisibility();

	defenseslabel.setVisible(index ~= 2);
	ac.setVisible(index ~= 2);
	aclabel.updateVisibility();
	fortitude.setVisible(index ~= 2);
	fortitudelabel.updateVisibility();
	reflex.setVisible(index ~= 2);
	reflexlabel.updateVisibility();
	will.setVisible(index == 1);
	willlabel.updateVisibility();
end
