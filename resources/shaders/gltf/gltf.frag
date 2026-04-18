#version 300 es
precision highp float;
precision highp sampler2DArrayShadow;
precision highp sampler2DArray;

layout(std140) uniform SL {
    mat4 viewProjMat;
    mat4 projMat;
    mat4 viewMat;
    vec3 viewPos;
    highp uint radianceMipLevelCount;
} sl;

layout(std140) uniform DirectionalLight {
    mat4 lightSpaceViewProjMat[4];
    vec4 cascadeDistances;
    vec3 direction;
    vec3 color;
    float cameraZFar;
    highp uint cascadeCount;
} directionalLight;

in vec3 v_position;
in vec3 v_normal;
in vec3 v_tangent;
in vec3 v_bitangent;
in vec2 v_uv;

out vec4 o_color;

// Directional Light
uniform sampler2DArrayShadow u_cascadeShadowMap;
// uniform sampler2DArray u_cascadeShadowMap;

// Environment
uniform float u_ambientIntensity;
uniform samplerCube u_irradianceMap;
uniform samplerCube u_prefilterMap;
uniform sampler2D u_brdfLut;

// PBR Material Uniforms
uniform vec4 u_baseColorFactor;
uniform float u_metallicFactor;
uniform float u_roughnessFactor;

uniform sampler2D u_baseColorTexture;
uniform bool u_hasBaseColorTexture;

uniform sampler2D u_metallicRoughnessTexture;
uniform bool u_hasMetallicRoughnessTexture;

uniform sampler2D u_normalTexture;
uniform bool u_hasNormalTexture;
uniform float u_normalScale;

uniform sampler2D u_occlusionTexture;
uniform bool u_hasOcclusionTexture;
uniform float u_occlusionStrength;

uniform sampler2D u_emissiveTexture;
uniform bool u_hasEmissiveTexture;
uniform vec3 u_emissiveFactor;

const float PI = 3.14159265359;

