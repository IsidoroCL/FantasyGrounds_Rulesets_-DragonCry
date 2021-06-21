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

function addMIWeapon(source)

	-- drop the data onto the magic item
	-- Static nodes
	local statwindow = window.getDatabaseNode()
	statwindow.createChild("damage","string").setValue(source.createChild("damage","string").getValue() .. " damage");
	statwindow.createChild("profbonus","number").setValue(source.createChild("profbonus","number").getValue());
	statwindow.createChild("weight","number").setValue(source.createChild("weight","number").getValue());
	statwindow.createChild("range","number").setValue(source.createChild("range","number").getValue());
	statwindow.createChild("group","string").setValue(source.createChild("group","string").getValue());
	statwindow.createChild("properties","string").setValue(source.createChild("properties","string").getValue());
	statwindow.createChild("type","string").setValue(source.createChild("type","string").getValue());
 	
	return newentry;
end


function addMIArmor(source)
	-- drop the data onto the magic item
	-- Static nodes
	local statwindow = window.getDatabaseNode()
	statwindow.createChild("ac","number").setValue(source.createChild("ac","number").getValue());
	statwindow.createChild("min_enhance","number").setValue(source.createChild("min_enhance","number").getValue());
	statwindow.createChild("weight","number").setValue(source.createChild("weight","number").getValue());
	statwindow.createChild("checkpenalty","number").setValue(source.createChild("checkpenalty","number").getValue());
	statwindow.createChild("speed","number").setValue(source.createChild("speed","number").getValue());
	statwindow.createChild("type","string").setValue(source.createChild("type","string").getValue());
	statwindow.createChild("damage","string").setValue(source.createChild("damage","string").getValue() .. " damage");
	statwindow.createChild("range","number").setValue(source.createChild("range","number").getValue());
 	
	return newentry;
end

function onDrop(x, y, draginfo)

	if draginfo.isType("shortcut") then
		local class, datasource = draginfo.getShortcutData();
		local source = draginfo.getDatabaseNode();

		if source and class == "referenceweapon" then
			local newentry = addMIWeapon(source);
		else
			if source and class == "referencearmor" then
				local newentry = addMIArmor(source);
			end
		end


		return true;
	end
end

