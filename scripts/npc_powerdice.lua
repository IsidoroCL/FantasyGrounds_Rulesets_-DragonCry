-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local source = nil;
local readonly = false;

function onInit()
	if window.getDatabaseNode().isStatic() then
		readonly = true;
	end
	
	if not readonly then
		registerMenuItem("Delete dice", "delete", 4);
	end
					
	source = window.getDatabaseNode().getChild("dice");
	if source then
		enable(true);
	end
end

function setSourceValue(value)
	if readonly then
		return;
	end
	
	enable(true);

	local dietypetable = source.getValue();
	if not dietypetable then
		dietypetable = {};
	end

	--[[ Allow both dragdata style and database style die lists ]]
	for k,v in ipairs(value) do
		if type(v) == "table" then
			table.insert(dietypetable, v.type);
		else
			table.insert(dietypetable, v);
		end
	end

	if source then
		source.setValue(dietypetable);
	end
end

function enable(state)
	if state then
		source = window.getDatabaseNode().getChild("dice");
		if not readonly and not source then
			source = NodeManager.createSafeChild(window.getDatabaseNode(), "dice", "dice");
		end
		if source then
			source.onUpdate = onUpdate;
			onUpdate();
		end
	elseif source then
		setDice({});
		if not readonly then
			source.delete();
		end
		source = nil;
	end

	setVisible(state);
end

function onUpdate()
	if source then
		setDice(source.getValue());
	end
end
			
-- NOTE: Never called, since default diecontrol menu overrides ours.
-- NOTE: So, there is no mechanism to hide the diecontrol field once
-- NOTE: it becomes visible other than to delete the whole power entry.
function onMenuSelection(selection)
	if selection == 4 then
		enable(false);
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("dice") then
		setSourceValue(draginfo.getDieList());
		return true;
	end
end

function onDrag(button, x, y, draginfo)
	if source then
		draginfo.setType("dice");
		draginfo.setDieList(getDice());
		return true;
	end
end

function onDoubleClick(x,y)
	if source then
		ChatManager.DoubleClickDieControl("dice", 0, "", nil, getDice());
		return true;
	end
end			
