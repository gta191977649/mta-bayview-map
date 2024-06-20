float lighting = 1.5;

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

struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float4 C2 : COLOR1;
    float2 TexCoord : TEXCOORD0;
    float3 TexProj : TEXCOORD1;
    float2 MatDepth : TEXCOORD2;
};
float4 PSFunction(PSInput PS) : COLOR0
{

    float4 Tex = tex2D(Sampler0, float2( PS.TexCoord.xy ));
   
    Tex *= PS.Diffuse;

    return saturate(Tex);
}


//-----------------------------------------------------------------------------
// Techniques
//-----------------------------------------------------------------------------
technique custom_corona0
{
    pass P0
    {
        CullMode = 1;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        
        AlphaBlendEnable = true;
        Lighting = false;
		AlphaRef = 1;
        AlphaFunc = GREATER;
        FogEnable = false;
        //PixelShader = compile ps_2_0 PSFunction();
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
