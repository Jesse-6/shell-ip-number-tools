format ELF64 executable 3
entry Start

include 'anon_label.inc'
include 'fastcall_v1.inc'
include 'stdio.inc'
include 'gmp.inc'

; bl flags map:
; BIT0: set when it might contain IPv4 portion at the end;
; BIT1: set when address contains '::' abbreviation
; BIT2: set if IPv4 portion is preceded by '::' (which means don't invert);

_bss align 16
        IPv6                mpz_t

_data align 16
        full_IPv6           db '000000000000000000000000'
            .IPv4           db '00000000'
                            db 0
        helpMsg             db 'IPv6 to number converter utility.',10
                            db 'Version: 0.'
                            file 'ip6tonum.subver'
                            db 10,10
                            db 'Usage:',10
                            db 10,'   %s ipv6:addr:ess::0',10
                            db 10,'Converts to a decimal number provided IPv6 address.',10
                            db 0

_code align 8
        Start:              endbr64
                            cmp         [rsp], dword 2
                            jne         .help

                            xor         ebx, ebx        ; bl = conversion flags¹
                            mov         rsi, [rsp+16]   ; Start sanity check
                            mov         rdi, [rsp+16]
                            xor         al, al
                            mov         ecx, -1         ; Get paramater size
                            repne       scasb
                            lea         r14, [rdi-2]    ; r14 = last char on IPv6 string
                            not         ecx             ; Size including null termination
                            lea         r11d, [ecx-1]   ; r11d = true string length
                            cmp         ecx, 3          ; Minimum size
                            je          .nullIPv6
                            jb          .errconv
                            cmp         ecx, 46         ; Maximum size with IPv4 end format
                            ja          .errconv
                            mov         rdi, rsi        ; Search address abbreviation '::'
                            mov         ax, '::'        ;
                            xor         edx, edx        ; dl = '.' counter
                    @@      dec         ecx
                            jz          @f2
                            lea         r8d, [edx+1]
                            cmp         [rdi], byte '.' ; check for 3 dots also
                            cmove       edx, r8d        ; ² dots counter
                            jne         @f
                            cmp         [rdi+1], byte '.' ;  '.' followed by '.' = error
                            je          .errconv
                    @@      scasw
                            lea         rdi, [rdi-1]
                            jne         @b2
                            inc         bh              ; Count number of abbreviations
                            jmp         @b2
                    @@      cmp         dl, 3
                            ja          .errconv
                            test        dl, dl          ; '.' counter != 0
                            setnz       bl              ; set BIT0 flag
                            jnz         @f
                            cmp         r11d, 39        ; If without IPv4 portion, check IPv6 string
                            ja          .errconv        ; length: > 39 = error
                    @@      cmp         bh, 1           ; IPv6 address should only contain 1 '::'
                            ja          .errconv
                            jne         @f
                            or          bl, 10b         ; Set BIT1 abbreviation flag
                    @@      mov         rdi, rsi
                            mov         ecx, r11d       ; Count number of ':'
                            test        bl, 1b          ; Check if contains IPv4 portion and
                            setnz       bh              ; add 1 : to initial counter
                    @@      repne       scasb
                            jne         @f
                            inc         bh              ; From now, bh = ':' counter
                            jmp         @b
                    @@      cmp         bh, 2           ; A valid IPv6 has at least 2 ':'
                            jb          .errconv
                            cmp         bh, 8           ; and a maximum of 8 if ended '::'
                            ja          .errconv
                            jne         @f              ; If contains 8 '::' then the last
                            cmp         [rdi-2], word '::' ; should be abbreviated
                            jne         .errconv
                            or          bl, 100b        ; Check don't invert flag if '::' at the end
                    @@      cmp         bh, 7           ; Full IPv6 has 7 ':'
                            jae         @f
                            test        bl, 10b         ; < 7 and not abbreviated = invalid IPv6
                            jz          .errconv
                    @@      mov         rdi, rsi
                            lea         r12, [full_IPv6.IPv4+8] ; r12 = last conversion pointer
                            test        bl, 1           ; Verify if IPv6 contains IPv4 portion
                            jz          .IPv6conv

            .IPv4conv:      cmp         dl, 3           ; dl = number of dots from above²
                            jne         .errconv
                            lea         rdi, [rdi+r11-1] ; Point to last number
                            push        rdi
                            std
                            mov         r9, rdi
                            mov         ecx, 16
                            repne       scasb           ; Search for the last ':' (ax is still '::' here)
                            mov         r14, rdi        ; r14 = IPv4 portion start
                            pop         rdi
                            jne         .errconv
                            cmp         [r14], byte ':' ; test for :: before IPv4 portion
                            jne         @f
                            or          bl, 100b        ; Set don't invert (BIT2) if :: before IPv4
                    @@      sub         rcx, 14         ; Get IPv4 portion (-) string length
                            cmp         [rdi], byte '.' ; IPv4 string cannot begin or end with '.'
                            je          .errconv
                            cmp         [rdi+rcx], byte '.'
                            je          .errconv
                            mov         r10d, 1         ; Multiply factor
                            xor         edx, edx
                            xor         eax, eax
                            xor         r8d, r8d        ; Octet integer result
                            mov         r9b, 4          ; Octet counter
                            xchg        rdi, rsi        ; Start parsing IPv4 in reverse
                    @@      lodsb
                            cmp         al, '.'
                            je          @f2
                            cmp         al, ':'
                            jne         @f
                            cmp         r9b, 1          ; ':' Only after highest octet
                            ja          .errconv
                            jmp         @f2
                    @@      cmp         al, '0'
                            jb          .errconv
                            cmp         al, '9'
                            ja          .errconv
                            cmp         r10d, 100       ; Only 3 digits max per octet (x100)
                            ja          .errconv
                            sub         al, '0'
                            mul         r10d
                            add         r8d, eax
                            imul        r10d, r10d, 10
                            jmp         @b2
                    @@      cmp         r8d, 255        ; Result integer from octet
                            ja          .errconv
                            sub         r12, 2
                            mov         edx, r8d
                            mov         r10d, 1
                            mov         dh, dl
                            shr         dl, 4
                            and         dh, 0Fh
                            xor         r8d, r8d
                            mov         cl, 7
                            cmp         dh, 9
                            cmovbe      ecx, r8d
                            add         dh, cl          ; Add 7 if A to F range
                            cmp         dl, 9
                            mov         cl, 7
                            cmovbe      ecx, r8d
                            add         dl, cl          ;
                            add         [r12], dx       ; Add word to '00' in string
                            xor         edx, edx
                            dec         r9b
                            jnz         @b3
                            mov         rsi, rdi

            .IPv6conv:      cld
                            test        bl, 100b        ; Check don't invert flag and
                            jz          @f
                            dec         r14             ; make last hextet point to last char
                    @@      lea         r11, [r14+1]
                            sub         r11, rdi        ; r11 = hextet portion length
                            test        bl, 1b          ; Check IPv4 portion flag and
                            jz          @f
                            mov         [rsi+r11], byte 0   ; put 0 at end of hextet
                            cmp         r11b, 29        ; If hextets' size > 29 = error
                            ja          .errconv
                    @@      xor         ecx, ecx
                    @@      lodsb                       ; Start checking hextets' size
                            cmp         al, ':'
                            je          @f
                            test        al, al
                            jz          @f2
                            inc         cl
                            cmp         cl, 4
                            ja          .errconv
                            cmp         al, '0'         ; Also check hextext digits
                            jb          .errconv
                            cmp         al, '9'         ; Valid values: 0-9, A-F, a-f
                            jbe         @b
                            cmp         al, 'A'
                            jb          .errconv
                            cmp         al, 'F'
                            jbe         @b
                            and         [rsi-1], byte not 20h   ; Uppercase conversion
                            cmp         al, 'a'
                            jb          .errconv
                            cmp         al, 'f'
                            jbe         @b
                            jmp         .errconv
                    @@      xor         cl, cl
                            cmp         rsi, r14
                            jbe         @b2

                    @@      lea         rsi, [full_IPv6]
            .forward:       xchg        rsi, rdi        ; Expand hextet values
                            mov         eax, '0000'     ; Dummy '0000' value
                    @@      shl         rax, 8
                            lodsb
                            mov         cl, al          ; cl = last hex char
                            cmp         al, ':'
                            je          @f
                            test        al, al
                            jz          @f
                            jmp         @b
                    @@      shr         rax, 8          ; restore padded 0 value if ':'
                            bswap       eax
                            stosd
                            test        cl, cl          ; cl = 0 end of string has been reached
                            jz          .output
                            cmp         [rsi], byte ':' ; Check for ::
                            je          @f
                            mov         eax, '0000'
                            jmp         @b2
                    @@      test        bl, 100b        ; Check don't invert flag
                            jnz         .output

            .reverse:       std                         ; Reverse parser
                            lea         rdi, [r12-4]    ; Last octet, or last after IPv4 portion
                            mov         rsi, r14        ; Last source hex char, same as above
                            mov         edx, '0000'
                            mov         cl, 24
                    @@      lodsb
                            cmp         al, ':'
                            je          @f
                            mov         dl, al
                            rol         edx, 8
                            sub         cl, 8
                            jmp         @b
                    @@      mov         eax, edx
                            rol         eax, cl
                            stosd
                            cmp         [rsi], byte ':' ; This ends on ::
                            je          @f
                            mov         edx, '0000'
                            mov         cl, 24
                            jmp         @b2
                    @@      cld

            .output:        mpz_init_set_str(&IPv6, &full_IPv6, 16);
                            test        eax, eax
                            jz          @f
                            mpz_clear(&IPv6);
                            jmp         .errconv
                    @@      gmp_fprintf(**stdout, <"%Zd",10,0>, &IPv6);
                            mpz_clear(&IPv6);
            .debug:         mov         rax, [stderr]
                            push        [rax]
                            pop         [stderr]
                            lea         r15, [full_IPv6]
                            fputs(<27,"[2;37mDebug: ",0>, *stderr);
                            sub         rsp, 8
                            mov         rdx, 2020202020h
                            mov         bl, 8
                            push        rdx
                    @@      mov         eax, [r15]
                            add         r15, 4
                            mov         [rsp], eax
                            fputs(&rsp, *stderr);
                            dec         bl
                            jnz         @b
                            fputs(<27,"[0m",10,0>, *stderr);
                            exit(EXIT_SUCCESS);

            .nullIPv6:      cmp         [rsi], word '::'
                            je          .output
                            ; Error if not equal
            .errconv:       cld
                            fputs(<"Invalid IPv6 format.",10,0>, **stderr);
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

; nnnn:nnnn:nnnn:nnnn:nnnn:nnnn:nnnn:nnnn
; nnnn:nnnn:nnnn:nnnn:nnnn:nnnn:nnnn::
; nnnn:nnnn:nnnn:nnnn:nnnn:nnnn:xxx.xxx.xxx.xxx
; ::x.x.x.x
; ::
; nnnn::n:nn:nnn:nnnn
