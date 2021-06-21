-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local tokenref = nil;

function onInit()
	-- Acquire token reference, if any
	linkToken();
	
	-- Update the wound and status displays
	onTypeChanged();
	onWoundsChanged();
end

function linkToken()
	if tokenrefid and tokenrefnode then
		local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
		if imageinstance then
			tokenref = imageinstance;
			tokenref.onDelete = refDeleted;
			tokenref.onDrop = refDrop;
		end
	end
end

function refDeleted(deleted)
	tokenref = nil;
end

function refDrop(droppedon, draginfo)
	CombatCommon.onDrop("ct", getDatabaseNode().getNodeName(), draginfo);
end

function onTypeChanged()
	-- Update what fields are visible for health display
	updateHealthDisplay();
end

function onWoundsChanged()
	-- Calculate the percent wounded for this unit
	local percent_wounded = 0;
	if hp.getValue() > 0 then
		percent_wounded = wounds.getValue() / hp.getValue();
	end
	
	-- Based on the percent wounded, change the font color for the Wounds field
	if percent_wounded <= 0 then
		wounds.setFont("ct_healthy_font");
	elseif percent_wounded < .5 then
		wounds.setFont("ct_ltwound_font");
	elseif percent_wounded < 1 then
		wounds.setFont("ct_bloodied_font");
	else
		wounds.setFont("ct_dead_font");
	end
end

function onSurgesChanged()
	-- Update the healing surges remaining field when healing surges max or healing surges used changes
	healsurgeremaining.setValue(healsurgesmax.getValue() - healsurgesused.getValue());
end

-- Section visibility handling

function updateHealthDisplay()
	-- Check the party health view option
	-- Hide any NPC health fields, and if the option is off, hide the party health fields also
	if type.getValue() == "npc" or OptionsManager.isOption("SHPH", "off") then
		hp.setVisible(false);
		hptemp.setVisible(false);
		wounds.setVisible(false);
		healsurgeremaining.setVisible(false);

		status.setVisible(true);
	else
		hp.setVisible(true);
		hptemp.setVisible(true);
		wounds.setVisible(true);
		healsurgeremaining.setVisible(true);

		status.setVisible(false);
	end
end
