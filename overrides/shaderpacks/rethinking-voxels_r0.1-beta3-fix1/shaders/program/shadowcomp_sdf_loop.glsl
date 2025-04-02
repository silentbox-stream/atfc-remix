{
    ivec3 prevTexCoord0 = texCoord + (1<<j) * camOffset;
    ivec3 prevTexCoord = prevTexCoord0 + ivec3(0, (frameCounter % 2 * 2 + j/4) * voxelVolumeSize.y, 0);
    ivec3 prevCoord = prevTexCoord0 / 2 + voxelVolumeSize / 4 + ivec3(0, (frameCounter % 2 * 2 + (j-1)/4) * voxelVolumeSize.y, 0);
    ivec3 prevFractCoord = prevTexCoord0 % 2 + 1;
    fullDist[localCoord.x+1][localCoord.y+1][localCoord.z+1] =
        (thisOccupancy >> j & 1) == 1 ? (1.0-1.0/sqrt(3.0)) / (1<<j) : (
        all(greaterThanEqual(prevTexCoord0, ivec3(0))) &&
        all(lessThan(prevTexCoord0, voxelVolumeSize)) ?
        imageLoad(distanceFieldI, prevTexCoord)[j%4] + 1.0 / (1<<j) : (
            #if j > 0
                max(imageLoad(distanceFieldI, prevCoord)[(j-1)%4] - 0.5 / (1<<j), 1.0/(1<<j))
            #else
                1000.0
            #endif
        ));
    barrier();
    memoryBarrierShared();
    if (all(greaterThanEqual(localCoord, ivec3(0))) && all(lessThan(localCoord, ivec3(8)))) {
        #if j > 0
            float prevDist = mix(
                imageLoad(distanceFieldI, prevCoord)[(j-1)%4],
                imageLoad(distanceFieldI, prevCoord + 2 * prevFractCoord - 1)[(j-1)%4],
                0.0
            );
            if (prevDist < 3.0/(1<<j)) {
            #endif
            theseDists[j] = (thisOccupancy >> j & 1) == 1 ? -1.0/sqrt(3.0) / (1<<j) : ((thisOccupancy >> j+8 & 1) == 1 ? 0.5 : 1000);
            #if j > 0
                if (any(lessThan(texCoord, ivec3(1))) || any(greaterThanEqual(texCoord, voxelVolumeSize - 1))) {
                    theseDists[j] = min(theseDists[j], prevDist + 0.25/(1<<j));
                }
            #endif

            for (int k = 0; k < 27; k++) {
                ivec3 c2 = localCoord + ivec3(k%3, k/3%3, k/9%3);
                ivec3 c3 = localCoord + 2 * ivec3(k%3, k/3%3, k/9%3) - 1;
                theseDists[j] = min(theseDists[j], fullDist[c2.x][c2.y][c2.z]);
                theseDists[j] = min(theseDists[j], all(greaterThanEqual(c3, ivec3(0))) && all(lessThan(c3, ivec3(10))) ? fullDist[c3.x][c3.y][c3.z] + 1.0/(1<<j) : 1000);
            }
        #if j > 0
                if (prevDist > 2.0/(1<<j)) {
                    theseDists[j] = mix(theseDists[j], prevDist - 0.5 / (1<<j),  prevDist * (1<<j) - 2.0);
                }
            } else {
                theseDists[j] = prevDist - 0.5/(1<<j);
            }
        #endif
    }
    barrier();
}
