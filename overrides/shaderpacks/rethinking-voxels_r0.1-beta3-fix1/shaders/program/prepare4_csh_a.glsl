#include "/lib/common.glsl"

#ifdef CSH_A
const vec2 workGroupsRender = vec2(0.3125, 0.3125);
layout(local_size_x = 10, local_size_y = 10, local_size_z = 1) in;

uniform sampler2D colortex8;
uniform sampler2D colortex10;
layout(rgba16f) uniform image2D colorimg12;

shared vec3[20][20] readColors;

void main() {
    ivec2 localCoord = ivec2(gl_LocalInvocationID.xy) - 1;
    ivec2 globalInvocationID = ivec2(gl_WorkGroupID * 8) + localCoord;
    ivec2 texelCoord = 2 * globalInvocationID;
    bool canWrite = all(greaterThan(gl_LocalInvocationID.xy, uvec2(0))) && all(lessThanEqual(gl_LocalInvocationID.xy, uvec2(8)));
    for (int k = 0; k < 4; k++) {
        ivec2 readOffset = ivec2(k%2, k/2);
        vec4 readColor = texelFetch(colortex10, texelCoord + readOffset, 0);
        readColors[localCoord.x * 2 + 2 + readOffset.x][localCoord.y * 2 + 2 + readOffset.y] = readColor.xyz;
    }
    barrier();
    memoryBarrierShared();
    if (canWrite) {
        for (int k = 0; k < 4; k++) {
            ivec2 valueOffset = ivec2(k%2, k/2);
            for (int j = 0; j < 4; j++) {
                ivec2 writeOffset = ivec2(j%2, j/2);
                vec3 writeColor = vec3(0);
                vec4 writePosNDData = texelFetch(colortex8, 2 * (texelCoord + valueOffset) + writeOffset, 0) * vec4(1, 1, 1, 100);
                float totalWeight = 0.0001;
                for (int i = 0; i < 4; i++) {
                    ivec2 corner = ivec2(i%2, i/2);
                    vec4 cornerNDData = texelFetch(colortex8, 2 * (texelCoord + valueOffset + corner), 0) * vec4(1, 1, 1, 100);
                    float weight = (1 - corner.x + (corner.x - 0.5) * writeOffset.x) * (1 - corner.y + (corner.y - 0.5) * writeOffset.y);
                    weight *= max(0, 1 - length(cornerNDData - writePosNDData));
                    writeColor += weight * readColors[localCoord.x * 2 + 2 + valueOffset.x + corner.x][localCoord.y * 2 + 2 + valueOffset.y + corner.y];
                    totalWeight += weight;
                }
                writeColor /= totalWeight;
                imageStore(colorimg12, 2 * (texelCoord + valueOffset) + writeOffset, vec4(writeColor, 1));
            }
        }
    }
}
#endif