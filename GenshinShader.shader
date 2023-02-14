Shader "Toon/URP_Toon"
{
    Properties
    {
        [Header(Shader Setting)]
        [Space(5)]
        [KeywordEnum(Base,Hair,Face)] _ShaderEnum("Shader����",int) = 0
        [Toggle] _IsNight ("In Night", int) = 0
        [Space(5)]

        [Header(Main Texture Setting)]
        [Space(5)]
        [MainTexture] _MainTex ("Texture", 2D) = "white" {}
        [HDR][MainColor] _MainColor ("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Space(30)]

        [Header(Shadow Setting)]
        [Space(5)]
        _LightMap ("LightMap", 2D) = "grey" {}
        _RampMap ("RampMap", 2D) = "white" {}
        _ShadowSmooth ("Shadow Smooth", Range(0, 1)) = 0.5
        _RampShadowRange ("Ramp Shadow Range", Range(0.5, 1.0)) = 0.8
        _RangeAO ("AO Range", Range(1, 2)) = 1.5
        _ShadowColor ("Shadow Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Space(30)]

        [Header(Face Setting)]
        [Space(5)]
        _FaceShadowOffset ("Face Shadow Offset", range(0.0, 1.0)) = 0.1
        _FaceShadowPow ("Face Shadow Pow", range(0.001, 1)) = 0.1
        [Space(30)]

        [Header(Specular Setting)]
        [Space(5)]
        [Toggle] _EnableSpecular ("Enable Specular", int) = 1
        _MetalMap ("Metal Map", 2D) = "white" {}
        [HDR] _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _BlinnPhongSpecularGloss ("Blinn Phong Specular Gloss", Range(0.01, 10)) = 5
        _BlinnPhongSpecularIntensity ("Blinn Phong Specular Intensity", Range(0, 1)) = 1
        _StepSpecularGloss ("Step Specular Gloss", Range(0, 1)) = 0.5
        _StepSpecularIntensity ("Step Specular Intensity", Range(0, 1)) = 0.5
        _MetalSpecularGloss ("Metal Specular Gloss", Range(0, 1)) = 0.5
        _MetalSpecularIntensity ("Metal Specular Intensity", Range(0, 1)) = 1
        [Space(30)]

        [Header(Rim Setting)]
        [Space(5)]
        [Toggle] _EnableRim ("Enable Rim", int) = 1
        [HDR] _RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimOffset ("Rim Offset", Range(0, 0.5)) = 0.1    //��ϸ
        _RimThreshold ("Rim Threshold", Range(0, 2)) = 1  //ϸ�³̶�
        [Space(30)]

        [Header(Outline Setting)]
        [Space(5)]
        [Toggle] _EnableOutline ("Enable Outline", int) = 1
        _OutlineWidth ("Outline Width", Range(0, 4)) = 1
        _OutlineColor ("Outline Color", Color) = (0.5, 0.5, 0.5, 1)
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque"}

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #pragma shader_feature _SHADERENUM_BASE _SHADERENUM_HAIR _SHADERENUM_FACE

        int _IsNight;
        TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
        TEXTURE2D(_LightMap);           SAMPLER(sampler_LightMap);
        TEXTURE2D(_RampMap);            SAMPLER(sampler_RampMap);
        TEXTURE2D(_MetalMap);           SAMPLER(sampler_MetalMap);
        TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);

        // �������ʶ��еĲ����������� CBUFFER �У����������
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _MainColor;

        float4 _LightMap_ST;
        float4 _RampMap_ST;
        half _ShadowSmooth;
        half _RampShadowRange;
        half4 _ShadowColor;

        int _EnableSpecular;
        float4 _MetalMap_ST;
        half4 _SpecularColor;
        half _BlinnPhongSpecularGloss;
        half _BlinnPhongSpecularIntensity;
        half _StepSpecularGloss;
        half _StepSpecularIntensity;
        half _MetalSpecularGloss;
        half _MetalSpecularIntensity;

        float _FaceShadowOffset;
        float _FaceShadowPow;

        int _EnableRim;
        half4 _RimColor;
        half _RimOffset;
        half _RimThreshold;

        int _EnableOutline;
        half _OutlineWidth;
        half4 _OutlineColor;
        CBUFFER_END

        struct a2v{
            float3 vertex : POSITION;       //��������
            half4 color : COLOR0;           //����ɫ
            half3 normal : NORMAL;          //����
            half4 tangent : TANGENT;        //����
            float2 texCoord : TEXCOORD0;    //��������
        };
        struct v2f{
            float4 pos : SV_POSITION;              //�ü��ռ䶥������
            float2 uv : TEXCOORD0;              //uv
            float3 worldPos : TEXCOORD1;        //��������
            float3 worldNormal : TEXCOORD2;     //����ռ䷨��
            float3 worldTangent : TEXCOORD3;    //����ռ�����
            float3 worldBiTangent : TEXCOORD4;  //����ռ丱����
            half4 color : COLOR0;               //ƽ��Rim���趥��ɫ
        };
        ENDHLSL

        Pass
        {
            Tags {"LightMode"="UniversalForward" "RenderType"="Opaque"}
            
            HLSLPROGRAM
            #pragma vertex ToonPassVert
            #pragma fragment ToonPassFrag

            v2f ToonPassVert(a2v v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.texCoord, _MainTex);
                o.worldPos = TransformObjectToWorld(v.vertex);
                // ʹ��URP�Դ�������������ռ䷨��
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal, v.tangent);
                o.worldNormal = vertexNormalInput.normalWS;
                o.worldTangent = vertexNormalInput.tangentWS;
                o.worldBiTangent = vertexNormalInput.bitangentWS;
                o.color = v.color;
                return o;
            }

            half4 ToonPassFrag(v2f i) : SV_TARGET
            {   
                //lightmap��4��ͨ���ֱ��ǣ�r:�߹ⷶΧ��g:AO mask b:�߹�ǿ�� a:ramp��y����
                float4 BaseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _MainColor;
                float4 LightMapColor = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv);
                Light mainLight = GetMainLight();
                half4 LightColor = half4(mainLight.color, 1.0);
                half3 lightDir = normalize(mainLight.direction);
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 halfDir = normalize(viewDir + lightDir);

                //ʹ�ð������ز���ramp
                half halfLambert = dot(lightDir, i.worldNormal) * 0.5 + 0.5;

                //==========================================================================================
                // Base Ramp
                // ����ԭ����lambertֵ������0��һ����ֵ��smooth���䣬������һ��ֵ��ȫ������ramp���ұߵ���ɫ���Ӷ��γ�Ӳ��
                // ���ǵ���halfLambert
                halfLambert = smoothstep(0.0, _ShadowSmooth, halfLambert);

                // AO,������halfLambert
                float ShadowAO = smoothstep(0.1, LightMapColor.g,0.7);


                //����������ramp�����꣬x���갴��hanllambert,y���갴��aͨ���洢����ֵ
                float RampPixelX = 0.00195;  // = 1/256/2
                float RampPixelY = 0.02500;  //0.03125 = 1/20/2   ����������ramp���������м䣬�Ա��⾫�����
                float RampX, RampY;
                // ��X��һ��Clamp����ֹ�������߽�
                RampX = clamp(halfLambert*ShadowAO, RampPixelX, 1-RampPixelX);

                // �Ҷ�0.0-0.2  ӲRamp
                // �Ҷ�0.2-0.4  ��Ramp
                // �Ҷ�0.4-0.6  ������
                // �Ҷ�0.6-0.8  ���ϲ㣬��ҪΪsilk��
                // �Ҷ�0.8-1.0  Ƥ��/ͷ����
                // ��������ϰ룬���ϲ����°�

                //�� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� ��
                // Base Ramp
                if (_IsNight == 0.0)
                    RampY = RampPixelY * (39 - LightMapColor.a * 18);
                else
                    RampY = RampPixelY * (19 - LightMapColor.a * 18);

                float2 RampUV = float2(RampX, RampY);
                float4 rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, RampUV);

                // ���ռ��㣬_RampShadowRange����ֵ���Լ����ã�û�������rampColor * BaseColor * _ShadowColor����Ȼ��BaseColor
                half4 FinalRamp = lerp(rampColor * BaseColor * _ShadowColor, BaseColor, step(_RampShadowRange, halfLambert * ShadowAO));

                //�� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� ��
                // Hair Ramp ͬ��
                #if _SHADERENUM_HAIR
                    if (_IsNight == 0.0)
                        RampY = RampPixelY * (39 - 2 * lerp(2, 5, step(0.5, LightMapColor.a)));
                    else
                        RampY = RampPixelY * (19 - 2 * lerp(2, 5, step(0.5, LightMapColor.a)));
                    RampUV = float2(RampX, RampY);
                    rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, RampUV);
                    FinalRamp = lerp(rampColor * BaseColor * _ShadowColor, BaseColor, step(_RampShadowRange, halfLambert * ShadowAO));
                #endif

               //�� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� �� ��
               // SDF������Ӱ�����ݷ��������ַ��򣬼���sdf�Ĳ����㣬Ȼ���õ���ֵ���ٸ��ݷ������泯���򣬼���ʵ����ɫ
                #if _SHADERENUM_FACE
                    float4 upDir = mul(unity_ObjectToWorld, float4(0,1,0,0));  
                    float4 frontDir = mul(unity_ObjectToWorld, float4(0,0,1,0));
                    float3 rightDir = cross(upDir.xyz, frontDir.xyz);

                    float FdotL = dot(normalize(frontDir.xz), normalize(lightDir.xz));
                    float RdotL = dot(normalize(rightDir.xz), normalize(lightDir.xz));

                    // ��������ֵ���л���ͼ����
                    float2 FaceMapUV = float2(lerp(i.uv.x, 1-i.uv.x, step(0, RdotL)), i.uv.y);
                    float FaceMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, FaceMapUV).r;

                    // �����仯���ߣ�ʹ���м�󲿷ֱ仯�ٶ�����ƽ��
                    FaceMap = pow(FaceMap, _FaceShadowPow);

                    // ֱ���ò����Ľ����FdotL�Ƚ��жϣ�ͷ����Ӱ���沿��Ӱ��Բ��ϣ���Ҫ�ֶ�����ƫ��
                    // ����ֱ����LightMap�����ϡ�Offset�ᵼ�¹��ս����Եʱ������Ӱ����
                    float sinx = sin(_FaceShadowOffset);
                    float cosx = cos(_FaceShadowOffset);
                    float2x2 rotationOffset1 = float2x2(cosx, sinx, -sinx, cosx); //˳ʱ��ƫ��
                    float2x2 rotationOffset2 = float2x2(cosx, -sinx, sinx, cosx); //��ʱ��ƫ��
                    float2 FaceLightDir = lerp(mul(rotationOffset1, lightDir.xz), mul(rotationOffset2, lightDir.xz), step(0, RdotL));
                    FdotL = dot(normalize(frontDir.xz), normalize(FaceLightDir));

                    //FinalRamp = float4(FaceMap, FaceMap, FaceMap, 1);
                    FinalRamp = lerp(BaseColor, _ShadowColor * BaseColor, step(FaceMap, 1-FdotL));
                #endif

                //==========================================================================================
                // �߹�
                half4 BlinnPhongSpecular;
                half4 MetalSpecular;
                half4 StepSpecular;
                half4 FinalSpecular;
                // ILM��Rͨ������ɫΪ�ñ��ӽǸ߹⣬0-0.8����ֻ���ӽǹ�
                half StepMask = step(0.2, LightMapColor.r) - step(0.8, LightMapColor.r);
                StepSpecular = step(1 - _StepSpecularGloss, saturate(dot(i.worldNormal, viewDir))) * _StepSpecularIntensity * StepMask;
                // ILM��Rͨ������ɫΪ Blinn-Phong + �����߹�
                half MetalMask = step(0.9, LightMapColor.r);
                // Blinn-Phong
                BlinnPhongSpecular = pow(max(0, dot(i.worldNormal, halfDir)), _BlinnPhongSpecularGloss) * _BlinnPhongSpecularIntensity * MetalMask;
                // �����߹⣬������ռ䷢��ת��view�ռ䣬Ȼ��ʹ��xy������metalmap�ϲ�����Ȼ�������ֵ���Ͻ����߹�
                float2 MetalMapUV = mul((float3x3) UNITY_MATRIX_V, i.worldNormal).xy * 0.5 + 0.5;
                float MetalMap = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, MetalMapUV).r;
                MetalMap = step(_MetalSpecularGloss, MetalMap);
                MetalSpecular = MetalMap * _MetalSpecularIntensity * MetalMask;
                
                FinalSpecular = StepSpecular + BlinnPhongSpecular + MetalSpecular;

                //������bͨ�����߹�ǿ�ȣ�halflambert��Ao
                FinalSpecular = lerp(0, BaseColor * FinalSpecular * _SpecularColor, LightMapColor.b) ;
                FinalSpecular *= halfLambert * ShadowAO * _EnableSpecular;

                //==========================================================================================
                // ��Ļ�ռ���ȵȿ��Ե��
                // ��Ļ�ռ�UV
                float2 RimScreenUV = float2(i.pos.x / _ScreenParams.x, i.pos.y / _ScreenParams.y);
                // ��������ƫ��UV����smothNormalת��������ռ�,��ת�����ӽǿռ䣬�ǵó�i.pos.w��ƫ�ƺ��ֵ������smoothstep
                float3 smoothNormal = normalize(UnpackNormalmapRGorAG(i.color));
                float3x3 tangentTransform = float3x3(i.worldTangent, i.worldBiTangent, i.worldNormal);
                float3 worldRimNormal = normalize(mul(smoothNormal, tangentTransform));
                float2 RimOffsetUV = float2(mul((float3x3) UNITY_MATRIX_V, worldRimNormal).xy * _RimOffset * 0.01 / i.pos.w);
                RimOffsetUV += RimScreenUV;
                
                //����������ֵ-����ǰ�����ֵ
                float ScreenDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, RimScreenUV);
                float Linear01ScreenDepth = LinearEyeDepth(ScreenDepth, _ZBufferParams);
                float OffsetDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, RimOffsetUV);
                float Linear01OffsetDepth = LinearEyeDepth(OffsetDepth, _ZBufferParams);

                //����һ����ֵ�����
                float diff = Linear01OffsetDepth - Linear01ScreenDepth;
                float rimMask = step(_RimThreshold * 0.1, diff);

                // ��Ե����ɫ��aͨ���������Ʊ�Ե��ǿ��
                half4 RimColor = float4(rimMask * _RimColor.rgb * _RimColor.a, 1) * _EnableRim;

                //return FinalSpecular;
                //return half4(1,1,1,1);
                return FinalRamp + FinalSpecular + RimColor;
            }
            ENDHLSL
        }

        Pass
        {
            Name "OUTLINE_PASS"
            Tags {}

            //�����޳�������ֻ�б�Ե�Ż���Ⱦ
            Cull Front

            HLSLPROGRAM
            #pragma vertex OutlinePassVert
            #pragma fragment OutlinePassFrag

            //����Ե���࣬��������һ��pass�Ȼ��Ҫ�Ⱦ��룬�����ڶ�����ɫ�������������޳�
            v2f OutlinePassVert(a2v v)
            {   
                v2f o;
                float4 pos = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.texCoord, _MainTex);
                o.worldPos = TransformObjectToWorld(v.vertex);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal, v.tangent);
                o.worldNormal = vertexNormalInput.normalWS;
                o.worldTangent = vertexNormalInput.tangentWS;
                o.worldBiTangent = vertexNormalInput.bitangentWS;

                //LRC add
                o.color=0;

                // ��ȡԤ�Ⱥ決������ɫ�����߿ռ�ƽ�����ߣ��޸���߶��ѣ�ͬʱ������Ƥ�������ܷ����Ĵ������
                // UnpackNormalmapRGorAG���Զ���RG��ΪAG��Ҳ�ͽ�����ɫ������ߴ�ϸ�仯һ��ʵ����
                half3 smoothNormal = normalize(UnpackNormalmapRGorAG(v.color));
                // �����ߴ����߿ռ�任������ռ�
                float3x3 tangentTransform = float3x3(o.worldTangent, o.worldBiTangent, o.worldNormal);
                half3 worldOutlineNormal = normalize(mul(smoothNormal, tangentTransform));
                // �ٴ�����ռ�任���ü��ռ䣬�˴� * pos.w ��Ϊ��������γ�����Ӱ�죬ʹ���������Զ�������仯ʱ����ߴ�ϸ���ֲ���
                half3 outlineNormal = TransformWorldToHClip(worldOutlineNormal) * pos.w;
                // �����Ļ��߱ȣ�������������䴰��
                float aspect = _ScreenParams.x / _ScreenParams.y;
                pos.xy += 0.001 * _OutlineWidth * v.color.a * outlineNormal.xy * aspect * _EnableOutline;

                //pos.xy += 0.001 * _OutlineWidth * v.color.a * o.worldNormal.xy * pos.w * aspect * _EnableOutline;

                // float3 viewNormal = TransformWorldToHClip(TransformObjectToWorldNormal(v.tangent.xyz));
                // pos.xy += 0.001 * _OutlineWidth * v.color.a * viewNormal.xy * aspect * _EnableOutline;
                o.pos = pos;
                return o;
            }

            half4 OutlinePassFrag(v2f i): COLOR
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                return _OutlineColor * col;
            }
            ENDHLSL
        }

        Pass
        {
            Tags {"LightMode" = "DepthOnly"}
        }
    }
}