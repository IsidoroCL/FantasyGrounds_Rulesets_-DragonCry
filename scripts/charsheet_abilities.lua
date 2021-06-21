-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onSortCompare(w1, w2)
	if w1.value.getValue() == "" then
		return true;
	elseif w2.value.getValue() == "" then
		return false;
	end
				
	return w1.value.getValue() > w2.value.getValue();
end
					
function onClickDown(button, x, y)
	return true;
end
					
function onClickRelease(button, x, y)
	if not getNextWindow(nil) then
		local wnd = NodeManager.createSafeWindow(self);
		if wnd then
			wnd.value.setFocus();
		end
	end
	return true;
end
					
function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local class, sourcenodename = draginfo.getShortcutData();
		local source = draginfo.getDatabaseNode();

		if source then
			if class == "powerdesc" then
				local name = NodeManager.getSafeChildValue(source, "name", "");

				if name ~= "" then
					local wnd = NodeManager.createSafeWindow(self);
					if wnd then
						wnd.value.setValue(name);
						wnd.shortcut.setValue(draginfo.getShortcutData())
					end

					-- New style linked powers (v1.5+)
					if source.getChild("linkedpowers") then
						for k,v in pairs(source.getChild("linkedpowers").getChildren()) do
							local powerclass, powernodename = v.getChild("link").getValue();
							if powerclass == "powerdesc" then
								CharSheetCommon.addPowerDB(window.getDatabaseNode(), DB.findNode(powernodename));
							end
						end

					-- Old style linked powers (v1.0 - v1.4)
					elseif source.getChild("link") then
						local powerclass, powernodename = source.getChild("link").getValue();
						if powerclass == "powerdesc" then
							CharSheetCommon.addPowerDB(window.getDatabaseNode(), DB.findNode(powernodename));
						end
					end
				end
			elseif class == "reference_ritual" then
				local name = NodeManager.getSafeChildValue(source, "name", "");

				if name ~= "" then
					local wnd = NodeManager.createSafeWindow(self);
					if wnd then
						wnd.value.setValue("Ritual - " .. name);
						wnd.shortcut.setValue(draginfo.getShortcutData());
					end
				end
			end
		end

		return true;
	end
end
