; this was generated by gcc272 -O6 -unroll-loops
; the nasm output is op-for-op identical to the original gas output.
;
; This code is slightly faster than that obtained
; from gcc295 (-02 -mcpu=i[3|6]86 -unroll-loops)
; if your compiler can generate faster code please send it to me
; for disassembly.
;
; $Id: ogr.asm,v 1.1.2.7 2000/12/25 23:19:14 snake Exp $

               global ogr_get_dispatch_table, _ogr_get_dispatch_table

%ifdef __OMF__  ; Watcom and Borland
 extern ogr_choose_dat
[SECTION _DATA CLASS=DATA USE32 FLAT PUBLIC ALIGN=16]
[SECTION _TEXT CLASS=CODE USE32 FLAT PUBLIC ALIGN=16] ;8,16,256,512,...
%define __DATASECT__ [SECTION _DATA]
%define __CODESECT__ [SECTION _TEXT]
%define CHOOSE_DAT ogr_choose_dat
%elifdef __ELF__
 extern ogr_choose_dat
[SECTION .data align=16]
[SECTION .text align=32]
%define __DATASECT__ [SECTION .data]
%define __CODESECT__ [SECTION .text]
%define CHOOSE_DAT ogr_choose_dat
%else
 extern _ogr_choose_dat
%define __DATASECT__ [SECTION .data]
%define __CODESECT__ [SECTION .text]
%define CHOOSE_DAT _ogr_choose_dat
%endif

%define offset
%define ptr
%define memset my_memset

%macro calign 1
  %assign sz  0
  %if %1 > 0
    %%szx equ ($ - $$)
    %assign sz (%%szx & (%1 - 1))
    %if sz != 0
      %assign sz %1 - sz
    %endif
  %endif
  %assign edinext 0
  %rep %1
    ;%assign edinext 0 ; always esi only for gas compatibility
    %if sz >= 7
      db 0x8D,0xB4,0x26,0x00,0x00,0x00,0x00  ; lea       esi,[esi]
      %assign sz sz-7
      %assign edinext 1
    %elif sz >= 6 && edinext != 0
      db 0x8d,0xBf,0x00,0x00,0x00,0x00       ; lea       edi,[edi]
      %assign edinext 0
      %assign sz sz-6
    %elif sz >= 6
      db 0x8D,0xB6,0x00,0x00,0x00,0x00       ; lea       esi,[esi]
      %assign edinext 1
      %assign sz sz-6
    %elif sz >= 4   
      db 0x8D,0x74,0x26,0x00                 ; lea       esi,[esi]
      %assign sz sz-4
      %assign edinext 1
    %elif sz >= 3 && edinext != 0
      db 0x8d,0x7f,0x00                      ; lea       edi,[edi]
      %assign sz sz-3
      %assign edinext 0
    %elif sz >= 3
      db 0x8D,0x76,0x00                      ; lea       esi,[esi] 
      %assign sz sz-3
      %assign edinext 1
    %elif sz >= 2 && edinext != 0
      db 0x8d,0x3f                           ; lea       edi,[edi]
      %assign sz sz-2
      %assign edinext 0
    %elif sz >= 2
      ;db 0x8D,0x36                          ; gas 2.7: lea esi,[esi]     
      mov esi,esi                            ; gas 2.9: mov esi,esi   
      %assign sz sz-2
      %assign edinext 1
    %elif sz >= 1
      nop
      %assign sz sz-1
    %else 
      %exitrep
    %endif
  %endrep  
%endmacro

%macro CALIGN 1  ; gcc 272 alignment is always 4 bytes
   calign 4
%endmacro

%macro gas_xxx 3 ;
  %ifnum %3
    %if %3 < 0x80
       %1 %2,BYTE %3
    %else 
      %assign j (%3 & 0xff)
      %assign m (%3 - j)
      %if m == 0 && j < 0x80
        %1 %2,BYTE j
      %elif m != 0xffffff00
        %1 %2,%3
      %elif j > 0x80
        %assign j (0 - j)
        %1 %2,BYTE -j
      %else 
        %1 %2,BYTE j
      %endif
    %endif
  %else
    %1 %2,%3
  %endif
%endmacro

%macro gas_jmp 1
  jmp short %1
%endmacro
%macro gas_sub 2 ;
  gas_xxx sub,%1,%2
%endmacro
%macro gas_add 2 ;
  gas_xxx add,%1,%2
%endmacro
%macro gas_cmp 2 ;
  gas_xxx cmp,%1,%2
%endmacro
%macro gas_and 2 ;
  gas_xxx and,%1,%2
%endmacro
%macro gas_sar 2
  %ifnum %2
    %ifidni %1,eax
      db 0xc1,0xf8,%2
    %elifidni %1,edx
      db 0xc1,0xfa,%2   
    %else
      sar %1,%2
    %endif
  %else
    sar %1,%2
  %endif
