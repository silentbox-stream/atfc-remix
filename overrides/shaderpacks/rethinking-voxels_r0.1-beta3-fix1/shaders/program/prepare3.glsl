#include "/lib/common.glsl"

//////Fragment Shader//////Fragment Shader//////
#ifdef FSH
in vec3 dir;

uniform sampler2D colortex8;

uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
vec2 view = vec2(viewWidth, viewHeight);
uniform vec3 cameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

const ivec2 offsets[8] = ivec2[8](
    ivec2( 1, 0),
    ivec2( 1, 1),
    ivec2( 0, 1),
    ivec2(-1, 1),
    ivec2(-1, 0),
    ivec2(-1,-1),
    ivec2( 0,-1),
    ivec2( 1,-1));

#include "/lib/vx/voxelReading.glsl"
#include "/lib/util/random.glsl"
void main() {
    float dither = nextFloat();
    ivec2 texelCoord = ivec2(gl_FragCoord.xy);
    vec4 writeData = texelFetch(colortex8, texelCoord, 0);
    if (writeData.a > 1.5) {
        vec4 avgAroundData = vec4(0);
        int validAroundCount = 0;
        bool extendable = true;
        for (int k = 0, invalidInARow = 0; k < 10; k++) {
            vec4 aroundData = texelFetch(colortex8, texelCoord + offsets[k%8], 0);
            if (aroundData.a > 1.5) {
                invalidInARow++;
                if (invalidInARow >= 4) {
                    extendable = false;
                    break;
                }
                continue;
            }
            invalidInARow = 0;
            if (k < 8) {
                avgAroundData += aroundData;
                validAroundCount++;
            }
        }
        if (extendable) {
            writeData = avgAroundData / validAroundCount;
        } else {
            // fuck view bobbing!
            vec3 rayHit = rayTrace(fract(cameraPosition) - gbufferModelView[3].xyz + normalize(dir), dir, dither);
            float hitDF = getDistanceField(rayHit);
            if (hitDF < 0.1) {
                writeData.rgb = normalize(distanceFieldGradient(rayHit));
                vec4 clipHitPos = gbufferProjection * (gbufferModelView * vec4(rayHit - fract(cameraPosition), 1));
                clipHitPos = 0.5 / clipHitPos.w * clipHitPos + 0.5;
                writeData.a = 1 - clipHitPos.z;
            }
        }
    }
    /*RENDERTARGETS:8*/
    gl_FragData[0] = writeData;
}
#endif

//////Vertex Shader//////Vertex Shader//////
#ifdef VSH

out vec3 dir;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

void main() {
    gl_Position = ftransform();
    dir = normalize((gbufferModelViewInverse * (gbufferProjectionInverse * vec4(gl_Position.xy / gl_Position.w, 0.9999, 1))).xyz) * (voxelVolumeSize.x * 0.4);
}
#endif
