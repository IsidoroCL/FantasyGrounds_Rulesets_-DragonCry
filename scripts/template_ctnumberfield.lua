-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

linknode = nil;
semaphorenode = nil;

function onInit()
	super.onInit();

	if self.update then
		self.update();
	end
end

function isSemaphoreClear()
	if not semaphorenode then
		return false;
	end
	return (semaphorenode.getValue() == 1);
end

function initSemaphore()
	semaphorenode = NodeManager.createSafeChild(window.getDatabaseNode(), getName() .. "_lock", "number");
	clearSemaphore();
end

function setSemaphore()
	if semaphorenode then
		semaphorenode.setValue(0);
	end
end

function clearSemaphore()
	if semaphorenode then
		semaphorenode.setValue(1);
	end
end

function onDrop(x, y, draginfo)
	if User.isHost() then
		if draginfo.getType() ~= "number" then
			return false;
		end

		if self.handleDrop then
			self.handleDrop(draginfo);
			return true;
		end
	end
end

function onValueChanged()
	if self.update then
		self.update();
	end

	if linknode and not isReadOnly() then
		if isSemaphoreClear() then
			setSemaphore();
			linknode.setValue(getValue());
			clearSemaphore();
		end
	end

end

function onLinkUpdated(source)
	if source then
		if isSemaphoreClear() then
			setSemaphore();
			setValue(source.getValue());
			clearSemaphore();
		end
	end

	if self.update then
		self.update();
	end
end

function setLink(dbnode, readonly)
	if dbnode then
		initSemaphore();
		
		linknode = dbnode;
		linknode.onUpdate = onLinkUpdated;

		if readonly then
			addBitmapWidget("indicator_linked").setPosition("bottomright", 0, -3);
		else
			addBitmapWidget("indicator_linked").setPosition("bottomright", -5, -5);
		end
		
		if readonly == true then
			setReadOnly(true);
		end

		onLinkUpdated(linknode);
	end
end

