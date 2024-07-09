-- 
-- Bayview Road Shader
-- Shader created by Ren712 & modified by Nurupo
--

scx, scy = guiGetScreenSize()
local bEffectEnabled

----------------------------------------------------------------
----------------------------------------------------------------
-- Effect switching on and off
----------------------------------------------------------------
----------------------------------------------------------------

--------------------------------
-- onClientResourceStart
--		Auto switch on at start
--------------------------------
addEventHandler( "onClientResourceStart", resourceRoot,
	function()
		triggerEvent( "switchLR", resourceRoot, true )
	end
)

--------------------------------
-- Command handler
--		Toggle via command
--------------------------------
addCommandHandler( "sslr",
	function()
		triggerEvent( "switchLR", resourceRoot, not bEffectEnabled )
	end
)


--------------------------------
-- Switch effect on or off
--------------------------------
function switchLR( bOn )
	if bOn then
		enableLR()
	else
		disableLR()
	end
end
addEvent( "switchLR", true )
addEventHandler( "switchLR", resourceRoot, switchLR )


----------------------------------------------------------------
----------------------------------------------------------------
-- Effect clever stuff
----------------------------------------------------------------
----------------------------------------------------------------

-- List of world texture name matches and how much of the effect to apply to each match.
-- (The ones later in the list will take priority) 
local alpha =1.2
local applyList = {	
	{ alpha, "0x7aa659ff" },
	{ alpha, "0x9832553f" },
	{ alpha, "0xc38d3f54" },
	{ alpha, "0xd1c98e50" },
	{ alpha, "0xd1c901ef" },
	{ alpha, "0xd1ca1ab1" },
	{ alpha, "0xde762fdd" },
	{ alpha, "0xf91d258c" },
	{ alpha, "0xf91s2588" },
	{ alpha, "0x1ada178b" },
	{ alpha, "0x05dbf754" },
	{ alpha, "0x05dbf751" },
	{ alpha, "0x6c338031" },
	{ alpha, "0xf91d2588" },
	{ alpha, "0x05dbf750" },
	{ alpha, "0x05dbf74f" },
	{ alpha, "0x75aaa724" },
	{ alpha, "0xec4807c1" },
	{ alpha, "0x15bebbfd" },
	{ alpha, "0xfd4fe94e" },
	{ alpha, "0x1de30448" },
	{ alpha, "0x42b2664d" },
	{ alpha, "0x05dbf74c" },
	{ alpha, "0xf91d258d" },
	{ alpha, "0x1ada1789" },
	{ 0, "0x6ef8f936" },
	{ 0, "0x05dbf74e" },
	{ 0, "0x05dbf74d" },
	{ 0, "0x574fdda8" },
	{ 0, "0x83a9fbcd" },
	{ 0, "0x70f156a1" },
	{ 0, "0x62396fb7" },
	{ 0, "0x0e457817" },
	{ 0, "0x67d37717" },
	{ 0, "0xae306e88" },
	{ 0, "0x16519ebf" },
	{ 0, "0x6ef9b462" },
	-- Bayview Speedway Track
	{ alpha, "0x58091daf" },
	{ alpha, "0xb9783a7c" },
	{ alpha, "0x576a4908" },
	{ alpha, "0x5376a764" },
	{ alpha, "0x81725e82" },
	
}
-- List of world textures to exclude from this effect
local removeList = {
						"",												-- unnamed
						"vehicle*", "?emap*", "?hite*",					-- vehicles
						"*92*", "*wheel*", "*interior*",				-- vehicles
						"*handle*", "*body*", "*decal*",				-- vehicles
						"*8bit*", "*logos*", "*badge*",					-- vehicles
						"*plate*", "*sign*",							-- vehicles
						"shad*",										-- shadows
						"coronastar",									-- coronas
						"tx*",											-- grass effect
						"lod*",											-- lod models
						"cj_w_grad",									-- checkpoint texture
						"*cloud*",										-- clouds
						"*smoke*",										-- smoke
						"sphere_cj",									-- nitro heat haze mask
						"particle*",									-- particle skid and maybe others
						"water*", "sw_sand", "coral",					-- sea
						"sm_des_bush*", "*tree*", "*ivy*", "*pine*",	-- trees and shrubs
						"veg_*", "*largefur*", "hazelbr*", "weeelm",
						"*branch*", "cypress*", "plant*", "sm_josh_leaf",
						"trunk3", "*bark*", "gen_log", "trunk5"
					}


-- set alpha of selected textures to 1
addEventHandler( "onClientResourceStart", resourceRoot,
	function()
	local zeroShader = dxCreateShader("RTinput_world_zero.fx",0,0,false,"world,object")
	if not zeroShader then return end
	for _,apply in ipairs(applyList) do
		local nameMatch = apply[2]
		-- Add this texture name match to the shader
		engineApplyShaderToWorldTexture ( zeroShader, nameMatch )
	end
end
)
	