%endmacro
%macro gas_push 1+
  %ifnum %1
    %if %1 < 0x80
      push BYTE %1
    %else 
      push dword %1
    %endif
  %else
    push %1
  %endif
%endmacro

__CODESECT__
init_load_choose:
    gas_cmp       byte ptr [CHOOSE_DAT+0x2],0x0c
    jne       X$1
    xor       eax,eax
    ret       
X$1:
    mov       eax,0xfffffffd
    ret       
    CALIGN 4

found_one:
    gas_sub      esp,0x00000084
    gas_push      ebp
    gas_push      edi
    gas_push      esi
    gas_push      ebx
    mov       ebx,dword ptr [esp+0x98]
    mov       ebx,dword ptr [ebx]
    mov       dword ptr [esp+0x18],ebx
    mov       ebx,dword ptr [esp+0x98]
    mov       ebx,dword ptr [ebx+0x4]
    mov       dword ptr [esp+0x14],ebx
    gas_push      0x00000078
    gas_push      0x00000000
    lea       eax,[esp+0x24]
    gas_push      eax
    call      ptr memset
    mov       edi,0x00000001
    gas_add       esp,0x0000000c
    nop       
X$2:
    gas_cmp       dword ptr [esp+0x14],edi
    jle       X$7
    mov       ebx,dword ptr [esp+0x98]
    mov       ebp,dword ptr [ebx+edi*4+0x18]
    xor       esi,esi
    CALIGN 4
X$3:
    gas_cmp       esi,edi
    jge       X$6
    mov       edx,ebp
    mov       ebx,dword ptr [esp+0x98]
    gas_sub      edx,dword ptr [ebx+esi*4+0x18]
    lea       eax,[edx+edx]
    gas_cmp       dword ptr [esp+0x18],eax
    jl        X$5
    gas_cmp       edx,0x00000040
    jle       X$6
    gas_add       edx,0xffffffc0
    mov       ecx,edx
    gas_and       ecx,0x00000007
    mov       ebx,0x00000001
    shl       ebx,cl
    mov       dword ptr [esp+0x10],ebx
    gas_sar       edx,0x00000003
    mov       cl,byte ptr [esp+edx+0x1c]
    movsx     eax,cl
    test      eax,ebx
    je        X$4
    xor       eax,eax
    pop       ebx
    pop       esi
    pop       edi
    pop       ebp
    gas_add       esp,0x00000084
    ret       
    CALIGN 4
X$4:
    or        cl,byte ptr [esp+0x10]
    mov       byte ptr [esp+edx+0x1c],cl
X$5:
    inc       esi
    gas_jmp       X$3
    nop       
X$6:
    inc       edi
    gas_jmp       X$2
    nop       
X$7:
    mov       eax,0x00000001
    pop       ebx
    pop       esi
    pop       edi
    pop       ebp
    gas_add       esp,0x00000084
    ret       

__CODESECT__
ogr_init:
    call      ptr init_load_choose
    test      eax,eax
    jne       X$8
    xor       eax,eax
    ret       
X$8:
    ret       
    CALIGN 4


ogr_create:
    gas_sub      esp,0x00000018
    gas_push      ebp
    gas_push      edi
    gas_push      esi
    gas_push      ebx
    mov       ecx,dword ptr [esp+0x2c]
    mov       dword ptr [esp+0x24],ecx
    test      ecx,ecx
    je        X$9
    gas_cmp       dword ptr [esp+0x30],0x0000001c
    je        X$10
X$9:
    mov       eax,0xfffffffd
    pop       ebx
    pop       esi
    pop       edi
    pop       ebp
    gas_add       esp,0x00000018
    ret       
    nop       
X$10:
    gas_cmp       dword ptr [esp+0x38],0x00000c1b
    jbe       X$9
    mov       ebx,dword ptr [esp+0x34]
    test      ebx,ebx
    jne       X$11
    mov       eax,0xffffffff
    pop       ebx
    pop       esi
    pop       edi
    pop       ebp
    gas_add       esp,0x00000018
    ret       
    nop       
X$11:
    gas_push      0x00000c1c
    gas_push      0x00000000
    gas_push      ebx
    call      ptr memset
    mov       edi,dword ptr [esp+0x30]
    movzx     eax,word ptr [edi]
    mov       dword ptr [ebx+0x4],eax
    dec       eax
    mov       dword ptr [ebx+0x8],eax
    mov       eax,dword ptr [ebx+0x4]
    gas_add       esp,0x0000000c
    gas_cmp       eax,0x0000001d
    ja        X$9
    mov       eax,dword ptr [eax*4+OGR+0xfffffffc]
    mov       dword ptr [ebx],eax
    mov       eax,dword ptr [ebx+0x4]
    inc       eax
    mov       edx,eax
    gas_sar       edx,0x00000001
    lea       eax,[edx-0x1]
    mov       dword ptr [ebx+0x10],eax
    mov       dword ptr [ebx+0x14],eax
    test      byte ptr [ebx+0x4],0x01
    jne       X$12
    mov       dword ptr [ebx+0x14],edx
