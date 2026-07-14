#include <stdio.h>
#include <stdlib.h>
#include "bitmap.h"

int main()
{
    FILE *fpBmp;//읽어오기용
    FILE *fpOut;//출력용

    BITMAPFILEHEADER fileHeader;//비트맵 파일 헤더 구조체 선언(14바이트)
    BITMAPINFOHEADER infoHeader;//비트맵 정보 헤더 구조체 선언(40바이트)


    fpBmp=fopen("lenna.bmp", "rb");//스트림 연결(바이너리 읽기)

    if(fpBmp==NULL)//읽지 못하는 경우 예외처리
    {
        printf("Not available to open file");
        return 1;
    }

    //순차로 파일/정보헤더 읽어오기
    fread(&fileHeader, sizeof(BITMAPFILEHEADER), 1, fpBmp);
    fread(&infoHeader, sizeof(BITMAPINFOHEADER), 1, fpBmp);

    //파일헤더 출력
    printf("\n===== FILE HEADER =====\n");
    printf("bfType = %x\n", fileHeader.bfType);
    printf("bfSize = %x\n", fileHeader.bfSize);
    printf("bfOffBits = %u\n", fileHeader.bfOffBits);


    //정보헤더 출력
    printf("\n===== INFO HEADER =====\n");
    printf("biSize = %u\n", infoHeader.biSize);
    printf("biWidth = %d\n", infoHeader.biWidth);
    printf("biHeight = %d\n", infoHeader.biHeight);
    printf("biPlanes = %u\n", infoHeader.biPlanes);
    printf("biBitCount = %u\n", infoHeader.biBitCount);
    printf("biCompression = %u\n", infoHeader.biCompression);
    printf("biSizeImage = %u\n", infoHeader.biSizeImage);
    printf("biXPelsPerMeter = %d\n", infoHeader.biXPelsPerMeter);
    printf("biYPelsPerMeter = %d\n", infoHeader.biYPelsPerMeter);
    printf("biClrUsed = %u\n", infoHeader.biClrUsed);
    printf("biClrImportant = %u\n", infoHeader.biClrImportant);


    //읽은 파일의 이미지 크기와 같은 크기의 배열 동적할당
    unsigned char *pO=(unsigned char*)calloc(infoHeader.biSizeImage, sizeof(unsigned char));

    if(pO==NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed");
        fclose(fpBmp);
        return 1;
    }

    fseek(fpBmp, fileHeader.bfOffBits, SEEK_SET);//실제 이미지의 픽셀 데이터 찾기
    fread(pO, sizeof(unsigned char), infoHeader.biSizeImage, fpBmp);//실제 이미지의 픽셀 데이터 읽기


    fpOut = fopen("output_horizntal.bmp", "wb");//출력 파일 열기(바이너리 쓰기)


    if(fpOut==NULL)//파일생성실패 예외처리
    {
        printf("Not available to create file");
        free(pO);
        fclose(fpBmp);
        return 1;
    }

    fwrite(&fileHeader, sizeof(BITMAPFILEHEADER), 1, fpOut);//파일 헤더 쓰기
    fwrite(&infoHeader, sizeof(BITMAPINFOHEADER), 1, fpOut);//정보 헤더 쓰기

    int i, j, k;
    int rowSize;

    //행 크기(RGB포함)
    rowSize=infoHeader.biSizeImage/infoHeader.biHeight;

    //인덱싱
    for(i=0; i<infoHeader.biHeight; i++)
    {
        for(j=infoHeader.biWidth-1; j>= 0; j--)
        {
            for(k=0; k<3; k++)
            {
                fwrite(pO+i*rowSize+j*3+k, sizeof(unsigned char), 1, fpOut);
            }
        }
    }
    

    fclose(fpOut);//fopen 후 꼭 해줘야함
    fclose(fpBmp);//fopen 후 꼭 해줘야함

    free(pO);//동적할당 해제

    return 0;
}