// Fresnel Schlick approximation
vec3 F_Schlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// GGX / Trowbridge-Reitz Normal Distribution Function
float D_GGX(float NdotH, float roughness) {
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;
    float NdotH2 = NdotH * NdotH;
    
    float num = alpha2;
    float denom = (NdotH2 * (alpha2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    
    return num / denom;
}

// Schlick-GGX Geometry Function
float G_SchlickGGX(float NdotV, float roughness) {
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float num = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}

vec3 F_SchlickRoughness(float cosTheta, vec3 F0, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// Smith Geometry Function
float G_Smith(float NdotV, float NdotL, float roughness) {
    float ggx2 = G_SchlickGGX(NdotV, roughness);
    float ggx1 = G_SchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

mat3 getTangentFrame(vec3 normal, vec3 position, vec2 uv) {
    vec3 dp1 = dFdx(position);
    vec3 dp2 = dFdy(position);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);

    vec3 tangent = normalize(dp1 * duv2.t - dp2 * duv1.t);
    vec3 bitangent = -normalize(cross(normal, tangent));
    
    tangent = normalize(tangent - normal * dot(normal, tangent));

    return mat3(tangent, bitangent, normal);
}

void main() {
    // Fallback constants if uniforms aren't being set yet
    vec4 baseColor = u_baseColorFactor == vec4(0.0) ? vec4(0.8, 1.0, 1.0, 1.0) : u_baseColorFactor;
    if (u_hasBaseColorTexture) {
        vec4 texColor = texture(u_baseColorTexture, v_uv);
        // glTF spec requires baseColorTexture to be strictly sRGB to linear
        texColor.rgb = pow(texColor.rgb, vec3(2.2));
        baseColor *= texColor;
    }

    float metallic = u_metallicFactor == 0.0 && u_roughnessFactor == 0.0 ? 0.0 : u_metallicFactor;
    float roughness = u_metallicFactor == 0.0 && u_roughnessFactor == 0.0 ? 0.4 : u_roughnessFactor;
    
    if (u_hasMetallicRoughnessTexture) {
        vec4 mrTex = texture(u_metallicRoughnessTexture, v_uv);
        // glTF spec: metallic is in the B channel, roughness is in the G channel
        metallic *= mrTex.b;
        roughness *= mrTex.g;
    }
    
    vec3 N = normalize(v_normal);
    if (u_hasNormalTexture) {
        mat3 tbn;
        if (length(v_tangent) > 0.001) {
            vec3 t = normalize(v_tangent);
            vec3 b = normalize(v_bitangent);
            tbn = mat3(t, b, N);
        } else {
            tbn = getTangentFrame(N, v_position, v_uv);
        }
        
        vec3 nTex = texture(u_normalTexture, v_uv).rgb * 2.0 - 1.0;
        nTex = normalize(vec3(nTex.xy * u_normalScale, nTex.z));
        N = normalize(tbn * nTex);
    }

    vec3 V = normalize(sl.viewPos - v_position);
    
    vec3 L = normalize(directionalLight.direction);
    vec3 H = normalize(V + L);
    
    vec3 radiance = directionalLight.color;
    
    float NdotV = max(dot(N, V), 0.000001); // Prevent divide by zero
    float NdotL = max(dot(N, L), 0.0);
    float HdotV = max(dot(H, V), 0.0);
    float NdotH = max(dot(N, H), 0.0);

    // Dielectrics have roughly 0.04 specular reflection. Metals tint the specular by baseColor.
    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, baseColor.rgb, metallic);
    
    // Per-light radiance (Cook-Torrance BRDF)
    float NDF = D_GGX(NdotH, roughness);   
    float G   = G_Smith(NdotV, NdotL, roughness);      
    vec3 F    = F_Schlick(HdotV, F0);
    
    vec3 numerator    = NDF * G * F;
    float denominator = 4.0 * NdotV * NdotL + 0.0001; 
    vec3 specular     = numerator / denominator;
    
    // Evaluate diffuse lighting
    vec3 kS = F;
    vec3 kD = vec3(1.0) - kS;
    kD *= 1.0 - metallic;   
    vec3 diffuse = kD * baseColor.rgb / PI;
    
    // Add both light outputs (Lo)
    vec3 Lo = (diffuse + specular) * radiance * NdotL;
    
    // Ambient / Image Based Lighting
    vec3 F_IBL = F_SchlickRoughness(NdotV, F0, roughness);
    vec3 kS_IBL = F_IBL;
    vec3 kD_IBL = 1.0 - kS_IBL;
    kD_IBL *= 1.0 - metallic;
    
    vec3 irradiance = texture(u_irradianceMap, N).rgb;
    vec3 diffuseIBL = irradiance * baseColor.rgb;
    
    float MAX_REFLECTION_LOD = float(sl.radianceMipLevelCount) - 1.0;
    vec3 R = reflect(-V, N);
    vec3 prefilteredColor = textureLod(u_prefilterMap, R, roughness * MAX_REFLECTION_LOD).rgb;
    vec2 envBRDF = texture(u_brdfLut, vec2(NdotV, roughness)).rg;
    vec3 specularIBL = prefilteredColor * (F_IBL * envBRDF.x + envBRDF.y);
    
    vec3 ambient = (kD_IBL * diffuseIBL + specularIBL) * u_ambientIntensity;
    
    float ao = 1.0;
    if (u_hasOcclusionTexture) {
        ao = texture(u_occlusionTexture, v_uv).r;
        ao = 1.0 + u_occlusionStrength * (ao - 1.0);
    }
    
    vec3 emissive = u_emissiveFactor;
    if (u_hasEmissiveTexture) {
        vec3 eTex = texture(u_emissiveTexture, v_uv).rgb;
        eTex = pow(eTex, vec3(2.2));
        emissive *= eTex;
    }
    
    // Shadow Calculation
    vec4 viewSpacePos = sl.viewMat * vec4(v_position, 1.0);
    float viewZ = abs(viewSpacePos.z);
    
    int cascadeIndex = -1;
    for (int i = 0; i < int(min(directionalLight.cascadeCount, 4u)); i++) {
        if (viewZ < directionalLight.cascadeDistances[i]) {
            cascadeIndex = i;
            break;
        }
    }
    float shadow = 0.0;
    if (cascadeIndex != -1) {
        vec4 fragPosLightSpace = directionalLight.lightSpaceViewProjMat[cascadeIndex] * vec4(v_position, 1.0);
        vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
        projCoords = projCoords * 0.5 + 0.5;
        
        if (projCoords.z <= 1.0) {
            float bias = max(0.05 * (1.0 - dot(N, L)), 0.005);
            // Scale appropriately (using the cascade far plane)
            bias *= 1.0 / directionalLight.cascadeDistances[cascadeIndex];

            vec2 texelSize = 1.0 / vec2(textureSize(u_cascadeShadowMap, 0));
            for(int x = -1; x <= 1; x++) {
                for(int y = -1; y <= 1; y++) {
                    shadow += 1.0 - texture(u_cascadeShadowMap, vec4(projCoords.xy, cascadeIndex, projCoords.z - bias));

                    // vec2 sampleUv = projCoords.xy + vec2(x, y) * texelSize;
                    // float pcfDepth = 1.0;
                    // if (sampleUv.x >= 0.0 && sampleUv.x <= 1.0 && sampleUv.y >= 0.0 && sampleUv.y <= 1.0) {
                    //     pcfDepth = texture(u_cascadeShadowMap, vec3(sampleUv, cascadeIndex)).r;
                    // }
                    // shadow += projCoords.z - bias > pcfDepth ? 1.0 : 0.0;
                }
            }
            shadow /= 9.0;
        }
    }
    
    vec3 color = ambient * ao + Lo * (1.0 - shadow) + emissive;
    
    // glTF 2.0 requires linear output converted to sRGB. We also apply simple tone mapping.
    color = color / (color + vec3(1.0));
    color = pow(color, vec3(1.0/2.2));

    o_color = vec4(color, baseColor.a);
}