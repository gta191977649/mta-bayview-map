//-----------------------------------------------------------------------------
// Techniques
//-----------------------------------------------------------------------------
technique building
{
    pass P0
    {
 
        ShadeMode = Gouraud;
        AlphaBlendEnable = true;
        CullMode = 0;
        AlphaRef = 2;
        AlphaFunc = 7;
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
