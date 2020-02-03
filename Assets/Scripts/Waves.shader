

Shader "Custom/Waves"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _DeepWaterColor ("_DeepWaterColor", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0
        _Metallic ("Metallic", Range(0,1)) = 0
        _Tess ("Tessellation", Range(1,32)) = 4
        _DeepArea("DeepArea", Range(0,1)) = 0
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1
        _WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
        _WaveB ("Wave B", Vector) = (0,1,0.25,20)
        _WaveC ("Wave C", Vector) = (1,1,0.15,10)
        _BumpTex("Bump Tex", 2D) = "white" {}
        _BumpAngle("BumpAngle factor", Vector) = (0,0,0,0)
        _RefractionTex("Refraction map", 2D) = "white" {}
        _FogFactor("Fog factor", Range(0, 1)) = 0.15
        _RefractionFactor("RefractionFactor factor", Range(0, 5)) = 0.15
        _FoamColor ("FoamColor", Color) = (1,1,1,1)
        _FoamTex("Foam Texture", 2D) = "white" {}
        _FoamProperties("Speed X, Speed Y, Height Threadshold, Cutoff", Vector) = (0,0,0,0)
        _FoamNoise("Foam Noise", 2D) = "white" {}
        _FoamNoiseProperty("Noise Property(DirX, DirY, Max, Min)", Vector) = (0,0,1,0)
        [Toggle] _EnableFoam("Enable Foam", Float) = 1
        _debugDepth("_debugDepth factor", Range(0, 15)) = 0
        _EmissionFactor("Emission factor", Range(0, 1)) = 0
        _FrenselFactor("Frensel factor", Range(0, 1)) = 0
        [Toggle] _EnableReflection("Enable Reflection", Float) = 1
        _ReflectionFactor("Reflection factor", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparent" 
            "Queue" = "Transparent"
            "ForceNoShadowCasting"="True"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        LOD 200

        GrabPass {"_WaterBackground"}

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard vertex:vert alpha tessellate:tessDistance

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        #pragma shader_feature _ENABLEFOAM_ON
        #pragma shader_feature _ENABLEREFLECTION_ON
        #include "Tessellation.cginc"

        sampler2D _MainTex;
        sampler2D _FoamNoise;
        float4 _FoamNoise_TexelSize;
        sampler2D _RefractionTex;
        sampler2D _FoamTex;
        sampler2D _BumpTex;
        sampler2D _ReflectionTex;

        float4 _BumpTex_ST;
        float4 _FoamTex_ST;

        struct appdata {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_FoamNoise;
            float2 uv_RefractionTex;
            float4 screenPos;
            float3 worldNormal;
            float3 worldPos;
            float3 viewDir;
            float3 worldRefl; INTERNAL_DATA
        };

        half _Glossiness; 
        half _Metallic;
        fixed4 _Color;
        fixed4 _DeepWaterColor;
        float _Tess;
        float4 _WaveA, _WaveB, _WaveC;
        float _DepthMaxDistance;
        float _FoamLength;
        float4 _FoamNoiseProperty;
        float _FoamNoiseCutoff;
        float _FogFactor;
        float _RefractionFactor;
        float _debugDepth;
        float _DeepArea;
        float4 _FoamProperties;
        float4 _BumpAngle;
        float _FrenselFactor;
        float4 _FoamColor;
        float _EmissionFactor;
        float _ReflectionFactor;

        float4 _CameraDepthTexture_TexelSize;

        sampler2D _CameraDepthTexture, _WaterBackground;

        float4 tessDistance (appdata v0, appdata v1, appdata v2) {
            float minDist = 10.0;
            float maxDist = 100.0;
            return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
        }

        void ResetAlpha (Input IN, SurfaceOutputStandard o, inout fixed4 color) {
            color.a = 1;
        }

        float3 GerstnerWave (
        float4 wave, float3 p, inout float3 tangent, inout float3 binormal
        ) {
            float steepness = wave.z;
            float wavelength = wave.w;
            float k = 2 * UNITY_PI / wavelength;
            float c = sqrt(9.8 / k);
            float2 d = normalize(wave.xy);
            float f = k * (dot(d, p.xz) - c * _Time.y);
            float a = steepness / k;

            tangent += float3(
            -d.x * d.x * (steepness * sin(f)),
            d.x * (steepness * cos(f)),
            -d.x * d.y * (steepness * sin(f))
            );
            binormal += float3(
            -d.x * d.y * (steepness * sin(f)),
            d.y * (steepness * cos(f)),
            -d.y * d.y * (steepness * sin(f))
            );
            return float3(
            d.x * (a * cos(f)),
            a * sin(f),
            d.y * (a * cos(f))
            );
        }

        void vert(inout appdata vertexData) {
            float3 gridPoint = vertexData.vertex.xyz;
            float3 tangent = float3(1, 0, 0);
            float3 binormal = float3(0, 0, 1);
            float3 p = gridPoint;
            float remainZ = 1-(_WaveA.z+_WaveB.z+_WaveC.z);


            p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
            p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
            p += GerstnerWave(_WaveC, gridPoint, tangent, binormal);
            
            float4 waveAA = float4(float2(-_WaveA.x, 0), 0.1, _WaveA.w*3);
            p += GerstnerWave(waveAA, gridPoint, tangent, binormal);
            float4 waveBB = float4(float2(-_WaveA.x, -_WaveA.y), 0.1, _WaveA.w*2);
            p += GerstnerWave(waveBB, gridPoint, tangent, binormal);
            float4 waveCC = float4(float2(0, -_WaveA.y), 0.05, _WaveA.w);
            p += GerstnerWave(waveCC, gridPoint, tangent, binormal);
            
            float3 normal = normalize(cross(binormal, tangent));
            vertexData.normal = normal;
            vertexData.vertex.xyz = p;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)).r;
            // Convert the depth from non-linear 0...1 range to linear
            // depth, in Unity units.
            float existingDepthLinear = LinearEyeDepth(existingDepth01);
            // Difference, in Unity units, between the water's surface and the object behind it.
            float depthDifference = existingDepthLinear - IN.screenPos.w;
            float DepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
            float3 objectPos = IN.worldPos - mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;
            float height01 = saturate( objectPos.y/_debugDepth - _DeepArea + (1-DepthDifference01) );

            //surface normal map
            const float2 v0 = float2(0.94, 0.34), v1 = float2(-0.85, -0.53);
            //const float lodDataGridSize = _GeomData.x;
            float nstretch = _BumpTex_ST.xy * 100; // normals scaled with geometry
            const float spdmulL = _BumpAngle.w;
            half2 norm =
            UnpackNormal(tex2D(_BumpTex, (v0*_Time.y*spdmulL + IN.worldPos.xz) / nstretch)).xy +
            UnpackNormal(tex2D(_BumpTex, (v1*_Time.y*spdmulL + IN.worldPos.xz) / nstretch)).xy;
            o.Normal.xz += norm*_BumpAngle.x;
            normalize(o.Normal);
            //surface normal map end

            //surface refraction map
            float2 displaceUv = float2((IN.uv_RefractionTex.x + _Time.y *0.2), (IN.uv_RefractionTex.y + _Time.y *0.2));
            float displace = tex2D(_RefractionTex, displaceUv).r * 2 - 1;
            //surface refraction map end

            //surface reflection
            float3 worldRefl = WorldReflectionVector (IN, o.Normal);
            float4 reflData =  UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);
            //float reflectFactor = saturate(pow(1.0 - (saturate (dot (normalize (IN.viewDir), o.Normal))), 4));
            float reflectFactor = 1-saturate (pow(dot (normalize (IN.viewDir), o.Normal),1));
            float4 specReflColor = float4(DecodeHDR(reflData, unity_SpecCube0_HDR)*reflectFactor, 1);
            ///surface reflection end

            //surface color
            fixed4 surfaceWaterColor = lerp(_DeepWaterColor, _Color, saturate(height01));
            //surface color end

            //refraction start
            float2 uvOffset = displace * (_RefractionFactor);
            if(depthDifference < 0)
            {
                uvOffset*=0;
            }   
            float2 grabUv = (IN.screenPos.xy + uvOffset * 0.1) / IN.screenPos.w;
            fixed4 underWaterColor = saturate(_FogFactor * (1-DepthDifference01)) * tex2D(_WaterBackground, grabUv);
            //refraction end

            //final color
            underWaterColor = saturate(underWaterColor * _Color);
            surfaceWaterColor = lerp(surfaceWaterColor, specReflColor*0.8, saturate(reflectFactor));
            #if _ENABLEREFLECTION_ON
                fixed4 reflColor = tex2D(_ReflectionTex, IN.screenPos.xy / IN.screenPos.w);
                surfaceWaterColor = lerp(surfaceWaterColor, reflColor, saturate(_ReflectionFactor-height01));
            #endif
            float surfacePercent = saturate(reflectFactor + _FrenselFactor);
            float4 finalColor =  surfaceWaterColor * surfacePercent + underWaterColor * (1 - surfacePercent);
            //final color end

            //shoreline start
            fixed4 shorelineTex = tex2D(_FoamTex, IN.worldPos.xz*_FoamTex_ST.xy + sin(_Time.y) * _FoamProperties.xy);
            float foamDiff = saturate((existingDepthLinear - IN.screenPos.w) / 1);
            float shoreFoam = saturate(shorelineTex - smoothstep(_FoamProperties.z + _FoamProperties.w, _FoamProperties.z, (1-foamDiff)));
            saturate(finalColor += shoreFoam);
            //shoreline end

            #if _ENABLEFOAM_ON
                fixed4 noiseSample = tex2D(_FoamNoise, float4(IN.worldPos.xz,0,0) * 0.05 + sin(_Time.y) * (_FoamNoiseProperty.xy)).r * 2 - 1;
                //foam start
                fixed4 foamTex = fixed4(_FoamColor.rgb, tex2D(_FoamTex, IN.worldPos.xz * _FoamTex_ST.xy+ _Time.y * _FoamNoiseProperty.xy).r);
                float a = 2 * UNITY_PI / _WaveA.w;
                foamTex.a *= saturate(smoothstep(0.2,1, (objectPos.y/(_WaveA.z/a))));
                finalColor = lerp(finalColor, foamTex, saturate(foamTex.a*(noiseSample+_FoamNoiseProperty.w)));
                //foam end
            #endif

            o.Albedo = saturate(finalColor);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness * foamDiff;
            o.Alpha =1;
            o.Emission = reflData.rgb * _EmissionFactor;
            //o.Alpha = reflData.a;
        }
        ENDCG
    }
    FallBack "Standard"  
}
