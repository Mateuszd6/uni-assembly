#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "easyppm/easyppm.h"

typedef char unsigned u8;
typedef int unsigned u32;

// Kod w asmie bedzie tego uzwal jak tablicy 3 word'ow, ale nam
// wygodniej ustawiac poszczegolne skladowe structowi.
typedef union
{
    struct
    {
        u32 r;
        u32 g;
        u32 b;
    } cols;
    u32 e[3];
} color_weight;

// To jest stala, ktora jest extern w asmie. Kod modyfikujacy obraz
// czyta z niej wagi pikseli, ktore najpierw moga byc zmienione z
// domyslnych na inne, z poziomu programu glownego.
color_weight colorw = {
    .cols = { 77, 151, 28 } // Domyslne wartosci.
};

extern void
rgb_to_grayscale(u8* rgb_image, u32 width, u32 height);

// Nalezy zwolnic pamiec zaalokowana przez ta funkcje!
static char*
rename_ppm_to_pgm(char const* orig_fname)
{
    // Dla uproszczenia nie sprawdzamy malloc'a.

    char const* last_dot = strrchr(orig_fname, '.');
    if (last_dot && strcmp(last_dot, ".ppm") == 0)
    {
        char* retval = (char*)malloc(strlen(orig_fname));
        *retval = 0;
        strcat(retval, orig_fname);

        size_t last_dot_offset = last_dot - orig_fname;
        char* p = retval + last_dot_offset + 1;
        *p++ = 'p';
        *p++ = 'g';
        *p++ = 'm';

        return retval;
    }
    else
    {
        // Jeśli plik nie ma rozszezenia .ppm to i tak sprobujemy
        // dodajac na koniec nazwy pliku .pgm
        char* retval = (char*)malloc(strlen(orig_fname) + 5);
        *retval = 0;
        strcat(retval, orig_fname);
        strcat(retval, ".pgm");

        return retval;
    }
}

static void
usage(char** argv)
{
    printf("Usage: %s file [R G B]\n", argv[0]);
    exit(1);
}

int
main(int argc, char** argv)
{
    // Ustawiamy argumenty.
    char const* fname = 0;
    if (argc == 2 || argc == 5)
    {
        fname = argv[1];
        if (argc == 5)
        {
            colorw.cols.r = atoi(argv[2]);
            colorw.cols.g = atoi(argv[3]);
            colorw.cols.b = atoi(argv[4]);

            if (colorw.cols.r > 256 || colorw.cols.g > 256 || colorw.cols.b > 256)
            {
                printf("All weights must be in range [0-255].\n");
                exit(1);
            }

            if (colorw.cols.r + colorw.cols.g + colorw.cols.b != 256)
            {
                printf("Color weights must sum up to 256. (%d + %d + %d != 256)\n",
                       colorw.cols.r, colorw.cols.g, colorw.cols.b);
                exit(1);
            }
        }
    }
    else
    {
        usage(argv);
    }

    char* output_fname = rename_ppm_to_pgm(fname);

    PPM ppm = easyppm_create(1, 1, IMAGETYPE_PPM);
    easyppm_read(&ppm, fname);

    u8* img = ppm.image;
    rgb_to_grayscale(img, ppm.width, ppm.height);

    // Nasz obraz jest zmieniony w miejscu, koduja go bajty na
    // poczatku obrazu zrodlowego. Kopiujemy na wynik.
    PPM output = easyppm_create(ppm.width, ppm.height, IMAGETYPE_PGM);
    u8* dest = output.image;

    size_t npixels = ppm.width * ppm.height;
    for (size_t i = 0; i != npixels; ++i)
        *dest++ = *img++;

    easyppm_write(&output, output_fname);
    free(output_fname);
    easyppm_destroy(&output);
    easyppm_destroy(&ppm);
    return 0;
}
