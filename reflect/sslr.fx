//
// file: sslr.fx
// version: v1.5
//

//--------------------------------------------------------------------------------------
// Settings
//--------------------------------------------------------------------------------------
float3 sElementPosition = float3(0, 0, 0);
float2 fViewportSize = float2(800, 600);
float2 fViewportScale = float2(1, 1);
float2 fViewportPos = float2(0, 0);

float2 sPixelSize = float2(0.00125, 0.00166);
float4 sSkyColor = float4(0,0,0,0);

texture sColorTex;
texture sDepthTex;
texture sMaskTex;
texture sVignetTex;

//--------------------------------------------------------------------------------------
// Variables set by MTA
//--------------------------------------------------------------------------------------
texture gDepthBuffer : DEPTHBUFFER;
float4x4 gProjectionMainScene : PROJECTION_MAIN_SCENE;
float4x4 gViewMainScene : VIEW_MAIN_SCENE;
float4x4 gWorldViewProjection : WORLDVIEWPROJECTION;
int CUSTOMFLAGS < string skipUnusedParameters = "yes"; >;

//--------------------------------------------------------------------------------------
// Sampler 
//--------------------------------------------------------------------------------------
sampler SamplerTex = sampler_state 
{
    Texture = (sColorTex);
    AddressU = Border;
    AddressV = Border;
	BorderColor = float4(0,0,0,0);
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler SamplerDepthTex = sampler_state
{
    Texture = (sDepthTex);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler SamplerMaskTex = sampler_state
{
    Texture = (sMaskTex);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler VignetTex = sampler_state 
{
    Texture = (sVignetTex);
    AddressU = Border;
    AddressV = Border;
	BorderColor = float4(0,0,0,0);
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler SamplerDepth = sampler_state
{
    Texture = (gDepthBuffer);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

//--------------------------------------------------------------------------------------
// Structures
//--------------------------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse : COLOR0;
};

struct PSInput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float2 PixPos : TEXCOORD1;
    float4 UvToView : TEXCOORD2;
    float4 Diffuse : COLOR0;
};

//--------------------------------------------------------------------------------------
// Returns a translation matrix
//--------------------------------------------------------------------------------------
float4x4 makeTranslation( float3 trans) 
{
    return float4x4(
     1,  0,  0,  0,
     0,  1,  0,  0,
     0,  0,  1,  0,
     trans.x, trans.y, trans.z, 1
    );
}

//--------------------------------------------------------------------------------------
// Creates projection matrix of a shadered dxDrawImage
//--------------------------------------------------------------------------------------
float4x4 createImageProjectionMatrix(float2 viewportPos, float2 viewportSize, float2 viewportScale, float adjustZFactor, float nearPlane, float farPlane)
{
    float Q = farPlane / ( farPlane - nearPlane );
    float rcpSizeX = 2.0f / viewportSize.x;
    float rcpSizeY = -2.0f / viewportSize.y;
    rcpSizeX *= adjustZFactor;
    rcpSizeY *= adjustZFactor;
    float viewportPosX = 2 * viewportPos.x;
    float viewportPosY = 2 * viewportPos.y;
	
    float4x4 sProjection = {
        float4(rcpSizeX * viewportScale.x, 0, 0,  0), float4(0, rcpSizeY * viewportScale.y, 0, 0), float4(viewportPosX, -viewportPosY, Q, 1),
        float4(( -viewportSize.x / 2.0f - 0.5f ) * rcpSizeX,( -viewportSize.y / 2.0f - 0.5f ) * rcpSizeY, -Q * nearPlane , 0)
    };

    return sProjection;
}

//--------------------------------------------------------------------------------------
// Vertex Shader 
//--------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    VS.Position.xyz = float3(VS.TexCoord.xy, 0);
	
    // resize
    VS.Position.xy *= fViewportSize;

    // create projection matrix (as done for shadered dxDrawImage)
    float4x4 sProjection = createImageProjectionMatrix(fViewportPos, fViewportSize, fViewportScale, 1000, 100, 10000);
	
    // calculate screen position of the vertex
    float4 viewPos = mul(float4(VS.Position.xyz, 1), makeTranslation(float3(0,0, 1000.5)));
    PS.Position = mul(viewPos, sProjection);

    // pass texCoords
    PS.TexCoord = VS.TexCoord;
	
    // pass screen position to be used in PS
    PS.PixPos = VS.Position.xy;
	
    // pass vertex color to PS
    PS.Diffuse = VS.Diffuse;
	
    // calculations for perspective-correct position recontruction
    float2 uvToViewADD = - 1 / float2(gProjectionMainScene[0][0], gProjectionMainScene[1][1]);	
    float2 uvToViewMUL = -2.0 * uvToViewADD.xy;
    PS.UvToView = float4(uvToViewMUL, uvToViewADD);
	
    return PS;
}

//------------------------------------------------------------------------------------------
// Inverse matrix
//------------------------------------------------------------------------------------------
float4x4 inverseMatrix(float4x4 input)
{
     #define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
     
     float4x4 cofactors = float4x4(
          minor(_22_23_24, _32_33_34, _42_43_44), 
         -minor(_21_23_24, _31_33_34, _41_43_44),
          minor(_21_22_24, _31_32_34, _41_42_44),
         -minor(_21_22_23, _31_32_33, _41_42_43),
         
         -minor(_12_13_14, _32_33_34, _42_43_44),
          minor(_11_13_14, _31_33_34, _41_43_44),
         -minor(_11_12_14, _31_32_34, _41_42_44),
          minor(_11_12_13, _31_32_33, _41_42_43),
         
          minor(_12_13_14, _22_23_24, _42_43_44),
         -minor(_11_13_14, _21_23_24, _41_43_44),
          minor(_11_12_14, _21_22_24, _41_42_44),
         -minor(_11_12_13, _21_22_23, _41_42_43),
         
         -minor(_12_13_14, _22_23_24, _32_33_34),
          minor(_11_13_14, _21_23_24, _31_33_34),
         -minor(_11_12_14, _21_22_24, _31_32_34),
          minor(_11_12_13, _21_22_23, _31_32_33)
     );
     #undef minor
     return transpose(cofactors) / determinant(input);
}

//-----------------------------------------------------------------------------
//-- Get value from the depth buffer
//-- Uses define set at compile time to handle RAWZ special case (which will use up a few more slots)
//-----------------------------------------------------------------------------
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
//-- Use the last scene projecion matrix to linearize the depth (to world units)
//--------------------------------------------------------------------------------------
float Linearize(float posZ)
{
    return gProjectionMainScene[3][2] / (posZ - gProjectionMainScene[2][2]);
}

//--------------------------------------------------------------------------------------
//-- Use the last scene projecion matrix to transform linear depth to logarithmic
//--------------------------------------------------------------------------------------
float InvLinearize(float posZ)
{
    return (gProjectionMainScene[3][2] / posZ) + gProjectionMainScene[2][2];
}

//--------------------------------------------------------------------------------------
//-- Use the last scene projecion matrix to linearize the depth (0-1)
//--------------------------------------------------------------------------------------
float LinearizeToFloat(float posZ)
{
    return (1 - gProjectionMainScene[2][2])/ (posZ - gProjectionMainScene[2][2]);
}

//--------------------------------------------------------------------------------------
// GetPositionFromDepth
//--------------------------------------------------------------------------------------
float3 GetPositionFromDepth(float2 coords, float4 uvToView)
{
    return float3(coords.x * uvToView.x + uvToView.z, (1 - coords.y) * uvToView.y + uvToView.w, 1.0) 
        * Linearize(FetchDepthBufferValue(coords.xy));
}

//--------------------------------------------------------------------------------------
//  Calculates normals based on partial depth buffer derivatives.
//--------------------------------------------------------------------------------------
float3 GetNormalFromDepth(float2 coords, float4 uvToView)
{
    float3 offs = float3(sPixelSize.xy, 0);

    float3 f = GetPositionFromDepth(coords.xy, uvToView);
    float3 d_dx1 = - f + GetPositionFromDepth(coords.xy + offs.xz, uvToView);
    float3 d_dx2 =   f - GetPositionFromDepth(coords.xy - offs.xz, uvToView);
    float3 d_dy1 = - f + GetPositionFromDepth(coords.xy + offs.zy, uvToView);
    float3 d_dy2 =   f - GetPositionFromDepth(coords.xy - offs.zy, uvToView);

    d_dx1 = lerp(d_dx1, d_dx2, abs(d_dx1.z) > abs(d_dx2.z));
    d_dy1 = lerp(d_dy1, d_dy2, abs(d_dy1.z) > abs(d_dy2.z));

    return (normalize(cross(d_dy1, d_dx1)));
}

//------------------------------------------------------------------------------------------
// ComputeNormalsPS
//------------------------------------------------------------------------------------------
float3 ComputeNormalsPS(sampler2D sample, float2 texCoord, float4 lightness, float2 tSize)
{
    float2 off = 1.0 /  tSize;

    // Take all neighbor samples
    float4 s00 = tex2D(sample, texCoord + float2(-off.x, -off.y));
    float4 s01 = tex2D(sample, texCoord + float2( 0,   -off.y));
    float4 s02 = tex2D(sample, texCoord + float2( off.x, -off.y));

    float4 s10 = tex2D(sample, texCoord + float2(-off.x,  0));
    float4 s12 = tex2D(sample, texCoord + float2( off.x,  0));

    float4 s20 = tex2D(sample, texCoord + float2(-off.x,  off.y));
    float4 s21 = tex2D(sample, texCoord + float2( 0,    off.y));
    float4 s22 = tex2D(sample, texCoord + float2( off.x,  off.y));

    // Slope in X direction
    float4 sobelX = s00 + 2 * s10 + s20 - s02 - 2 * s12 - s22;
    // Slope in Y direction
    float4 sobelY = s00 + 2 * s01 + s02 - s20 - 2 * s21 - s22;

    // Weight the slope in all channels, we use grayscale as height
    float sx = dot(sobelX, lightness);
    float sy = dot(sobelY, lightness);

    // Compose the normal
    float3 normal = normalize(float3(sx, sy, 1));

    // Pack [-1, 1] into [0, 1]
    return float3(normal * 0.5 + 0.5);
}

//------------------------------------------------------------------------------------------
// Calculates UVs based on world position
//------------------------------------------------------------------------------------------
float3 GetUV(float3 position, float4x4 ViewProjection)
{
    float4 pVP = mul(float4(position, 1.0f), ViewProjection);
    pVP.xy = float2(0.5f, 0.5f) + float2(0.5f, -0.5f) * pVP.xy / pVP.w;
    return float3(pVP.xy, pVP.z / pVP.w);
}

//------------------------------------------------------------------------------------------
// Calculate pixel position
//------------------------------------------------------------------------------------------
float3 GetPositionFromDepthValue(float2 UV, float depth, float4x4 g_matInvProjection)
{
    float4 position = 1.0f; 
    position.x = UV.x * 2.0f - 1.0f; 
    position.y = -(UV.y * 2.0f - 1.0f); 
    position.z = depth; 
    position = mul(position, g_matInvProjection); 
    position /= position.w;
    return position.xyz;
}

//--------------------------------------------------------------------------------------
// Pixel shaders 
//--------------------------------------------------------------------------------------
float4 PixelShaderFunctionAO(PSInput PS) : COLOR0
{
    // don't draw over far clip distance
    float BufferValue = FetchDepthBufferValue(PS.TexCoord.xy);
    if (BufferValue > 0.9999) return 0;
    float4 depthTex = tex2D(SamplerDepthTex , PS.TexCoord.xy);
    if (((depthTex.r - BufferValue) > 0.0001f) || (depthTex.r == 0)) return 0;
	
    // recreate needed matrices
    float4x4 sViewProjection = mul(gViewMainScene, gProjectionMainScene);
    float4x4 sProjectionInverse = inverseMatrix(gProjectionMainScene);
    float4x4 sViewInverse = inverseMatrix(gViewMainScene);
	
    // get camera position and direction
    float3 sCameraDirection = sViewInverse[2].xyz;
    float3 sCameraPosition = sViewInverse[3].xyz;
	
    // recreate world position from pixel depth
    float3 viewPos = GetPositionFromDepth(PS.TexCoord, PS.UvToView);
    float3 worldPos = mul(float4(viewPos.xyz, 1), sViewInverse);
	
    // recreate world normal from pixel depth
    float3 viewNormal = GetNormalFromDepth(PS.TexCoord, PS.UvToView);	
    float3 worldNormal = mul(-viewNormal.xyz, (float3x3)sViewInverse).xyz;

    // get view direction
    float3 viewDir = normalize(worldPos.xyz - sCameraPosition);

    // create scene normal (using sobel filter)
    //float4 texel = tex2D(SamplerTex, PS.TexCoord.xy);
    //float3 tenNorm = ComputeNormalsPS(SamplerTex, PS.TexCoord.xy, texel, fViewportSize); 
    //tenNorm = (tenNorm - 0.5) * 2;
	
    // get Mask 
    float4 maskTex = tex2D(SamplerMaskTex, PS.TexCoord.xy);
	
    // add normalTexture intensivity variation based on distance
    //float linDepth = saturate(pow(4 / Linearize(BufferValue), 2));
    //worldNormal += tenNorm * maskTex.g * saturate(linDepth);
    //worldNormal = lerp(worldNormal, float3(0, 0, 1), 0);
	
    // source //https://habrahabr.ru/post/244367/

    // get reflection vector
    float3 reflectDir = normalize(reflect(viewDir, worldNormal));

    float L = 0.1 * viewPos.z;
    float d = 1;
    float3 nuv = 0;
    float3 currentRay = 0;
	
    float LDelmiter = 0.005;
    float alpha = 1;

    // get reflected pixel UVs
    for(int i = 0; i < 20; i++)
    {
        currentRay = worldPos.xyz + reflectDir * L;

        nuv = GetUV(currentRay , sViewProjection);
        d = FetchDepthBufferValue(nuv.xy);
		
        float3 newPos = GetPositionFromDepthValue(nuv.xy, d, sProjectionInverse);
        newPos = mul(float4(newPos, 1), sViewInverse).xyz;
        L = length(worldPos.xyz - newPos);
    }
    L = saturate(L * LDelmiter);// alpha *= (1 - L);

    // clamp the UVs 
    if ((nuv.x > 1) || (nuv.x < 0) || (nuv.y > 1) || (nuv.y < 0)) alpha = 0;

    float3 cnuv = tex2D(SamplerTex, nuv.xy).rgb;
    float anuv = pow(saturate(1 - tex2D(VignetTex, nuv.xy).a), 3);

    // cut pixels closer to camera than the reflection surface
    if (d > 0.9999) alpha = 0;
    if (BufferValue > d) alpha = 0;
	
    // apply freshnel
    float fresnel = 1 - saturate(4 * dot(viewDir, -worldNormal));	
	
    // lerp and apply
    cnuv = lerp(saturate(sSkyColor.rgb * 1.25) * sSkyColor.a, cnuv.rgb, 0.0 + (alpha * anuv));
    alpha = saturate(fresnel * clamp(0, 1, worldNormal.z));
    alpha *= maskTex.r;

    return float4(cnuv, alpha );

}

//--------------------------------------------------------------------------------------
// Techniques
//--------------------------------------------------------------------------------------
technique dxDrawImage3D_sslr
{
  pass P0
  {
    ZEnable = false;
    ZWriteEnable = false;
    CullMode = 1;
    ShadeMode = Gouraud;
    AlphaBlendEnable = true;
    SrcBlend = SrcAlpha;
    DestBlend = InvSrcAlpha;
    AlphaTestEnable = false;
    AlphaRef = 1;
    AlphaFunc = GreaterEqual;
    Lighting = false;
    FogEnable = false;
    VertexShader = compile vs_3_0 VertexShaderFunction();
    PixelShader  = compile ps_3_0 PixelShaderFunctionAO();
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
	
