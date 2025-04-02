////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in int mat;

in vec2 texCoord;

flat in vec3 sunVec, upVec;

in vec4 position;
flat in vec4 glColor;

flat in int passType;
flat in ivec3 correspondingBlock;
in vec3 vxPosF;

//Uniforms//
uniform int isEyeInWater;
uniform int renderStage;

uniform vec3 cameraPosition;

uniform sampler2D tex;
uniform sampler2D noisetex;

layout(r32i) restrict uniform iimage3D occupancyVolume;

#if WATER_CAUSTIC_STYLE >= 3
    uniform float frameTimeCounter;

    uniform sampler2D gaux4;
#endif

//Pipeline Constants//

//Common Variables//
float SdotU = dot(sunVec, upVec);
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;

//Common Functions//
void DoNaturalShadowCalculation(inout vec4 color1, inout vec4 color2) {
    color1.rgb *= glColor.rgb;
    color1.rgb = mix(vec3(1.0), color1.rgb, pow(color1.a, (1.0 - color1.a) * 0.5) * 1.05);
    color1.rgb *= 1.0 - pow(color1.a, 64.0);
    color1.rgb *= 0.2; // Natural Strength

    color2.rgb = normalize(color1.rgb) * 0.5;
}

//Includes//

//Program//
void main() {
    if (passType == 0) {
        vec4 color1 = texture2DLod(tex, texCoord, 0); // Shadow Color

        #if SHADOW_QUALITY >= 1
            vec4 color2 = color1; // Light Shaft Color

            color2.rgb *= 0.25; // Natural Strength

            #if defined LIGHTSHAFTS_ACTIVE && LIGHTSHAFT_BEHAVIOUR == 1 && defined OVERWORLD
                float positionYM = position.y;
            #endif

            if (mat < 31008) {
                if (mat < 31000) {
                    DoNaturalShadowCalculation(color1, color2);
                } else {
                    if (mat == 31000) { // Water
                        vec3 worldPos = position.xyz + cameraPosition;

                        #if defined LIGHTSHAFTS_ACTIVE && LIGHTSHAFT_BEHAVIOUR == 1 && defined OVERWORLD
                            // For scene-aware light shafts to be more prone to get extreme near water
                            positionYM += 3.5;
                        #endif

                        // Water Caustics
                        #if WATER_CAUSTIC_STYLE < 3
                            #if MC_VERSION >= 11300
                                float wcl = GetLuminance(color1.rgb);
                                color1.rgb = color1.rgb * pow2(wcl) * 1.2;
                            #else
                                color1.rgb = mix(color1.rgb, vec3(GetLuminance(color1.rgb)), 0.88);
                                color1.rgb = pow2(color1.rgb) * vec3(2.5, 3.0, 3.0) * 0.96;
                            #endif
                        #else
                            #define WATER_SPEED_MULT_M WATER_SPEED_MULT * 0.035
                            vec2 causticWind = vec2(frameTimeCounter * WATER_SPEED_MULT_M, 0.0);
                            vec2 cPos1 = worldPos.xz * 0.10 - causticWind;
                            vec2 cPos2 = worldPos.xz * 0.05 + causticWind;

                            float cMult = 14.0;
                            float offset = 0.001;

                            float caustic = 0.0;
                            caustic += dot(texture2D(gaux4, cPos1 + vec2(offset, 0.0)).rg, vec2(cMult))
                                    - dot(texture2D(gaux4, cPos1 - vec2(offset, 0.0)).rg, vec2(cMult));
                            caustic += dot(texture2D(gaux4, cPos2 + vec2(0.0, offset)).rg, vec2(cMult))
                                    - dot(texture2D(gaux4, cPos2 - vec2(0.0, offset)).rg, vec2(cMult));
                            color1.rgb = vec3(max0(min1(caustic * 0.8 + 0.35)) * 0.65 + 0.35);

                            #if MC_VERSION < 11300
                                color1.rgb *= vec3(0.3, 0.45, 0.9);
                            #endif
                        #endif

                        #if MC_VERSION >= 11300
                            #if WATERCOLOR_MODE >= 2
                                color1.rgb *= glColor.rgb;
                            #else
                                color1.rgb *= vec3(0.3, 0.45, 0.9);
                            #endif
                        #endif
                        color1.rgb *= vec3(0.6, 0.8, 1.1);
                        ////

                        // Underwater Light Shafts
                        vec3 worldPosM = worldPos;

                        #if WATER_FOG_MULT > 100
                            #define WATER_FOG_MULT_M WATER_FOG_MULT * 0.01;
                            worldPosM *= WATER_FOG_MULT_M;
                        #endif

                        vec2 waterWind = vec2(syncedTime * 0.01, 0.0);
                        float waterNoise = texture2D(noisetex, worldPosM.xz * 0.012 - waterWind).g;
                            waterNoise += texture2D(noisetex, worldPosM.xz * 0.05 + waterWind).g;

                        float factor = max(2.5 - 0.025 * length(position.xz), 0.8333) * 1.3;
                        waterNoise = pow(waterNoise * 0.5, factor) * factor * 1.3;

                        #if MC_VERSION >= 11300 && WATERCOLOR_MODE >= 2
                            color2.rgb = normalize(sqrt1(glColor.rgb)) * vec3(0.24, 0.22, 0.26);
                        #else
                            color2.rgb = vec3(0.08, 0.12, 0.195);
                        #endif
                        color2.rgb *= waterNoise * (1.0 + sunVisibility - rainFactor);
                        ////

                        #ifdef UNDERWATERCOLOR_CHANGED
                            color1.rgb *= vec3(UNDERWATERCOLOR_RM, UNDERWATERCOLOR_GM, UNDERWATERCOLOR_BM);
                            color2.rgb *= vec3(UNDERWATERCOLOR_RM, UNDERWATERCOLOR_GM, UNDERWATERCOLOR_BM);
                        #endif
                    } else /*if (mat == 31004)*/ { // Ice
                        color1.rgb *= color1.rgb;
                        color1.rgb *= color1.rgb;
                        color1.rgb = mix(vec3(1.0), color1.rgb, pow(color1.a, (1.0 - color1.a) * 0.5) * 1.05);
                        color1.rgb *= 1.0 - pow(color1.a, 64.0);
                        color1.rgb *= 0.28;

                        color2.rgb = normalize(pow(color1.rgb, vec3(0.25))) * 0.5;
                    }
                }
            } else {
                if (mat < 31020) { // Glass, Glass Pane, Beacon (31008, 31012, 31016)
                    if (color1.a > 0.5) color1 = vec4(0.0, 0.0, 0.0, 1.0);
                    else color1 = vec4(vec3(0.2 * (1.0 - GLASS_OPACITY)), 1.0);
                    color2.rgb = vec3(0.3);
                } else {
                    DoNaturalShadowCalculation(color1, color2);
                }
            }
        #endif

        gl_FragData[0] = color1; // Shadow Color

        #if SHADOW_QUALITY >= 1
            #if defined LIGHTSHAFTS_ACTIVE && LIGHTSHAFT_BEHAVIOUR == 1 && defined OVERWORLD
                color2.a = 0.25 + max0(positionYM * 0.05); // consistencyMEJHRI7DG
            #endif

            gl_FragData[1] = color2; // Light Shaft Color
        #endif
    } else {
        vec4 col = textureLod(tex, texCoord, 0);
        col.rgb *= glColor.rgb;
        if (col.a > 0.1) {
            for (int k = 0; k < passType >> 1; k++) {
                vec3 position2 = vxPosF * (1<<k) - 0.1561271 * upVec + voxelVolumeSize * 0.5;
                if (any(lessThan(position2, vec3(0))) || any(greaterThanEqual(position2, voxelVolumeSize - 0.01))) {
                    break;
                }
                ivec3 coords2 = ivec3(position2);
                imageAtomicOr(occupancyVolume, coords2, 1<<(k + 8 * int(col.a < 0.9)));
            }
        }
        discard;
    }
}

