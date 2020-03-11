#include <stdlib.h>
#include <stdio.h>

#include "./easyppm/easyppm.h"
#include "./easyppm/easyppm.c"

extern void
changeimg(char* imgdata, long h, long w, char ink, char value);

void
usage(char** argv)
{
    printf("Usage: %s [file] [R|G|B] [change (in [-127;127])]\n", argv[0]);
    exit(1);
}

int
main(int argc, char** argv)
{
    char const* fname;
    char* dest_fname;
    char ink;
    int change;

    if (argc != 4 || argv[2][1]) // Drugi arg to musi być jedna litera
        usage(argv);

    fname = argv[1];
    ink = argv[2][0];
    if (ink != 'R' && ink != 'G' && ink != 'B')
        usage(argv);

    change = atoi(argv[3]);
    if (change < -127 || change > 127)
        usage(argv);

    char const* last_slash = strrchr(fname, '/');
    dest_fname = malloc(strlen(fname) + 2); // 2 bo \0 i Y na poczatku.
    dest_fname[0] = 0;
    if (last_slash)
    {
        strncat(dest_fname, fname, last_slash - fname + 1);
        strcat(dest_fname, "Y");
        strcat(dest_fname, last_slash + 1);
    }
    else
    {
        strcat(dest_fname, "Y");
        strcat(dest_fname, fname);
    }

    PPM ppm = easyppm_create(256, 256, IMAGETYPE_PPM);
    easyppm_read(&ppm, fname);

    // Nasza biblioteka alokuje dokladnie tyle pamieci ile potrzebuje,
    // wiec musimy zrobic malloca i zarezerwowac sobie wiecej, bo
    // nasze instrukcje moga napisac cos nieco poza tablica. Mogloby
    // byc troche mniej dodatkowej pamieci ale tak dla bezpieczenstwa.
    void* d = malloc((ppm.width * ppm.height) * 3 + 128);
    // To wyrownanie byloby potrzebna dla avx, ktore mi nie dzialaja na students.
    void* data = (void*)(((size_t)(d) + 32) & ~(32 - 1));
    memcpy(data, (char*)ppm.image, ppm.width * ppm.height * 3);
    changeimg(data, ppm.height, ppm.width, ink, (char)change);
    memcpy(ppm.image, data, ppm.width * ppm.height * 3);

    // Zapisujemy do pliku, zwalniamy pamiec i konczymy. Dla
    // uproszczenia pomijamy sprawdzanie czy write zadzialalo.
    easyppm_write(&ppm, dest_fname);
    easyppm_destroy(&ppm);
    free(d);
    free(dest_fname);

    return 0;
}
