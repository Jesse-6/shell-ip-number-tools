format ELF64 executable 3
entry Start

include 'anon_label.inc'
include 'fastcall_v1.inc'
include 'stdio.inc'

_data
        helpMsg        db 'IPv4 to number converter utility.',10
                       db 'Version: 0.'
                       file 'ip4tonum.subver'
                       db 10,10
                       db 'Usage:',10
                       db 10,'   %s ip.add.res.s',10
                       db 10,'Converts to a decimal number provided IPv4 address.',10
                       db 0
        align 16
        addmask:        dq 3030303030303030h, 3030303030303030h
        digitmask:      dq 0F0F0F0F0F0F0F0Fh, 0F0F0F0F0F0F0F0Fh
        reversemask:    db 15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0

_code align 4
        Start:          endbr64
                        cmp         [rsp], dword 2
                        jne         .help
                        mov         rdi, [rsp+16]       ; Check formatting errors
                        mov         rsi, [rsp+16]
                        mov         eax, '.'            ; Verify for 3 dots
                        mov         ecx, 16
                        mov         edx, 16
                @@      repne       scasb
                        jne         @f
                        inc         ah
                        jmp         @b
                @@      cmp         ah, 3
                        jne         .err0
                        xor         eax, eax            ; Check length (<= 16)
                        mov         rdi, rsi
                        lea         ecx, [edx+1]
                        repne       scasb
                        jne         .err0
                        lea         r10, [rdi-2]        ; Pointer to last digit
                        sub         edx, ecx            ; edx = size of IP string
                        cmp         dl, 15
                        ja          .err0
                        mov         rdi, rsi            ; Test for only dots and numbers
                @@      lodsb
                        test        al, al
                        jz          @f
                        cmp         al, '.'
                        je          @b
                        cmp         al, '0'
                        jb          .err0
                        cmp         al, '9'
                        ja          .err0
                        jmp         @b
                @@      cmp         [rdi], byte '.'     ; IPs cannot begin or end
                        je          .err0
                        cmp         [rsi-2], byte '.'   ; with dots
                        je          .err0
                        mov         rsi, rdi            ; Check 3 consecutive digits or less
                        xor         r9d, r9d
                        xor         ecx, ecx
                @@      lodsb
                        test        al, al
                        jz          @f2
                        inc         cl
                        cmp         al, '.'
                        cmove       ecx, r9d
                        jne         @f
                        cmp         [rsi], byte '.'     ; Dot followed by dot -> error
                        je          .err0
                @@      cmp         cl, 3
                        ja          .err0
                        jmp         @b2
                @@      std
                        mov         rsi, r10
                        xor         r11, r11
                        xor         rcx, rcx
                        xor         rdx, rdx
                        mov         r9d, 1
                        mov         r10d, 1
                @@@     cmp         rsi, rdi
                        jb          @f
                        lodsb
                        cmp         al, '.'
                        je          @f
                        sub         al, 30h
                        imul        r10d
                        add         rcx, rax
                        imul        r10d, r10d, 10
                        jmp         @@b
                @@      cmp         ecx, 256
                        jae         .err0
                        mov         eax, ecx
                        imul        r9d
                        add         r11, rax
                        cmp         rsi, rdi
                        jb          @@f
                        mov         r10d, 1
                        shl         r9d, 8      ; n * 256
                        xor         ecx, ecx
                        xor         eax, eax
                        jmp         @@b
                @@@     cld
                        mov         rdx, 0FFFFFFFF00000000h
                        test        r11, rdx
                        jnz         .err0
                        sub         rsp, 24
                        finit
                        push        r11
                        fild        qword [rsp]
                        fbstp       [rsp]
                        fwait
                        movq        xmm7, [rsp]
                        pxor        xmm5, xmm5
                        pxor        xmm6, xmm6
                        punpcklbw   xmm5, xmm7
                        punpcklbw   xmm7, xmm6
                        psrlw       xmm5, 4
                        por         xmm7, xmm5
                        pand        xmm7, [digitmask]
                        paddb       xmm7, [addmask]
                        pshufb      xmm7, [reversemask] ; This SSSE3 instruction replaces
                        movdqa      [rsp], xmm7
                        ; pop         rcx               ; this whole block
                        ; pop         rdx
                        ; bswap       rcx
                        ; bswap       rdx
                        ; push        rcx
                        ; push        rdx
                        mov         [rsp+16], word 0Ah
                        lea         rdi, [rsp]
                        mov         al, '0'
                        mov         ecx, 16
                        repe        scasb
                        dec         rdi
                        fputs(rdi, **stdout);
                        exit(0);
            .err0:      fputs(<"Invalid argument.",10,0>, **stderr);
                        exit(2);
            .help:      mov         rdi, [rsp+8]
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
                        exit(1);