#endif

/////////Geometry Shader////////Geometry Shader////////Geometry Shader/////////
#ifdef GEOMETRY_SHADER

layout(triangles) in;
layout(triangle_strip, max_vertices=6) out;

flat in int matV[3];
in vec2 texCoordV[3];
in vec2 lmCoordV[3];
in vec3 midBlock[3];
flat in vec3 sunVecV[3], upVecV[3];
in vec4 positionV[3];
flat in vec4 glColorV[3];
flat in ivec3 correspondingBlockV[3];

flat out int mat;
out vec2 texCoord;
flat out vec3 sunVec, upVec;
out vec4 position;
flat out vec4 glColor;
out vec3 vxPosF;

flat out int passType;
flat out ivec3 correspondingBlock;
//Uniforms//

uniform int renderStage;
uniform int entityId;
uniform int currentRenderedItemId;

uniform vec3 cameraPosition;

// default value as feature check
uniform ivec3 cameraPositionInt = ivec3(-1679125, -93126, 691246);
uniform vec3 cameraPositionFract;

uniform vec3 eyePosition;
uniform sampler2D tex;
uniform sampler2D specular;
uniform ivec2 atlasSize;
uniform vec4 entityColor;

layout(r32i) restrict uniform iimage3D voxelCols;
layout(r32i) restrict uniform iimage3D occupancyVolume;

