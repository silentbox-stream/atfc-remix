////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

//Uniforms//
uniform float viewWidth, viewHeight;

#ifndef LIGHT_COLORING
    uniform sampler2D colortex3;
#else
    uniform sampler2D colortex8;
#endif

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//
#ifdef FXAA
    #include "/lib/antialiasing/fxaa.glsl"
#endif

//Program//

uniform int frameCounter;
#include "/lib/vx/voxelReading.glsl"
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform sampler2D colortex4;
uniform sampler2D colortex12;
void main() {
    #ifndef LIGHT_COLORING
        vec3 color = texelFetch(colortex3, texelCoord, 0).rgb;
    #else
        vec3 color = texelFetch(colortex8, texelCoord, 0).rgb;
    #endif

    #ifdef FXAA
        FXAA311(color);
    #endif
    if (texCoord.x < 0.5) {
//        color = getDistanceField(vec3(texCoord.xy * 10 - vec2(2.5, 5.0), 0.2)).xxx;
    } else if (false) {
//        color = texelFetch(colortex4, texelCoord, 0).gba;
        vec4 dir = gbufferModelViewInverse * (gbufferProjectionInverse * vec4(texCoord * 2 - 1, 0.999, 1));
        dir = normalize(dir * dir.w);
        vec3 start = fract(cameraPosition) + 2 * dir.xyz;
        vec3 normal;
        vec4 hitPos = voxelTrace(start, dir.xyz * 128, normal);
        //normal = normalize(distanceFieldGradient(hitPos));
        //if (!(length(normal) > 0.5)) normal = vec3(0);
        if (hitPos.a > 15) color = getColor(hitPos.xyz - 0.1 * normal).xyz + 0.2 * normal + 0.2;
    }
    #ifndef LIGHT_COLORING
    /* DRAWBUFFERS:3 */
    #else
    /* DRAWBUFFERS:8 */
    #endif
    gl_FragData[0] = vec4(color, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

//Uniforms//

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif
