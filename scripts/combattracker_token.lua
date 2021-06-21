-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local ref = nil;
local scale = 0;

function refDeleted(deleted)
	-- Clear the callbacks
	--ref.onTargetUpdate = nil;
	--ref.onDrop = nil;
	--ref.onDelete = nil;

	-- Clear the reference variable
	ref = nil;
end

function refTargeted(targeted)
	-- Update the targeting list
	window.targeting.update(ref);
end

function refDrop(droppedon, draginfo)
	CombatCommon.onDrop("ct", window.getDatabaseNode().getNodeName(), draginfo);
end

function setActive(status)
	if User.isHost() then
		if ref then
			ref.setActive(status);
		end
	end
end

function setName(name)
	if User.isHost() then
		if ref then
			ref.setName(name);
		end
	end
end

function updateUnderlay()
	if User.isHost() then
		if ref then
			ref.removeAllUnderlays();

			local space = math.ceil(window.space.getValue()) / 2;
			local reach = math.ceil(window.reach.getValue()) + space;

			local percent_wounded = 0;
			if window.hp.getValue() > 0 then
				percent_wounded = window.wounds.getValue() / window.hp.getValue();
			end

			if window.type.getValue() == "pc" then
				ref.addUnderlay(reach, "4f000000", "hover");
			else
				ref.addUnderlay(reach, "4f000000", "hover,gmonly");
			end

			local friendfoe = window.friendfoe.getSourceValue();
			if friendfoe == "friend" then
				if percent_wounded >= 1 then
					ref.addUnderlay(space, "4f002200");
				elseif percent_wounded >= .5 and percent_wounded < 1 then
					ref.addUnderlay(space, "4f006600");
				else
					ref.addUnderlay(space, "2f00ff00");
				end
			elseif friendfoe == "foe" then
				if percent_wounded >= 1 then
					ref.addUnderlay(space, "4f220000");
				elseif percent_wounded >= .5 and percent_wounded < 1 then
					ref.addUnderlay(space, "4f660000");
				else
					ref.addUnderlay(space, "2fff0000");
				end
			elseif friendfoe == "neutral" then
				if percent_wounded >= 1 then
					ref.addUnderlay(space, "4f222200");
				elseif percent_wounded >= .5 and percent_wounded < 1 then
					ref.addUnderlay(space, "4f666600");
				else
					ref.addUnderlay(space, "2fffff00");
				end
			end
		end
	end
end

function acquireReference(dropref)
	-- Validate parameters
	if not dropref then
		return;
	end
	
	-- Update the tokeninstance ref variable
	if ref and ref ~= dropref then
		ref.delete();
	end
	ref = dropref;

	-- Add callback handlers to clear the variable and to handle drops
	ref.onDelete = refDeleted;
	ref.onDrop = refDrop;

	-- If host, then we have more work to do
	if User.isHost() then
		ref.onTargetUpdate = refTargeted;

		ref.setTargetable(true);
		ref.setActivable(true);
		if window.type.getValue() == "pc" then
			ref.setVisible(true);
		else
			ref.setModifiable(false);
		end

		window.tokenrefid.setValue(ref.getId());
		window.tokenrefnode.setValue(ref.getContainerNode().getNodeName());

		ref.setActive(window.active.getState());
		ref.setName(window.name.getValue());

		updateUnderlay();

		scale = ref.getScale();

		return true;
	end
end

function deleteReference()
	if ref then
		ref.delete();
		ref = nil;
	end
end

function onDrop(x, y, draginfo)
	if User.isHost() then
		if draginfo.isType("token") then
			local prototype, dropref = draginfo.getTokenData();
			setPrototype(prototype);
			return acquireReference(dropref);
		end
		if draginfo.isType("number") then
			return window.wounds.onDrop(x, y, draginfo);
		end
	end
end

function onDrag(button, x, y, draginfo)
	if not User.isHost() then
		return false;
	end
end

function onDragEnd(draginfo)
	if User.isHost() then
		local prototype, dropref = draginfo.getTokenData();
		return acquireReference(dropref);
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if User.isHost() then
		if ref then
			if button == 1 then
				if ref.isActive() then
					ref.setActive(false);
				else
					ref.setActive(true);
				end
			else
				ref.setScale(1.0)
				scale = 0;
				if scaleWidget then
					scaleWidget.setVisible(false);
				end
			end
		end

		return true;
	end
end

function onWheel(notches)
	if User.isHost() then
		if ref then
			if not scaleWidget then		
				scaleWidget = addTextWidget("sheetlabelsmall", "0");
				scaleWidget.setFrame("tempmodmini", 4, 1, 6, 3);
				scaleWidget.setPosition("topright", -2, 2);
			end

			if Input.isControlPressed() then
				scale = math.floor(scale + notches);
				if scale < 1 then
					scale = 1;
				end
			else
				scale = scale + notches*0.1;

				if scale < 0.1 then
					scale = 0.1;
				end
			end

			if scale == 1 then
				ref.setScale(1.0);
				scaleWidget.setVisible(false);
			else
				ref.setScale(scale);
				scaleWidget.setVisible(true);
				scaleWidget.setText(scale);
			end
		end

		return true;
	end
end
