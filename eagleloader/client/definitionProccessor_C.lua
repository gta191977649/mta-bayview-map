
-- Tables --
resource		    = {}
resourceModels 	 	= {}
resourceMaps		= {}

streamingDistances  = {}

validID 			= {}
streamEverything    = true

timeTableID         = {}
timeTable           = {}

definitionZones     = {}
idObjectProperties  = {}
lodAttach 			= {}
lodCache 			= {} -- use it to store lod related positions
lodMaxDistance 	    = 1000
lodAttach['tram']   = true
modelPool 			= {}
failed              = {}

pleaceHolderModelID = 8585

function loadMapDefinitions ( resourceName,mapDefinitions,last)

	if globalCache[resourceName] then
		releaseCatche(resourceName)
	end
	
	globalCache[resourceName] = {}
	resourceModels[resourceName] = {}
	startTickCount = getTickCount ()
	resource[resourceName] = {}
	

	for i,v in pairs(getElementsByType('object')) do -- // Loop through all of the objects and mark which IDs exist
		local id = getElementID(v)
		local lodID = getElementData(v,'lodID')
		validID[lodID] = true
		validID[id] = true
	end
	
	-- check if use global texture
	local globalTxdPath = fileExists((":%s/%s"):format(resourceName,'map.txd')) and (":%s/%s"):format(resourceName,'map.txd') or false

	Async:setPriority("medium")
	Async:foreach(mapDefinitions, function(data)

		if not (data.default == 'true') then
			--iprint(data)
			local isTimedObject = tonumber(data.timeIn) and tonumber(data.timeOut)

			local modelType = isTimedObject and "timed-object" or "object"
			local modelID,new = requestModelID(data.id,modelType)

			if modelID then
				
				if new then
					resourceModels[resourceName][modelID] = true
				end
					
				if streamEverything or validID[data.id] then

					local zone = data.zone
					local hasLOD = data.lod and data.lod == 'true'
					--local isLOD = startsWithLOD(data.id)
					definitionZones[modelID] = zone
					local loddist = tonumber(data.lodDistance or 200) 
					
					
					-- deal with if object needs lods
					local needLODs = loddist > 300
					
					engineSetModelLODDistance (modelID,(loddist > lodMaxDistance and lodMaxDistance or loddist),needLODs)
					engineSetModelFlags(modelID,tonumber(data.flags),true)
					streamingDistances[modelID] = (loddist)
					
					
					
					if needLODs then -- we only checks with object that greate distance in ide
						if hasLOD then -- if it has lod model assigned
							useLODs[data.id] = data.lodID
						else -- or we assign it, (use itself as lod) e.g. like timed objects
							useLODs[data.id] = data.id
						end
					end


					if data.flags then
						getFlags(data)
					end
					
					idObjectProperties[data.id] = {}
					
					idObjectProperties[data.id]['doubleSided'] = data.doubleSided
					idObjectProperties[data.id]['breakable'] = data.breakable
					idObjectProperties[data.id]['lodDistance'] = loddist
					
					-- // Textures
					
					local textureString = data.txd

					local TXDPath = ':'..resourceName..'/zones/'..zone..'/txd/'..textureString..'.txd'

					-- // Check if the map use global texture 
					if globalTxdPath then
						TXDPath = globalTxdPath
					end
					
					local texture,textureCache = requestTextureArchive(TXDPath,resourceName)

					if texture then
						if engineImportTXD(texture,modelID) then
							--table.insert(resource[resourceName],textureCache)
						else
							print('Texture : '..textureString..' could not be loaded!')
						end
					else
						print('Texture : '..textureString..' could not be loaded!')
					end
					
					-- // Collisions
					
					local collisionString = data.col

					local COLPath = ':'..resourceName..'/zones/'..zone..'/col/'..collisionString..'.col'

					local collision,collisionCache = requestCollision(COLPath,resourceName)

					if collision then
						if not engineReplaceCOL(collision,modelID) then
							print('Collision : '..collisionString..' could not be loaded!')
						end
					else
						print('Collision : '..collisionString..' could not be loaded!')
					end
					
					-- // Models
					
					local modelString = data.dff or data.id
					
					local DFFPath = ':'..resourceName..'/zones/'..zone..'/dff/'..modelString..'.dff'
					local model,modelCache = requestModel(DFFPath,resourceName)
						
					if model then
						if (data.alphaTransparency == 'true') or (data.alphaTransparency == true) then
							if not engineReplaceModel(model,modelID,true) then
								print('Model : '..modelString..' could not be loaded!')
								failed[data.id] = true
							end
						else
							if not engineReplaceModel(model,modelID) then
								print('Model : '..modelString..' could not be loaded!')
								failed[data.id] = true
							end
						end
					else
						print('Model : '..modelString..' could not be loaded!')
						failed[data.id] = true
					end
					
					if isTimedObject then
						outputChatBox(string.format("time obj: %d, time: %d-%d",modelID,tonumber(data.timeIn),tonumber(data.timeOut)))
						--setModelStreamTime (modelID, tonumber(data.timeIn), tonumber(data.timeOut))
						engineSetModelVisibleTime(modelID,tonumber(data.timeIn),tonumber(data.timeOut))
						timeTableID[data.id] = true
					end
				end
				
				if (data.id == last) then
					loaded(resourceName)
				end
			end
		end
	end)
end

