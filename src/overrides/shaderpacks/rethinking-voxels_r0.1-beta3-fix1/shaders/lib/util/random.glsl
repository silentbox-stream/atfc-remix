#ifndef INCLUDE_RANDOM
#define INCLUDE_RANDOM
#if defined FSH || defined FRAGMENT_SHADER
    #define gl_GlobalInvocationID uvec3(gl_FragCoord.xy, 0)
#endif

uint globalSeed = uint(frameCounter * 382 + gl_GlobalInvocationID.x * 419 + gl_GlobalInvocationID.y * 353 + gl_GlobalInvocationID.z * 383);

uint murmur(uint seed) {
    seed = (seed ^ (seed >> 16)) * 0x85ebca6bu;
    seed = (seed ^ (seed >> 13)) * 0xc2b2ae35u;
    return seed ^ (seed >> 16);
}

uint nextUint() {
    return murmur(globalSeed += 0x9e3779b9u);
}

float nextFloat() {
    return float(nextUint()) / float(uint(0xffffffff));
}

vec3 randomSphereSample() {
    float x1, x2;
    float len2;
    do {
        x1 = nextFloat() * 2 - 1;
        x2 = nextFloat() * 2 - 1;
        len2 = x1 * x1 + x2 * x2;
    } while (len2 >= 1);
    float x3 = sqrt(1 - len2);
    return vec3(
        2 * x1 * x3,
        2 * x2 * x3,
        1 - 2 * len2);
}

#endif