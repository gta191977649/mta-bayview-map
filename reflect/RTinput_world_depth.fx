//
// RTinput_world_depth.fx
//

//------------------------------------------------------------------------------------------
// Settings
//------------------------------------------------------------------------------------------
bool sDisableNormals = false;
float sStrength = 1;
float2 sHalfPixel = float2(0.000625,0.00083);

//------------------------------------------------------------------------------------------
// Include some common stuff
//------------------------------------------------------------------------------------------
//#define GENERATE_NORMALS      // Uncomment for normals to be generatedk
float4x4 gProjectionMainScene : PROJECTION_MAIN_SCENE;
#include "mta-helper.fx"

//------------------------------------------------------------------------------------------
// Render targets
//------------------------------------------------------------------------------------------
texture depthRT < string renderTarget = "yes"; >;
texture maskRT < string renderTarget = "yes"; >;

//------------------------------------------------------------------------------------------
// Sampler for the main texture
//------------------------------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

//------------------------------------------------------------------------------------------
// Structure of data sent to the vertex shader
//------------------------------------------------------------------------------------------
struct VSInput
{
  float3 Position : POSITION0;
  float4 Diffuse : COLOR0;
  float3 Normal : NORMAL0;
  float2 TexCoord : TEXCOORD0;
  float2 TexCoord1 : TEXCOORD1;
};

//------------------------------------------------------------------------------------------
// Structure of data sent to the pixel shader ( from the vertex shader )
//------------------------------------------------------------------------------------------
struct PSInput
{
  float4 Position : POSITION0;
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
  float3 TexProj : TEXCOORD1;
  float4 Depth : TEXCOORD2;
}; 

//------------------------------------------------------------------------------------------
// VertexShaderFunction
//------------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    // Pass through tex coord
    PS.TexCoord = VS.TexCoord;
	
    // Calculate screen pos of vertex	
    float4 worldPos = mul(float4(VS.Position.xyz,1) , gWorld);	
    float4 viewPos = mul(worldPos, gView);
    float4 projPos = mul(viewPos, gProjection);
    PS.Position = projPos;
	
    // set texCoords for projective texture
    float projectedX = (0.5 * (PS.Position.w + PS.Position.x));
    float projectedY = (0.5 * (PS.Position.w - PS.Position.y));
    PS.TexProj.xyz = float3(projectedX, projectedY, PS.Position.w); 
	
    // Pass depth
    PS.Depth = float4(viewPos.z, viewPos.w, projPos.z, projPos.w);

    // Calculate GTA lighting for Buildings
    PS.Diffuse = MTACalcGTABuildingDiffuse(VS.Diffuse);
    return PS;
}

//------------------------------------------------------------------------------------------
// Structure of color data sent to the renderer ( from the pixel shader  )
//------------------------------------------------------------------------------------------
struct Pixel
{
    float4 World : COLOR0;      // Render target #0
    float4 Depth : COLOR1;      // Render target #1
    float4 Mask : COLOR2;
};

//------------------------------------------------------------------------------------------
// PixelShaderFunction
//------------------------------------------------------------------------------------------
Pixel PixelShaderFunction(PSInput PS)
{
    Pixel output;

    // get projective texture coords
    float2 TexProj = PS.TexProj.xy / PS.TexProj.z;
    TexProj += sHalfPixel.xy;
	
    // Get texture pixel
    float4 texel = tex2D(Sampler0, PS.TexCoord);

    // Apply diffuse lighting
    float4 finalColor = float4(texel.rgb, 1) * PS.Diffuse;
    float linDist = PS.Depth.x / PS.Depth.y;
    finalColor.rgb = MTAApplyFog(finalColor.rgb, linDist);
    float logDist = PS.Depth.z / PS.Depth.w;

    output.Depth = float4(logDist,1,1,1);
    output.Mask = float4(texel.a * sStrength,1,1,texel.a * sStrength);
	output.World = saturate(finalColor);

    return output;
}

//------------------------------------------------------------------------------------------
// Techniques
//------------------------------------------------------------------------------------------
technique RTinput_world_depth
{
    pass P0
    {
        SRGBWriteEnable = false;
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PixelShaderFunction();
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