global start, place, step

section .data
align 8

width:  dd 0 ; wymiary matrycy
height: dd 0
matrix: dq 0 ; matryca
currentmat: dq 0 ; wsk. na wsk. na aktualna matryce (float**)
c_val:  dd 0 ; temperatura chodnic
weight: dd 0 ; wsp. przekazywania ciepla
num:    dd 0 ; rozmiar tablic x, y i t (temp).
x_arr:  dq 0
y_arr:  dq 0
t_arr:  dq 0

section .text
align 8

;; void start(int szer, int wys, void* M, float C, float waga)
start:
        ;; przechowujemy zmienne globalne.
        mov     [width], edi
        mov     [height], esi
        mov     [matrix], rdx
        movss   [c_val], xmm0
        movss   [weight], xmm1

        mov     r8, rdi
        add     r8, 2
        mov     r9, rsi
        add     r9, 2
        imul    r8, r9         ; r8: (width + 2) * (height + 2)
        mov     rcx, [matrix]
        lea     rcx, [rcx + 8*r8] ; rcx: &m[2 * (width + 2) * (height + 2)],
                                ; [rcx]: pointer na aktualna tablice, rcx to float**
        mov     [currentmat], rcx

        ;; Wypelniamy brzegi wartoscia C.
        ;; Petla po kolumnach, wypelniamy pierwszy i ostatni wiersz.
        mov     ecx, 0          ; rcx: licznik pentli
        mov     edx, dword [width]
        add     edx, 2          ; rdx: width + 2
        mov     esi, dword [height]
        add     esi, 1
        imul    esi, edx        ; rsi: (height+1)*(width+2) - offset ost. wiersza.
L1:
        mov     rdi, [matrix]
        lea     rdi, [rdi + 4*rcx]
        movss   [rdi], xmm0     ; w xmm0 cialge siedzi wartosc C
        mov     rdi, [matrix]
        lea     rdi, [rdi + 4*rsi]
        lea     rdi, [rdi + 4*rcx]
        movss   [rdi], xmm0
        inc     rcx
        cmp     rcx, rdx
        jl      L1

        ;; Petla po wierszach, wypelniamy pierwsza i ostatnia kolumne.
        mov     ecx, 0          ; rcx: licznik pentli
        mov     edx, dword [width]
        add     edx, 2          ; rdx: width + 2
        mov     esi, dword [height]
        add     esi, 2          ; rsi: height + 2
L2:
        mov     rdi, [matrix]
        mov     r8, rdx
        imul    r8, rcx
        lea     rdi, [rdi + 4*r8] ; m[(width + 2) * i] - lewa kolumna.
        movss   [rdi], xmm0
        lea     rdi, [rdi + 4*rdx - 4]
        movss   [rdi], xmm0 ; m[(width + 2) * i + (width + 1)] - prawa kolumna.
        inc     rcx
        cmp     rcx, rsi
        jl      L2

        ;; Druga macierz cala wypelniamy C
        imul    esi, edx        ; rsi: (height + 2) + (width + 2)
        mov     rcx, [matrix]
        lea     rcx, [rcx + 4*rsi] ; rcx: &m[(height + 2) * (width + 2)]
        lea     rdx, [rcx + 4*rsi] ; rdx: &m[2 * (height + 2) * (width + 2)]
L3:
        movss   [rcx], xmm0
        lea     rcx, [rcx + 4]
        cmp     rcx, rdx
        jne     L3

        ret

;; void place(int ile, int* x, int* y, float* temp);
place:
        ;; edi: ile,  rsi: x*,  rdx: y*,  rcx: temp*
        ;; Zapisujemy wartosic - uzywamy ich do poprawiania grzejnikow po step
        mov     [num], edi
        mov     [x_arr], rsi
        mov     [y_arr], rdx
        mov     [t_arr], rcx

        ;; Idziemy od konca, tak zeby oszczedzic rejestr
        ;; Zakladamy, ze wartosci sa w odpowiednim zakresie
        mov     r11d, dword [width]
        add     r11d, 2         ; r11d: width + 2
