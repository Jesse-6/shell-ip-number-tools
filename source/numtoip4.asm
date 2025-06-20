format ELF64 executable 3
entry Start

include 'anon_label.inc'
include 'fastcall_v1.inc'
include 'stdio.inc'

_data
        helpMsg         db 'Number to IPv4 converter utility.',10
                        db 'Version: 0.'
                        file 'numtoip4.subver'
                        db 10,10
                        db 'Usage:',10
                        db 10,'   %s number',10
                        db 10,'Converts to a decimal number provided IPv4 address.',10
                        db 0
        align 16
        nummask:        dq 0F0F0F0F0F0F0F0Fh,0F0F0F0F0F0F0F0Fh
        filtermask:     dq 00FF00FF00FF00FFh,00FF00FF00FF00FFh

        ; I know this table looks dumb, but processors index tables very very fast.
        numIndex    dd '0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15'
                    dd '16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31'
                    dd '32','33','34','35','36','37','38','39','40','41','42','43','44','45','46','47'
                    dd '48','49','50','51','52','53','54','55','56','57','58','59','60','61','62','63'
                    dd '64','65','66','67','68','69','70','71','72','73','74','75','76','77','78','79'
                    dd '80','81','82','83','84','85','86','87','88','89','90','91','92','93','94','95'
            dd '96','97','98','99','100','101','102','103','104','105','106','107','108','109','110','111'
            dd '112','113','114','115','116','117','118','119','120','121','122','123','124','125','126','127'
            dd '128','129','130','131','132','133','134','135','136','137','138','139','140','141','142','143'
            dd '144','145','146','147','148','149','150','151','152','153','154','155','156','157','158','159'
            dd '160','161','162','163','164','165','166','167','168','169','170','171','172','173','174','175'
            dd '176','177','178','179','180','181','182','183','184','185','186','187','188','189','190','191'
            dd '192','193','194','195','196','197','198','199','200','201','202','203','204','205','206','207'
            dd '208','209','210','211','212','213','214','215','216','217','218','219','220','221','222','223'
            dd '224','225','226','227','228','229','230','231','232','233','234','235','236','237','238','239'
            dd '240','241','242','243','244','245','246','247','248','249','250','251','252','253','254','255'

_code align 4
        Start:          endbr64
                        cmp         [rsp], dword 2
                        jne         .help
                        mov         rdi, [rsp+16]
                        mov         rsi, [rsp+16]
                        mov         ecx, 11         ; Maximum integer string size: 10 (+ 1 for null byte)
                        mov         r8d, 10
                        xor         eax, eax
                        repne       scasb
                        jne         .err0
                        lea         rdx, [rdi-2]    ; Pointer to least significant digit
                        sub         r8d, ecx        ; String length
                @@      lodsb                       ; Check if only numbers on argument
                        test        al, al
                        jz          @f
                        cmp         al, '0'
                        jb          .err0
                        cmp         al, '9'
                        ja          .err0
                        jmp         @b
                @@      fninit
                        sub         rsp, 32
                        pxor        xmm0, xmm0
                        movdqa      [rsp], xmm0
                        movdqa      [rsp+16], xmm0
                        mov         rsi, rdx
                        mov         rdi, rsp
                @@      std
                        lodsb
                        cld
                        stosb
                        dec         r8d
                        jnz         @b
                        movdqa      xmm1, [rsp]
                        pand        xmm1, [nummask]
                        movdqa      xmm3, xmm1
                        psrlw       xmm1, 4
                        por         xmm3, xmm1
                        pand        xmm3, [filtermask]
                        packuswb    xmm3, xmm0
                        movdqa      [rsp+16], xmm3
                        fwait
                        fbld        [rsp+16]
                        fistp       qword [rsp]
                        fwait
                        pop         rax
                        emms
                        mov         edx, -1
                        cmp         rax, rdx
                        ja          .err0
                        lea         r11, [numIndex]
                        shld        r9d, eax, 8
                        shld        edx, eax, 16
                        shld        ecx, eax, 24
                        movzx       r9, r9b             ; x.-.-.-
                        movzx       rdx, dl             ; -.x.-.-
                        movzx       rcx, cl             ; -.-.x.-
                        movzx       r10, al             ; -.-.-.x
                        mov         rdi, rsp            ; Format string and put it in buffer
                        lea         rsi, [r11+r9*4]
                @@      lodsb
                        test        al, al
                        jz          @f
                        stosb
                        jmp         @b
                @@      mov         al, '.'
                        stosb
                        lea         rsi, [r11+rdx*4]
                @@      lodsb
                        test        al, al
                        jz          @f
                        stosb
                        jmp         @b
                @@      mov         al, '.'
                        stosb
                        lea         rsi, [r11+rcx*4]
                @@      lodsb
                        test        al, al
                        jz          @f
                        stosb
                        jmp         @b
                @@      mov         al, '.'
                        stosb
                        lea         rsi, [r11+r10*4]
                @@      lodsb
                        test        al, al
                        jz          @f
                        stosb
                        jmp         @b
                @@      mov         ax, 0Ah
                        stosw
                        fputs(rsp, **stdout);
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
