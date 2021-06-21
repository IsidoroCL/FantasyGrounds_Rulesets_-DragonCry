-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function getCompletion(str)
	-- Find a matching completion for the given string
	for i = 1, #autofill do
		if string.lower(str) == string.lower(string.sub(autofill[i], 1, #str)) then
			return string.sub(autofill[i], #str + 1);
		end
	end
	
	return "";
end

function onChar()
	if getCursorPosition() == #getValue()+1 then
		completion = getCompletion(getValue());

		if completion ~= "" then
			value = getValue();
			newvalue = value .. completion;

			setValue(newvalue);
			setSelectionPosition(getCursorPosition() + #completion);
		end

		return;
	end
end

function onGainFocus()
	autofill = {};
	
	for k, v in ipairs(window.windowlist.getWindows()) do
		local s = v.name.getValue();
		if s ~= "" then
			table.insert(autofill, s);
		end
	end
	
	super.onGainFocus();
end

function onLoseFocus()
	super.onLoseFocus();
	window.windowlist.applySort();
end
