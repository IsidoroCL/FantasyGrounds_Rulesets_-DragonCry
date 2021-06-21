-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

spacingon = false;
defensiveon = false;
activeon = false;
effectson = false;

function onInit()
	-- Set the displays to what should be shown
	setSpacingVisible(false);
	setDefensiveVisible(false);
	setActiveVisible(false);
	setEffectsVisible(false);

	-- Acquire token reference, if any
	linkToken();
	
	-- Set up the PC links
	if type.getValue() == "pc" then
		linkPCFields();
	end
	
	-- Update the wound and status displays
	onWoundsChanged();
	
	-- Register the deletion menu item for the host
	registerMenuItem("Delete Item", "delete", 6);
end

function linkToken()
	if tokenrefid and tokenrefnode then
		local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
		if imageinstance then
			token.acquireReference(imageinstance);
		end
	end
end

function onMenuSelection(selection)
	if selection == 6 then
		delete();
	end
end

function delete()
	-- Move to the next actor, if this CT entry is active
	if isActive() then
		windowlist.nextActor();
	end

	-- If this is an NPC with a token on the map, then remove the token also
	if type.getValue() == "npc" then
		token.deleteReference();
	end

	-- Clear the effects list
	effects.reset(false);

	-- Delete the database node and close the window
	getDatabaseNode().delete();

	-- Update the global subsection toggle buttons
	windowlist.onEntrySectionToggle();
end


function onTypeChanged()
	-- If a PC, then set up the links to the char sheet
	local val = type.getValue();
	if val == "pc" then
		linkPCFields();
	end

	-- If a NPC, then show the NPC display button; otherwise, hide it
	if val == "npc" then
		show_npc.setVisible(true);
	else
		show_npc.setVisible(false);
	end
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

	-- Based on the percent wounded, set the Status text field
	if percent_wounded <= 0 then
		status.setValue("Healthy");
	elseif percent_wounded < .5 then
		status.setValue("Light");
	elseif percent_wounded < 1 then
		status.setValue("Bloodied");
	elseif percent_wounded < 1.5 then
		status.setValue("Dying");
	else
		status.setValue("Dead");
	end

	-- Update the token underlay to reflect wound status
	token.updateUnderlay();
end

function onSurgesChanged()
	-- Update the healing surges remaining field when healing surges max or healing surges used changes
	healsurgeremaining.setValue(healsurgesmax.getValue() - healsurgesused.getValue());
end

function onFOFChanged()
	-- Update the token underlay to friend-or-foe status
	token.updateUnderlay();
end

function linkPCFields(src)
	local src = link.getTargetDatabaseNode();
	if src then
		name.setLink(NodeManager.createSafeChild(src, "name", "string"), true);

		hp.setLink(NodeManager.createSafeChild(src, "vida.total", "number"));
		hptemp.setLink(NodeManager.createSafeChild(src, "vida.temp", "number"));
		wounds.setLink(NodeManager.createSafeChild(src, "mana.total", "number"));
		healsurgeremaining.setLink(NodeManager.createSafeChild(src, "mana.temp", "number"));
		initresult.setLink(NodeManager.createSafeChild(src, "atributo.agilidad.mod", "number"));

		healsurgesused.setLink(NodeManager.createSafeChild(src, "hp.surgesused", "number"));
		healsurgesmax.setLink(NodeManager.createSafeChild(src, "hp.surgesmax", "number"));

		ac.setLink(NodeManager.createSafeChild(src, "defenses.ac.total", "number"), true);
		fortitude.setLink(NodeManager.createSafeChild(src, "defenses.fortitude.total", "number"), true);
		reflex.setLink(NodeManager.createSafeChild(src, "defenses.reflex.total", "number"), true);
		will.setLink(NodeManager.createSafeChild(src, "defenses.will.total", "number"), true);
		save.setLink(NodeManager.createSafeChild(src, "defenses.save.total", "number"), true);
		specialdef.setLink(NodeManager.createSafeChild(src, "defenses.special", "string"), true);

		speed.setLink(NodeManager.createSafeChild(src, "basico.mov", "number"), true);
		reach.setLink(NodeManager.createSafeChild(src, "basico.mov", "number"), true);
		init.setLink(NodeManager.createSafeChild(src, "initiative.total", "number"), true);

		actionpoints.setLink(NodeManager.createSafeChild(src, "actionpoints", "number"));
	end
end

-- Section visibility handling

function setSpacerState()
	if spacingon or defensiveon or activeon or effectson then
		spacer.setVisible(true);
	else
		spacer.setVisible(false);
	end
end

function setSpacingVisible(v)
	if activatespacing.getValue() then
		v = true;
	end

	spacingon = v;
	spacingicon.setVisible(v);
	spacingframe.setVisible(v);
	
	speed.setVisible(v);
	speedlabel.setVisible(v);
	space.setVisible(v);
	spacelabel.setVisible(v);
	reach.setVisible(v);
	reachlabel.setVisible(v);
	
	setSpacerState();
end

function setDefensiveVisible(v)
	if activatedefensive.getValue() then
		v = true;
	end
	if not targeting.isEmpty() then
		v = true;
	end
	
	defensiveon = v;
	defensiveicon.setVisible(v);

	ac.setVisible(v);
	aclabel.setVisible(v);
	fortitude.setVisible(v);
	fortitudelabel.setVisible(v);
	reflex.setVisible(v);
	reflexlabel.setVisible(v);
	will.setVisible(v);
	willlabel.setVisible(v);
	save.setVisible(v);
	savelabel.setVisible(v);
	specialdef.setVisible(v);
	specialdeflabel.setVisible(v);

	targeting.setVisible(v);
	
	setSpacerState();
end
	
function setActiveVisible(v)
	if activateactive.getValue() then
		v = true;
	end
	if active.getState() then
		v = true;
	end
	
	activeon = v;
	activeicon.setVisible(v);

	init.setVisible(v);
	initlabel.setVisible(v);
	actionpoints.setVisible(v);
	aplabel.setVisible(v);
	atk.setVisible(v);
	atklabel.setVisible(v);
	
	setSpacerState();
end

function setEffectsVisible(v)
	if activateeffects.getValue() then
		v = true;
	end
	
	effectson = v;
	effecticon.setVisible(v);
	
	effects.setVisible(v);
	if v then
		effects.checkForEmpty();
	end
	
	setSpacerState();
end

-- Activity state

function isActive()
	return active.getState();
end

function setActive(state)
	active.setState(state);
	
	if state then
		-- Turn notification
		local msg = {font = "narratorfont", icon = "indicator_flag"};
		msg.text = "[TURN] " .. name.getValue();

		local affectedby = effects.getEffectListString();
		if (affectedby ~= "") then
			msg.text = msg.text .. " - Effects: " .. affectedby;
		end 

		if type.getValue() == "pc" then
			-- Player Turn notification
			ChatManager.deliverMessage(msg);
			
			-- Ring bell also, if option enabled
			if OptionsManager.isOption("RING", "on") then
				local usernode = link.getTargetDatabaseNode();
				if usernode then
					local ownerid = User.getIdentityOwner(usernode.getName());
					if ownerid then
						User.ringBell(ownerid);
					end
				end
			end
		else
			-- DM Turn notification
			if show_npc.getState() then
				ChatManager.deliverMessage(msg);
			else
				msg.font = "systemfont";
				msg.text = "[GM] " .. msg.text;
				ChatManager.addMessage(msg);
			end
		end
	end
end
