-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

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
		end
	end

	-- Set properties and create missing entries for all known skills
	for k, t in pairs(DataCommon.skilldata) do
		local matches = entrymap[k];
		
		if not matches then
			local wnd = NodeManager.createSafeWindow(self);
			if wnd then
				wnd.label.setValue(k);
				matches = { wnd };
			end
		end
		
		-- Update properties
		for matchindex, match in pairs(matches) do
			if t.stat then
				match.statlabel.setSourceValue(t.stat);
			else
				match.statlabel.setSourceValue("");
				match.stat.setVisible(false);
				match.misc.setVisible(false);
				match.total.setVisible(false);
			end
			
			if t.armorcheckmultiplier then
				local acmultnode = NodeManager.createSafeChild(match.getDatabaseNode(), "armorcheckmultiplier", "number");
				if acmultnode then
					acmultnode.setValue(t.armorcheckmultiplier);
				end
			end
			
			match.setCustom(false);
		end
	end
end
