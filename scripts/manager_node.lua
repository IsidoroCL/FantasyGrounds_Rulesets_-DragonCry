-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

-- Adds the username to the list of holders for the given node
function addWatcher (nodename, username)
	local node = DB.findNode(nodename);
	if not node then
		node = DB.createNode(nodename);
	end

	if node then
		node.addHolder(username);
	end	
end

-- Copy the source node into the node tree under the destination parent node
-- Used recursively to handle node subtrees
--
-- NOTE: Node types supported are: 
-- 			number, string, image, dice, windowreference, node
function copyNode(srcnode, dst_parent_node, rename)
    -- Parameter validation
    if not srcnode or not dst_parent_node then
    	return nil;
    end
    
    -- Create a variable for our new node
    local newnode = nil;
    
    -- Figure out what type of node this is
    local nodeType = srcnode.getType();
    local nodeName = srcnode.getName();

    -- For basic nodes, just create a copy of the source node in the target list
    if nodeType == "number" or nodeType == "string" or nodeType == "image" or nodeType == "dice" or nodeType == "windowreference" then
      	newnode = createSafeChild(dst_parent_node, nodeName, nodeType);
      	if newnode then
      		newnode.setValue(srcnode.getValue());
      	end

    -- For list nodes, copy all the children too
    elseif nodeType == "node" then
		if rename == true then
			newnode = createSafeChild(dst_parent_node);
		else
			newnode = createSafeChild(dst_parent_node, nodeName);
		end
		for k, subnode in pairs(srcnode.getChildren()) do
			copyNode(subnode, newnode);
		end
	end
	
	return newnode;
end

-- Sets the given value into the fieldname child of sourcenode.  
-- If the fieldname child node does not exist, then it is created.
function setSafeChildValue(sourcenode, fieldname, fieldtype, initialval)
	if sourcenode and fieldname and fieldtype then
		srcvalnode = createSafeChild(sourcenode, fieldname, fieldtype);
		if srcvalnode then
			srcvalnode.setValue(initialval);
			return srcvalnode;
		end
	end

	return nil;
end

-- Gets the given value of the fieldname child of sourcenode.  
-- If the fieldname child node does not exist, then the defaultval is returned instead.
function getSafeChildValue(sourcenode, fieldname, defaultval)
	if sourcenode then
		local srcvalnode = sourcenode.getChild(fieldname);
		if srcvalnode then
			return srcvalnode.getValue();
		end
	end
	
	return defaultval;
end

--
-- SAFE NODE CREATION
--

function isReadOnly(sourcenode)
	if not sourcenode then
		return true;
	end
	
	if User.isHost() or User.isLocal() then
		return false;
	end
	
	if sourcenode.isOwner() then
		return false;
	end
	
	return true;
end

function createSafeChild(sourcenode, fieldname, fieldtype)
	if not sourcenode then
		return nil;
	end
	
	if not isReadOnly(sourcenode) then
		if fieldname then
			if fieldtype then
				return sourcenode.createChild(fieldname, fieldtype);
			else
				return sourcenode.createChild(fieldname);
			end
		else
			return sourcenode.createChild();
		end
	end

	return sourcenode.getChild(fieldname);
end

function createSafeWindow(windowlist)
	if not windowlist then
		return nil;
	end
	
	local listnode = windowlist.getDatabaseNode();
	if listnode then
		if isReadOnly(listnode) then
			return nil;
		end
	end
	
	return windowlist.createWindow();
end