--------------------------------
-- Switch effect on
--------------------------------
function enableLR()
	if bEffectEnabled then return end
	if not (tonumber(dxGetStatus().VideoCardPSVersion) > 2  and tostring(DepthBufferFormat) ~= "unknown") then return end

	myShader = dxCreateShader("sslr.fx")
	brightPassShader = dxCreateShader( "brightPass.fx" )
	blurHShader = dxCreateShader( "blurH.fx" )
	blurVShader = dxCreateShader( "blurV.fx" )
	myTexture = dxCreateTexture("vignette1.dds")
	myRTDepth = dxCreateRenderTarget( scx, scy, "r32f"  )
	myRTMask = dxCreateRenderTarget( scx, scy )
	myScreenSource = dxCreateScreenSource(scx , scy )

	bAllValid = myShader and myScreenSource and myTexture and myRTDepth and myRTMask
	if not bAllValid then return end
	
	local _, _, _, colR, colG, colB = getSkyGradient()
	dxSetShaderValue(myShader, "sSkyColor", colR / 255, colG / 255, colB / 255, 1)
	--dxSetShaderValue(myShader, "sColorTex", myScreenSource)
	dxSetShaderValue(myShader, "sDepthTex", myRTDepth)
	dxSetShaderValue(myShader, "sMaskTex", myRTMask)
	dxSetShaderValue(myShader, "sVignetTex", myTexture)
	dxSetShaderValue(myShader, "sPixelSize", 1 / scx, 1 / scy)
	dxSetShaderValue(myShader, "fViewportSize", scx, scy)
	dxSetShaderValue(myShader, "fViewportScale", 1, 1)
	dxSetShaderValue(myShader, "fViewportPos", 0, 0)
		
	-- Process apply list
	for _,apply in ipairs(applyList) do
		local strength = apply[1]
		local nameMatch = apply[2]
		-- Find or create shader which handles this strength
		local info = ShaderInfoList.getShaderInfoForStrength(strength)
		if not info then return end
		-- Add this texture name match to the shader
		engineApplyShaderToWorldTexture ( info.shader, nameMatch )
	end

	-- Process remove list
	for _,removeMatch in ipairs(removeList) do
		-- Remove for each shader
		for _,info in ipairs(ShaderInfoList.items) do
			engineRemoveShaderFromWorldTexture ( info.shader, removeMatch )
		end
	end

	-- Update direction all the time
	skyTimer = setTimer( updateSkyColor, 100, 0 )


	-- Flag effect as running
	bEffectEnabled = true
end


--------------------------------
-- Switch effect off
--------------------------------
function disableLR()
	if not bEffectEnabled then return end

	-- Destroy all shaders
	for f,info in ipairs(ShaderInfoList.items) do
		destroyElement( info.shader )		
	end
	ShaderInfoList.items = {}

	killTimer( skyTimer )
	skyTimer = nil
	
	destroyElement(myShader) 
	myShader = nil
	destroyElement(myTexture) 
	myTexture = nil
	destroyElement(myRTDepth) 
	myRTDepth = nil
	destroyElement(myRTMask) 
	myRTMask = nil
	destroyElement(myScreenSource) 
	myScreenSource = nil

	-- Flag effect as stopped
	bEffectEnabled = false
end


--------------------------------
-- Shader info list
--		List of created shaders
--------------------------------
ShaderInfoList = {}
ShaderInfoList.items = {}

