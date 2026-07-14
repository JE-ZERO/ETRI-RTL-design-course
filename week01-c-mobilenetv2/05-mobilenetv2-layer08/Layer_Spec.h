#ifndef LAYER_SPEC_H
#define LAYER_SPEC_H
#define EPSILON          1e-5f

#define LAYER8_IN_H      14
#define LAYER8_IN_W      14
#define LAYER8_IN_C      64

#define LAYER8_EXP_C     384
#define LAYER8_OUT_C     64

#define LAYER8_IN_SIZE   (LAYER8_IN_H * LAYER8_IN_W * LAYER8_IN_C)
#define LAYER8_EXP_SIZE  (LAYER8_IN_H * LAYER8_IN_W * LAYER8_EXP_C)
#define LAYER8_OUT_SIZE  (LAYER8_IN_H * LAYER8_IN_W * LAYER8_OUT_C)

#endif