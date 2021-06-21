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

function getFullString()
	local str = "Item Power [" .. getDatabaseNode().getParent().getParent().getChild("name").getValue() .. "]";
	local desc = "";
	
	-- Add everything else in the notes
	local shortdesc = getDatabaseNode().getChild("shortdescription").getValue();
	if shortdesc and shortdesc ~= "" and shortdesc ~= "-" then
		if desc ~= "" then
			desc = desc .. "; ";
		end
		desc = desc .. shortdesc;
	end
	
	if desc ~= "" then
		str = str .. " -> " .. desc;
	end

	return str;
end

function getShortString()
	return "Item Power [" .. getDatabaseNode().getParent().getParent().getChild("name").getValue() .. "]";
end

function activatePower(showfullstr)
	local desc = "";
	if showfullstr == true then
		desc = getFullString();
	else
		desc = getShortString();
	end
	ChatManager.Message(desc, true, {pc = getDatabaseNode().getParent().getParent().getParent().getParent()});
end

function addMI(source)

	-- Create a new MI window to hold the data
	local newentry = createWindow();
	local newnode = newentry.getDatabaseNode();


	-- Static nodes
  	newnode.createChild("name","string").setValue(source.createChild("name","string").getValue());
  	newnode.createChild("level","number").setValue(source.createChild("level","number").getValue());
  	newnode.createChild("bonus","number").setValue(source.createChild("bonus","number").getValue());
  	newnode.createChild("cost","string").setValue(source.createChild("cost","string").getValue());
  	newnode.createChild("class","string").setValue(source.createChild("class","string").getValue());
  	newnode.createChild("subclass","string").setValue(source.createChild("subclass","string").getValue());
  	newnode.createChild("critical","string").setValue(source.createChild("critical","string").getValue());
  	newnode.createChild("special","string").setValue(source.createChild("special","string").getValue());
  	newnode.createChild("enhancement","string").setValue(source.createChild("enhancement","string").getValue());
  	newnode.createChild("flavor","string").setValue(source.createChild("flavor","string").getValue());
 
	local miclass = newnode.getChild("class") 	

	if miclass.getValue() == "Weapon" then
		newnode.createChild("mitype","string").setValue("weapon");
	else
		if miclass.getValue() == "Armor" then
			newnode.createChild("mitype","string").setValue("armor");
		else
			newnode.createChild("mitype","string").setValue("other");
		end
	end


	---property list
      if source.getChild("props") then
            local propertynode = newnode.createChild("props");
            for key, val in pairs(source.getChild("props").getChildren()) do
                  -- keys here are prop001, prop002, etc
                  -- vals are db nodes containing children that you need to parse through
                  local prop1 = propertynode.createChild(key);
                  for key2, val2 in pairs(val.getChildren()) do
                        -- keys here seem to be "shortdescription"
                        -- values are leaf database nodes that contain the value which is the string description
                        local prop2 = prop1.createChild(key2, type(val2.getValue()));
                        prop2.setValue(val2.getValue());
                  end
            end
      end

  --powerlist
  if source.getChild("powers") then
    local newlist = newnode.createChild("powers");
    for key, oldpow in pairs(source.getChild("powers").getChildren()) do
    	NodeManager.copyNode(oldpow, newlist);
    end
  end

 	
	return newentry;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local class, datasource = draginfo.getShortcutData();
		local source = draginfo.getDatabaseNode();

		if source and class == "referencemagicitem" then
			local newentry = addMI(source);
		end

		return true;
	end
end