X$12:
    dec       dword ptr [ebx+0x10]
    inc       dword ptr [ebx+0x14]
    mov       eax,dword ptr [ebx]
    gas_add       eax,0xfffffffc
    gas_sar       eax,0x00000001
    mov       dword ptr [ebx+0xc],eax
    test      byte ptr [ebx+0x4],0x01
    jne       X$13
    mov       eax,dword ptr [ebx]
    gas_add       eax,0xfffffff9
    gas_sar       eax,0x00000001
    mov       dword ptr [ebx+0xc],eax
X$13:
    mov       dword ptr [ebx+0xc0],0x00000001
    mov       ecx,dword ptr [esp+0x24]
    mov       ecx,dword ptr [ecx+0x18]
    mov       dword ptr [esp+0x1c],ecx
    mov       edi,dword ptr [esp+0x24]
    movzx     eax,word ptr [edi+0x2]
    gas_cmp       ecx,eax
    jge       X$14
    mov       dword ptr [esp+0x1c],eax
X$14:
    gas_cmp       dword ptr [esp+0x1c],0x0000000a
    jg        near X$9
    lea       esi,[ebx+0x124]
    mov       dword ptr [esp+0x20],0x00000000
    mov       dword ptr [esp+0x18],ebx
    CALIGN 4
X$15:
    mov       ecx,dword ptr [esp+0x1c]
    gas_cmp       dword ptr [esp+0x20],ecx
    jge       near X$26
    mov       edx,dword ptr [ebx+0xc0]
    gas_cmp       dword ptr [ebx+0x14],edx
    jl        X$18
    mov       ebp,dword ptr [ebx+0x10]
    gas_cmp       edx,ebp
    jg        X$16
    mov       eax,dword ptr [ebx+0x8]
    gas_sub      eax,edx
    mov       edx,dword ptr [ebx]
    gas_sub      edx,dword ptr [eax*4+OGR]
    mov       eax,dword ptr [ebx+0xc]
    gas_jmp       X$17
    nop       
X$16:
    mov       eax,dword ptr [esi+0x14]
    shr       eax,0x00000014
    mov       edi,dword ptr [ebx+0x8]
    gas_sub      edi,edx
    mov       edx,edi
    lea       eax,[eax+eax*2]
    movzx     edx,byte ptr [edx+eax*4+CHOOSE_DAT+0x3]
    mov       eax,dword ptr [ebx]
    mov       ecx,eax
    gas_sub      ecx,edx
    mov       edx,ecx
    gas_sub      eax,dword ptr [ebx+ebp*4+0x18]
    dec       eax
X$17:
    gas_cmp       edx,eax
    jle       X$19
    mov       edx,eax
    gas_jmp       X$19
    CALIGN 4
X$18:
    mov       eax,dword ptr [esi+0x14]
    shr       eax,0x00000014
    mov       edi,dword ptr [ebx+0x8]
    gas_sub      edi,edx
    mov       edx,edi
    lea       eax,[eax+eax*2]
    movzx     eax,byte ptr [edx+eax*4+CHOOSE_DAT+0x3]
    mov       edx,dword ptr [ebx]
    gas_sub      edx,eax
X$19:
    mov       dword ptr [esi+0x44],edx
    mov       ecx,dword ptr [esp+0x20]
    mov       edi,dword ptr [esp+0x24]
    movzx     ebp,word ptr [edi+ecx*2+0x4]
    mov       edi,dword ptr [ebx+ecx*4+0x18]
    gas_add       edi,ebp
    mov       ecx,dword ptr [esp+0x18]
    mov       dword ptr [ecx+0x1c],edi
    gas_add       dword ptr [esi+0x40],ebp
    mov       dword ptr [esp+0x10],ebp
    gas_cmp       ebp,0x0000001f
    jle       near X$23
    mov       eax,0x0000001f
    gas_sub      eax,ebp
    gas_and       eax,0x0000007f
    je        near X$22
    gas_cmp       eax,0x00000060
    jge       near X$21
    gas_cmp       eax,0x00000040
    jge       X$20
    gas_cmp       eax,0x0000001f
    jle       near X$22
    mov       eax,dword ptr [esi+0x2c]
    mov       dword ptr [esi+0x28],eax
    mov       eax,dword ptr [esi+0x30]
    mov       dword ptr [esi+0x2c],eax
    mov       eax,dword ptr [esi+0x34]
    mov       dword ptr [esi+0x30],eax
    mov       eax,dword ptr [esi+0x38]
    mov       dword ptr [esi+0x34],eax
    mov       dword ptr [esi+0x38],0x00000000
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x10],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0xc],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x8],eax
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x4],eax
    mov       dword ptr [esi],0x00000000
    lea       ecx,[ebp-0x20]
    mov       dword ptr [esp+0x10],ecx
