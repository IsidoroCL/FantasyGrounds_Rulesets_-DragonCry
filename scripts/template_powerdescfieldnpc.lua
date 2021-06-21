-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function getCreatureType()
	return "npc";
end
function getCreatureClass()
	return "npc";
end
function getCreatureNode()
	return window.getDatabaseNode().getParent().getParent();
end

function getAbilityCheck(stat)
	local levelbonus = 0;
	local levelrole = NodeManager.getSafeChildValue(window.getDatabaseNode(), "...levelrole", "");
	local level = string.match(levelrole, "Level (%d*)");
	if level then
		levelbonus = math.floor(level / 2);
	end

	local statval = NodeManager.getSafeChildValue(window.getDatabaseNode(), "..." .. stat, 0);
	local statbonus = math.floor((statval - 10) / 2);

	return levelbonus + statbonus;
end
function getWeaponAttackBonus()
	return 0;
end
function getImplementAttackBonus()
	return 0;
end

function getWeaponDice()
	local dice = window.dice.getDice();
	if not dice then
		dice = {};
	end
	return dice;
end
function getAbilityBonus(stat)
	local statval = NodeManager.getSafeChildValue(window.getDatabaseNode(), "..." .. stat, 0);
	local statbonus = math.floor((statval - 10) / 2);
	return statbonus;
end
function getWeaponDamageBonus()
	return 0;
end
function getImplementDamageBonus()
	return 0;
end
