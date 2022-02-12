.model tiny
.code
org 100h

start:
    mov ah, 9
    mov dx, offset msg
    int 21h

    mov ax, 4c00h
    int 21h

.data
msg     db "murr poltorashka$"

end start