X$20:
    mov       eax,dword ptr [esi+0x2c]
    mov       dword ptr [esi+0x28],eax
    mov       eax,dword ptr [esi+0x30]
    mov       dword ptr [esi+0x2c],eax
    mov       eax,dword ptr [esi+0x34]
    mov       dword ptr [esi+0x30],eax
    mov       eax,dword ptr [esi+0x38]
    mov       dword ptr [esi+0x34],eax
    mov       dword ptr [esi+0x38],0x00000000
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x10],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0xc],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x8],eax
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x4],eax
    mov       dword ptr [esi],0x00000000
    gas_add       dword ptr [esp+0x10],0xffffffe0
X$21:
    mov       eax,dword ptr [esi+0x2c]
    mov       dword ptr [esi+0x28],eax
    mov       eax,dword ptr [esi+0x30]
    mov       dword ptr [esi+0x2c],eax
    mov       eax,dword ptr [esi+0x34]
    mov       dword ptr [esi+0x30],eax
    mov       eax,dword ptr [esi+0x38]
    mov       dword ptr [esi+0x34],eax
    mov       dword ptr [esi+0x38],0x00000000
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x10],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0xc],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x8],eax
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x4],eax
    mov       dword ptr [esi],0x00000000
    gas_add       dword ptr [esp+0x10],0xffffffe0
    gas_cmp       dword ptr [esp+0x10],0x0000001f
    jle       near X$23
X$22:
    mov       eax,dword ptr [esi+0x2c]
    mov       dword ptr [esi+0x28],eax
    mov       eax,dword ptr [esi+0x30]
    mov       dword ptr [esi+0x2c],eax
    mov       eax,dword ptr [esi+0x34]
    mov       dword ptr [esi+0x30],eax
    mov       eax,dword ptr [esi+0x38]
    mov       dword ptr [esi+0x34],eax
    mov       dword ptr [esi+0x38],0x00000000
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x10],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0xc],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x8],eax
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x4],eax
    mov       dword ptr [esi],0x00000000
    mov       eax,dword ptr [esi+0x2c]
    mov       dword ptr [esi+0x28],eax
    mov       eax,dword ptr [esi+0x30]
    mov       dword ptr [esi+0x2c],eax
    mov       eax,dword ptr [esi+0x34]
    mov       dword ptr [esi+0x30],eax
    mov       eax,dword ptr [esi+0x38]
    mov       dword ptr [esi+0x34],eax
    mov       dword ptr [esi+0x38],0x00000000
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x10],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0xc],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x8],eax
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x4],eax
    mov       dword ptr [esi],0x00000000
    mov       eax,dword ptr [esi+0x2c]
    mov       dword ptr [esi+0x28],eax
    mov       eax,dword ptr [esi+0x30]
    mov       dword ptr [esi+0x2c],eax
    mov       eax,dword ptr [esi+0x34]
    mov       dword ptr [esi+0x30],eax
    mov       eax,dword ptr [esi+0x38]
    mov       dword ptr [esi+0x34],eax
    mov       dword ptr [esi+0x38],0x00000000
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x10],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0xc],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x8],eax
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x4],eax
    mov       dword ptr [esi],0x00000000
    mov       eax,dword ptr [esi+0x2c]
    mov       dword ptr [esi+0x28],eax
    mov       eax,dword ptr [esi+0x30]
    mov       dword ptr [esi+0x2c],eax
    mov       eax,dword ptr [esi+0x34]
    mov       dword ptr [esi+0x30],eax
    mov       eax,dword ptr [esi+0x38]
    mov       dword ptr [esi+0x34],eax
    mov       dword ptr [esi+0x38],0x00000000
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x10],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0xc],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x8],eax
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x4],eax
    mov       dword ptr [esi],0x00000000
    gas_add       dword ptr [esp+0x10],0xffffff80
    gas_cmp       dword ptr [esp+0x10],0x0000001f
    jg        near X$22
