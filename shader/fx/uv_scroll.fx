int direction = 0; // 0 = UP, 1 = DOWN, 2 = LEFT, 3 = RIGHT
float speed = 1.0;

///////////////////////////////////////////////////////////////////////////////
// Global variables
///////////////////////////////////////////////////////////////////////////////
float gTime : TIME;
///////////////////////////////////////////////////////////////////////////////
// Functions
///////////////////////////////////////////////////////////////////////////////

//-------------------------------------------
// Returns UV anim transform based on direction
//-------------------------------------------
float3x3 getTextureTransform ()
{
    float posU = 0;
    float posV = 0;

    if (direction == 0) { // UP
        posV = -fmod(gTime * speed, 1); // Scroll upwards by decrementing V
    } else if (direction == 1) { // DOWN
        posV = fmod(gTime * speed, 1); // Scroll downwards by incrementing V
    } else if (direction == 2) { // LEFT
        posU = -fmod(gTime * speed, 1); // Scroll left by decrementing U
    } else if (direction == 3) { // RIGHT
        posU = fmod(gTime * speed, 1); // Scroll right by incrementing U
    }
    
    return float3x3(
                    1, 0, 0,
                    0, 1, 0,
                    posU, posV, 1
                    );
}

///////////////////////////////////////////////////////////////////////////////
// Techniques
///////////////////////////////////////////////////////////////////////////////
technique tec0
{
    pass P0
    {
        
        // Set the UV transformation based on direction
        TextureTransform[0] = getTextureTransform();

        // Enable texture transformation for two coordinates
        TextureTransformFlags[0] = Count2;
    }
}
