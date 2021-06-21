-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Interface.onWindowOpened = onWindowOpened;
	Interface.onWindowClosed = onWindowClosed;
end

function onWindowOpened(window)
	if CampaignRegistry then
		local sourcename = "";
		if window.getDatabaseNode() then
			sourcename = window.getDatabaseNode().getNodeName();
		end

		if CampaignRegistry.windowpositions then
			if CampaignRegistry.windowpositions[window.getClass()] then
				if CampaignRegistry.windowpositions[window.getClass()][sourcename] then
					local pos = CampaignRegistry.windowpositions[window.getClass()][sourcename];

					window.setPosition(pos.x, pos.y);
					window.setSize(pos.w, pos.h);
				end
			end
		end
	end
end

function onWindowClosed(window)
	if CampaignRegistry then
		if not CampaignRegistry.windowpositions then
			CampaignRegistry.windowpositions = {};
		end

		if not CampaignRegistry.windowpositions[window.getClass()] then
			CampaignRegistry.windowpositions[window.getClass()] = {};
		end

		-- Get window data source node name
		local sourcename = "";
		if window.getDatabaseNode() then
			sourcename = window.getDatabaseNode().getNodeName();
		end

		-- Get window positioning data
		local x, y = window.getPosition();
		local w, h = window.getSize();

		-- Store positioning data
		local pos = {};
		pos.x = x;
		pos.y = y;
		pos.w = w;
		pos.h = h;

		CampaignRegistry.windowpositions[window.getClass()][sourcename] = pos;
	end
end
