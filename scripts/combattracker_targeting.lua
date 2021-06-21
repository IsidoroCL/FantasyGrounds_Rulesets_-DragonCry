-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

widgets = {};
empty = true;

function isEmpty()
	return empty;
end

function update(token)
	for k, v in ipairs(widgets) do
		v.destroy();
	end
	empty = true;
	
	local ids = token.getTargetingIdentities();
	
	local w, h = getSize();
	local spacing = w / #ids;
	if spacing > tonumber(iconspacing[1]) then
		spacing = iconspacing[1];
	end

	for i = #ids, 1, -1 do
		widgets[i] = addBitmapWidget("portrait_" .. ids[i] .. "_miniportrait");
		widgets[i].setPosition("right", -(iconspacing[1]/2 + (i-1)*spacing), 0);
		empty = false;
	end
	
	window.setDefensiveVisible(not isEmpty());
end
