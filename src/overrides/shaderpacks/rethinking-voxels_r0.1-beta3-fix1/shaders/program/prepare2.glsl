#include "/lib/common.glsl"

//////Fragment Shader//////Fragment Shader//////
#ifdef FSH

in mat4 unprojectionMatrix, projectionMatrix;


uniform float viewWidth;
uniform float viewHeight;
vec2 view = vec2(viewWidth, viewHeight);

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D colortex10;

layout(rgba16f) uniform image2D colorimg8;
layout(r32ui) uniform restrict readonly uimage2D colorimg9;

#define MATERIALMAP_ONLY
#include "/lib/vx/SSBOs.glsl"

void main() {
    ivec2 texelCoord = ivec2(gl_FragCoord.xy);
    float prevDepth = 1 - texelFetch(colortex2, texelCoord, 0).w;
    vec4 prevClipPos = vec4(gl_FragCoord.xy / view, prevDepth, 1) * 2 - 1;
    vec4 newClipPos = prevClipPos;
    if (prevDepth > 0.56) {
        newClipPos = unprojectionMatrix * prevClipPos;
        newClipPos.xyz += newClipPos.w * (previousCameraPosition - cameraPosition);
        if (abs(texelFetch(colortex1, texelCoord, 0).y - OSIEBCA * 254.0) < 0.5 * OSIEBCA) {
            vec3 velocity = texelFetch(colortex10, texelCoord, 0).rgb;
            newClipPos.xyz += newClipPos.w * velocity;
        }
        newClipPos = projectionMatrix * newClipPos;
        newClipPos /= newClipPos.w;
    }
    newClipPos = 0.5 * newClipPos + 0.5;
    if (prevClipPos.z > 0.99998) newClipPos.z = 0.9999985;
    if (all(greaterThan(newClipPos.xyz, vec3(0))) && all(lessThan(newClipPos.xyz, vec3(0.999999)))) {
        newClipPos.xy *= view;
        vec2 diff = newClipPos.xy - gl_FragCoord.xy + 0.01;
        ivec2 writePixelCoord = ivec2(gl_FragCoord.xy + floor(diff));
        uint depth = uint((1<<30) * newClipPos.z);
        if (imageLoad(colorimg9, writePixelCoord).r == depth) {
            vec2 prevSampleCoord = (gl_FragCoord.xy - fract(diff)) / view;
            vec4 writeData = vec4(newClipPos.z < 0.999998 ? texture(colortex4, prevSampleCoord).gba * 2 - 1 : vec3(0), 1 - newClipPos.z);
            imageStore(colorimg8, writePixelCoord, writeData);
        }
    }
    /*DRAWBUFFERS:1*/
    gl_FragData[0] = vec4(1);
}
#endif

//////Vertex Shader//////Vertex Shader//////
#ifdef VSH

out mat4 unprojectionMatrix, projectionMatrix;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform int frameCounter;

#define MATERIALMAP_ONLY
#include "/lib/vx/SSBOs.glsl"

void main() {
    projectionMatrix =
        gbufferProjection *
        gbufferModelView;
    unprojectionMatrix =
        gbufferPreviousModelViewInverse * 
        gbufferPreviousProjectionInverse;
    gl_Position = ftransform();
}
#endif