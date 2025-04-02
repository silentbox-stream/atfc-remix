/*
const int colortex0Format = R11F_G11F_B10F; //main color
const int colortex1Format = R16;            //previous depth
const int colortex2Format = RGBA16F;        //taa & previous depth
const int colortex3Format = RGBA8;          //(cloud/water map on deferred) | translucentMult & bloom & final color // can replace colortex8
const int colortex4Format = RGBA8;          //volumetric cloud linear depth & volumetric light factor & normalM in composite
const int colortex5Format = RGBA8_SNORM;    //normalM & scene image for water reflections
const int colortex6Format = RGBA8;          //smoothnessD & materialMask & skyLightFactor
const int colortex7Format = RGBA16F;        //(cloud/water map on gbuffers) | temporal filter
const int colortex8Format = RGBA8;          //light source info but replaces colortex3 to work as colorimg3
const int colortex8Format = RGBA16F;        //reprojected normal and depth data in prepare
const int colortex9Format = R32UI;          //scaled depth for atomics in reprojection validation
const int colortex10Format= RGBA16F;        //raw block lighting in bottom left quarter
const int colortex11Format= RGBA16I;        //valid light sample storage in bottom left quarter
const int colortex12Format= RGBA32F;        //accumulated block lighting
const int colortex13Format= RGBA16F;        //denoised block lighting
const int colortex14Format = R8;            //Conway's game of life
*/
const bool colortex0Clear = true;
const bool colortex1Clear = false;
const bool colortex2Clear = false;

const bool colortex3Clear = true;

const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = true;
const bool colortex7Clear = false;
const bool colortex8Clear = false;
const bool colortex9Clear = false;
const bool colortex10Clear = false;
const bool colortex11Clear = false;
const bool colortex12Clear = false;
const bool colortex13Clear = false;
const bool colortex14Clear = false;

const int noiseTextureResolution = 128;

const bool shadowHardwareFiltering = true;
const float shadowDistanceRenderMul = 1.0;
const float entityShadowDistanceMul = 0.5; // Iris feature

const float drynessHalflife = 300.0;
const float wetnessHalflife = 300.0;

const float ambientOcclusionLevel = 1.0;