X$23:
    gas_cmp       dword ptr [esp+0x10],0x00000000
    jle       X$24
    lea       edi,[esi+0x28]
    mov       ecx,dword ptr [esp+0x10]
    mov       eax,dword ptr [edi+0x4]
    mov       edx,dword ptr [esi+0xc]

    shld      dword ptr [edi],eax,cl
    mov       eax,dword ptr [edi+0x8]

    shrd      dword ptr [esi+0x10],edx,cl
    mov       edx,dword ptr [esi+0x8]

    shld      dword ptr [edi+0x4],eax,cl
    mov       eax,dword ptr [edi+0xc]

    shrd      dword ptr [esi+0xc],edx,cl
    mov       edx,dword ptr [esi+0x4]

    shld      dword ptr [edi+0x8],eax,cl
    mov       eax,dword ptr [edi+0x10]

    shrd      dword ptr [esi+0x8],edx,cl
    mov       edx,dword ptr [esi]

    shld      dword ptr [edi+0xc],eax,cl
    shrd      dword ptr [esi+0x4],edx,cl

    shl       dword ptr [edi+0x10],cl
    shr       dword ptr [esi],cl
X$24:
    lea       edi,[esi+0x48]
    mov       dword ptr [esp+0x14],edi
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x48],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x4c],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0x50],eax
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x54],eax
    mov       eax,dword ptr [esi+0x10]
    mov       dword ptr [esi+0x58],eax
    gas_cmp       ebp,0x000000a0
    ja        X$25
    lea       eax,[ebp-0x1]
    mov       edx,eax
    shr       edx,0x00000005
    mov       ebp,eax
    gas_and       ebp,0x0000001f
    mov       eax,0x80000000
    mov       ecx,ebp
    shr       eax,cl
    or        dword ptr [edi+edx*4],eax
X$25:
    mov       edi,dword ptr [esi+0x14]
    or        edi,dword ptr [esi+0x48]
    mov       dword ptr [esi+0x5c],edi
    mov       ecx,dword ptr [esi+0x18]
    or        ecx,dword ptr [esi+0x4c]
    mov       dword ptr [esi+0x60],ecx
    mov       edi,dword ptr [esi+0x1c]
    or        edi,dword ptr [esi+0x50]
    mov       dword ptr [esi+0x64],edi
    mov       ecx,dword ptr [esi+0x20]
    or        ecx,dword ptr [esi+0x54]
    mov       dword ptr [esi+0x68],ecx
    mov       edi,dword ptr [esi+0x24]
    or        edi,dword ptr [esi+0x58]
    mov       dword ptr [esi+0x6c],edi
    mov       ecx,dword ptr [esi+0x28]
    or        ecx,dword ptr [esi+0x5c]
    mov       dword ptr [esi+0x70],ecx
    mov       edi,dword ptr [esi+0x2c]
    or        edi,dword ptr [esi+0x60]
    mov       dword ptr [esi+0x74],edi
    mov       ecx,dword ptr [esi+0x30]
    or        ecx,dword ptr [esi+0x64]
    mov       dword ptr [esi+0x78],ecx
    mov       edi,dword ptr [esi+0x34]
    or        edi,dword ptr [esi+0x68]
    mov       dword ptr [esi+0x7c],edi
    mov       ecx,dword ptr [esi+0x38]
    or        ecx,dword ptr [esi+0x6c]
    mov       dword ptr [esi+0x80],ecx
    mov       eax,dword ptr [esi+0x40]
    mov       dword ptr [esi+0x84],eax
    mov       eax,dword ptr [esi+0x40]
    mov       dword ptr [esi+0x88],eax
    mov       esi,dword ptr [esp+0x14]
    inc       dword ptr [ebx+0xc0]
    gas_add       dword ptr [esp+0x18],0x00000004
    inc       dword ptr [esp+0x20]
    jmp       ptr X$15
    CALIGN 4
X$26:
    dec       dword ptr [ebx+0xc0]
    mov       edi,dword ptr [esp+0x24]
    movzx     edi,word ptr [edi+0x2]
    mov       dword ptr [ebx+0xbc],edi
    xor       eax,eax
    pop       ebx
    pop       esi
    pop       edi
    pop       ebp
    gas_add       esp,0x00000018
    ret       
    CALIGN 4

    ;-------------------------------------------------
    align 32
OGR:
    db  0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00
    db  0x03, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00
    db  0x0b, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00
    db  0x19, 0x00, 0x00, 0x00, 0x22, 0x00, 0x00, 0x00
    db  0x2c, 0x00, 0x00, 0x00, 0x37, 0x00, 0x00, 0x00
    db  0x48, 0x00, 0x00, 0x00, 0x55, 0x00, 0x00, 0x00
    db  0x6a, 0x00, 0x00, 0x00, 0x7f, 0x00, 0x00, 0x00
    db  0x97, 0x00, 0x00, 0x00, 0xb1, 0x00, 0x00, 0x00
    db  0xc7, 0x00, 0x00, 0x00, 0xd8, 0x00, 0x00, 0x00
    db  0xf6, 0x00, 0x00, 0x00, 0x1b, 0x01, 0x00, 0x00
    db  0x4d, 0x01, 0x00, 0x00, 0x64, 0x01, 0x00, 0x00
    db  0x74, 0x01, 0x00, 0x00, 0xa9, 0x01, 0x00, 0x00
    db  0xe0, 0x01, 0x00, 0x00, 0xec, 0x01, 0x00, 0x00
    db  0x29, 0x02, 0x00, 0x00, 0x49, 0x02, 0x00, 0x00
    db  0x6f, 0x02, 0x00, 0x00,    0,0,0,0
    db  0,0,0,0, 0,0,0,0
    ;-------------------------------------------------
    align 32


