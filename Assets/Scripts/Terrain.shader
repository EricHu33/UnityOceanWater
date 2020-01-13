Shader "Custom/Terrain"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
        #pragma exclude_renderers d3d11 gles
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        const static int maxColorCount = 8;
        float3 tintColors[maxColorCount];
        float baseStartHeights[maxColorCount];
        float baseBlends[maxColorCount];
        int baseColorCount;
        float minHeight;
        float maxHeight;

        sampler2D texture1[maxColorCount];
        float baseTextureScales[maxColorCount];
        UNITY_DECLARE_TEX2DARRAY(baseTextures);

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            float3 worldNormal;
        };

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float InverseLerp(float a, float b, float value)
        {
            return saturate((value-a)/(b-a));
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float heightPercent = InverseLerp(minHeight, maxHeight, IN.worldPos.y);
            for(int i=0; i < baseColorCount; i++)
            {
                float drawStrength =  InverseLerp(-baseBlends[i]/2, baseBlends[i]/2, heightPercent - baseStartHeights[i]);

                float3 scaledWorldPos = IN.worldPos/baseTextureScales[i];
                float3 blendAxes = abs(IN.worldNormal);
                blendAxes /= (blendAxes.x + blendAxes.y + blendAxes.z);
                float3 xProj = UNITY_SAMPLE_TEX2DARRAY(baseTextures, float3(scaledWorldPos.y, scaledWorldPos.z, i)) * blendAxes.x;
                float3 yProj = UNITY_SAMPLE_TEX2DARRAY(baseTextures, float3(scaledWorldPos.x, scaledWorldPos.z, i)) * blendAxes.y;
                float3 zProj = UNITY_SAMPLE_TEX2DARRAY(baseTextures, float3(scaledWorldPos.x, scaledWorldPos.y, i)) * blendAxes.z;
                float3 textureColor = (xProj+yProj+zProj); 

                o.Albedo = o.Albedo * (1-drawStrength) + tintColors[i] * textureColor * drawStrength;
            }
        }
        ENDCG
    }
    FallBack "Diffuse"
}
