.text
.global rgb_to_grayscale

.balign 4
.global colorw

.balign 4
rgb_to_grayscale:
        /* Dla 0 pixeli nie ma nic do roboty. */
        cmp     r2, #0
        beq     .END

	/* Parametry:
         *   r0  - matryca - jednoczesnie piszemy na nia wynik.
         *   r1  - szerokosc
         *   r2  - wysokosc
         */
        mul     r2, r1, r2
        mov     r1, r0

        /*
         *   r0  - obraz zrodlowy (stad czytamy)
         *   r1  - obraz docelowy (tu zapisujemy)
         *   r2  - ilosc pixelow (szerokosc * wysokosc)
         *   r3  - uzyty do przepisania wag poszczegolnych skladowych
         *   r4  - licznik petli (limit obrotow to r2)
         *   r5  - suma składowych po przeskalowaniu
         *   r6  - Aktualny pixel (kanal R)
         *   r7  - Aktualny pixel (kanal G)
         *   r8  - Aktualny pixel (kanal B)
         *   r9  - waga R
         *   r10 - waga G
         *   r11 - waga B
         */
        push    {r4, r5, r6, r7, r8, r9, r10, r11}

        /* Wagi kanalow - wczytujemy ja raz i bedziemy je trzymac w r9-11. */
        ldr     r3, =colorw /* Bierzemy adres z colorw. */
        ldr     r9, [r3], #4
        ldr     r10, [r3], #4
        ldr     r11, [r3], #4

        mov     r4, #0
.LOOP:
        /* Czytamy trzy skladowe kolejnego pixela. */
        ldrb    r6, [r0], #1
        ldrb    r7, [r0], #1
        ldrb    r8, [r0], #1

        /* Mnozymy razy wagi kanalow. */
        mul     r6, r9
        mul     r7, r10
        mul     r8, r11

        /* Dodajemy przy okazji dzielac kazdy iloczyn przez 256
           i piszemy na pointer wynikowy. */
        mov     r5, #0
        add     r5, r6, lsr #8
        add     r5, r7, lsr #8
        add     r5, r8, lsr #8
        strb    r5, [r1], #1

        add     r4, #1
        cmp     r4, r2
        bne     .LOOP

        pop    {r4, r5, r6, r7, r8, r9, r10, r11}
.END:
        mov     pc, lr
