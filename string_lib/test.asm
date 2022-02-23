model tiny
.code
org 100h

start:
    
    mov si, offset msg1
    call atoi_10
    ;call atoi_8
    ;call atoi_2
    ;call itoa_8
    ;call itoa_16
    ;call itoa_2
    ;call itoa_10
    ;call StrNCmp
    ;call StrNCpy
    ;call StrChr
    ;call StrLen
    
    mov ax, 4c00h
    int 21h

    include str_lib.asm

.data 
msg1     db "57040",  0
msg2     db "kekkaks loll", 0
end start