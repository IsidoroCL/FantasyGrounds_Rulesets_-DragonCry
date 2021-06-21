-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

-- Parse the power description for attack, damage and effect clauses
function parsePowerDescription(s)
  	-- Parse the words
  	local str;
  	local words = {};
  	local index = 1;
  	local delimiter = "[^%w%+%-]+";
  	local delim_start, delim_end = string.find(s, delimiter, index);
  	while delim_start do
  		str = string.lower(string.sub(s, index, delim_start - 1));
  		table.insert(words, {val = str, starts = index, ends = delim_start});

  		index = delim_end + 1;
  		delim_start, delim_end = string.find(s, delimiter, index);
  	end
	str = string.lower(string.sub(s, index));
  	table.insert(words, {val = str, starts = index, ends = #s + 1});

	-- Get the various components
	local attacks = parseAttacks(words);
	local damages = parseDamages(words);
	local effects = parseEffects(words);
	
	-- Return what we found
	return attacks, damages, effects;
end

function getAbility(s)
	local stat = "";
	if s == "str" or s == "strength" then
		stat = "strength";
	elseif s == "con" or s == "constitution" then
		stat = "constitution";
	elseif s == "dex" or s == "dexterity" then
		stat = "dexterity";
	elseif s == "int" or s == "intelligence" then
		stat = "intelligence";
	elseif s == "wis" or s == "wisdom" then
		stat = "wisdom";
	elseif s == "cha" or s == "charisma" then
		stat = "charisma";
	end
	return stat;
end

function getDefense(s)
	local defense = "";
	local short = string.sub(string.lower(s), 1, 3);
	if short == "ac" then
		defense = "ac";
	elseif short == "for" then
		defense = "fortitude";
	elseif short == "ref" then
		defense = "reflex";
	elseif short == "wil" then
		defense = "will";
	end
	return defense;
end

-- Form [PHB]: <stat> vs. <defense>
-- Form [PHB]: <stat> + <bonus> vs. <defense>
-- Form [PHB]: <stat> - <penalty> vs. <defense>
-- Form [MM ]: +<bonus> vs. <defense>
-- Form [MM ]: -<penalty> vs. <defense>
function parseAttacks(words)
	-- Start with an empty set
	local attacks = {};

  	-- Iterate through the words looking for clauses
  	for i = 1, #words do
  		-- Our main trigger is the "vs" in the defense part of the clause
  		if words[i].val == "vs" and i > 1 then
  			-- Calculate the attack stat, bonus and defense
  			local atk_stat = "";
  			local atk_starts = i - 1;
  			local atk_bonus = tonumber(words[i-1].val);
  			if atk_bonus then
  				local temp_index = i - 2;
  				if words[temp_index] then
  					if words[temp_index].val == "+" then
  						temp_index = temp_index - 1;
  					elseif words[temp_index].val == "-" then
  						atk_bonus = 0 - atk_bonus;
  						temp_index = temp_index - 1;
  					end
  					
  					if words[temp_index] then
  						atk_stat = getAbility(words[temp_index].val);
  					end
  					if atk_stat ~= "" then
  						atk_starts = temp_index;
  					end
  				end
  			else
  				atk_stat = getAbility(words[i-1].val);
  				atk_bonus = 0;
  				atk_starts = i - 1;
  			end
  			local atk_defense = "";
  			if words[i+1] then
  				atk_defense = getDefense(words[i+1].val);
  			end

			-- If the defense checks out, then we have a viable attack clause
			if atk_defense ~= "" then
				table.insert(attacks, { startpos = words[atk_starts].starts, endpos = words[i+1].ends, atkstat = atk_stat, bonus = atk_bonus, defense = atk_defense });
			end
  		end
	end
	
	-- Return the set of clauses found in the string
	return attacks;
end

--Form [PHB]: <dice> <opt_type> damage
--Form [PHB]: <dice> + <stat> modifier <opt_type> damage
--Form [PHB]: <dice> + <stat> modifier + <stat> modifier <opt_type> damage
--Form [MM ]: <dice> <opt_type> damage
--Form [SHORT]: <dice> + <shortstat> <opt_type> damage
--Form [SHORT]: <dice> + <shortstat> + <shortstat> <opt_type> damage
--<dice> = <#d#+#> or <#d#> or <#>
--Form [PHB]: <mult>[W] <opt_type> damage
--Form [PHB]: <mult>[W] + <stat> modifier <opt_type> damage
--Form [PHB]: <mult>[W] + <stat> modifier + <stat2> modifier <opt_type> damage
--Form [SHORT]: <mult>[W] + <shortstat> <opt_type> damage
--Form [SHORT]: <mult>[W] + <shortstat> + <shortstat> <opt_type> damage
--Form [PHB2]: <mult>[W] + <dice> + <stat> modifier <opt_type> damage
--Form [SHORT]: <mult>[W] + <dice> + <shortstat> <opt_type> damage
function parseDamageClause(words, damage_index, inclusive_flag)
	-- Set up variables to capture the parts of the damage clause
	local dmg_starts = 0;
	local dmg_ends = 0;
	if inclusive_flag then
		dmg_ends = words[damage_index].ends;
	else
		dmg_ends = words[damage_index - 1].ends;
	end
	local dmg_dice = {};
	local dmg_weaponmult = 0;
	local dmg_abilities = {};
	local dmg_types = {};

	local isweapon = false;

	-- Go backwards through words to find the parts of the damage clause
	local j = damage_index - 1;
	local numberflag = false;
	while j > 0 do
		-- Skip null words
		if DataCommon.contains({"and", "modifier", "your"}, words[j].val) then
		
		-- Plus or minus sign will reset number flag
		elseif words[j].val == "+" or words[j].val == "-" then
			numberflag = false;

		-- Check for weapon damage clauses
		elseif words[j].val == "w" then
			isweapon = true;

		-- Otherwise process the damage clause
		else
			-- Run some checks on the word
			local dicestr = string.match(words[j].val, "[%+%-]?%d[d%d%+%-]*");
			local abilitystr = getAbility(words[j].val);

			-- Look for a number/dice string
			if dicestr then
				-- Not allowed to have 2 number/dice phrases in a row without a '+' or '-' in-between
				if numberflag then
					break;
				end
				numberflag = true;

				-- Catch weapon multiplier if we just found a [W]
				if isweapon then
					dmg_weaponmult = tonumber(dicestr) or 0;
				-- Otherwise, we have a dice string or numbers
				else
					-- Handle negatives
					if (j > 2) and (words[j].val == "-") then
						dicestr = "-" .. dicestr;
					end
					
					-- Add to the dice string list
					table.insert(dmg_dice, 1, dicestr);
				end
			-- Look for ability keywords
			elseif abilitystr ~= "" then
				table.insert(dmg_abilities, 1, abilitystr);
			-- As long as we haven't found an ability modifier or dice string, assume we are on damage types
			elseif DataCommon.contains(DataCommon.dmgtypes, words[j].val) then
				table.insert(dmg_types, 1, words[j].val);
			else
				break;
			end
		end
		
		j = j - 1;
	end

	-- Make sure we have a damage clause, and insert it into table
	if #dmg_dice > 0 or dmg_weaponmult ~= 0 or #dmg_abilities > 0 then
		dmg_starts = words[j+1].starts;

		local stat1 = dmg_abilities[1] or "";
		local stat2 = dmg_abilities[2] or "";
		local dmgtypestr = table.concat(dmg_types, ",");
		local dicestr = table.concat(dmg_dice, "+");
		dicestr = string.gsub(dicestr,"%+%-","-");

		return { startpos = dmg_starts, endpos = dmg_ends, damagemult = dmg_weaponmult, damage = dicestr, dmgstat = stat1, dmgstat2 = stat2, dmgtype = dmgtypestr};
	end
	
	-- Return null
	return nil;
end

function parseDamages(words)
	-- Start with an empty set
	local damages = {};

  	-- Iterate through the words looking for clauses
  	local ongoing = false;
  	local i = 1;
  	while words[i] do
		-- Main trigger for damage clauses is "damage"
		if words[i].val == "damage" then
			-- Skip this one if we're in an ongoing damage clause
			if ongoing then
				ongoing = false;
			-- Catch special damage clauses that aren't handled yet
			elseif words[i+1] and words[i+1].val == "equal" then

			-- Otherwise, try to pick out the damage clause
			else
				local dmg_result = parseDamageClause(words, i, true);
				if dmg_result then
					table.insert(damages, dmg_result);
				end
			end
		-- Alternate trigger for damage clause is "plus"
		elseif words[i].val == "plus" then
			if words[i-1].val then
				if string.match(words[i-1].val, "%d+") == words[i-1].val then
					local dmg_result = parseDamageClause(words, i);
					if dmg_result then
						table.insert(damages, dmg_result);
					end
				end
			end
		-- Alternate trigger for damage clause is "crit"
		elseif words[i].val == "crit" then
			if words[i+1] and words[i+2] and words[i+2].val == "+" and words[i+3] then
				local dmg_result = parseDamageClause(words, i + 4);
				if dmg_result then
					dmg_result.startpos = words[i].starts;
					table.insert(damages, dmg_result);
				end
				i = i + 3;
				if words[i+4] and words[i+4].val == "plus" then
					i = i + 1;
				end
			end
		-- Some words can end an ongoing clause
		elseif words[i].val == "effect" then
			ongoing = false;
		-- Skip the next damage word if we reach an ongoing keyword
		elseif words[i].val == "ongoing" then
			ongoing = true;
		end
		
		-- Increment our counter
		i = i + 1;
	end	

	-- Return the set of clauses found in the string
	return damages;
end

function determineEffectEnd(words, next_index)
	-- Make sure we have a word to look at
	if words[next_index] then
		-- Save ends
		if words[next_index].val == "save" then
			if words[next_index + 1] and words[next_index+1].val == "ends" then
				return "save";
			end
		end
	
		-- Until some trigger
		if words[next_index].val == "until" then
			local temp_index = next_index + 1;
			if words[temp_index] and words[temp_index].val == "the" then
				temp_index = temp_index + 1;
			end
			if words[temp_index] then
				if words[temp_index].val == "encounter" then
					return "encounter";
				elseif words[temp_index].val == "end" then
					temp_index = temp_index + 3;
					if words[temp_index] then
						if words[temp_index].val == "encounter" then
							return "encounter";
						else
							while words[temp_index] do
								if words[temp_index].val == "next" then
									return "endnext";
								elseif words[temp_index].val == "turn" then
									return "end";
								end
								temp_index = temp_index + 1;
							end
						end
					end
				elseif words[temp_index].val == "start" then
					return "start";
				end
			end
		end
	end
	
	return "";
end

function parseEffects(words)
	-- Start with an empty set
	local effects = {};

  	-- Variables to handle effects parsing
  	local cur_effect = nil;
  	local cur_effect_start = 0;
  	local cur_effect_end = 0;
  	local combo_effect = nil;
  	local combo_start = 0;
  	local combo_end = 0;
  	local ongoing_start = nil;
  	local exp_flag, connect_flag, cond_flag, trigger_flag;

  	-- Iterate through the words looking for effects
  	local i = 1;
  	while words[i] do
  		-- Determine what kind of word we are dealing with
  		connect_flag = DataCommon.contains({"and"}, words[i].val);
  		exp_flag = DataCommon.contains({"until", "save"}, words[i].val);
  		trigger_flag = DataCommon.contains({"miss"}, words[i].val);
  		cond_flag = DataCommon.contains(DataCommon.conditions, words[i].val);
  		
  		-- Process current effects
  		if cur_effect and (connect_flag or exp_flag or trigger_flag or cond_flag) then
			if combo_effect then
				combo_effect = combo_effect .. "; " .. cur_effect;
			else
				combo_effect = cur_effect;
				combo_start = cur_effect_start;
			end
			combo_end = cur_effect_end;
			cur_effect = nil;
  		end

  		-- Handle expiration expressions or trigger words
  		if exp_flag or trigger_flag then
			if combo_effect then
				local exp = determineEffectEnd(words, i);
				table.insert(effects, {startpos = words[combo_start].starts, endpos = words[combo_end].ends, name = combo_effect, expire = exp, savemod = 0});
				combo_effect = nil;
			end
  		
  		-- Handle conditions
  		elseif cond_flag then

  			-- Look for targeting conditions or other non-effect condition text
  			local valid_condition = true;
  			local allow_connectors = true;
  			local j = i - 1;
  			while words[j] do
  				if DataCommon.contains({"and", "or", "nor"}, words[j].val) then
  					if not allow_connectors then
  						break;
  					end
  				elseif DataCommon.contains({"you", "target", "enemy"}, words[j].val) then
  					allow_connectors = false;
  				elseif DataCommon.contains({"targets"}, words[j].val) then
  					if words[j+1] and words[j+1].val == "are" then
  						allow_connectors = false;
  					else
						valid_condition = false;
						break;
					end
  				elseif DataCommon.contains({"a", "an", "the", "each", "pushed", "knocked", "is", "are", "as"}, words[j].val) then
  				elseif DataCommon.contains(DataCommon.conditions, words[j].val) then
  				elseif DataCommon.contains({"against", "not", "neither", "while", "if", "longer", "already", "currently", "affects", "to", "has", "when", "long", "hits"}, words[j].val) then
  					valid_condition = false;
  					break;
  				else
  					break;
  				end
  				j = j - 1;
  			end
  			local j = i + 1;
  			local target_connect_flag = false;
  			while words[j] do
  				if DataCommon.contains ({"and", "or"}, words[j].val) then
  					target_connect_flag = true;
  				else
  					if DataCommon.contains ({"target"}, words[j].val) then
  					elseif DataCommon.contains(DataCommon.conditions, words[j].val) then
  					elseif DataCommon.contains({"only"}, words[j].val) then
						valid_condition = false;
						break;
  					elseif DataCommon.contains({"takes"}, words[j].val) then
						if not target_connect_flag then
							valid_condition = false;
						end
						break;
					else
						break;
					end
  					target_connect_flag = false;
				end
  				j = j + 1;
  			end
  			
			-- If we found an effect condition vs. some other condition text, then we have a valid effect
			if valid_condition then
				-- Save the current effect information
				local str = string.upper(string.sub(words[i].val, 1, 1)) .. string.sub(words[i].val, 2);
				cur_effect = str;
				cur_effect_start = i;
				cur_effect_end = i;

				-- Look for replacement conditions
				if words[i+1] and words[i+2] and 
				  ((words[i+1].val == "instead" and words[i+2].val == "of") or (words[i+1].val == "rather" and words[i+2].val == "than")) then
					j = i + 3;
					while words[j] do
						if DataCommon.contains({"and", "or"}, words[j].val) or DataCommon.contains(DataCommon.conditions, words[j].val) then
						else
							break;
						end
						j = j + 1;
					end
					current_effect_end = j - 1;
				end
			end
  		end

		-- Ongoing Damage
		if words[i].val == "ongoing" then
			ongoing_start = i;
		elseif words[i].val == "effect" then
			ongoing_start = nil;
		elseif words[i].val == "damage" then
			if ongoing_start then
				local dmg_result = parseDamageClause(words, i);
				if dmg_result then
					local dmg_amount = tonumber(dmg_result["damage"]) or 0;
					if dmg_amount > 0 then
						if string.match(dmg_result["damage"], "d") then
							-- We don't handle non-fixed ongoing damage yet
						else
							cur_effect = "DMG: " .. dmg_amount .. " " .. dmg_result["dmgtype"];
							cur_effect_start = ongoing_start;
							cur_effect_end = i;
						end
					end
				end
				ongoing_start = nil;
			end
		end
		
		-- Increment i
		i = i + 1;
  	end
  	
  	-- Handle final dangling effects, if any
  	if cur_effect then
		if combo_effect then
			combo_effect = combo_effect .. "; " .. cur_effect;
		else
			combo_effect = cur_effect;
			combo_start = cur_effect_start;
		end
		combo_end = cur_effect_end;
	end
  	if combo_effect then
		table.insert(effects, {startpos = words[combo_start].starts, endpos = words[combo_end].ends, name = combo_effect, expire = "", savemod = 0});
  	end
  	
	-- Return the set found
	return effects;
end

function parseClauses(s)
  	-- Parse the words
  	local str;
  	local words = {};
  	local index = 1;
  	local delimiter = "[^%w%+%-:]+";
  	local delim_start, delim_end = string.find(s, delimiter, index);
  	while delim_start do
  		str = string.sub(s, index, delim_start - 1);
  		table.insert(words, {val = str, starts = index, ends = delim_start});

  		index = delim_end + 1;
  		delim_start, delim_end = string.find(s, delimiter, index);
  	end
	str = string.sub(s, index);
  	table.insert(words, {val = str, starts = index, ends = #s + 1});
  	
  	-- Build the clauses
  	local clauses = {};
  	
  	-- Iterate through the words to build the clauses
  	local clause_start = 1;
  	local clause_label = "";
  	for i = 1, #words do
  		-- Handle any labels we come across
  		local temp_label = nil;
  		local temp_index = i;
  		if DataCommon.contains({"Prerequisite:", "Requirement:", "Special:", "Effect:", "Hit:", "Miss:", "Weapon:"}, words[i].val) then
  			temp_label = words[i].val;
  		elseif DataCommon.contains({"Target:", "Targets:", "Attack:"}, words[i].val) then
  			temp_label = words[i].val;
  			if words[i-1] and words[i-1].val == "Secondary" then
  				temp_label = "Secondary " .. temp_label;
  			elseif words[i-1] and words[i-1].val == "Tertiary" then
  				temp_label = "Tertiary " .. temp_label;
  				temp_index = i - 1;
  			end
  		elseif DataCommon.contains({"Minor:", "Move:", "Standard:"}, words[i].val) then
  			if words[i-1] and words[i-1].val == "Sustain" then
  				temp_label = "Sustain " .. words[i].val;
  				temp_index = i - 1;
  			end
  		end
  		
  		-- If we have a label, then end the last clause and start a new one
  		if temp_label then
 			if clause_start ~= words[temp_index].starts then
 				local clause_value = string.sub(s, clause_start, words[temp_index].starts - 1);
 				clause_value = string.gsub(clause_value, "(.-);?%s*$", "%1");
  				table.insert(clauses, { startpos = clause_start, endpos = words[temp_index].starts - 1, label = clause_label, value = clause_value});
  			end
  			
  			clause_label = string.match(temp_label, "[^:]*");
  			if words[i+1] then
  				clause_start = words[i + 1].starts;
  			else
  				clause_start = #s + 1;
  			end
  		end
  	end
  
	-- Catch dangling clauses
	local clause_value = string.sub(s, clause_start, #s + 1);
	if clause_label ~= "" or clause_value ~= "" then
		table.insert(clauses, { startpos = clause_start, endpos = #s + 1, label = clause_label, value = clause_value});
	end
	
	-- Return the set of clauses found in the string
	return clauses;
end