-- Return info for a shader that uses the same strength setting
function ShaderInfoList.getShaderInfoForStrength(strength)
	-- Use exsiting if it was the last one used
	if #ShaderInfoList.items > 0 then
		local info = ShaderInfoList.items[#ShaderInfoList.items]
		if info.strength == strength then
			return info
		end
	end

	-- Create a new shader
	local shader = dxCreateShader ( "RTinput_world_depth.fx", 1, 0,false,"world,object") 
			
	if not shader then
		outputChatBox( "Could not create shader. Please use debugscript 3" )
		return nil
	end
	-- Setup shader
	dxSetShaderValue( shader, "sStrength", strength )
	dxSetShaderValue( shader, "depthRT", myRTDepth)
	dxSetShaderValue( shader, "maskRT", myRTMask)
	dxSetShaderValue( shader, "sHalfPixel", (1 / scx) * 0.5, (1 / scy) * 0.5)
	-- Add info to list
	table.insert(ShaderInfoList.items, { shader=shader, strength=strength } )
	return ShaderInfoList.items[#ShaderInfoList.items]
end


function updateSkyColor()
	if myShader then
		local _, _, _, colR, colG, colB = getSkyGradient()
		dxSetShaderValue(myShader, "sSkyColor", colR / 255, colG / 255, colB / 255, 1)
	end
end

----------------------------------------------------------------
-- Math helper functions
----------------------------------------------------------------
function math.lerp(from,alpha,to)
    return from + (to-from) * alpha
end

function math.unlerp(from,pos,to)
	if ( to == from ) then
		return 1
	end
	return ( pos - from ) / ( to - from )
end


function math.clamp(low,value,high)
    return math.max(low,math.min(value,high))
end

function math.unlerpclamped(from,pos,to)
	return math.clamp(0,math.unlerp(from,pos,to),1)
end

-----------------------------------------------------------------------------------
-- Apply the different stages
-----------------------------------------------------------------------------------
function applyDownsample( src, amount )
	if not src then return nil end
	amount = amount or 2
	local mx,my = dxGetMaterialSize( src )
	mx = mx / amount
	my = my / amount
	local newRT = RTPool.GetUnused(mx,my)
	if not newRT then return nil end
	dxSetRenderTarget( newRT )
	dxDrawImage( 0, 0, mx, my, src )
	DebugResults.addItem( newRT, "applyDownsample" )
	return newRT
end

function applyGBlurH( src, bloom )
	if not src then return nil end
	local mx,my = dxGetMaterialSize( src )
	local newRT = RTPool.GetUnused(mx,my)
	if not newRT then return nil end
	dxSetRenderTarget( newRT, true ) 
	dxSetShaderValue( blurHShader, "TEX0", src )
	dxSetShaderValue( blurHShader, "TEX0SIZE", mx,my )
	dxSetShaderValue( blurHShader, "BLOOM", bloom )
	dxSetShaderValue( blurHShader, "BLUR",2 )
	dxDrawImage( 0, 0, mx, my, blurHShader )
	DebugResults.addItem( newRT, "applyGBlurH" )
	return newRT
end

function applyGBlurV( src, bloom )
	if not src then return nil end
	local mx,my = dxGetMaterialSize( src )
	local newRT = RTPool.GetUnused(mx,my)
	if not newRT then return nil end
	dxSetRenderTarget( newRT, true ) 
	dxSetShaderValue( blurVShader, "TEX0", src )
	dxSetShaderValue( blurVShader, "TEX0SIZE",  mx,my )
	dxSetShaderValue( blurVShader, "BLOOM", bloom )
	dxSetShaderValue( blurVShader, "BLUR", 2 )
	dxDrawImage( 0, 0, mx,my, blurVShader )
	DebugResults.addItem( newRT, "applyGBlurH" )
	return newRT
end

function applyBrightPass( src, cutoff, power )
	if not src then return nil end
	local mx,my = dxGetMaterialSize( src )
	local newRT = RTPool.GetUnused(mx,my)
	if not newRT then return nil end
	dxSetRenderTarget( newRT, true ) 
	dxSetShaderValue( brightPassShader, "TEX0", src )
	dxSetShaderValue( brightPassShader, "CUTOFF", cutoff )
	dxSetShaderValue( brightPassShader, "POWER", power )
	dxDrawImage( 0, 0, mx,my, brightPassShader )
	DebugResults.addItem( newRT, "applyBrightPass" )
	return newRT
end

-----------------------------------------------------------------------------------
-- onClientPreRender
-----------------------------------------------------------------------------------
addEventHandler( "onClientPreRender", root,
    function()
		if not bEffectEnabled then return end
		DebugResults.frameStart()
		dxDrawImage(0, 0, scx, scy, myShader)
		DebugResults.addItem( myRTDepth, "depth" )
		DebugResults.addItem( myRTMask, "mask" )
		DebugResults.addItem( current, "screen" )
		DebugResults.drawItems (130, 100, 45 )
    end	
, true, "high" )

-----------------------------------------------------------------------------------
-- onClientHUDRender
-----------------------------------------------------------------------------------
addEventHandler("onClientHUDRender", root,
    function()
		if not bEffectEnabled then return end
		RTPool.frameStart()
		
		dxUpdateScreenSource(myScreenSource, false)
		current = myScreenSource
		current = applyBrightPass( current,0.2,1)
		--current = applyDownsample( current, 2 )
		current = applyGBlurH( current,2)
		current = applyGBlurV( current,2)
		-- Clear secondary render target
		dxSetRenderTarget( myRTDepth,true )

		dxSetRenderTarget( myRTMask,true )

		
		dxSetRenderTarget()
		

		dxSetShaderValue(myShader, "sColorTex", current)

		
		
		
    end
, true, "high")