ogr_cycle:
    gas_sub      esp,0x00000018
    gas_push      ebp
    gas_push      edi
    gas_push      esi
    gas_push      ebx
    mov       ebx,dword ptr [esp+0x2c]
    mov       ecx,dword ptr [ebx+0xc0]
    inc       ecx
    mov       dword ptr [esp+0x24],ecx
    lea       eax,[ecx+ecx*8]
    lea       esi,[ebx+eax*8+0xdc]
    mov       dword ptr [esp+0x20],0x00000000
    mov       edi,dword ptr [esp+0x30]
    mov       edi,dword ptr [edi]
    mov       dword ptr [esp+0x1c],edi
    mov       dword ptr [esp+0x18],0x00000001
    CALIGN 4
X$27:
    mov       eax,dword ptr [esi+0x40]
    mov       ecx,dword ptr [esp+0x24]
    mov       dword ptr [ebx+ecx*4+0x14],eax
    gas_cmp       dword ptr [ebx+0x14],ecx
    jl        X$30
    mov       edi,dword ptr [ebx+0x10]
    mov       dword ptr [esp+0x10],edi
    gas_cmp       ecx,edi
    jg        X$28
    mov       ecx,dword ptr [esp+0x1c]
    gas_cmp       dword ptr [esp+0x20],ecx
    jge       near X$39
    mov       eax,dword ptr [ebx+0x8]
    gas_sub      eax,dword ptr [esp+0x24]
    mov       ebp,dword ptr [ebx]
    gas_sub      ebp,dword ptr [eax*4+OGR]
    mov       eax,dword ptr [ebx+0xc]
    gas_jmp       X$29
    CALIGN 4
X$28:
    mov       eax,dword ptr [esi+0x14]
    shr       eax,0x00000014
    mov       edx,dword ptr [ebx+0x8]
    gas_sub      edx,dword ptr [esp+0x24]
    lea       eax,[eax+eax*2]
    movzx     edx,byte ptr [edx+eax*4+CHOOSE_DAT+0x3]
    mov       eax,dword ptr [ebx]
    mov       ebp,eax
    gas_sub      ebp,edx
    mov       edi,dword ptr [esp+0x10]
    gas_sub      eax,dword ptr [ebx+edi*4+0x18]
    dec       eax
X$29:
    gas_cmp       ebp,eax
    jle       X$31
    mov       ebp,eax
    gas_jmp       X$31
    nop       
X$30:
    mov       eax,dword ptr [esi+0x14]
    shr       eax,0x00000014
    mov       edx,dword ptr [ebx+0x8]
    gas_sub      edx,dword ptr [esp+0x24]
    lea       eax,[eax+eax*2]
    movzx     eax,byte ptr [edx+eax*4+CHOOSE_DAT+0x3]
    mov       ebp,dword ptr [ebx]
    gas_sub      ebp,eax
X$31:
    inc       dword ptr [esp+0x20]
X$32:
    mov       edx,dword ptr [esi+0x28]
    gas_cmp       edx,0xfffffffd
    ja        X$33
    not       edx
    mov       ecx,0x00000020
    bsr       edx,edx
    gas_sub      ecx,edx
    mov       dword ptr [esp+0x10],ecx
    mov       eax,ecx
    gas_add       eax,dword ptr [esi+0x40]
    mov       dword ptr [esi+0x40],eax
    gas_cmp       eax,ebp
    jg        near X$37
    lea       edi,[esi+0x28]
    mov       ecx,dword ptr [esp+0x10]
    mov       eax,dword ptr [edi+0x4]
    mov       edx,dword ptr [esi+0xc]
    shld      dword ptr [edi],eax,cl
    mov       eax,dword ptr [edi+0x8]
    shrd      dword ptr [esi+0x10],edx,cl
    mov       edx,dword ptr [esi+0x8]
    shld      dword ptr [edi+0x4],eax,cl
    mov       eax,dword ptr [edi+0xc]
    shrd      dword ptr [esi+0xc],edx,cl
    mov       edx,dword ptr [esi+0x4]
    shld      dword ptr [edi+0x8],eax,cl
    mov       eax,dword ptr [edi+0x10]
    shrd      dword ptr [esi+0x8],edx,cl
    mov       edx,dword ptr [esi]
    shld      dword ptr [edi+0xc],eax,cl
    shrd      dword ptr [esi+0x4],edx,cl
    shl       dword ptr [edi+0x10],cl
    shr       dword ptr [esi],cl
    gas_jmp       X$34
