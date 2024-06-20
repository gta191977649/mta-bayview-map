//--------------------------------------------------------------------------------------
// Global variables
//--------------------------------------------------------------------------------------
float gTime : TIME; // Time variable to control the alpha animation
float gMinFade = 0.1; // Minimum alpha value, adjustable
float gFadeSpeed = 1;
texture gTexture0 < string textureState="0,Texture"; >;

sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

//--------------------------------------------------------------------------------------
// Structures for Input and Output of Vertex and Pixel Shaders
//--------------------------------------------------------------------------------------
struct VSInput
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
};

struct PSInput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput input)
{
    PSInput output;
    output.Position = input.Position; // Pass through position
    output.TexCoord = input.TexCoord; // Pass through texture coordinates
    return output;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PixelShaderFunction(PSInput input) : SV_TARGET
{
    // Adjust alpha to oscillate between 0.5 and 1.0
    float alpha = (1.0 - gMinFade) * 0.5 * sin(gTime * gFadeSpeed) + 0.5 * (1.0 + gMinFade);
    float4 color = tex2D(Sampler0, input.TexCoord); // Sample the texture
    color.a *= alpha; // Apply the calculated alpha to the texture's alpha
    return saturate(color); // Ensure the color values are clamped between 0 and 1
}

//--------------------------------------------------------------------------------------
// Techniques
//--------------------------------------------------------------------------------------
technique FadeTechnique
{
    pass P0
    {
        //SetVertexShader(compile vs_3_0 VertexShaderFunction());
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
        FogEnable = true;
        SetPixelShader(compile ps_2_0 PixelShaderFunction());
    }
}