L4:
        dec     rdi
        lea     rax, [rcx + 4*rdi]
        movss   xmm0, [rax]
        mov     r9, [currentmat]       ; r9: float** - ptr na akt. matryce
        mov     r9, [r9]               ; r9: float* akt. matryca
        lea     r8, [rdx + 4*rdi]
        mov     r8d, dword [r8]        ; r8: x[i]
        inc     r8
        imul    r8, r11                ; r8: x[i] * (width + 2)
        lea     r9, [r9 + 4*r8]
        lea     r8, [rsi + 4*rdi]
        mov     r8d, dword [r8]        ; r8: y[i]
        inc     r8
        lea     r9, [r9 + 4*r8]
        movss   [r9], xmm0
        cmp     rdi, 0
        jne     L4

        ret

;; void step(void);
step:
        ;; Ustalamy wsk. na macierz aktualna i na docelowa
        mov     r8d, [height]
        add     r8, 2
        mov     r9d, [width]
        add     r9, 2           ; r9: (width + 2) (== pitch)
        imul    r8, r9          ; r8: (height + 2) * (width + 2)
        mov     rdi, [matrix]
        mov     rax, [currentmat]
        mov     rax, [rax]
        cmp     rax, rdi
        jne     LDontSwap
        lea     rdi, [rdi + 4*r8]
LDontSwap:
        ;; rax: obecna matryca
        ;; rdi: matryca na ktora piszemy wynik
        mov     r10, 1          ; licznik zewnetrzny (wiersz)
        push    r12
LOuter:
        mov     r11, 1          ; licznik wewnetrzny (kolumna)
LInner:
        push    rax
        push    rdi
        mov     r12, r10
        imul    r12, r9
        add     r12, r11
        lea     rax, [rax + 4*r12]
        lea     rdi, [rdi + 4*r12]
        mov     rcx, rax
        fld     dword [rcx]     ; stara wartosc - dodamy na koniec
        fld     dword [weight]  ; wsp. znamy ciepla - pomnozy roznice
        fld     dword [rcx]     ; stara wartosc
        add     rax, 4
        fld     dword [rax]     ; prawy sasiad
        fsubr
        fld     dword [rcx]     ; stara wartosc
        sub     rax, 8
        fld     dword [rax]     ; lewy sasiad
        fsubr
        mov     edx, [width]
        add     rdx, 2
        lea     rax, [rcx + 4*rdx]
        fld     dword [rcx]     ; stara wartosc
        fld     dword [rax]     ; gorny sasiad
        fsubr
        neg     rdx
        lea     rax, [rcx + 4*rdx]
        fld     dword [rcx]     ; stara wartosc
        fld     dword [rax]     ; dolny sasiad - cofamy o dwa rzedy
        fsubr
        fadd
        fadd
        fadd                    ; sumujemy wszystkie roznice
        fmul                    ; mnozymy razy wsp.
        fadd                    ; dodajemy do orginalnej wartosci
        fstp    dword [rdi]     ; zapisujemy tam gdzie wskazuje rdi
        pop     rdi
        pop     rax

        inc     r11
        lea     r12, [r11 + 1]
        cmp     r12, r9         ; break gdy licznik = (width + 1)
                                ; w r9 mamy (width + 2), wiec porownujemy z tym
        jl      LInner
        inc     r10
        mov     r12d, [height]
        inc     r12
        cmp     r10, r12        ; break gdy licznik = (height + 1)
        jl      LOuter

        ;; Zmana pointera wsk. na aktualna matryce.
        mov     r9, [currentmat]
        mov     rcx, [matrix]
        cmp     rcx, [r9]       ; jak bylo na dolnej to dajemy na gorna
        jne     LSwpTemp
        lea     rcx, [rcx + 4*r8]
LSwpTemp:
        mov     [r9], rcx       ; wpp wracamy do dolnej

        ;; Tailcall do place - poprawiamy grzejniki na aktualnej matrycy
        pop     r12             ; zdejmujemy zapisany r12 przed callem
        mov     edi, [num]
        mov     rsi, [x_arr]
        mov     rdx, [y_arr]
        mov     rcx, [t_arr]
        jmp     place
        ret