//Includes//
#define WRITE_TO_SSBOS
#include "/lib/vx/SSBOs.glsl"
#include "/lib/materials/shadowChecks.glsl"
#include "/lib/vx/positionHashing.glsl"

void main() {
    vec3 fractCamPos = cameraPositionFract;
    if (cameraPositionInt == ivec3(-1679125, -93126, 691246)) {
        fractCamPos = fract(cameraPosition);
    }
    int localMat = matV[0];
    if (entityId > 0) localMat = entityId;
    if (currentRenderedItemId > 0) localMat = currentRenderedItemId;

    vec3 cnormal = cross(positionV[1].xyz - positionV[0].xyz, positionV[2].xyz - positionV[0].xyz);
    float area = length(cnormal);
    cnormal += vec3(0.00001, 0.00021, -0.0000391);

    cnormal = normalize(cnormal);

    bool emissive = isEmissive(localMat) || (lmCoordV[0].x > 0.99 && localMat == 0);

    vec3[3] vxPos;

    for (int i = 0; i < 3; i++) vxPos[i] = positionV[i].xyz + fractCamPos;
    if (localMat == 50088) { // entity flame needs to be moved outside of entity it belongs to or it will glitch out
        for (int i = 0; i < 3; i++) vxPos[i].y += 0.5 * sqrt(area);
    }
    vec3 center = 0.5 * (
        min(min(vxPos[0], vxPos[1]), vxPos[2]) +
        max(max(vxPos[0], vxPos[1]), vxPos[2])
    );
    bool isHeldLight = false;
    if (entityId == 50016 && emissive && length(center) < 8) { // handheld item
        isHeldLight = true;
        vec3 floorCamPosRelEyePos = (cameraPositionInt - eyePosition);
        if (cameraPositionInt == ivec3(-1679125, -93126, 691246)) {
            floorCamPosRelEyePos = (floor(cameraPosition) - eyePosition);
        }
        vec3 offset = 0.5 * normalize((center - 0.025 * cnormal + floorCamPosRelEyePos) * vec3(1, 0, 1));
        center += offset;
        for (int i = 0; i < 3; i++) {
            vxPos[i] += offset;
        }
    }
    vec3 lowerBound = floor(min(min(vxPos[0], vxPos[1]), vxPos[2]));
    vec3 minAbsPos = min(min(abs(vxPos[0]), abs(vxPos[1])), abs(vxPos[2]));
    int bestNormalAxis = int(dot(vec3(greaterThanEqual(abs(cnormal), max(abs(cnormal).yzx, abs(cnormal.zxy)))), vec3(0.5, 1.5, 2.5)));
    int localResolution = min(VOXEL_DETAIL_AMOUNT, int(-log2(infnorm(minAbsPos / voxelVolumeSize))));
    if (localResolution > 0) {
        vec2 minTexCoord = min(min(texCoordV[0], texCoordV[1]), texCoordV[2]);
        vec2 maxTexCoord = max(max(texCoordV[0], texCoordV[1]), texCoordV[2]);
        int lodLevel = int(log2(max(4.1, 1.01 * min((maxTexCoord.x - minTexCoord.x) * atlasSize.x, (maxTexCoord.y - minTexCoord.y) * atlasSize.y)))) - 2;
        vec4 col = vec4(getLightCol(localMat), 1);
        int lightLevel = 0;
        if (emissive) {
            lightLevel = getLightLevel(localMat);
        }
        #if RP_MODE >= 2
            #if RP_MODE == 2
                #define EMISSION_CHANNEL b
            #else
                #define EMISSION_CHANNEL a
            #endif
            else {
                for (int k = 0; k < 9; k++) {
                    vec2 offset = (vec2(k%3, k/3) + 0.5)/3.0;
                    vec4 s = textureLod(specular, mix(minTexCoord, maxTexCoord, offset), 0);
                    if (
                        #if RP_MODE == 3
                            s.EMISSION_CHANNEL < 0.999 &&
                        #endif
                        s.EMISSION_CHANNEL > 0.2) {
                        emissive = true;
                        lightLevel = max(lightLevel, int(31.9 * s.EMISSION_CHANNEL));
                    }
                }
            }
        #endif
        vec4 textureCol = textureLod(tex, 0.5 * (minTexCoord + maxTexCoord), lodLevel);
        for (int k = 0; k < 9; k++) {
            vec2 offset = (vec2(k%3, k/3) + 0.5)/3.0;
            vec4 textureCol2 = textureLod(tex, mix(minTexCoord, maxTexCoord, offset), max(0, lodLevel - 2));
            if (textureCol2.a > textureCol.a + 0.01) textureCol = textureCol2;
        }
        col.a = textureCol.a;
        bool detectCol = (col.rgb == vec3(0));
        if (detectCol) col = textureCol;
        if (localMat != 10996) col.rgb *= glColorV[0].rgb;
        col.rgb = mix(col.rgb, entityColor.rgb, entityColor.a);
        ivec3 coords = ivec3(center - 0.1 * cnormal + 0.5 * voxelVolumeSize);
        if (correspondingBlockV[0] != ivec3(-1000)) coords = correspondingBlockV[0];
        if (all(greaterThan((maxTexCoord - minTexCoord) * atlasSize, vec2(1.5)))) {
            ivec2 packedCol = ivec2(int(20 * col.r) + (int(20 * col.g) << 13),
                                    int(20 * col.b) + (int(4.5 * (1 - col.a)) << 13) + (1<<23));
            imageAtomicAdd(voxelCols,
                coords * ivec3(1, 2, 1),
                packedCol.x);
            imageAtomicAdd(voxelCols,
                coords * ivec3(1, 2, 1) + ivec3(0, 1, 0),
                packedCol.y);
        }

        #if HELD_LIGHTING_MODE == 0
            if (isHeldLight) emissive = false;
        #endif

        int skyLight = int(5.49 * lmCoordV[0].y + 0.5);
        int writeSkyLight = (1<<skyLight/2) | (1<<(skyLight-1)/2);
        imageAtomicOr(occupancyVolume, coords, writeSkyLight << 28);
        bool shouldVoxelize = true;
        if (
            #ifndef PLAYER_VOXELIZATION
                entityId == 50016 ||
            #endif
            #ifndef ENTITY_VOXELIZATION
                (entityId != 50016 && renderStage == MC_RENDER_STAGE_ENTITIES) ||
            #endif
            #ifndef FOLIAGE_VOXELIZATION
                length(abs(cnormal.xz) - vec2(sqrt(0.5))) < 0.01 ||
                localMat == 10000 || // dripleaves
                localMat == 10004 || // general foliage
                localMat == 10012 || // vines
                localMat == 10016 || // various "more special" foliage
                localMat == 10348 || // azalea
                localMat == 10488 || // lily pad
                localMat == 10988 || // smallest cocoa stage
                localMat == 10992 || // nether wart
            #endif
            false) {
                shouldVoxelize = false;
        }

        // campfires
        if (localMat == 10652 || localMat == 10656) {
            if (length(abs(cnormal.xz) - vec2(sqrt(0.5))) < 0.01) {
                // flame needs to be moved up a little
                for (int i = 0; i < 3; i++) {
                    vxPos[i].y += 0.4;
                }
            } else {
                // logs are not emissive
                emissive = false;
            }
        }

        if (emissive) {
            if (detectCol) {
                float brightness = infnorm(col.xyz);
                col.xyz -= brightness;
                float minVal = max(0.0001, infnorm(col.xyz));
                col.xyz *= mix(1.0, min(1.0 + 4 * LIGHT_COLOR_SATURATION, brightness/minVal), LIGHT_COLOR_SATURATION);
                col.xyz += brightness;
            }
            if (localMat == 10368) { // nether quartz ore colour doesn't work for some reason
                col = vec4(1);
            }
            uint hash = posToHash(coords - voxelVolumeSize/2) % uint(1<<18);
            vec3[3] blockRelPos;
            for (int i = 0; i < 3; i++) {
                blockRelPos[i] = vxPos[i] - coords + voxelVolumeSize/2 - 0.5;
                if (correspondingBlockV[0] != ivec3(-1000)) {
                    blockRelPos[i] = clamp(blockRelPos[i] + 0.5 * cnormal, vec3(-0.5), vec3(0.5));
                }
            }
            vec3 meanPos = 1.0/3.0*(blockRelPos[0] + blockRelPos[1] + blockRelPos[2]) + 1.5;
            meanPos = clamp(meanPos, vec3(0), vec3(4));
            vec3 meanSquarePos = 1.0/6.0*(
                blockRelPos[0] * blockRelPos[0] +
                blockRelPos[1] * blockRelPos[1] +
                blockRelPos[2] * blockRelPos[2] +
                blockRelPos[0] * blockRelPos[1] +
                blockRelPos[1] * blockRelPos[2] +
                blockRelPos[2] * blockRelPos[0]);
            vec3 variance = meanSquarePos - (meanPos - 1.5) * (meanPos - 1.5);
            uvec2 packedMeanPos = uvec2(
                uint(meanPos.x * 32 + 0.5) | (uint(meanPos.y * 32 + 0.5) << 16),
                uint(meanPos.z * 32 + 0.5) | uint(1<<16)
            );
            uvec2 packedCol2 = uvec2(
                uint(col.x * 32 + 0.5) | (uint(col.y * 32 + 0.5) << 16),
                uint(col.z * 32 + 0.5)
            );
            atomicAdd(globalLightHashMap[hash*4], packedMeanPos.x);
            atomicAdd(globalLightHashMap[hash*4+1], packedMeanPos.y);
            atomicAdd(globalLightHashMap[hash*4+2], packedCol2.x);
            atomicAdd(globalLightHashMap[hash*4+3], packedCol2.y);
            if ((imageAtomicOr(occupancyVolume, coords, 1<<16) >> 16 & 1) == 0) {
                int lightLevel = getLightLevel(localMat);
                #if HELD_LIGHTING_MODE == 1
                    if (isHeldLight) {
                        lightLevel /= 2;
                    }
                #endif
                if (lightLevel == 0) lightLevel = max(10, int(31 * lmCoordV[0].x));
                imageAtomicOr(occupancyVolume, coords, (lightLevel + (localMat/4%32 << 5) << 17));
                if (
                    renderStage != MC_RENDER_STAGE_TERRAIN_SOLID &&
                    renderStage != MC_RENDER_STAGE_TERRAIN_CUTOUT &&
                    renderStage != MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
                ) {
                    imageAtomicOr(occupancyVolume, coords, 1<<27);
                }
            }
        } else if (shouldVoxelize) {
            for (int i = 0; i < 3; i++) {
                vec2 relProjectedPos
                    = vec2(  vxPos[i][(bestNormalAxis+1)%3],   vxPos[i][(bestNormalAxis+2)%3])
                    - vec2(lowerBound[(bestNormalAxis+1)%3], lowerBound[(bestNormalAxis+2)%3]);
                gl_Position = vec4((relProjectedPos * (1<<localResolution) + 0.09) / shadowMapResolution - 0.9, 0.5, 1.0);
                mat = matV[i];
                texCoord = texCoordV[i];
                sunVec = sunVecV[i];
                upVec = cnormal;
                position = positionV[i];
                glColor = glColorV[i];
                vxPosF = vxPos[i];
                passType = 1 + (localResolution << 1);
                correspondingBlock = correspondingBlockV[i];
                EmitVertex();
            }
            EndPrimitive();
        }
    }
    #if (defined OVERWORLD || defined END) && defined REALTIME_SHADOWS
        for (int i = 0; i < 3; i++) {
            gl_Position = gl_in[i].gl_Position;
            mat = matV[i];
            texCoord = texCoordV[i];
            sunVec = sunVecV[i];
            upVec = upVecV[i];
            position = positionV[i];
            glColor = glColorV[i];
            passType = 0;
            correspondingBlock = correspondingBlockV[i];
            EmitVertex();
        }
        EndPrimitive();
    #endif
}
#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

