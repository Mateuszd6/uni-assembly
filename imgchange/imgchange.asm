global changeimg

section .data
align   8

;; Maska potrzebna przy uzywaniu blendv. Dzieki temu bedziemy pisac co
;; trzeci element. Maski na kolor niebieski i zielony zaczynaja sie na
;; arr + 1 i arr + 2.
mask_arr   db 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0

section .text
align   8

changeimg:
        lddqu xmm5, [mask_arr]
        lddqu xmm6, [mask_arr + 1]
        lddqu xmm7, [mask_arr + 2]

        ;; Ustawiamy wszystkie elementy xmm4 na wartosc, o jaka
        ;; zwiekszana bedzie skladowa, czyli edx. Pewnie lepiej byloby
        ;; uzyc vpbroadcastb, ale nie dzialal mi na students.
        movd    xmm4, r8d
        pxor    xmm1, xmm1
        pshufb  xmm4, xmm1
        pabsb   xmm4, xmm4      ; Dzialamy tylko na dodatnich liczbach.

        imul    rdx, rsi
        imul    rdx, 3
        lea     rdx, [rdi + rdx]
        ; rdx to pointer, a ktorym musimy zatrzymac iterowanie petli.
        ; Ale wymagamy, zeby bylo wystarczajaco pamieci, zeby moc sie
        ; wyindeksowac o przynajmniej 48 bajtow (bo na raz robimy 3 iteracje)

        cmp     rdx, rdi
        je      .loop_end       ; Pomijamy petle jak 0 iteracji.

;; Decydujemy gdzie zaczniemy. Dodawania i odejmowanie jest
;; obslugiwane przez rozne petle. Dodatkowo, W zaleznosci od tego od
;; ktorej maski zaczniemy xmm 5-7 bedziemy zmieniac rozne skladowe.
.loop_init:
        test    r8b, r8b        ; Wartosc w xmm4 jest zawsze bez znaku, a teraz
                                ; decydujemy czy bedziemy odejmowac czy dodawac.
        js      .loop_init_sub
.loop_init_add:
        cmp     cl, 'R'
        je      .loop_add_red
        cmp     cl, 'G'
        je      .loop_add_green
        jmp     .loop_add_blue
.loop_init_sub:
        cmp     cl, 'R'
        je      .loop_sub_red
        cmp     cl, 'G'
        je      .loop_sub_green
        jmp     .loop_sub_blue

;; Wczytujemy 16 bajtow (czyli 5 i 1/3 piksela), dodajemy nasza
;; wartosc uzywajac padd(sub)usb, tak zeby miec saturacje w zakresie
;; jednego bajta (czyli nie obracalo sie jak powyzej 255 albo ponizej 0)
;; A nastepnie piszemy tylko co 3 bajt kozystajac z maski odpowiedniej
;; do koloru ktory modyfikujemy (zalezy od miejsca w ktorym wystartujemy)
.loop_add:
.loop_add_red:
        movdqa  xmm1, [rdi]
        movdqa  xmm2, xmm1
        paddusb xmm2, xmm4
        movdqa  xmm0, xmm5
        pblendvb xmm1, xmm2, xmm0
        movdqa  [rdi], xmm1
        lea     rdi, [rdi + 16]
.loop_add_blue:
        movdqa  xmm1, [rdi]
        movdqa  xmm2, xmm1
        paddusb xmm2, xmm4
        movdqa  xmm0, xmm6
        pblendvb xmm1, xmm2, xmm0
        movdqa  [rdi], xmm1
        lea     rdi, [rdi + 16]
.loop_add_green:
        movdqa  xmm1, [rdi]
        movdqa  xmm2, xmm1
        paddusb xmm2, xmm4
        movdqa  xmm0, xmm7
        pblendvb xmm1, xmm2, xmm0
        movdqa  [rdi], xmm1
        lea     rdi, [rdi + 16]

        cmp     rdi, rdx
        jl      .loop_add
        jmp     .loop_end

;; To samo, tylko dla odejmowania. Tak jest szybciej, bo psubusb i
;; paddsub dodaja bajty bez znaku a nastepnie saturuja. Ciezko wiec
;; dodac do czegos bez znaku cos ze znakiem, a potem zsaturowac w
;; zakrese bez znaku. Dlatego sa dwie pentle, jedna do dodwania a
;; druga do odejmowania, a wektor ktory dodajemy, (ten w xmm4) ma
;; zawsze wartosic nieujemne. Dzieki temu nie musimy sprawdzac czy
;; byly przepelnienia i mamy mniej instrukcji do wykonania.
.loop_sub:
.loop_sub_red:
        movdqa  xmm1, [rdi]
        movdqa  xmm2, xmm1
        psubusb xmm2, xmm4
        movdqa  xmm0, xmm5
        pblendvb xmm1, xmm2, xmm0
        movdqa  [rdi], xmm1
        lea     rdi, [rdi + 16]
.loop_sub_blue:
        movdqa  xmm1, [rdi]
        movdqa  xmm2, xmm1
        psubusb xmm2, xmm4
        movdqa  xmm0, xmm6
        pblendvb xmm1, xmm2, xmm0
        movdqa  [rdi], xmm1
        lea     rdi, [rdi + 16]
.loop_sub_green:
        movdqa  xmm1, [rdi]
        movdqa  xmm2, xmm1
        psubusb xmm2, xmm4
        movdqa  xmm0, xmm7
        pblendvb xmm1, xmm2, xmm0
        movdqa  [rdi], xmm1
        lea     rdi, [rdi + 16]

        cmp     rdi, rdx
        jl      .loop_sub
        jmp     .loop_end

.loop_end:
        ret
