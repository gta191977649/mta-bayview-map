-- //Properties you can edit
removeDefaultMap = true

-- //Rest of the script
if removeDefaultMap then
	engineSetPoolCapacity('building',20000)
	removeAllGameBuildings()
end



function getLines(file)
	local fData = fileRead(file, fileGetSize(file))
	local fProccessed = split(fData,10) -- Split the lines
	fileClose (file)
	return fProccessed
end

function onResourceStart(resourceThatStarted)
	
	local resourceName = getResourceName(resourceThatStarted)
	local path = ((":%s/%s"):format(resourceName,'eagleZones.txt'))
	local definitionList = {}
	local placementList = {}

	-- Check nessary files
	if fileExists(path) then 
		print("Note: eagleZones.txt is not found!")
	end

	if fileExists(path) then
		local zones = getLines(fileOpen(path))
		for _,zone in pairs(zones) do
			local list = loadZone(resourceName,zone)
			
			if list then
				for i,v in pairs(list) do
					table.insert(definitionList,v)
				end
			end
			
			local p_list = loadPlacement(resourceName,zone)
			for i,v in pairs(p_list) do
				table.insert(placementList,v)
			end
			
		end
	end

	local last = definitionList[#definitionList]
	if last then
		local lastID = last.id
		loadMapDefinitions(resourceName,definitionList,lastID)
	end
	
	local last_placement = placementList[#placementList]
	if last_placement then
		local lastID = last_placement.id
		loadMapPlacements(resourceName,placementList,lastID)
	end
	
	
end

addEventHandler( "onClientResourceStart", root, onResourceStart)

function loadZone(resourceName,zone)
	local path = ':'..resourceName..'/zones/'..zone..'/'..zone..'.def'
	if not fileExists(path) then 
		print("File Not Found, Skipped "..path)
		return false
	end
	local zoneDefinitions = xmlLoadFile(path)
	print(path)
	print(zoneDefinitions)
	local sDefintions = xmlNodeGetChildren(zoneDefinitions)
	local newTable = {}
	
	for _,definiton in pairs (sDefintions) do
		local attributes = xmlNodeGetAttributes(definiton)
		table.insert(newTable,attributes)
	end
	
	xmlUnloadFile(zoneDefinitions)
	return newTable
end

function loadPlacement(resourceName,zone)
	local path = ':'..resourceName..'/zones/'..zone..'/'..zone..'.map'
	if fileExists(path) then
		local zoneDefinitions = xmlLoadFile(path)
		print(path)
		print(zoneDefinitions)
		local sDefintions = xmlNodeGetChildren(zoneDefinitions)
		local newTable = {}
		
		for _,definiton in pairs (sDefintions) do
			local attributes = xmlNodeGetAttributes(definiton)
			table.insert(newTable,attributes)
		end
		
		xmlUnloadFile(zoneDefinitions)
		return newTable
	end
	return {}
end
