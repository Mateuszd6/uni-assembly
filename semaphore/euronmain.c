#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include <pthread.h>

uint64_t euron(uint64_t n, char const* prog);

uint64_t get_value(uint64_t n)
{
    printf("GET_VALUE (n = %llu) -> %llu\n", n, n + 1);

    assert(n < N);
    return n + 1;
}

void put_value(uint64_t n, uint64_t v)
{
    printf("PUT_VALUE (n = %llu, v = %lld)\n", n ,v);

    assert(n < N);
    // assert(v == n + 4); TODO: Bring back!
}

void
DEBUG_sync(int64_t n, int64_t for_who)
{
    printf("%ld is synced with %ld\n", n, for_who);
}

void DEBUG_currchar(uint64_t ch)
{
    printf("Current: %c\n", (char)(ch));
}

typedef struct
{
    size_t n;
    char const* txt;
} eurarg;

void* run(void* argptr)
{
    eurarg arg = *((eurarg*)(argptr));
    return (void*)(euron(arg.n, arg.txt));
}

#if 1
int main()
{
    pthread_t pt[N];
    char const* common_txt = "01234n+P56789E-+D+*G*1n-+S2ED+E1-+75+-BC";

    eurarg arg0 = {0};
    arg0.n = 0;
    arg0.txt = common_txt;

    eurarg arg1 = {0};
    arg1.n = 1;
    arg1.txt = common_txt;

    for (int i = 0; i < N; ++i)
    {
        int err = pthread_create(&pt[i], 0, run,
                                 i == 0 ? (void*)(&arg0) : (void*)(&arg1));
        assert(!err);
    }

    for( int i = 0; i < N; ++i)
    {
        void* retval;
        int err = pthread_join(pt[i], &retval);
        assert(!err);

        printf("Output for i=%d: %lld\n", i, (ssize_t)retval);
    }

    return 0;
}
#else
int main()
{
    asm volatile("mov $1, %rbx\n"
                 "mov $2, %r12\n"
                 "mov $3, %r13\n"
                 "mov $4, %r14\n"
                 "mov $5, %r15\n");

    char const* common_txt = "01234n+P56789E-+D+*G*1n-+1234";
    euron(0, common_txt);

    return 0;
}
#endif
