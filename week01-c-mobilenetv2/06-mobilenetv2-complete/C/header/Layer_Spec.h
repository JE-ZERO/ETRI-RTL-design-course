#ifndef LAYER_SPEC_H
#define LAYER_SPEC_H

#define EPSILON               1e-5f
#define KERNEL_SIZE           3

#define LAYER0_IN_H           224
#define LAYER0_IN_W           224
#define LAYER0_IN_C           3
#define LAYER0_OUT_H          112
#define LAYER0_OUT_W          112
#define LAYER0_OUT_C          32
#define LAYER0_KERNEL_SIZE    3
#define LAYER0_STRIDE         2
#define LAYER0_PADDING        1
#define LAYER0_IN_SIZE        (LAYER0_IN_H * LAYER0_IN_W * LAYER0_IN_C)
#define LAYER0_OUT_SIZE       (LAYER0_OUT_H * LAYER0_OUT_W * LAYER0_OUT_C)
#define LAYER1_IN_H           112
#define LAYER1_IN_W           112
#define LAYER1_IN_C           32
#define LAYER1_EXP_C          32
#define LAYER1_OUT_H          112
#define LAYER1_OUT_W          112
#define LAYER1_OUT_C          16
#define LAYER1_DW_KERNEL_SIZE 3
#define LAYER1_DW_STRIDE      1
#define LAYER1_DW_PADDING     1
#define LAYER1_HAS_EXPAND     0
#define LAYER1_HAS_SKIP       0
#define LAYER1_IN_SIZE        (LAYER1_IN_H * LAYER1_IN_W * LAYER1_IN_C)
#define LAYER1_EXP_SIZE       (LAYER1_IN_H * LAYER1_IN_W * LAYER1_EXP_C)
#define LAYER1_DW_OUT_SIZE    (LAYER1_OUT_H * LAYER1_OUT_W * LAYER1_EXP_C)
#define LAYER1_OUT_SIZE       (LAYER1_OUT_H * LAYER1_OUT_W * LAYER1_OUT_C)
#define LAYER2_IN_H           112
#define LAYER2_IN_W           112
#define LAYER2_IN_C           16
#define LAYER2_EXP_C          96
#define LAYER2_OUT_H          56
#define LAYER2_OUT_W          56
#define LAYER2_OUT_C          24
#define LAYER2_DW_KERNEL_SIZE 3
#define LAYER2_DW_STRIDE      2
#define LAYER2_DW_PADDING     1
#define LAYER2_HAS_EXPAND     1
#define LAYER2_HAS_SKIP       0
#define LAYER2_IN_SIZE        (LAYER2_IN_H * LAYER2_IN_W * LAYER2_IN_C)
#define LAYER2_EXP_SIZE       (LAYER2_IN_H * LAYER2_IN_W * LAYER2_EXP_C)
#define LAYER2_DW_OUT_SIZE    (LAYER2_OUT_H * LAYER2_OUT_W * LAYER2_EXP_C)
#define LAYER2_OUT_SIZE       (LAYER2_OUT_H * LAYER2_OUT_W * LAYER2_OUT_C)
#define LAYER3_IN_H           56
#define LAYER3_IN_W           56
#define LAYER3_IN_C           24
#define LAYER3_EXP_C          144
#define LAYER3_OUT_H          56
#define LAYER3_OUT_W          56
#define LAYER3_OUT_C          24
#define LAYER3_DW_KERNEL_SIZE 3
#define LAYER3_DW_STRIDE      1
#define LAYER3_DW_PADDING     1
#define LAYER3_HAS_EXPAND     1
#define LAYER3_HAS_SKIP       1
#define LAYER3_IN_SIZE        (LAYER3_IN_H * LAYER3_IN_W * LAYER3_IN_C)
#define LAYER3_EXP_SIZE       (LAYER3_IN_H * LAYER3_IN_W * LAYER3_EXP_C)
#define LAYER3_DW_OUT_SIZE    (LAYER3_OUT_H * LAYER3_OUT_W * LAYER3_EXP_C)
#define LAYER3_OUT_SIZE       (LAYER3_OUT_H * LAYER3_OUT_W * LAYER3_OUT_C)
#define LAYER4_IN_H           56
#define LAYER4_IN_W           56
#define LAYER4_IN_C           24
#define LAYER4_EXP_C          144
#define LAYER4_OUT_H          28
#define LAYER4_OUT_W          28
#define LAYER4_OUT_C          32
#define LAYER4_DW_KERNEL_SIZE 3
#define LAYER4_DW_STRIDE      2
#define LAYER4_DW_PADDING     1
#define LAYER4_HAS_EXPAND     1
#define LAYER4_HAS_SKIP       0
#define LAYER4_IN_SIZE        (LAYER4_IN_H * LAYER4_IN_W * LAYER4_IN_C)
#define LAYER4_EXP_SIZE       (LAYER4_IN_H * LAYER4_IN_W * LAYER4_EXP_C)
#define LAYER4_DW_OUT_SIZE    (LAYER4_OUT_H * LAYER4_OUT_W * LAYER4_EXP_C)
#define LAYER4_OUT_SIZE       (LAYER4_OUT_H * LAYER4_OUT_W * LAYER4_OUT_C)
#define LAYER5_IN_H           28
#define LAYER5_IN_W           28
#define LAYER5_IN_C           32
#define LAYER5_EXP_C          192
#define LAYER5_OUT_H          28
#define LAYER5_OUT_W          28
#define LAYER5_OUT_C          32
#define LAYER5_DW_KERNEL_SIZE 3
#define LAYER5_DW_STRIDE      1
#define LAYER5_DW_PADDING     1
#define LAYER5_HAS_EXPAND     1
#define LAYER5_HAS_SKIP       1
#define LAYER5_IN_SIZE        (LAYER5_IN_H * LAYER5_IN_W * LAYER5_IN_C)
#define LAYER5_EXP_SIZE       (LAYER5_IN_H * LAYER5_IN_W * LAYER5_EXP_C)
#define LAYER5_DW_OUT_SIZE    (LAYER5_OUT_H * LAYER5_OUT_W * LAYER5_EXP_C)
#define LAYER5_OUT_SIZE       (LAYER5_OUT_H * LAYER5_OUT_W * LAYER5_OUT_C)
#define LAYER6_IN_H           28
#define LAYER6_IN_W           28
#define LAYER6_IN_C           32
#define LAYER6_EXP_C          192
#define LAYER6_OUT_H          28
#define LAYER6_OUT_W          28
#define LAYER6_OUT_C          32
#define LAYER6_DW_KERNEL_SIZE 3
#define LAYER6_DW_STRIDE      1
#define LAYER6_DW_PADDING     1
#define LAYER6_HAS_EXPAND     1
#define LAYER6_HAS_SKIP       1
#define LAYER6_IN_SIZE        (LAYER6_IN_H * LAYER6_IN_W * LAYER6_IN_C)
#define LAYER6_EXP_SIZE       (LAYER6_IN_H * LAYER6_IN_W * LAYER6_EXP_C)
#define LAYER6_DW_OUT_SIZE    (LAYER6_OUT_H * LAYER6_OUT_W * LAYER6_EXP_C)
#define LAYER6_OUT_SIZE       (LAYER6_OUT_H * LAYER6_OUT_W * LAYER6_OUT_C)
#define LAYER7_IN_H           28
#define LAYER7_IN_W           28
#define LAYER7_IN_C           32
#define LAYER7_EXP_C          192
#define LAYER7_OUT_H          14
#define LAYER7_OUT_W          14
#define LAYER7_OUT_C          64
#define LAYER7_DW_KERNEL_SIZE 3
#define LAYER7_DW_STRIDE      2
#define LAYER7_DW_PADDING     1
#define LAYER7_HAS_EXPAND     1
#define LAYER7_HAS_SKIP       0
#define LAYER7_IN_SIZE        (LAYER7_IN_H * LAYER7_IN_W * LAYER7_IN_C)
#define LAYER7_EXP_SIZE       (LAYER7_IN_H * LAYER7_IN_W * LAYER7_EXP_C)
#define LAYER7_DW_OUT_SIZE    (LAYER7_OUT_H * LAYER7_OUT_W * LAYER7_EXP_C)
#define LAYER7_OUT_SIZE       (LAYER7_OUT_H * LAYER7_OUT_W * LAYER7_OUT_C)
#define LAYER8_IN_H           14
#define LAYER8_IN_W           14
#define LAYER8_IN_C           64
#define LAYER8_EXP_C          384
#define LAYER8_OUT_H          14
#define LAYER8_OUT_W          14
#define LAYER8_OUT_C          64
#define LAYER8_DW_KERNEL_SIZE 3
#define LAYER8_DW_STRIDE      1
#define LAYER8_DW_PADDING     1
#define LAYER8_HAS_EXPAND     1
#define LAYER8_HAS_SKIP       1
#define LAYER8_IN_SIZE        (LAYER8_IN_H * LAYER8_IN_W * LAYER8_IN_C)
#define LAYER8_EXP_SIZE       (LAYER8_IN_H * LAYER8_IN_W * LAYER8_EXP_C)
#define LAYER8_DW_OUT_SIZE    (LAYER8_OUT_H * LAYER8_OUT_W * LAYER8_EXP_C)
#define LAYER8_OUT_SIZE       (LAYER8_OUT_H * LAYER8_OUT_W * LAYER8_OUT_C)
#define LAYER9_IN_H           14
#define LAYER9_IN_W           14
#define LAYER9_IN_C           64
#define LAYER9_EXP_C          384
#define LAYER9_OUT_H          14
#define LAYER9_OUT_W          14
#define LAYER9_OUT_C          64
#define LAYER9_DW_KERNEL_SIZE 3
#define LAYER9_DW_STRIDE      1
#define LAYER9_DW_PADDING     1
#define LAYER9_HAS_EXPAND     1
#define LAYER9_HAS_SKIP       1
#define LAYER9_IN_SIZE        (LAYER9_IN_H * LAYER9_IN_W * LAYER9_IN_C)
#define LAYER9_EXP_SIZE       (LAYER9_IN_H * LAYER9_IN_W * LAYER9_EXP_C)
#define LAYER9_DW_OUT_SIZE    (LAYER9_OUT_H * LAYER9_OUT_W * LAYER9_EXP_C)
#define LAYER9_OUT_SIZE       (LAYER9_OUT_H * LAYER9_OUT_W * LAYER9_OUT_C)
#define LAYER10_IN_H           14
#define LAYER10_IN_W           14
#define LAYER10_IN_C           64
#define LAYER10_EXP_C          384
#define LAYER10_OUT_H          14
#define LAYER10_OUT_W          14
#define LAYER10_OUT_C          64
#define LAYER10_DW_KERNEL_SIZE 3
#define LAYER10_DW_STRIDE      1
#define LAYER10_DW_PADDING     1
#define LAYER10_HAS_EXPAND     1
#define LAYER10_HAS_SKIP       1
#define LAYER10_IN_SIZE        (LAYER10_IN_H * LAYER10_IN_W * LAYER10_IN_C)
#define LAYER10_EXP_SIZE       (LAYER10_IN_H * LAYER10_IN_W * LAYER10_EXP_C)
#define LAYER10_DW_OUT_SIZE    (LAYER10_OUT_H * LAYER10_OUT_W * LAYER10_EXP_C)
#define LAYER10_OUT_SIZE       (LAYER10_OUT_H * LAYER10_OUT_W * LAYER10_OUT_C)
#define LAYER11_IN_H           14
#define LAYER11_IN_W           14
#define LAYER11_IN_C           64
#define LAYER11_EXP_C          384
#define LAYER11_OUT_H          14
#define LAYER11_OUT_W          14
#define LAYER11_OUT_C          96
#define LAYER11_DW_KERNEL_SIZE 3
#define LAYER11_DW_STRIDE      1
#define LAYER11_DW_PADDING     1
#define LAYER11_HAS_EXPAND     1
#define LAYER11_HAS_SKIP       0
#define LAYER11_IN_SIZE        (LAYER11_IN_H * LAYER11_IN_W * LAYER11_IN_C)
#define LAYER11_EXP_SIZE       (LAYER11_IN_H * LAYER11_IN_W * LAYER11_EXP_C)
#define LAYER11_DW_OUT_SIZE    (LAYER11_OUT_H * LAYER11_OUT_W * LAYER11_EXP_C)
#define LAYER11_OUT_SIZE       (LAYER11_OUT_H * LAYER11_OUT_W * LAYER11_OUT_C)
#define LAYER12_IN_H           14
#define LAYER12_IN_W           14
#define LAYER12_IN_C           96
#define LAYER12_EXP_C          576
#define LAYER12_OUT_H          14
#define LAYER12_OUT_W          14
#define LAYER12_OUT_C          96
#define LAYER12_DW_KERNEL_SIZE 3
#define LAYER12_DW_STRIDE      1
#define LAYER12_DW_PADDING     1
#define LAYER12_HAS_EXPAND     1
#define LAYER12_HAS_SKIP       1
#define LAYER12_IN_SIZE        (LAYER12_IN_H * LAYER12_IN_W * LAYER12_IN_C)
#define LAYER12_EXP_SIZE       (LAYER12_IN_H * LAYER12_IN_W * LAYER12_EXP_C)
#define LAYER12_DW_OUT_SIZE    (LAYER12_OUT_H * LAYER12_OUT_W * LAYER12_EXP_C)
#define LAYER12_OUT_SIZE       (LAYER12_OUT_H * LAYER12_OUT_W * LAYER12_OUT_C)
#define LAYER13_IN_H           14
#define LAYER13_IN_W           14
#define LAYER13_IN_C           96
#define LAYER13_EXP_C          576
#define LAYER13_OUT_H          14
#define LAYER13_OUT_W          14
#define LAYER13_OUT_C          96
#define LAYER13_DW_KERNEL_SIZE 3
#define LAYER13_DW_STRIDE      1
#define LAYER13_DW_PADDING     1
#define LAYER13_HAS_EXPAND     1
#define LAYER13_HAS_SKIP       1
#define LAYER13_IN_SIZE        (LAYER13_IN_H * LAYER13_IN_W * LAYER13_IN_C)
#define LAYER13_EXP_SIZE       (LAYER13_IN_H * LAYER13_IN_W * LAYER13_EXP_C)
#define LAYER13_DW_OUT_SIZE    (LAYER13_OUT_H * LAYER13_OUT_W * LAYER13_EXP_C)
#define LAYER13_OUT_SIZE       (LAYER13_OUT_H * LAYER13_OUT_W * LAYER13_OUT_C)
#define LAYER14_IN_H           14
#define LAYER14_IN_W           14
#define LAYER14_IN_C           96
#define LAYER14_EXP_C          576
#define LAYER14_OUT_H          7
#define LAYER14_OUT_W          7
#define LAYER14_OUT_C          160
#define LAYER14_DW_KERNEL_SIZE 3
#define LAYER14_DW_STRIDE      2
#define LAYER14_DW_PADDING     1
#define LAYER14_HAS_EXPAND     1
#define LAYER14_HAS_SKIP       0
#define LAYER14_IN_SIZE        (LAYER14_IN_H * LAYER14_IN_W * LAYER14_IN_C)
#define LAYER14_EXP_SIZE       (LAYER14_IN_H * LAYER14_IN_W * LAYER14_EXP_C)
#define LAYER14_DW_OUT_SIZE    (LAYER14_OUT_H * LAYER14_OUT_W * LAYER14_EXP_C)
#define LAYER14_OUT_SIZE       (LAYER14_OUT_H * LAYER14_OUT_W * LAYER14_OUT_C)
#define LAYER15_IN_H           7
#define LAYER15_IN_W           7
#define LAYER15_IN_C           160
#define LAYER15_EXP_C          960
#define LAYER15_OUT_H          7
#define LAYER15_OUT_W          7
#define LAYER15_OUT_C          160
#define LAYER15_DW_KERNEL_SIZE 3
#define LAYER15_DW_STRIDE      1
#define LAYER15_DW_PADDING     1
#define LAYER15_HAS_EXPAND     1
#define LAYER15_HAS_SKIP       1
#define LAYER15_IN_SIZE        (LAYER15_IN_H * LAYER15_IN_W * LAYER15_IN_C)
#define LAYER15_EXP_SIZE       (LAYER15_IN_H * LAYER15_IN_W * LAYER15_EXP_C)
#define LAYER15_DW_OUT_SIZE    (LAYER15_OUT_H * LAYER15_OUT_W * LAYER15_EXP_C)
#define LAYER15_OUT_SIZE       (LAYER15_OUT_H * LAYER15_OUT_W * LAYER15_OUT_C)
#define LAYER16_IN_H           7
#define LAYER16_IN_W           7
#define LAYER16_IN_C           160
#define LAYER16_EXP_C          960
#define LAYER16_OUT_H          7
#define LAYER16_OUT_W          7
#define LAYER16_OUT_C          160
#define LAYER16_DW_KERNEL_SIZE 3
#define LAYER16_DW_STRIDE      1
#define LAYER16_DW_PADDING     1
#define LAYER16_HAS_EXPAND     1
#define LAYER16_HAS_SKIP       1
#define LAYER16_IN_SIZE        (LAYER16_IN_H * LAYER16_IN_W * LAYER16_IN_C)
#define LAYER16_EXP_SIZE       (LAYER16_IN_H * LAYER16_IN_W * LAYER16_EXP_C)
#define LAYER16_DW_OUT_SIZE    (LAYER16_OUT_H * LAYER16_OUT_W * LAYER16_EXP_C)
#define LAYER16_OUT_SIZE       (LAYER16_OUT_H * LAYER16_OUT_W * LAYER16_OUT_C)
#define LAYER17_IN_H           7
#define LAYER17_IN_W           7
#define LAYER17_IN_C           160
#define LAYER17_EXP_C          960
#define LAYER17_OUT_H          7
#define LAYER17_OUT_W          7
#define LAYER17_OUT_C          320
#define LAYER17_DW_KERNEL_SIZE 3
#define LAYER17_DW_STRIDE      1
#define LAYER17_DW_PADDING     1
#define LAYER17_HAS_EXPAND     1
#define LAYER17_HAS_SKIP       0
#define LAYER17_IN_SIZE        (LAYER17_IN_H * LAYER17_IN_W * LAYER17_IN_C)
#define LAYER17_EXP_SIZE       (LAYER17_IN_H * LAYER17_IN_W * LAYER17_EXP_C)
#define LAYER17_DW_OUT_SIZE    (LAYER17_OUT_H * LAYER17_OUT_W * LAYER17_EXP_C)
#define LAYER17_OUT_SIZE       (LAYER17_OUT_H * LAYER17_OUT_W * LAYER17_OUT_C)
#define LAYER18_IN_H           7
#define LAYER18_IN_W           7
#define LAYER18_IN_C           320
#define LAYER18_OUT_H          7
#define LAYER18_OUT_W          7
#define LAYER18_OUT_C          1280
#define LAYER18_PW_KERNEL_SIZE 1
#define LAYER18_PW_STRIDE      1
#define LAYER18_PW_PADDING     0
#define LAYER18_HAS_EXPAND     0
#define LAYER18_HAS_SKIP       0
#define LAYER18_IN_SIZE        (LAYER18_IN_H * LAYER18_IN_W * LAYER18_IN_C)
#define LAYER18_OUT_SIZE       (LAYER18_OUT_H * LAYER18_OUT_W * LAYER18_OUT_C)
//AvgPool : Global Average Pooling 7x7
#define AVGPOOL_IN_H           7
#define AVGPOOL_IN_W           7
#define AVGPOOL_IN_C           1280

#define AVGPOOL_OUT_H          1
#define AVGPOOL_OUT_W          1
#define AVGPOOL_OUT_C          1280

#define AVGPOOL_IN_SIZE        (AVGPOOL_IN_H * AVGPOOL_IN_W * AVGPOOL_IN_C)
#define AVGPOOL_OUT_SIZE       (AVGPOOL_OUT_H * AVGPOOL_OUT_W * AVGPOOL_OUT_C)


//Classifier : Conv2d 1x1 + Bias
#define CLASSIFIER_IN_H        1
#define CLASSIFIER_IN_W        1
#define CLASSIFIER_IN_C        1280

#define CLASSIFIER_OUT_H       1
#define CLASSIFIER_OUT_W       1
#define CLASSIFIER_OUT_C       1000

#define CLASSIFIER_IN_SIZE     (CLASSIFIER_IN_H * CLASSIFIER_IN_W * CLASSIFIER_IN_C)
#define CLASSIFIER_OUT_SIZE    (CLASSIFIER_OUT_H * CLASSIFIER_OUT_W * CLASSIFIER_OUT_C)
#endif
