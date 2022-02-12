.model tiny
;----------------------------------------
; constants

videoseg	    = 0b800h
border_color    = 04h
bg_color        = 04h  

box_len         = 44h
box_height      = 0fh

window_len      = 50h
window_height   = 14h


start_x         = 5
start_y         = 5
;----------------------------------------

.code
locals @@
org 100h

start:
    mov ah, bg_color      
    mov bx, videoseg
    mov es, bx

    mov cx, box_len
    mov si, offset horyz_up_symbs
    mov di, (start_x + start_y * window_len) * 2
    call DrawLine

    xor bx, bx
    
    zaloop:
        add di, 2 * (window_len - box_len)

        inc bx
        mov cx, box_len
        mov si, offset vertc_symbs
        call DrawLine
        
        cmp bx, box_height
        jbe zaloop

    add di, 2 * (window_len - box_len)
    mov cx, box_len
    mov si, offset horyz_down_symbs
    call DrawLine


    mov ax, 4c00h
    int 21h


;----------------------------------------
; Draws a line in a frame
; Entry:    AH -- color of a line
;           CX -- len of a string
;           SI -- addr of 3-byte array containing line elements
;           DI -- addres of a start of a line
; Note:  ES -- videoseg addr (0b800h)
; Exit:  None
; Destr: AX, CX
;----------------------------------------

DrawLine    proc
    mov al, [si]        ; first symbol to a-low         ; one command loadsb (byte)
    inc si              ; increase si (si++)            ; one command loadsb (byte)         -- increases si on 1
                                                        ; also loadsw        (word)         -- increases si on 2
                                                        ; also loadsd        (double word)  -- increases si on 4
                                                        ; cld                               -- clear destination flag
                                                        
    mov es:[di], ax     ; add ah (color) and al (symb) to videoram
                                                        ; stosw (store string of words)

    add di, 2           ; moves line ptr        
                                    
    mov al, [si]        ; as above                      ; loadsb
    inc si                                              ; loadsb

    sub cx, 2                               
                                            
    jbe @@stopLine      ; if cx - 2 <= 0 then we shouldnt draw line

    @@nextSym:
        mov es:[di], ax                                 ; rep stosw = subs cx 1 and repeats "stosw"7 while cx > 0
        add di, 2           ; moves line ptr for 2 bytes
        loop @@nextSym      ; special command which subs 1 from cx and jumps to nextSym

    mov al, [si]            ; as above                  ; loadsb
    mov es:[di], ax                                     ; stosw

    add di, 2

    @@stopLine:
        ret
DrawLine endp

;----------------------------------------

.data
horyz_up_symbs      db "…Õª"
horyz_down_symbs    db "»Õº"
vertc_symbs         db "∫ ∫"
end start