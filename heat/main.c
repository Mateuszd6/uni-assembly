#include <stdio.h>
#include <stdlib.h>

extern void
start(int szer, int wys, void* M, float C, float waga);

extern void
place(int ile, int* x, int* y, float* temp);

extern void
step(void);

struct loaded_data
{
    int w;
    int h;
    int num;
    int* x;
    int* y;
    float c;
    float* m;
    float* t;
};

static void
loaded_data_free_resources(struct loaded_data* self)
{
    free(self->x);
    free(self->y);
    free(self->m);
    free(self->t);
}

// Ustawiony przy allocate_M() wsk. na aktualna matryce. Zmienia go step.
static float** current;
static float*
get_current_M(void)
{
    return (* current);
}

static void*
allocate_M(int w, int h)
{
    // M zawiera dwie takie same tablice float'ow, zeby mozna bylo pracowac na
    // kopii. Na koncu jest pointer na aktualna matryce. Nasz kod w c
    // zapamietuje gdzie on jest. Kod w assemblerze zmienia to na co wskazuje
    // ten pointer po kazdym wywolaniu funckji step.
    size_t msize = sizeof(float) * (w + 2) * (h + 2) * 2;
    void* retval = malloc(msize + 8);
    current = (float**)(retval + msize);
    *current = retval;

    return retval;
}

static struct loaded_data
read_data(FILE* file)
{
    int w, h;
    float c;
    float* m;

    fscanf(file, "%d", &w);
    fscanf(file, "%d", &h);
    fscanf(file, "%f", &c);

    m = allocate_M(w, h);

    // Pozostawiamy miejsce dla chlodnic - ustawi je funckja start.
    for (int i = 0; i < h + 2; ++i)
        for (int j = 0; j < w + 2; ++j)
        {
            if (i == 0 || i == h + 1)
                continue;

            if (j == 0 || j == w + 1)
                continue;

            fscanf(file, "%f", m + (i * (w + 2) + j));
        }

    int num;
    fscanf(file, "%d", &num);

    int* x = malloc(sizeof(int) * num);
    int* y = malloc(sizeof(int) * num);
    float* temp = malloc(sizeof(float) * num);
    for (int i = 0; i < num; ++i)
    {
        fscanf(file, "%d", x + i);
        fscanf(file, "%d", y + i);
        fscanf(file, "%f", temp + i);
    }

    struct loaded_data retval = {0};
    retval.w = w;
    retval.h = h;
    retval.num = num;
    retval.x = x;
    retval.y = y;
    retval.c = c;
    retval.m = m;
    retval.t = temp;

    return retval;
}

int
main(int argc, char** argv)
{
    if (argc != 4)
    {
        fprintf(stderr, "Usage: %s [data file] [ratio] [num steps]\n", argv[0]);
        exit(1);
    }

    FILE* input_file = fopen(argv[1], "r");
    if (!input_file)
    {
        fprintf(stderr, "Could not open file: %s\n", argv[1]);
        exit(1);
    }

    struct loaded_data ld = read_data(input_file);
    fclose(input_file);

    float weight = atof(argv[2]); // wsp. rozchodzenia sie ciepla.
    int num_steps = atoi(argv[3]); // l. krokow symulacji.

    // Macierz po przeczytaniu pliku nie ma ustawionych wartosci chlodnic -
    // chlodnice na odpowiednich miejscach ustawia funckja start. Wymagamy
    // tylko, zeby matryca byla odpowiednio przygotowana (pozostawione miejsca
    // na chlodnice po wczytaniu danych).
    start(ld.w, ld.h, ld.m, ld.c, weight);
    place(ld.num, ld.x, ld.y, ld.t);

    for (int nstep = 0; nstep < num_steps; ++nstep)
    {
        printf("\n");
        float* curr_m = get_current_M();
        for (int i = 0; i < ld.h + 2; ++i)
        {
            for (int j = 0; j < ld.w + 2; ++j)
                printf("%.2f\t", (*(curr_m + (i * (ld.w + 2) + j))));

            printf("\n");
        }

        // ctrl+D wychodzi z pentli
        int should_end = getchar() == EOF;
        if (should_end)
            break;

        step();
    }

    loaded_data_free_resources(&ld);
    return 0;
}
