.model tiny
;------------------------------------------------------------------------
; constants
cmd_n_args_addr = 80h
cmd_data_addr   = 82h
byte_array_len  = 3h

videoseg	    = 0b800h

box_len         = 44h
box_height      = 0fh

window_len      = 50h
window_height   = 14h

fg_color        = 0eh
bg_color        = 04h  
start_x         = 5
start_y         = 5

;------------------------------------------------------------------------
; macro block

NewLineForBox macro
    add di, 2 * (window_len - box_len)
endm

;------------------------------------------------------------------------
; code block

.code
locals @@
org 100h

;------------------------------------------------------------------------
; main block

start:
    mov dh, ds:[cmd_n_args_addr]
    cmp dh, 0
    je default_mode

    ; user_mode
        mov di, cmd_data_addr
        mov si, offset header_symbols
        call CopyCmdData
    
    default_mode:
        mov si, offset header_symbols               ; loads data addres to si 

    mov ah, bg_color                                ; loads color
    mov bx, videoseg                                ; loads videoseg addr
    mov es, bx                                      ; loads videoseg addr
    mov cx, box_len                                 ; loads box len
    mov di, (start_x + start_y * window_len) * 2    ; sets correct position

    call DrawLine                                   ; calls function to draw header line

    xor bx, bx                                      ; sets bx to 0
    
    zaloop:                                         ; (zaloop)
        NewLineForBox                               ; new line 
        inc bx                                      ; increment cycle counter
        mov cx, box_len                             ; loads box len to compare later
        mov si, offset middle_symbols               ; loads pointer to next array (middle-lines array)
        

        call DrawLine                               ; calls function to draw middle-lines
        
        cmp bx, box_height                          ; compare cycle counter and length of box
        jbe zaloop                                  ; (zaloop)

    NewLineForBox                                   ; another new line 

    mov cx, box_len                                 ; loads box len
    mov si, offset bottom_symbols                   ; loads pointer to array with footer line

    ;add si, byte_array_len
    call DrawLine                                   ; calls function to draw footer line 

    mov ax, 4c00h
    int 21h


;------------------------------------------------------------------------
; DrawLine
;
; Draws one a line in a frame by given characters
;
; Entry:    AH -- color of a line
;           CX -- len of a line
;           SI -- addr of 3-byte array containing line elements
;           DI -- addres of a start of a line
; Note:  ES -- videoseg addr (0b800h)
; Exit:  None
; Destr: AX, CX, DI, SI
;------------------------------------------------------------------------
DrawLine    proc
    cmp cx, 2                               
    jbe @@stopLine          ; if cx - 2 <= 0 then we shouldnt draw line

    lodsb                   ; puts first symbol to a-low and increses si by 1
    stosw                   ; puts ax (ah -- (color), al -- (symb)) to videoram and increses di by 2      
    
    lodsb                   ; puts second symbol to a-low and increses si by 1
    
    sub cx, 2                               
    repnz stosw             ; repeats while cx not zero
                            ; puts ax (ah -- (color), al -- (symb)) to videoram and increses di by 2 

    lodsb                   ; puts third symbol to a-low and increses si by 1
    stosw                   ; puts ax (ah -- (color), al -- (symb)) to videoram and increses di by 2

    @@stopLine:             
        ret
DrawLine    endp

;------------------------------------------------------------------------
; CopyCmdData
;
; Copies cmd args to special position in memory
;
; Entry:    SI -- addr of 3-byte array to copy cmd elements
;           DI -- addr of cmd elements array
; Exit:  None
; Destr: DI, SI, CX, AX
;------------------------------------------------------------------------
CopyCmdData     proc
    mov cx, byte_array_len * 3
    @@copy_zaloop:
        mov ah, [di]
        mov [si], ah
        inc di
        inc si
    loop @@copy_zaloop
    ret
CopyCmdData     endp


;------------------------------------------------------------------------
; data block
.data
header_symbols  db  "ÕÍ»"
middle_symbols  db  "³°º"
bottom_symbols  db  "ÔÍ¼"


end start