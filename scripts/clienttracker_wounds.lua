-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20
--
-- For information on the Fantasy Grounds d20 Ruleset licensing and
-- the OGL license text, see the d20 ruleset license in the program
-- options.
--
-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above licenses, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.
--
-- Copyright 2007 SmiteWorks Ltd.

function onInit()
	onValueChanged();
end

function onValueChanged()
	local percent_wounded = 0;
	local remaining_hp = window.hp.getValue() - window.wounds.getValue();
	if window.hp.getValue() > 0 then
		percent_wounded = window.wounds.getValue() / window.hp.getValue();
	end
	if percent_wounded <= 0 then
		window.wounds.setFont("ct_healthy_font");
	elseif percent_wounded < .5 then
		window.wounds.setFont("ct_ltwound_font");
	elseif percent_wounded < 1 then
		window.wounds.setFont("ct_bloodied_font");
	else
		window.wounds.setFont("ct_dead_font");
	end
end
