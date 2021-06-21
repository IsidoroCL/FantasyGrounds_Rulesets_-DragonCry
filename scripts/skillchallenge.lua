-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function addSkillResult(text, result)
	-- First, clean up the skill name and make sure this is a skill roll
	local starts, ends, skill_name = string.find(text, "Skill %[([^%]]+)%]");
	if not skill_name then
		return;
	end
	
	-- If it's only an assist, then don't add the result
	if string.match(text, "%[ASSIST%]") then
		return;
	end
	
	-- If there is a name associated with the roll, then use it to label the result
	local roller_name = string.match(text, "(.+) %-> Skill");
	if roller_name then
		local boxindex = string.find(text, "%[BOX%] ");
		if boxindex then
			roller_name = string.sub(roller_name, boxindex + 6); 
		end
	else
		roller_name = "";
	end
	
	-- Iterate through tracker skill list
	for x, w1 in pairs(getWindows()) do
		-- Make sure the name matches
		if w1.label.getValue() == skill_name then
			
			-- If DC = 0, then assume we don't want to track this one
			if w1.DC.getValue() > 0 then
				local wnd = NodeManager.createSafeWindow(w1.results);
				if wnd then
					wnd.actor.setValue(roller_name);
					wnd.roll.setValue(result);
					if result >= w1.DC.getValue() then				
						wnd.success.setState(true);
						wnd.failure.setState(false);
					else
						wnd.success.setState(false);
						wnd.failure.setState(true);
					end
				end
			end
			
			-- If the name matched, then we're done
			break;
		end
	end
	
	-- Update the totals
	calcTotals();
end

function calcTotals()
	local isuccess = 0;
	local ifailure = 0;
	local itotalsuccess = 0;
	local itotalfailure = 0;

	-- Iterate through tracker skill list
	for k1, w1 in pairs(getWindows()) do
		-- Calculate the per-skill successes/failures
		isuccess = 0;
		ifailure = 0;
		for k2, w2 in pairs(w1.results.getWindows()) do
			if w2.success.getState() then
				isuccess = isuccess + 1;
			else
				ifailure = ifailure + 1;
			end
		end
		w1.success.setValue(isuccess);
		w1.failure.setValue(ifailure);

		-- Add to total successes and failures
		itotalsuccess = itotalsuccess + isuccess;
		itotalfailure = itotalfailure + ifailure;
	end
	
	-- Set the total values
	window.totalsuccess.setValue(itotalsuccess);
	window.totalfailure.setValue(itotalfailure);
end

function onDrop(x, y, draginfo)
	if draginfo.getType("number") then
		addSkillResult(draginfo.getDescription(), draginfo.getNumberData());
	end

	return true;
end

function onSortCompare(w1, w2)
	if w1.label.getValue() == "" then
		return true;
	elseif w2.label.getValue() == "" then
		return false;
	end

	return w1.label.getValue() > w2.label.getValue();
end

function onInit()
	-- Construct default skills
	constructDefaultSkills();
end

-- Create default skill selection
function constructDefaultSkills()
	-- Collect existing entries
	local entrymap = {};
	for k, w in pairs(getWindows()) do
		local label = w.label.getValue(); 
	
		if DataCommon.skilldata[label] then
			if not entrymap[label] then
				entrymap[label] = { w };
			else
				table.insert(entrymap[label], w);
			end
			
			w.setCustom(false);
		end
	end

	-- Set properties and create missing entries for all known skills
	for k, t in pairs(DataCommon.skilldata) do
		local matches = entrymap[k];
		
		if not matches then
			local wnd = NodeManager.createSafeWindow(self);
			if wnd then
				wnd.label.setValue(k);
				wnd.setCustom(false);
				matches = { wnd };
			end
		end
	end
end
