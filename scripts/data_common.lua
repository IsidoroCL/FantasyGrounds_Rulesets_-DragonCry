-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function contains(set, item)
	for i = 1, #set do
		if set[i] == item then
			return true;
		end
	end
	return false;
end

-- Conditions supported in power descriptions
-- NOTE: Skipped concealment and cover since there are too many false positives in power descriptions
conditions = {
	"blinded", 
	"dazed", 
	"deafened", 
	"dominated", 
	"grabbed", 
	"immobilized", 
	"insubstantial", 
	"invisible", 
	"marked", 
	"petrified", 
	"prone", 
	"restrained", 
	"slowed", 
	"stunned", 
	"swallowed", 
	"unconscious", 
	"weakened"
};

-- Damage types supported in power descriptions
dmgtypes = {
	"acid",
	"cold",
	"fire",
	"force",
	"lightning",
	"necrotic",
	"poison",
	"psychic",
	"radiant",
	"thunder"
};

-- Skill properties
skilldata = {
	["Acrobatics"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Arcana"] = {
			stat = "intelligence"
		},
	["Athletics"] = {
			stat = "strength",
			armorcheckmultiplier = 1
		},
	["Bluff"] = {
			stat = "charisma"
		},
	["Diplomacy"] = {
			stat = "charisma"
		},
	["Dungeoneering"] = {
			stat = "wisdom"
		},
	["Endurance"] = {
			stat = "constitution",
			armorcheckmultiplier = 1
		},
	["Heal"] = {
			stat = "wisdom"
		},
	["History"] = {
			stat = "intelligence"
		},
	["Insight"] = {
			stat = "wisdom"
		},
	["Intimidate"] = {
			stat = "charisma"
		},
	["Nature"] = {
			stat = "wisdom"
		},
	["Perception"] = {
			stat = "wisdom"
		},
	["Religion"] = {
			stat = "intelligence"
		},
	["Stealth"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Streetwise"] = {
			stat = "charisma"
		},
	["Thievery"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		}
}
