struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float3 TexProj : TEXCOORD1;
    float2 MatDepth : TEXCOORD2;
};
texture gTexture0 < string textureState="0,Texture"; >;

sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

float4 PSMain(PSInput PS) : COLOR
{
    //float4 finalColor = tex2D(Sampler0, PS.TexCoord);
    //finalColor *= PS.Diffuse;
    float4 finalColor = PS.Diffuse;
    finalColor.a = 0.1;
    return saturate(finalColor);
}


technique soft_particles
{
  
    pass P0
    {
        PixelShader = compile ps_2_0 PSMain();

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