X$33:
    mov       eax,dword ptr [esi+0x40]
    gas_add       eax,0x00000020
    mov       dword ptr [esi+0x40],eax
    gas_cmp       eax,ebp
    jg        near X$37
    mov       eax,dword ptr [esi+0x2c]
    mov       dword ptr [esi+0x28],eax
    mov       eax,dword ptr [esi+0x30]
    mov       dword ptr [esi+0x2c],eax
    mov       eax,dword ptr [esi+0x34]
    mov       dword ptr [esi+0x30],eax
    mov       eax,dword ptr [esi+0x38]
    mov       dword ptr [esi+0x34],eax
    mov       dword ptr [esi+0x38],0x00000000
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x10],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0xc],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x8],eax
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x4],eax
    mov       dword ptr [esi],0x00000000
    gas_cmp       edx,0xffffffff
    je        near X$32
X$34:
    mov       edi,dword ptr [esp+0x24]
    gas_cmp       dword ptr [ebx+0x8],edi
    jne       X$35
    mov       eax,dword ptr [esi+0x40]
    mov       dword ptr [ebx+edi*4+0x18],eax
    gas_push      ebx
    call      ptr found_one
    gas_add       esp,0x00000004
    test      eax,eax
    je        near X$32
    mov       dword ptr [esp+0x18],0x00000002
    jmp       ptr X$39
X$35:
    lea       ecx,[esi+0x48]
    mov       dword ptr [esp+0x14],ecx
    mov       edx,dword ptr [esi+0x40]
    gas_sub      edx,dword ptr [esi+0x3c]
    mov       eax,dword ptr [esi]
    mov       dword ptr [esi+0x48],eax
    mov       eax,dword ptr [esi+0x4]
    mov       dword ptr [esi+0x4c],eax
    mov       eax,dword ptr [esi+0x8]
    mov       dword ptr [esi+0x50],eax
    mov       eax,dword ptr [esi+0xc]
    mov       dword ptr [esi+0x54],eax
    mov       eax,dword ptr [esi+0x10]
    mov       dword ptr [esi+0x58],eax
    gas_cmp       edx,0x000000a0
    ja        X$36
    lea       eax,[edx-0x1]
    mov       edx,eax
    shr       edx,0x00000005
    gas_and       eax,0x0000001f
    mov       dword ptr [esp+0x10],eax
    mov       eax,0x80000000
    mov       ecx,dword ptr [esp+0x10]
    shr       eax,cl
    mov       edi,dword ptr [esp+0x14]
    or        dword ptr [edi+edx*4],eax
X$36:
    mov       ecx,dword ptr [esi+0x14]
    or        ecx,dword ptr [esi+0x48]
    mov       dword ptr [esi+0x5c],ecx
    mov       edi,dword ptr [esi+0x18]
    or        edi,dword ptr [esi+0x4c]
    mov       dword ptr [esi+0x60],edi
    mov       ecx,dword ptr [esi+0x1c]
    or        ecx,dword ptr [esi+0x50]
    mov       dword ptr [esi+0x64],ecx
    mov       edi,dword ptr [esi+0x20]
    or        edi,dword ptr [esi+0x54]
    mov       dword ptr [esi+0x68],edi
    mov       ecx,dword ptr [esi+0x24]
    or        ecx,dword ptr [esi+0x58]
    mov       dword ptr [esi+0x6c],ecx
    mov       edi,dword ptr [esi+0x28]
    or        edi,dword ptr [esi+0x5c]
    mov       dword ptr [esi+0x70],edi
    mov       ecx,dword ptr [esi+0x2c]
    or        ecx,dword ptr [esi+0x60]
    mov       dword ptr [esi+0x74],ecx
    mov       edi,dword ptr [esi+0x30]
    or        edi,dword ptr [esi+0x64]
    mov       dword ptr [esi+0x78],edi
    mov       ecx,dword ptr [esi+0x34]
    or        ecx,dword ptr [esi+0x68]
    mov       dword ptr [esi+0x7c],ecx
    mov       edi,dword ptr [esi+0x38]
    or        edi,dword ptr [esi+0x6c]
    mov       dword ptr [esi+0x80],edi
    mov       eax,dword ptr [esi+0x40]
    mov       dword ptr [esi+0x84],eax
    mov       eax,dword ptr [esi+0x40]
    mov       dword ptr [esi+0x88],eax
    mov       dword ptr [esi+0x44],ebp
    mov       esi,dword ptr [esp+0x14]
    inc       dword ptr [esp+0x24]
    jmp       ptr X$27
    CALIGN 4
