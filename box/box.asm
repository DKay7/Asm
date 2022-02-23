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

fg_color        = 1Bh
bg_color        = 0Bh  
start_x         = 5
start_y         = 5

text_x_shift    = 2
text_y_shift    = 2

;------------------------------------------------------------------------
; macro block

NewLineForBox macro reg
    add reg, 2 * (window_len - box_len)
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
    cmp dh, 3 * byte_array_len
    jb default_mode

    ; user_mode        
        mov di, cmd_data_addr
        mov si, offset header_symbols
        call CopyCmdData

        mov dh, ds:[cmd_n_args_addr]
        cmp dh, 1 + 3 * byte_array_len  ; skip 9 character array, and first space
        jbe default_mode

        ; we have a text to copy
        mov cl, dh
        mov si, offset text_data
        mov di, cmd_data_addr
        call CopyCmdText
        
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
        NewLineForBox di                            ; new line 
        inc bx                                      ; increment cycle counter
        mov cx, box_len                             ; loads box len to compare later
        mov si, offset middle_symbols               ; loads pointer to next array (middle-lines array)
        

        call DrawLine                               ; calls function to draw middle-lines
        
        cmp bx, box_height                          ; compare cycle counter and length of box
        jbe zaloop                                  ; (zaloop)

    NewLineForBox di                                ; another new line 

    mov cx, box_len                                 ; loads box len
    mov si, offset bottom_symbols                   ; loads pointer to array with footer line

    ;add si, byte_array_len
    call DrawLine                                   ; calls function to draw footer line 

    ; draws text
    ; si -- offset of the text_data, di 
    mov si, offset text_data
    call CentringText

    mov si, offset text_data
    call WriteText

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
    @@copy_symbols_zaloop:
        mov ah, [di]
        mov [si], ah
        inc di
        inc si
    loop @@copy_symbols_zaloop
    ret 
CopyCmdData     endp

;------------------------------------------------------------------------
; CopyCmdText
;
; Copies cmd text to special position in memory
;
; Entry:    SI -- addr to copy text in
;           DI -- addr of cmd elements array
;           CX -- num of args
; Exit:  None
; Destr: DI, SI
;------------------------------------------------------------------------
CopyCmdText     proc
    add di, 1 + byte_array_len * 3  ; skip 9 character array, and first space
    
    sub cx, 2                       ; skip 2 spaces and 9-characters array
    sub cx, byte_array_len * 3
    je  @@no_text_to_copy

    @@copy_text_zaloop:
        mov ah, [di]
        mov [si], ah
        inc di
        inc si
    loop @@copy_text_zaloop

    mov ax, 0
    mov [si], ax        ; moves terminating 0 to [si]

    @@no_text_to_copy:
    ret 
CopyCmdText     endp

;------------------------------------------------------------------------
; strlen
;
; Counts the length of the given string
;
; Entry:    SI -- addr of 0-terminated string
;
; Exit:     CX -- length of the string without 0-symbol
;
; Destr:    AL, CX, SI
;------------------------------------------------------------------------
strlen    proc
    xor cx, cx

    lodsb 
    cmp al, 0
    je @@return     ; if string contains only 0-terminator char

    @@zaloop:
        inc cx
        lodsb
        cmp al, 0
    jne @@zaloop

    @@return:
        ret
strlen    endp

;------------------------------------------------------------------------
; CentringText
;
; centres text inside box it
;
; Entry:    SI -- addr of text
;
; Exit:     DI -- offset of start of text in videoram
;
; Destr:    AX, BX, CX, SI, DI
;------------------------------------------------------------------------
CentringText    proc
    call strlen
    
    xor ax, ax
    mov al, cl
    mov bl, (box_len - 2 * text_x_shift)
    div bl
    mov bl, al

    xor ax, ax
    mov al, cl
    mov dl, (box_height - 2 * text_y_shift)
    div dl

    mov dh, al
    cmp ah, 0h
    je @@no_reminder
        inc dh

    @@no_reminder:    
    mov dl, al

    mov di, (start_x + text_x_shift + (start_y + text_y_shift) * window_len) * 2

    mov ax, box_height - text_y_shift
    sub dh, al
    shr al, 1
    mov dh, al

    xor ax, ax
    mov al, dh
    mov dh, window_len * 2
    mul dh
    add di, ax

    ret
CentringText    endp

;------------------------------------------------------------------------
; WriteText
;
; writes centered text inside box
;
; Entry:    SI -- addr of text
;           DI -- offset of start of text in videoram
; Exit:     None
;
; Destr:    AX, BX, CX, SI, DI
;------------------------------------------------------------------------
WriteText   proc

    mov ah, fg_color

    jmp @@draw_text_start
    @@draw_text:
        mov cx, (box_len - 2 * text_x_shift)    
        @@draw_one_text_line:
            lodsb
            stosw
        loop @@draw_one_text_line

        NewLineForBox di
        add di, 8
        dec bl
    @@draw_text_start:
        cmp bl, 0h
    jne @@draw_text

    mov dx, si
    call strlen
    mov si, dx

    mov ax, box_len - text_x_shift
    sub ax, cx
    shr ax, 1
    add di, ax 
    add di, ax     

    mov ah, fg_color

    @@draw_the_last_text_line:
        lodsb
        stosw
    loop @@draw_the_last_text_line

    ret
WriteText   endp

;------------------------------------------------------------------------
; data block
.data
header_symbols  db  "ÕÍ»"
middle_symbols  db  "³°º"
bottom_symbols  db  "ÔÍ¼"
text_data       db  "Poltorashka! :3", 0

end start