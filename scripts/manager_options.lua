-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function isMouseWheelEditEnabled()
	return isOption("MWHL", "on") or Input.isControlPressed();
end

-- isOption: If option is equal to target_val, then return true; otherwise false.
function isOption(opt_name, target_value)
	local opt_value = getOption(opt_name);
	return (opt_value == target_value);
end

-- getOption: Return the value of the option
function getOption(opt_name)
	-- Check to see if it's a client or host option
	if opt_name == "DCLK" or opt_name == "DRGR" or opt_name == "MWHL" or opt_name == "SWPN" then
		return getClientOption(opt_name);
	else
		return getHostOption(opt_name);
	end
end

-- setOption: Sets the value of the given option
function setOption(opt_name, opt_value)
	-- Check to see if it's a client or host option
	if opt_name == "DCLK" or opt_name == "DRGR" or opt_name == "MWHL" or opt_name == "SWPN" then
		setClientOption(opt_name, opt_value);
	else
		setHostOption(opt_name, opt_value);
	end
end

-- getClientOption: Return the value of the given option
function getClientOption(opt_name)
	local opt = "off";
	
	if opt_name == "DCLK" then
		opt = "on";
		if CampaignRegistry.OptDCLK then
			opt = CampaignRegistry.OptDCLK;
		end
	elseif opt_name == "DRGR" then
		opt = "on";
		if CampaignRegistry.OptDRGR then
			opt = CampaignRegistry.OptDRGR;
		end
	elseif opt_name == "MWHL" then
		opt = "ctrl";
		if CampaignRegistry.OptMWHL then
			opt = CampaignRegistry.OptMWHL;
		end
	elseif opt_name == "SWPN" then
		opt = "off";
		if CampaignRegistry.OptSWPN then
			opt = CampaignRegistry.OptSWPN;
		end
	end
	
	return opt;
end

-- setClientOption: Sets the value of the given option
function setClientOption(opt_name, opt_value)
	if opt_name == "DCLK" then
		CampaignRegistry.OptDCLK = opt_value;
	elseif opt_name == "DRGR" then
		CampaignRegistry.OptDRGR = opt_value;
	elseif opt_name == "MWHL" then
		CampaignRegistry.OptMWHL = opt_value;
	elseif opt_name == "SWPN" then
		CampaignRegistry.OptSWPN = opt_value;
	end
end

-- getHostOption: Return the value of the given host-only option
function getHostOption(opt_name)
	local val = "off";

	local optnode = DB.findNode("options");
	if optnode then
		local opt_child_node = optnode.getChild(opt_name);
		if opt_child_node then
			val = opt_child_node.getValue();
			if val == "" then
				val = "off";
			end
		end
	end

	return val;
end

-- setHostOption: Sets the value of the given host-only option
function setHostOption(opt_name, opt_value)
	if not User.isHost() then
		return;
	end
	
	local optnode = DB.createNode("options");
	if optnode then
		local opt_child_node = NodeManager.createSafeChild(optnode, opt_name, "string");
		if opt_child_node then
			opt_child_node.setValue(opt_value);
		end
	end
end