flat out int matV;

out vec2 texCoordV;
out vec2 lmCoordV;

flat out vec3 sunVecV, upVecV;

out vec4 positionV;
flat out vec4 glColorV;
flat out ivec3 correspondingBlockV;

//Uniforms//
uniform int renderStage;
uniform int blockEntityId;
uniform vec3 cameraPosition;

// default value as feature check
uniform ivec3 cameraPositionInt = ivec3(-1679125, -93126, 691246);
uniform vec3 cameraPositionFract;

uniform mat4 shadowProjection, shadowProjectionInverse;
uniform mat4 shadowModelView, shadowModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#if defined WAVING_ANYTHING_TERRAIN || defined WAVING_WATER_VERTEX
    uniform float frameTimeCounter;

#endif

//Attributes//
in vec4 mc_Entity;
in vec3 at_midBlock;
#if defined PERPENDICULAR_TWEAKS || defined WAVING_ANYTHING_TERRAIN || defined WAVING_WATER_VERTEX
    attribute vec4 mc_midTexCoord;
#endif

//Common Variables//
#if (defined WAVING_ANYTHING_TERRAIN || defined WAVING_WATER_VERTEX) && defined NO_WAVING_INDOORS
    vec2 lmCoord = vec2(0.0);
#endif

//Common Functions//

