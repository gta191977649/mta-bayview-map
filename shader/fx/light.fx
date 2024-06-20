//
// soft_particles.fx
//

//--------------------------------------------------------------------------------------
// Effect Settings
//--------------------------------------------------------------------------------------
float fDepthAttenuation = 1;
float fDepthAttenuationPower = 5;

float2 sPixelSize = float2(0.00125,0.00166);

//--------------------------------------------------------------------------------------
// Include some common stuff
//--------------------------------------------------------------------------------------
float4x4 gWorld : WORLD;
float4x4 gView : VIEW;
float4x4 gProjection : PROJECTION;
float4x4 gWorldViewProjection : WORLDVIEWPROJECTION;
texture gDepthBuffer : DEPTHBUFFER;
texture gTexture0 < string textureState="0,Texture"; >;
float3 gCameraPosition : CAMERAPOSITION;

//--------------------------------------------------------------------------------------
// Sampler Inputs
//--------------------------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

sampler SamplerDepth = sampler_state
{
    Texture = (gDepthBuffer);
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
};

//--------------------------------------------------------------------------------------
// Structure of data sent to the vertex shader
//--------------------------------------------------------------------------------------
struct VSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

//--------------------------------------------------------------------------------------
// Structure of data sent to the pixel shader ( from the vertex shader )
//--------------------------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float3 TexProj : TEXCOORD1;
    float2 MatDepth : TEXCOORD2;
};

//--------------------------------------------------------------------------------------
//-- Get value from the depth buffer
//-- Uses define set at compile time to handle RAWZ special case (which will use up a few more slots)
//--------------------------------------------------------------------------------------
float FetchDepthBufferValue( float2 uv )
{
    float4 texel = tex2D(SamplerDepth, uv);
#if IS_DEPTHBUFFER_RAWZ
    float3 rawval = floor(255.0 * texel.arg + 0.5);
    float3 valueScaler = float3(0.996093809371817670572857294849, 0.0038909914428586627756752238080039, 1.5199185323666651467481343000015e-5);
    return dot(rawval, valueScaler / 255.0);
#else
    return texel.r;
#endif
}
 
//--------------------------------------------------------------------------------------
//-- Use the last scene projecion matrix to linearize the depth value a bit more
//--------------------------------------------------------------------------------------
float Linearize(float posZ)
{
    return gProjection[3][2] / (posZ - gProjection[2][2]);
}

//--------------------------------------------------------------------------------------
//-- Use the last scene projecion matrix to transform linear depth to logarithmic
//--------------------------------------------------------------------------------------
float InvLinearize(float posZ)
{
    return (gProjection[3][2] / posZ) + gProjection[2][2];
}

//--------------------------------------------------------------------------------------
// Get soft particle spread 
//--------------------------------------------------------------------------------------
float countDepthSpread(float sceneDepth, float pixelDepth, float depthSpread, float attenuationPower)
{
    if (pixelDepth > sceneDepth) 
        return pow(saturate((sceneDepth - (pixelDepth - depthSpread)) / depthSpread), attenuationPower); 
    else
        return 1;
}

//--------------------------------------------------------------------------------------
// VertexShaderFunction
//--------------------------------------------------------------------------------------
PSInput VertexShaderFunctionDB(VSInput VS)
{
    PSInput PS = (PSInput)0;

    float4 worldPos = mul(float4(VS.Position.xyz, 1.0), gWorld);
    float4 viewPos = mul(worldPos, gView);

    PS.MatDepth = float2(viewPos.z, viewPos.w);
	
    PS.Position = mul(viewPos, gProjection);
    float linDepth = viewPos.z / viewPos.w;
    float depthBias = InvLinearize(linDepth) - InvLinearize(linDepth - fDepthAttenuation);
    PS.Position.z -= depthBias * PS.Position.w;
    PS.Position.z = max(InvLinearize(Linearize(0)) * PS.Position.w, PS.Position.z);
	
    PS.TexCoord = VS.TexCoord;
    PS.Diffuse = VS.Diffuse;

    float projectedX = (0.5 * (PS.Position.w + PS.Position.x));
    float projectedY = (0.5 * (PS.Position.w - PS.Position.y));
    PS.TexProj = float3(projectedX, projectedY, PS.Position.w);
	
    return PS;
}

//--------------------------------------------------------------------------------------
// PixelShaderFunction
//--------------------------------------------------------------------------------------
float4 PixelShaderFunctionDB(PSInput PS) : COLOR0
{
    float2 TexProj = PS.TexProj.xy / PS.TexProj.z;
    TexProj += sPixelSize.xy * 0.5;
	
    float pixelDepth = (PS.MatDepth.x / PS.MatDepth.y);
    float BufferValue = FetchDepthBufferValue(TexProj);
    float depth = Linearize(BufferValue);
	
    float depthMul = countDepthSpread(depth, pixelDepth, fDepthAttenuation, fDepthAttenuationPower);
    float4 finalColor = tex2D(Sampler0 ,PS.TexCoord);
    finalColor *= PS.Diffuse;
    finalColor.a *= depthMul;
	
    return saturate(finalColor);
}

//--------------------------------------------------------------------------------------
// Techniques
//--------------------------------------------------------------------------------------
technique soft_particles
{
    pass P0
    {
        //VertexShader = compile vs_2_0 VertexShaderFunctionDB();
        //PixelShader = compile ps_2_0 PixelShaderFunctionDB();
        ZEnable = true;
        ZFunc = LessEqual;
        ZWriteEnable = false;
        CullMode = 1;
        ColorVertex = true;
        ShadeMode = Gouraud;
        AlphaBlendEnable = true;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        AlphaTestEnable = true;
        AlphaRef = 1;
        AlphaFunc = GreaterEqual;
        Lighting = false;
        FogEnable = false;
    }
}

// Fallback
technique fallback
{
    pass P0
    {
        // Just draw normally
    }
}
