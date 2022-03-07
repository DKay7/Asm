.model tiny
.186
.code
org 100h
locals @@


;-------------------------------------------------------------------------
; CONSTANTS BLOCK
;-------------------------------------------------------------------------

SwitchButton        =   1Ah     ; "[" on keyboard
videoseg	        =   0b800h
int_09_addr         =   09h * 4
int_08_addr         =   08h * 4
WP                  equ word ptr

one_reg_name_len    = 5d
num_of_regs         = 8d

byte_array_len      = 3d

fg_color            = 1Bh
bg_color            = 0Bh  

window_len          = 80d
window_height       = 25d
buffer_seg          = 0B925h
buffer_size         = window_len * window_height

box_len             = 18h
box_height          = 10h

text_x_shift        = 8
text_y_shift        = 2
start_x             = 5
start_y             = 5

;-------------------------------------------------------------------------
; MACRO BLOCK
;-------------------------------------------------------------------------


;-------------------------------------------------------------------------
; ResidentForever says dos not to delete our evil programm from interrups table 
;-------------------------------------------------------------------------
ResidentForever macro
    mov ax, 3100h
    mov dx, offset ResidentEnd
    add dx, 15d
    shr dx, 04h
    int 21h
endm

;-------------------------------------------------------------------------
; NewLineForBox makes new line for a given register
;-------------------------------------------------------------------------
NewLineForBox macro reg
    add reg, 2 * (window_len - box_len)
endm

NewLineForRegister macro reg
    add reg, 2 * (window_len - box_len +  2 * text_x_shift)
endm

;-------------------------------------------------------------------------
; MAIN BLOCK
;-------------------------------------------------------------------------

start:
    xor bx, bx
    mov es, bx

    mov bx, int_09_addr
    mov di, offset OldInt09
    mov si, offset NewInt09_Evil
    call ReplaceInterrupt

    mov bx, int_08_addr
    mov di, offset OldInt08
    mov si, offset NewInt08_Evil
    call ReplaceInterrupt
    
    ResidentForever

    include str_lib.asm

;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
; FUNCTIONS BLOCK
;-------------------------------------------------------------------------

; WriteBuffer
; 
; Expects:
;          ES:DI addres of start buffer to copy to
;          DS:SI addres of start of buffer
;          CX    size of buffer
; Destroys: AX
;-------------------------------------------------------------------------
WriteBuffer proc
    @@copy_cycle:
        lodsw
        stosw
    loop @@copy_cycle

    ret
WriteBuffer endp

;-------------------------------------------------------------------------
; ReplaceInterrupt
; replace old interrupt with new one, but saves old one too
; Expects:
;           BX: addres of interrupt to replace
;           DI: addres of buffer to save old interrupt
;           SI: addres of new interrupt to replace old one with
; Destroys: BX, DI, SI, ES
;-------------------------------------------------------------------------

ReplaceInterrupt proc
    xor ax, ax
    mov es, ax              ; moving 0 to es

    ; saving old intterupt 
    mov ax, WP es:[bx]      ; copy old-int addres to ax
    mov [di], ax            ; move old-int addres to buffer

    mov ax, WP es:[bx + 2]  ; copy old-int segment to ax
    mov [di + 2], ax        ; move old-int segment to buffer

    ; moving new int 09 to replace old
    cli                     ; forbids to call interrupts 
    mov ax, si
    mov WP es:[bx], ax      ; move new-int addres to interrupts table
    mov ax, cs
    mov WP es:[bx + 2], ax  ; move new-int segment to interrupts table

    sti                     ; allows to call interrupts 
    
    ret
ReplaceInterrupt endp

;-------------------------------------------------------------------------
; NewInt09_Evil
; custom 09 interrupt which change FrameSwitcher flag
;
; Destroys: All registers were pushed
;-------------------------------------------------------------------------

NewInt09_Evil proc
    push ax bx cx dx si di es ds 
    in al, 60h
    cmp al, SwitchButton
    je @@Switch

    jmp @@Return
    
    @@Switch:
        not cs:FrameSwitcher

        cmp cs:FrameSwitcher, 00h
        je @@DrawBufferBack
        
        mov ax, videoseg
        mov ds, ax
        xor si, si

        mov ax, buffer_seg
        mov es, ax
        xor di, di

        mov cx, buffer_size
        call WriteBuffer
        jmp @@Return

        @@DrawBufferBack:
            mov ax, videoseg
            mov es, ax
            xor di, di

            mov ax, buffer_seg
            mov ds, ax
            xor si, si

            mov cx, buffer_size
            call WriteBuffer
            jmp @@Return


    @@Return:
        ; K-BRD Acepted 
        mov ah, al
        or al, 80h
        out 61h, al
        mov al, ah
        out 61h, al
        
        ; EOI
        mov al, 20h
        out 20h, al
        
        pop ds es di si dx cx bx ax

                    db 0EAh             ; long jump to...
        OldInt09    dd 0                ; old 09 int. (zeros fill be filled later)
