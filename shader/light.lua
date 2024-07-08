light_txd = {
    "0x17e5ebd2",
    "0x17171c83",
    "0x214de4b2",
    "0x2914ba39",
    "0xffdba2df",
    "0xb706b947",-- spot lights
    "0x3394fe62",


}
neon_txd = {
    "0xc356e407",
    "0xad960d3d",
    "0x005fa675",
    "0x5f1f062b",
    "0x9dac57e2",
    "0x47dca16e",
    "0x7fed6a3c",
    "0x61497713",
    "0xd9cd6bf6",
    "0xf583e4e7",
    "0x738899d1",
    "0x39fd145b",
    "0x3ef7f76a",
    "0x8f916769",
    "0xa91ed97b",
    "0x3aece8ff",
    "0xf5cebc93",
    "0xdae60181",
    "0xcad0f894",
    "0x8687b0e9",
    "0x9d2f9027",
    "0x3de7be4a",
    "0xb896ba48",
    "0xb3bad128",
    "0x06aff005",
    "0x290bfc8a",
    "0x0fef89a3",
    "0x005b775c",
    "0x1d5ce492",
    "0x3c1f6ca3",
    "0x2b4e85d7",
    "0x792d2851",
    "0xa5d9b308",
    "0x455e4bd7",
    "0xead9f437",
    "0xA38D458C",
    "0x47DCA16E",
    "0x4a5871b5",
    "0x9f944e47",
    "0x9f93c1e6",
    "0x2505dc05",
    "0xddf2b8b0",
    "0x717f3b34",
    "0x54556a98",
    "0x1dc8841d",
    "0xe677724a",
    "0x6fe8d29b",
    "0x6322a8c1",
    "0x5dc403b5",
    "0x262d5211",
    "0xef5bd706",
    "0xf74552af",
    "0x36fe8e63",
    "0x6c3b38da",
    "0xdb650fe3",
    "0xb50fce29",
    "0xb1f47d9c",
    "0x45379393",
    "0x135227e5",
}
light_shad_txd = {

    "unnamed",
    
}

-- TXD_NAME, {0 = UP, 1 = DOWN, 2 = LEFT, 3 = RIGHT}
uv_anim = {
    {"0x6b098df4",1},
    {"0xb360e1d7",2},
    {"0x9d2f4a51",3},
    --{"0xcac99ec7",1},
}
uv_anim_alpha = {
    {"0x452ecd84",1},
    {"0xcac99ec7",0},
    {"0xc841d7ab",0},
    --{"0x3de7be4a",2},
    
}

uv_fade = {}

addEventHandler("onClientResourceStart", resourceRoot, function()
	local coronas_shader = dxCreateShader("fx/light.fx",0,0,false,"object") 
	local neon_shader = dxCreateShader("fx/neon.fx",0,0,false,"object") 
	--local neon_shader = dxCreateShader("fx/dl_neon.fx") 
    local l_shad = dxCreateShader("fx/light_shad.fx",0,0,false,"object") 
    local fade_shader = dxCreateShader("fx/uv_fade_neon.fx",0,0,false,"object")
	local building_shader = dxCreateShader("fx/building.fx",0,0 ,false,"object") 
    -- setup uv anim shader
	local uvAnim_shader = {}
    uvAnim_shader[1] = dxCreateShader("fx/uv_scroll.fx") 
    uvAnim_shader[2] = dxCreateShader("fx/uv_scroll.fx") 
    uvAnim_shader[3] = dxCreateShader("fx/uv_scroll.fx") 
    uvAnim_shader[4] = dxCreateShader("fx/uv_scroll.fx") 
    --asign vars
    dxSetShaderValue(uvAnim_shader[1], "direction", 0)
    dxSetShaderValue(uvAnim_shader[2], "direction",1)
    dxSetShaderValue(uvAnim_shader[3], "direction", 2)
    dxSetShaderValue(uvAnim_shader[4], "direction",3)

    local uvAnimNeon_shader = {}
    uvAnimNeon_shader[1] = dxCreateShader("fx/uv_scroll_neon.fx") 
    uvAnimNeon_shader[2] = dxCreateShader("fx/uv_scroll_neon.fx") 
    uvAnimNeon_shader[3] = dxCreateShader("fx/uv_scroll_neon.fx") 
    uvAnimNeon_shader[4] = dxCreateShader("fx/uv_scroll_neon.fx") 
    --asign vars
    dxSetShaderValue(uvAnimNeon_shader[1], "direction", 0)
    dxSetShaderValue(uvAnimNeon_shader[2], "direction",1)
    dxSetShaderValue(uvAnimNeon_shader[3], "direction", 2)
    dxSetShaderValue(uvAnimNeon_shader[4], "direction",3)



    
   
    
    --set shader vars

    for i,v in ipairs(light_txd) do
        engineApplyShaderToWorldTexture(coronas_shader, v)
    end
    for i,v in ipairs(neon_txd) do
        engineApplyShaderToWorldTexture(neon_shader, v)
    end
   
    for i,v in ipairs(light_shad_txd) do
        engineApplyShaderToWorldTexture(l_shad, v)
    end
    
    -- set uv animation shaders
    for i,v in ipairs(uv_anim) do
        engineApplyShaderToWorldTexture(uvAnim_shader[v[2]+1], v[1])
    end
    for i,v in ipairs(uv_anim_alpha) do
        engineApplyShaderToWorldTexture(uvAnimNeon_shader[v[2]+1], v[1])
    end
    
    for i,v in ipairs(uv_fade) do
        engineApplyShaderToWorldTexture(fade_shader, v)
    end
    
    --engineApplyShaderToWorldTexture(building_shader,"*")
    --engineApplyShaderToWorldTexture(coronas_shader, "unnamed")
  
    --setColorFilter (0, 0, 0, 0, 0, 0, 0, 0)
	resetColorFilter()
    setFarClipDistance (3000)
    setFogDistance(10)
    --resetFogDistance()
    --resetFarClipDistance()

    local CAMERA = getCamera()
    local LIGHT = createLight(0, 0, 0, 0, 60, 1, 0, 0)

    addEventHandler("onClientPreRender", root, 
        function()
            local x, y, z = getElementPosition(CAMERA)
            setElementPosition(LIGHT, x, y, z)
        end
    )
    setOcclusionsEnabled( false )

    resetWaterLevel()
    setWaterLevel ( -1000 ) 
    setWorldSpecialPropertyEnabled ("tunnelweatherblend", false )
end)

addCommandHandler("ssms", function(_, sizeMB)
    if tonumber(sizeMB) then
        outputChatbox("The maximum streaming memory available has been changed from " .. math.floor(engineGetStreamingMemorySize() / 1024 / 1024) .. " MB to " .. sizeMB .. " MB")      
        engineStreamingSetMemorySize(tonumber(sizeMB) * 1024 * 1024) -- Convert MB to Bytes
    else
        outputChatbox("Please enter a numeric value!")
    end
end, false, false)

addCommandHandler("sbs", function(_, sizeMB)
    if tonumber(sizeMB) then
        if engineStreamingSetBufferSize(tonumber(sizeMB) * 1024 * 1024) then -- Convert MB to Bytes
            outputChatBox("The streaming buffer size has been changed from " .. math.floor(engineStreamingGetBufferSize() / 1024 / 1024) .. " MB to " .. sizeMB .. " MB")
        else
            outputChatBox("Not enough memory!")
        end
    else
        outputChatBox("Please enter a numeric value!")
    end
end, false, false)