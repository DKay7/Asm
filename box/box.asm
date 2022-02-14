.model tiny

;------------------------------------------------------------------------
; constants

cmd_data_addr   = 82h
byte_array_len  = 3h

videoseg	    = 0b800h


box_len         = 44h
box_height      = 0fh

window_len      = 50h
window_height   = 14h

bg_color        = 04h  
start_x         = 5
start_y         = 5
;------------------------------------------------------------------------
; macro block

NewLineForBox macro
    add di, 2 * (window_len - box_len)
endm

;------------------------------------------------------------------------
; main block

.code
locals @@
org 100h

start:
    mov ah, bg_color                                ; loads color
    mov bx, videoseg                                ; loads videoseg addr
    mov es, bx                                      ; loads videoseg addr

    mov cx, box_len                                 ; loads box len
    mov si, cmd_data_addr                           ; loads cmd data addres 
    mov di, (start_x + start_y * window_len) * 2    ; sets correct position
    call DrawLine                                   ; calls function to draw header line

    xor bx, bx                                      ; sets bx to 0
    
    zaloop:                                         ; (zaloop)
        NewLineForBox                               ; new line 
        inc bx                                      ; increment cycle counter
        mov cx, box_len                             ; loads box len to compare later
        mov si, cmd_data_addr + byte_array_len      ; loads pointer to next array (middle-lines array)
        call DrawLine                               ; calls function to draw middle-lines
        
        cmp bx, box_height                          ; compare cycle counter and length of box
        jbe zaloop                                  ; (zaloop)

    NewLineForBox                                   ; another new line 

    mov cx, box_len                                 ; loads box len
    mov si, cmd_data_addr + 2 * byte_array_len      ; loads pointer to array with footer line
    call DrawLine                                   ; calls function to draw footer line 

    mov ax, 4c00h
    int 21h


;------------------------------------------------------------------------
; DrawLine
;
; Draws one a line in a frame by given characters
;
; Entry:    AH -- color of a line
;           CX -- len of a string
;           SI -- addr of 3-byte array containing line elements
;           DI -- addres of a start of a line
; Note:  ES -- videoseg addr (0b800h)
; Exit:  None
; Destr: AX, CX, DI, SI
;------------------------------------------------------------------------
DrawLine    proc
    mov al, [si]            ; first symbol to a-low         ; one command loadsb (byte)
    inc si                  ;                               ; one command loadsb (byte)         -- increases si on 1
                                                        
    mov es:[di], ax         ; add ah (color) and al         ; stosw (store string of words)
                            ; (symb) to videoram

    add di, 2               ; moves line ptr        
                                    
    mov al, [si]            ; as above                      ; loadsb
    inc si                                                  ; loadsb

    sub cx, 2                               
                                            
    jbe @@stopLine          ; if cx - 2 <= 0 then we shouldnt draw line

    @@nextSym:
        mov es:[di], ax                                     ; rep stosw = subs cx 1 and repeats "stosw"7 while cx > 0
        add di, 2           ; moves line ptr for 2 bytes
        loop @@nextSym      ; special command which subs 1 from cx and jumps to nextSym

    mov al, [si]            ; as above                      ; loadsb
    mov es:[di], ax                                         ; stosw

    add di, 2               ; idk

    @@stopLine:             
        ret
DrawLine endp

;------------------------------------------------------------------------
end start
;hate 111, let's make it 112