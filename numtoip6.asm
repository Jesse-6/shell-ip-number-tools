format ELF64 executable 3
entry Start

include 'anon_label.inc'
include 'fastcall_v1.inc'
include 'stdio.inc'
include 'gmp.inc'

; bl flags map:
; BIT0: set if string allows abbreviation

_bss align sizeof(IPv6)
        IPv6                mpz_t
        IPv6_max            mpz_t
        IPv6_min            mpz_t
        align 16
        IPv6_full           rb 40
        IPv6_out            rb 40

_data
        helpMsg             db 'Number to IPv6 converter utility.',10
                            db 'Version: 0.'
                            file 'numtoip6.subver'
                            db 10,10
                            db 'Usage:',10
                            db 10,'   %s number',10
                            db 10,'Converts a decimal number to IPv6 address.',10
                            db 0
        align 16
        cmpn9:              db '9999999999999999'
        andx20:             db '                '

_code align 8
        Start:              endbr64
                            cmp         [rsp], dword 2
                            jne         .help

                            mpz_inits(&IPv6_max, &IPv6_min, NULL); ; Initialize mpz variables to 0
                            mpz_ui_pow_ui(&IPv6_max, 2, 128);   ; (2^128) = IPv6 outer limit
                            mpz_init_set_str(&IPv6, [rsp+16], 10);
                            test        eax, eax
                            jnz         .err_clear
                            mpz_cmp(&IPv6, &IPv6_max);          ; IPv6 >= 2^128 -> error
                            test        eax, eax
                            jge         .err_clear
                            mpz_cmp(&IPv6, &IPv6_min);          ; IPv6 < 0 -> error
                            test        eax, eax
                            jl          .err_clear
                            gmp_snprintf(&IPv6_full, 40, "%032Zx", &IPv6);
                            lea         rdx, [IPv6_full]
                            mov         [rdx+rax], dword 0      ; padding for shortening
                            mpz_clears(&IPv6, &IPv6_max, &IPv6_min, NULL);

                            lea         rsi, [IPv6_full]        ; Source string
                            lea         rdi, [IPv6_full]        ;
                            mov         rax, '00000000'
                            xor         ebx, ebx                ; Flags
                            xor         edx, edx                ; Index
                            xor         r10d, r10d              ; Candidate
                            xor         r11d, r11d              ; Length of candidate
                            xor         r12d, r12d              ; Saved abbreviate index
                            xor         r13d, r13d              ; Saved abbreviate length
                            mov         ecx, 8

                    @@      scasq
                            lea         rdi, [rdi-4]
                            lea         edx, [edx+1]            ; Index
                            loopne      @b
                            jne         @f2
                            or          bl, 1b                  ; Flag abbreviate
                            add         rdi, 4
                            dec         ecx
                            mov         r10b, dl                ; Index candidate
                            mov         r11b, 2                 ; Candidate length counter
                            jz          @f2
                    @@      scasd
                            loopne      @f
                            jne         @f
                            inc         r11b
                            jecxz       @f
                            jmp         @b
                    @@      cmp         r11b, r13b              ; Check if cand. len > saved len,
                            cmovae      r12d, r10d              ; then replace with the highest
                            cmovae      r13d, r11d              ; size or rightmost abbreviation
                            jecxz       @f
                            add         dl, r11b
                            jmp         @b3

                    @@      mov         dl, 1                   ; Index count
                            lea         rdi, [IPv6_out]
                    @@@     test        bl, 1                   ; Check abbreviate flag
                            jz          @f
                            cmp         dl, r12b                ; Abbreviate at index
                            jne         @f
                            mov         ax, '::'
                            lea         rbx, [rdi-1]            ; Inside abbreviation? Then
                            cmp         [rdi-1], byte ':'       ; rbx value does not matter
                            cmove       rdi, rbx                ; anymore
                            stosw
                            lea         rsi, [rsi+r13*4]        ; Skip 0 hextets in source
                            add         dl, r13b                ; Add size to index
                            xor         bl, bl                  ; Done? Reset flag
                    @@      lodsd
                            inc         dl
                            mov         ecx, 32                 ; Abbreviate hextets
                    @@      cmp         al, '0'                 ; Trim out leading 0's
                            jne         @f
                            ror         eax, 8
                            sub         cl, 8
                            jnz         @b
                    @@      cmp         al, '0'
                            jne         @f2
                            cmp         dl, 8
                            ja          @f
                            mov         ah, ':'
                            stosw
                            jmp         @@b
                    @@      stosb
                            jmp         @@b
                    @@      stosd
                            sub         rcx, 32
                            sar         rcx, 3
                            lea         rdi, [rdi+rcx]
                            cmp         dl, 8
                            ja          @@f
                            mov         al, ':'
                            stosb
                            jmp         @@b
                    @@@     mov         [rdi], word 0Ah

            .output:        fputs(&IPv6_out, **stdout);
                            lea         r15, [IPv6_full]            ; SSE2 uppercase converter
                            movdqa      xmm0, [r15]
                            movdqa      xmm1, [r15+16]
                            pxor        xmm2, xmm2
                            pxor        xmm7, xmm7
                            movdqa      xmm5, [andx20]
                            movdqa      xmm6, [andx20]
                            movdqa      xmm3, [r15]
                            movdqa      xmm4, [r15+16]
                            pcmpgtb     xmm3, [cmpn9]
                            pcmpgtb     xmm4, [cmpn9]
                            pandn       xmm5, xmm3
                            pandn       xmm6, xmm4
                            pcmpeqb     xmm2, xmm5
                            pcmpeqb     xmm7, xmm6
                            por         xmm5, xmm2
                            por         xmm6, xmm7
                            pand        xmm0, xmm5
                            pand        xmm1, xmm6
                            movdqa      [r15], xmm0
                            movdqa      [r15+16], xmm1
                            mov         rdx, 2020202020h
                            sub         rsp, 8
                            push        rdx
                            mov         rcx, [stderr]
                            push        [rcx]
                            pop         [stderr]
                            fputs(<27,"[2;37mDebug: ",0>, *stderr);
                            mov         bl, 8
                    @@      mov         eax, [r15]
                            add         r15, 4
                            mov         [rsp], eax
                            fputs(&rsp, *stderr);
                            dec         bl
                            jnz         @b
                            fputs(<27,"[0m",10,0>, *stderr);
                            exit(EXIT_SUCCESS);

            .err_clear:     mpz_clears(&IPv6, &IPv6_max, &IPv6_min, NULL);
            .errconv:       fputs(<"Invalid argument.",10,0>, **stderr);
                            exit(2);

            .help:          mov         rdi, [rsp+8]
                            mov         r11, rdi
                            xor         al, al
                            mov         ecx, -1
                            repne       scasb
                            not         ecx
                            sub         rdi, 2
                            mov         al, '/'
                            std
                            repne       scasb
                            cmovne      rdi, r11
                            jne         @f
                            add         rdi, 2
                    @@      cld
                            fprintf(**stderr, &helpMsg, rdi);
                            exit(EXIT_FAILURE);

; 65536 > n > 0
; 0:n:0:n:0:n:0:n -> same
; n:0:n:0:n:0:n:0 -> same
; 0:0:n:0:0:n:0:0 -> ::n:0:0:n:0:0 | 0:0:n::n:0:0 | 0:0:n:0:0:n::
; 0:n:0:0:n:0:0:0 -> 0:n:0:0:n::
; 0:n:0:0:0:0:n:0 -> 0:n::n:0
;