//Includes//
#include "/lib/util/spaceConversion.glsl"

#if defined WAVING_ANYTHING_TERRAIN || defined WAVING_WATER_VERTEX
    #include "/lib/materials/materialMethods/wavingBlocks.glsl"
#endif

//Program//
void main() {
    vec3 fractCamPos = cameraPositionFract;
    if (cameraPositionInt == ivec3(-1679125, -93126, 691246)) {
        fractCamPos = fract(cameraPosition);
    }

    texCoordV = gl_MultiTexCoord0.xy;
    lmCoordV = clamp(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) * 1.06667, 0.0, 1.0);
    glColorV = gl_Color;

    sunVecV = GetSunVector();
    upVecV = normalize(gbufferModelView[1].xyz);

    positionV = shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    correspondingBlockV = ivec3(-1000);
    matV = blockEntityId;
    if (
        renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ||
        renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT ||
        renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
    ) {
        correspondingBlockV = ivec3(floor(positionV.xyz + fractCamPos + at_midBlock/64) + 1000.5) - 1000 + voxelVolumeSize/2;
        matV = int(mc_Entity.x + 0.5);
    }
    vec4 position = positionV;
    #if defined WAVING_ANYTHING_TERRAIN || defined WAVING_WATER_VERTEX
        #ifdef NO_WAVING_INDOORS
            lmCoord = GetLightMapCoordinates();
        #endif

        DoWave(position.xyz, matV);
    #endif
    #ifdef PERPENDICULAR_TWEAKS
        if (matV == 10004 || matV == 10016) { // Foliage
            vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
            vec2 texMinMidCoord = texCoordV - midCoord;
            if (texMinMidCoord.y < 0.0) {
                vec3 normal = gl_NormalMatrix * gl_Normal;
                position.xyz += normal * 0.35;
            }
        }
    #endif

    if (matV == 31000) { // Water
        position.y += 0.015 * max0(length(position.xyz) - 50.0);
    }
    gl_Position = shadowProjection * shadowModelView * position;

    float lVertexPos = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
    float distortFactor = lVertexPos * shadowMapBias + (1.0 - shadowMapBias);
    gl_Position.xy *= 1.0 / distortFactor;
    gl_Position.z = gl_Position.z * 0.2;
}

#endif
