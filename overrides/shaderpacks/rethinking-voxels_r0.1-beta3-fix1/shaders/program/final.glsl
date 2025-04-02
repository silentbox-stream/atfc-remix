////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

//Uniforms//
uniform int frameCounter;

uniform float viewWidth, viewHeight;

uniform sampler2D shadowcolor0;
#ifndef LIGHT_COLORING
    uniform sampler2D colortex3;
#else
    uniform sampler2D colortex8;
#endif

#ifdef UNDERWATER_DISTORTION
    uniform int isEyeInWater;

    uniform float frameTimeCounter;
#endif

//Pipeline Constants//
#include "/lib/pipelineSettings.glsl"

//Common Variables//

//Common Functions//
#if IMAGE_SHARPENING > 0
    vec2 viewD = 1.0 / vec2(viewWidth, viewHeight);

    vec2 sharpenOffsets[4] = vec2[4](
        vec2( viewD.x,  0.0),
        vec2( 0.0,  viewD.x),
        vec2(-viewD.x,  0.0),
        vec2( 0.0, -viewD.x)
    );

    void SharpenImage(inout vec3 color, vec2 texCoordM) {
        float mult = 0.0125 * IMAGE_SHARPENING;
        color *= 1.0 + 0.05 * IMAGE_SHARPENING;

        for (int i = 0; i < 4; i++) {
            #ifndef LIGHT_COLORING
                color -= texture2D(colortex3, texCoordM + sharpenOffsets[i]).rgb * mult;
            #else
                color -= texture2D(colortex8, texCoordM + sharpenOffsets[i]).rgb * mult;
            #endif
        }
    }
#endif

//Includes//
#include "/lib/util/textRendering.glsl"

void beginTextM(int textSize, vec2 offset) {
    beginText(ivec2(vec2(viewWidth, viewHeight) * texCoord) / textSize, ivec2(0 + offset.x, viewHeight / textSize - offset.y));
    text.bgCol = vec4(0.0);
}
#define WRITE_TO_SSBOS
#include "/lib/vx/SSBOs.glsl"

//Program//
void main() {
    vec2 texCoordM = texCoord;

    #ifdef UNDERWATER_DISTORTION
        if (isEyeInWater == 1)
            texCoordM += WATER_REFRACTION_INTENSITY * 0.00035 * sin((texCoord.x + texCoord.y) * 25.0 + frameTimeCounter * 3.0);
    #endif

    #ifndef LIGHT_COLORING
        vec3 color = texture2D(colortex3, texCoordM).rgb;
    #else
        vec3 color = texture2D(colortex8, texCoordM).rgb;
    #endif

    #if CHROMA_ABERRATION > 0
        vec2 scale = vec2(1.0, viewHeight / viewWidth);
        vec2 aberration = (texCoordM - 0.5) * (2.0 / vec2(viewWidth, viewHeight)) * scale * CHROMA_ABERRATION;
        #ifndef LIGHT_COLORING
            color.rb = vec2(texture2D(colortex3, texCoordM + aberration).r, texture2D(colortex3, texCoordM - aberration).b);
        #else
            color.rb = vec2(texture2D(colortex8, texCoordM + aberration).r, texture2D(colortex8, texCoordM - aberration).b);
        #endif
    #endif

    #if IMAGE_SHARPENING > 0
        SharpenImage(color, texCoordM);
    #endif

    /*ivec2 boxOffsets[8] = ivec2[8](
        ivec2( 1, 0),
        ivec2( 0, 1),
        ivec2(-1, 0),
        ivec2( 0,-1),
        ivec2( 1, 1),
        ivec2( 1,-1),
        ivec2(-1, 1),
        ivec2(-1,-1)
    );

    for (int i = 0; i < 8; i++) {
        color = max(color, texelFetch(colortex3, texelCoord + boxOffsets[i], 0).rgb);
    }*/

    #ifdef LIGHT_COLORING
        if (max(texCoordM.x, texCoordM.y) < 0.25) color = texture2D(colortex3, texCoordM * 4.0).rgb;
    #endif

    //if (gl_FragCoord.x < 479 || gl_FragCoord.x > 1441) color = vec3(0.0);
    if (gl_FragCoord.x < 0) color = texture(shadowcolor0, texCoord).rgb;
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);

    int index = int(gl_FragCoord.x) + int(viewWidth + 0.5) * int(gl_FragCoord.y);
    int clearPerFragment = 1 + 4 * (1<<18) / int(viewWidth * viewHeight + 0.5);
    if (index < 4 * (1<<18) / clearPerFragment) {
        for (int j = 0; j < clearPerFragment; j++) {
            globalLightHashMap[index * clearPerFragment + j] = uint(0);
        }
    }
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

//Uniforms//

uniform int frameCounter;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

//Attributes//

//Common Variables//

//Common Functions//

//Includes//
#define WRITE_TO_SSBOS
#include "/lib/vx/SSBOs.glsl"

//Program//
void main() {
    gbufferPreviousModelViewInverse = gbufferModelViewInverse;
    gbufferPreviousProjectionInverse = gbufferProjectionInverse;
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif
