-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function getCreatureType()
	return "pc";
end
function getCreatureClass()
	return "charsheet";
end
function getCreatureNode()
	return window.getDatabaseNode().getParent().getParent().getParent().getParent();
end

function getAbilityCheck(stat)
	local mod = NodeManager.getSafeChildValue(window.getDatabaseNode(), ".....abilities." .. stat .. ".check", 0);
	return mod;
end

function getWeaponAttackBonus()
	local mod = 0;

	local tool_order = NodeManager.getSafeChildValue(window.getDatabaseNode(), ".....powerfocus.weapon.order", 0);
	if tool_order > 0 then
		local weapons_node = window.getDatabaseNode().getChild(".....weaponlist");
		if weapons_node then
			for k, v in pairs(weapons_node.getChildren()) do
				local order_val = NodeManager.getSafeChildValue(v, "order", 0);
				if order_val == tool_order then
					mod = NodeManager.getSafeChildValue(v, "bonus", 0);
				end
			end
		end
	end

	return mod;
end

function getImplementAttackBonus()
	local mod = 0;

	local tool_order = NodeManager.getSafeChildValue(window.getDatabaseNode(), ".....powerfocus.implement.order", 0);
	if tool_order > 0 then
		local weapons_node = window.getDatabaseNode().getChild(".....weaponlist");
		if weapons_node then
			for k, v in pairs(weapons_node.getChildren()) do
				local order_val = NodeManager.getSafeChildValue(v, "order", 0);
				if order_val == tool_order then
					mod = NodeManager.getSafeChildValue(v, "bonus", 0);
				end
			end
		end
	end

	return mod;
end

function getWeaponDice()
	local dice = {};

	local tool_order = NodeManager.getSafeChildValue(window.getDatabaseNode(), ".....powerfocus.weapon.order", 0);
	if tool_order > 0 then
		local weapons_node = window.getDatabaseNode().getChild(".....weaponlist");
		if weapons_node then
			for k, v in pairs(weapons_node.getChildren()) do
				local order_val = NodeManager.getSafeChildValue(v, "order", 0);
				if order_val == tool_order then
					dice = NodeManager.getSafeChildValue(v, "damagedice", {});
					if not dice then
						dice = {};
					end
				end
			end
		end
	end

	return dice;
end

function getAbilityBonus(stat)
	local mod = NodeManager.getSafeChildValue(window.getDatabaseNode(), ".....abilities." .. stat .. ".bonus", 0);
	return mod;
end

function getWeaponDamageBonus()
	local mod = 0;

	local tool_order = NodeManager.getSafeChildValue(window.getDatabaseNode(), ".....powerfocus.weapon.order", 0);
	if tool_order > 0 then
		local weapons_node = window.getDatabaseNode().getChild(".....weaponlist");
		if weapons_node then
			for k, v in pairs(weapons_node.getChildren()) do
				local order_val = NodeManager.getSafeChildValue(v, "order", 0);
				if order_val == tool_order then
					mod = NodeManager.getSafeChildValue(v, "damagebonus", 0);
				end
			end
		end
	end

	return mod;
end

function getImplementDamageBonus()
	local mod = 0;

	local tool_order = NodeManager.getSafeChildValue(window.getDatabaseNode(), ".....powerfocus.implement.order", 0);
	if tool_order > 0 then
		local weapons_node = window.getDatabaseNode().getChild(".....weaponlist");
		if weapons_node then
			for k, v in pairs(weapons_node.getChildren()) do
				local order_val = NodeManager.getSafeChildValue(v, "order", 0);
				if order_val == tool_order then
					mod = NodeManager.getSafeChildValue(v, "damagebonus", 0);
				end
			end
		end
	end

	return mod;
end