X$37:
    gas_add       esi,0xffffffb8
    dec       dword ptr [esp+0x24]
    mov       ecx,dword ptr [esp+0x24]
    gas_cmp       dword ptr [ebx+0xbc],ecx
    jge       X$38
    mov       ebp,dword ptr [esi+0x44]
    jmp       ptr X$32
    nop       
X$38:
    mov       dword ptr [esp+0x18],0x00000000
X$39:
    mov       edi,dword ptr [esp+0x24]
    dec       edi
    mov       dword ptr [ebx+0xc0],edi
    mov       edi,dword ptr [esp+0x20]
    mov       ecx,dword ptr [esp+0x30]
    mov       dword ptr [ecx],edi
    mov       eax,dword ptr [esp+0x18]
    pop       ebx
    pop       esi
    pop       edi
    pop       ebp
    gas_add       esp,0x00000018
    ret       
    CALIGN 4

ogr_getresult:
    gas_push      ebx
    mov       edx,dword ptr [esp+0x8]
    mov       ecx,dword ptr [esp+0xc]
    gas_cmp       dword ptr [esp+0x10],0x0000001c
    je        X$40
    mov       eax,0xfffffffd
    pop       ebx
    ret       
    nop       
X$40:
    mov       eax,dword ptr [edx+0x4]
    mov       word ptr [ecx],ax
    mov       eax,dword ptr [edx+0xbc]
    mov       word ptr [ecx+0x2],ax
    mov       bx,word ptr [edx+0x1c]
    gas_sub      bx,word ptr [edx+0x18]
    mov       word ptr [ecx+0x4],bx
    mov       bx,word ptr [edx+0x20]
    gas_sub      bx,word ptr [edx+0x1c]
    mov       word ptr [ecx+0x6],bx
    mov       bx,word ptr [edx+0x24]
    gas_sub      bx,word ptr [edx+0x20]
    mov       word ptr [ecx+0x8],bx
    mov       bx,word ptr [edx+0x28]
    gas_sub      bx,word ptr [edx+0x24]
    mov       word ptr [ecx+0xa],bx
    mov       bx,word ptr [edx+0x2c]
    gas_sub      bx,word ptr [edx+0x28]
    mov       word ptr [ecx+0xc],bx
    mov       bx,word ptr [edx+0x30]
    gas_sub      bx,word ptr [edx+0x2c]
    mov       word ptr [ecx+0xe],bx
    mov       bx,word ptr [edx+0x34]
    gas_sub      bx,word ptr [edx+0x30]
    mov       word ptr [ecx+0x10],bx
    mov       bx,word ptr [edx+0x38]
    gas_sub      bx,word ptr [edx+0x34]
    mov       word ptr [ecx+0x12],bx
    mov       bx,word ptr [edx+0x3c]
    gas_sub      bx,word ptr [edx+0x38]
    mov       word ptr [ecx+0x14],bx
    mov       bx,word ptr [edx+0x40]
    gas_sub      bx,word ptr [edx+0x3c]
    mov       word ptr [ecx+0x16],bx
    mov       eax,dword ptr [edx+0xc0]
    mov       dword ptr [ecx+0x18],eax
    gas_cmp       eax,0x0000000a
    jbe       X$41
    mov       dword ptr [ecx+0x18],0x0000000a
X$41:
    xor       eax,eax
    pop       ebx
    ret       
    CALIGN 4

    ;---------------- end of bit compatible area -------------

ogr_destroy:
ogr_cleanup:
    xor       eax,eax
    ret       

    align 32

_dispatch_table:
    dd offset ogr_init
    dd offset ogr_create
    dd offset ogr_cycle
    dd offset ogr_getresult
    dd offset ogr_destroy
    dd offset ogr_cleanup
    dd 0,0

    align 32

_ogr_get_dispatch_table:
ogr_get_dispatch_table:
    mov       eax,offset _dispatch_table
    ret

    CALIGN 32
my_memset:
    gas_push       edi
    gas_push       ebx
    mov        edi, [esp+0xc]
    movzx eax, BYTE [esp+0x10] ;0f b6 44 24 10
    mov        ecx, [esp+0x14]
    gas_push       edi
    cld              
    gas_cmp        ecx, 15
    jle        short .here
    mov        ah,al
    mov        edx,eax
    shl        eax,16
    mov        ax,dx
    mov        edx,edi
    neg        edx
    gas_and        edx,3
    mov        ebx,ecx
    gas_sub        ebx,edx
    mov        ecx,edx
    repz       stosb
    mov        ecx,ebx
    shr        ecx,2
    repz       stosd
    mov        ecx,ebx
    gas_and        ecx,3
.here:
    repz stosb
    pop        eax
    pop        ebx
    pop        edi
    ret              