function loadMapPlacements(resourceName,mapPlacements,last)
	
	resourceMaps[resourceName] = {}
	
	Async:setPriority("medium")
	Async:foreach(mapPlacements, function(data)
		local isLOD = startsWithLOD(data.id)
		local isDynamic = tonumber(data.model) ~= pleaceHolderModelID 
		local obj = nil
		
		if isDynamic then -- if is dummy object, use object instead
			obj = createObject(data.model,data.posX,data.posY,data.posZ,data.rotX,data.rotY,data.rotZ)
			--obj = createBuilding(3504,data.posX,data.posY,data.posZ,data.rotX,data.rotY,data.rotZ)
		else
			-- if data.id and idCache[data.id] then
			-- 	--obj = createBuilding(idCache[data.id],data.posX,data.posY,data.posZ,data.rotX,data.rotY,data.rotZ,tonumber(data.interior))
			-- 	obj = createObject(idCache[data.id],data.posX,data.posY,data.posZ,data.rotX,data.rotY,data.rotZ)
			-- end
			--obj = createObject(data.model,data.posX,data.posY,data.posZ,data.rotX,data.rotY,data.rotZ)
			obj = createBuilding(3504,data.posX,data.posY,data.posZ,data.rotX,data.rotY,data.rotZ,tonumber(data.interior))
		end
		--setElementInterior(obj,tonumber(data.interior))
		setElementID(obj,data.id)
	end)
end

function loaded(resourceName)
	loadedFunction (resourceName)
	initializeObjects()
	releaseCatche(resourceName)
	engineRestreamWorld( true )
end
					

function initializeObjects()
	Async:setPriority("medium")
	Async:foreach(getElementsByType("building"), function(object)
	
		local id = getElementID(object)
		
		if failed[id] then
			destroyElement(object)
		else
			changeObjectModel(object,id,true,true)
		end
	end)
end

function loadedFunction (resourceName)
	local endTickCount = getTickCount ()-startTickCount
	triggerServerEvent ( "onPlayerLoad", resourceRoot, tostring(endTickCount),resourceName )
	createTrayNotification( 'You have finished loading : '..resourceName, "info" )
end


function changeObjectModel(object,newModel,streamNew,inital)
	local id = getElementID(object)
	
	if id or streamNew then
		if idCache[newModel] then
			if not inital then
				if id then
					print(id..'- Changed to : '..newModel)
				else
					print('New object streamed with ID: '..newModel)
				end
			end
			local lodID = useLODs[newModel] 
			-- fix barrier wrong position
			if not lodID then 
				local x,y,z = getElementPosition (object)
				local xr,yr,zr = getElementRotation (object)
				destroyElement(object)
				object = createObject(idCache[newModel],x,y,z,xr,yr,zr)
			end


			setElementModel(object,idCache[newModel])
			setElementID(object,newModel)
			setElementData(object,'Zone',definitionZones[id])
			setElementDoubleSided(object,(idObjectProperties[newModel]['doubleSided'] == 'true' or false))
			
			setObjectBreakable(object,(idObjectProperties[newModel]['breakable'] == 'true' or false))
			
			if timeTableID[newModel] then
				timeTable[object] = true
				-- Also set the lod for timed object
				local x,y,z = getElementPosition (object)
				local xr,yr,zr = getElementRotation (object)
				local nObject = createObject(idCache[newModel],x,y,z,xr,yr,zr,true)
				--setLowLODElement(object,nObject)
				engineSetModelLODDistance (idCache[newModel],300) 
				timeTable[nObject] = true

			end
			
			-- local LOD = getLowLODElement(object)
			-- if LOD then
			-- 	destroyElement(LOD) -- // Clear LOD if it exists
			-- end
			
			if not getLowLODElement(object) then
				if lodID then -- // Create new LOD if this model has a LOD assigned to it
					-- FIND LODS
					--local nObject = getElementByID(lodID) 
					--if nObject == object then -- check if it doesnt have lod,then we have to create it
					local x,y,z = getElementPosition (object)
					local xr,yr,zr = getElementRotation (object)
					nObject = createBuilding(idCache[lodID],x,y,z,xr,yr,zr)
					--end

					if nObject then
						setLowLODElement(object,nObject)
						setElementDoubleSided(nObject,true)
					end

			
				end
			end
			
		end
	end
end
addEvent( "changeObjectModel", true )
addEventHandler( "changeObjectModel", resourceRoot, changeObjectModel )


function streamObject(id,x,y,z,xr,yr,zr)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local obj = createObject(1337,x,y,z,xr,yr,zr)
	changeObjectModel(obj,id,true)
	setElementID(obj,id)
	return obj
end



function onElementDataChange(dataName, oldValue)
    if (dataName == "id") then
        local newId = getElementID(source)
		if idCache[newId] then
			if (newId ~= oldValue) then
				changeObjectModel (source,newId)
			end
		end
    end
end
addEventHandler("onElementDataChange", root, onElementDataChange)

function unloadMapDefinitions(name) -- // Feed this the resource name in order to unload the definitions loaded.
	if resourceModels[name] then
		for ID,_ in pairs(resourceModels[name]) do
			engineFreeModel(ID)
		end
	end
	resourceModels[name] = nil
end
addEvent( "resourceStop", true )
addEventHandler( "resourceStop", localPlayer, unloadMapDefinitions )

function onElementDestroy()
	if idCache[getElementID(source)] then -- // Only destroying the LOD if it's a custom model
		if getElementType(source) == "object" then
			if getLowLODElement(source) then
				destroyElement(getLowLODElement(source))
			end
		end
	end
end
addEventHandler("onElementDestroy",resourceRoot,onElementDestroy)


function getMaps()
	local tempTable = {}
	for i,v in pairs(resource) do
		table.insert(tempTable,i)
	end
	return tempTable
end