endp

;-------------------------------------------------------------------------
; NewInt08_Evil
; custom 08 interrupt which drows frame 
;
; Destroys: All registers were pushed
;-------------------------------------------------------------------------

NewInt08_Evil proc
    push ax bx cx dx si di es ds 
    
    cmp cs:FrameSwitcher, 0h
    je  @@Return

    call DrawBox

    @@Return: 
        pop ds es di si dx cx bx ax

                    db 0EAh             ; long jump to...
        OldInt08    dd 0                ; old 08 int. (zeros fill be filled later)
endp NewInt08_Evil
;-------------------------------------------------------------------------
; DrawBox
; drows a frame with registers values in it
;
; Destroys: None
;-------------------------------------------------------------------------
DrawBox proc
    push es ds di si dx cx bx ax 
    mov ax, cs
    mov ds, ax

    mov si, offset header_symbols                   ; loads data addres to si 
    mov ah, bg_color                                ; loads color
    mov bx, videoseg                                ; loads videoseg addr
    mov es, bx                                      ; loads videoseg addr
    mov cx, box_len                                 ; loads box len
    mov di, (start_x + start_y * window_len) * 2    ; sets correct position

    call DrawLine                                   ; calls function to draw header line

    xor bx, bx                                      ; sets bx to 0
    
    @@zaloop:
        NewLineForBox di                            ; new line 
        inc bx                                      ; increment cycle counter
        mov cx, box_len                             ; loads box len to compare later
        mov si, offset middle_symbols               ; loads pointer to next array (middle-lines array)

        call DrawLine                               ; calls function to draw middle-lines
        
        cmp bx, box_height                          ; compare cycle counter and length of box
    jbe @@zaloop

    NewLineForBox di                                ; another new line 

    mov cx, box_len                                 ; loads box len
    mov si, offset bottom_symbols                   ; loads pointer to array with footer line

    call DrawLine                                   ; calls function to draw footer line 

    mov cx, num_of_regs
    mov di, (start_x + text_x_shift + (start_y + text_y_shift) * window_len) * 2
    mov bx, offset Names_reg

    @@draw_regs:
        mov si, offset Bufer_reg
        
        mov ax, ds
        mov es, ax

        mov ax, di
        mov di, si
        mov dx, bx

        pop bx
        call itoa_16
        
        mov bx, dx
        mov si, di
        mov di, ax

        mov ax, videoseg
        mov es, ax
        
        mov ah, bg_color

        call WriteReg
        
        NewLineForRegister di
        NewLineForRegister di
        add di, 2 * text_x_shift

    loop @@draw_regs

    ret
DrawBox endp

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
    rep stosw               ; repeats while cx not zero
                            ; puts ax (ah -- (color), al -- (symb)) to videoram and increses di by 2 

    lodsb                   ; puts third symbol to a-low and increses si by 1
    stosw                   ; puts ax (ah -- (color), al -- (symb)) to videoram and increses di by 2

    @@stopLine:           
        ret
DrawLine    endp

;------------------------------------------------------------------------
; WriteReg
;
; Writes register name and its value inside box
;
; Entry:    AH -- color of a line
;           BX -- addr of array containg register name str. repr.
;           SI -- addr of array containing register value
;           DI -- addres of a start of a line
; Note:  ES -- videoseg addr (0b800h)
; Exit:  None
; Destr: AX
;------------------------------------------------------------------------
WriteReg    proc
    push cx

    mov cx, si
    mov si, bx
    jmp @@start_name_cycle

    @@write_name:
        stosw
        @@start_name_cycle:
        lodsb
        cmp al, 0
    jne @@write_name
    
    mov bx, si  ; for next iteration

    mov si, cx
    jmp @@start_value_cycle

    @@write_value:
        stosw
    @@start_value_cycle:
        lodsb
        cmp al, 0
    jne @@write_value

    pop cx
    ret
WriteReg    endp

;-------------------------------------------------------------------------
; DATA BLOCK
;-------------------------------------------------------------------------
.data
FrameSwitcher   db   0h

header_symbols  db  "ÉÍ»"
middle_symbols  db  "º º"
bottom_symbols  db  "ÈÍ¼"

Names_reg       db  "AX: ", 0, "BX: ", 0, "CX: ", 0, "DX: ", 0, "SI: ", 0, "DI: ", 0, "DS: ", 0, "ES: ", 0
Bufer_reg       db  4 dup ('0'), 0

ResidentEnd:
end start