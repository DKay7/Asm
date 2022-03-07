locals @@
.186

;------------------------------------------------------------------------
; StrLen
;
; Counts the length of the given string
;
; Entry:    SI -- addr of 0-terminated string
;
; Exit:     CX -- length of the string without 0-symbol
;
; Destr:    CX
;------------------------------------------------------------------------
StrLen    proc

    push ax si bp
    mov bp, sp
    
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

        pop bp si ax
        ret
StrLen    endp

;------------------------------------------------------------------------

;------------------------------------------------------------------------
; StrChr
;
; Findes the position of given char in given string
;
; Entry:    SI -- addr of 0-terminated string
;           BL -- char to find
;
; Exit:     CX -- Position of given char in given string or -1
;
; Destr:    CX
;------------------------------------------------------------------------

StrChr    proc
    push ax bx si bp
    mov bp, sp

    mov bl, [bp + 6]
    mov si, [bp + 2]

    xor cx, cx

    @@zaloop:
        lodsb

        cmp al, bl
        je  @@return

        inc cx
        cmp al, 0
    jne @@zaloop

    ; if char isnt found and loop is over:
    mov cx, -1
    jmp @@return

    ; if char is found
    @@return:
        pop bp si ax
        ret

StrChr    endp

;------------------------------------------------------------------------

;------------------------------------------------------------------------
; StrNCpy
;
; copies the first n chars of the first string to aother place 
;
; Entry:    SI -- addr of 0-terminated string
;           DI -- new addres to copy string
;           CX -- num chars to copy
;
; Exit:     None     
;
; Destr:    None
;------------------------------------------------------------------------

StrNCpy    proc
    push bx cx di si bp
    mov bp, sp

    mov cx, [bp + 8]
    mov di, [bp + 6]
    mov si, [bp + 4]

    @@zaloop:
        movsb                   ; [di] -> [si], inc si, inc di 
        mov bl, ds:[di]
        cmp bl, 0               ; checks 0-terminating symbol
        je @@string_was_ended 
    loop @@zaloop

    @@string_was_ended:
        mov bl, 0
        mov ds:[di], bl

        pop bp si di cx bx
        ret

StrNCpy    endp

;------------------------------------------------------------------------

;------------------------------------------------------------------------
; StrNCmp
;
; compares the first n chars of the given strins
;
; Entry:    SI -- addr of first 0-terminated string
;           DI -- addr of second 0-terminated string
;           CX -- num chars to compare
;
; Exit:     in ax: 0 if str1 == str2, less 0 if str1 < str2 or more 0 if str1 > str2     
;
; Destr:    AX
;------------------------------------------------------------------------

StrNCmp    proc
    push bx cx di si bp
    mov bp, sp

    mov cx, [bp + 6]
    mov di, [bp + 4]
    mov si, [bp + 2]

    @@zaloop:
        mov al, [si]         
        mov bl, [di]


        sub ax, bx
        inc si
        inc di

        cmp ax, 0
        jne @@not_equals_chars

        cmp bx, 0
        je @@strings_are_ended
    loop @@zaloop
    
    ; if loop is ended, but all chars are the same
    @@strings_are_ended:
        mov ax, 0
    
    @@not_equals_chars:
        pop bp si di cx bx
        ret 

StrNCmp    endp

;------------------------------------------------------------------------


;------------------------------------------------------------------------
; itoa_16
;
; converts 16-based integer number to str
;
; Entry:    BX -- number to be converted
;           DI -- addr to put string
;
; Exit:     None
;
; Destr:    None
;------------------------------------------------------------------------

itoa_16      proc
    push ax bx cx di si bp

    ; skip leading zeros
    mov cx, 4d

    @@convert_num_to_str:
        mov si, offset str_for_16
        mov ax, bx
        shr ax, 12d
        add si, ax
        mov ax, [si]
        stosb
        shl bx, 4d
    loop @@convert_num_to_str

    xor ax, ax
    stosb

    pop bp si di cx bx ax
    ret
itoa_16    endp

;------------------------------------------------------------------------
; itoa_10
;
; converts 10-based integer number to str
;
; Entry:    BX -- number to be converted
;           DI -- addr to put string
;
; Exit:     None     
;
; Destr:    None
;------------------------------------------------------------------------

itoa_10    proc
    push ax bx cx dx di si bp
    mov bp, sp
    
    mov di, [bp + 4]
    mov bx, [bp + 10]

    ; count len of the number
    mov ax, bx
    mov dl, 10d

    @@count_len_cycle:
        inc cx
        div dl           ; ax <- ax / 10, dx
        mov ah, 0

        cmp al, 0
    jne @@count_len_cycle

    
    mov si, di
    add si, cx
    mov ah, 0
    mov [si], ah

    mov ax, bx

    @@translate_int_to_str:
        dec cx

        div dl          ; al <- ax / 10, ah <- ah / 10
        
        mov si, di
        add si, cx
        add ah, '0'
        mov [si], ah
        mov ah, 0

        cmp cx, 0
    ja @@translate_int_to_str

    pop bp si di dx cx bx ax
    ret
itoa_10    endp

;------------------------------------------------------------------------
; itoa_8
;
; converts 8-based integer number to str
;
; Entry:    BX -- number to be converted
;           DI -- addr to put string
;
; Exit:     None
;
; Destr:    None
;------------------------------------------------------------------------
itoa_8      proc
    push ax bx cx di bp
    mov bp, sp
    
    mov di, [bp + 2]
    mov bx, [bp + 6]

    mov cx, 6       ; num of digits

    ; skip leading zeros
    mov ax, bx
    shr ax, 15d
    cmp ax, 0
    shl bx, 1
    jne @@no_leading_zeros 

    mov cx, 5       ; if there's no leading 1, than we have no more than 5 digits
    jmp @@check_leading_zero
    
    @@skip_leading_zeros:
        shl bx, 3d
        dec cx
    @@check_leading_zero:
        mov ax, bx
        shr ax, 13d
        cmp ax, 0 
    je @@skip_leading_zeros
    
    @@convert_num_to_str:
        mov ax, bx
        shr ax, 13d
        shl bx, 3
    @@no_leading_zeros:
        add ax, '0'
        stosb
    loop @@convert_num_to_str

    xor ax, ax
    stosb

    pop bp di cx bx ax
    ret
itoa_8    endp

;------------------------------------------------------------------------
; itoa_2
;
; converts 2-based integer number to str
;
; Entry:    BX -- number to be converted
;           DI -- addr to put string
;
; Exit:     None
;
; Destr:    None
;------------------------------------------------------------------------

itoa_2      proc
    push ax bx cx di bp
    mov bp, sp
    
    mov di, [bp + 2]
    mov bx, [bp + 6]

    ; skip leading zeros
    mov cx, 16d
    jmp @@check_leading_zero
    
    @@skip_leading_zeros:
        shl bx, 1
        dec cx
    @@check_leading_zero:
        mov ax, bx
        shr ax, 15 
        cmp ax, 0
    je @@skip_leading_zeros

    @@convert_num_to_str:
        mov ax, bx
        shr ax, 15
        add ax, '0'
        stosb
        shl bx, 1
    loop @@convert_num_to_str

    xor ax, ax
    stosb

    pop bp di cx bx ax
    ret
itoa_2    endp


;------------------------------------------------------------------------
; atoi_10
;
; converts str to 10-based integer
;
; Entry:    SI -- addr of string
;
; Exit:     BX -- result of convertation
;
; Destr:    BX
;------------------------------------------------------------------------
atoi_10  proc
    push ax cx si bp
    mov bp, sp
    
    mov di, [bp + 2]

    xor bx, bx
    mov cx, 10d
    jmp @@start_cycle
    
    @@convert_str_to_num:
        ; mul bx by 10...
        mul cx

        sub bl, '0'
        add al, bl
    @@start_cycle:
        mov bl, [si]
        inc si

        cmp bl, 0
    jne @@convert_str_to_num

    mov bx, ax
    pop bp si cx ax

    ret
atoi_10  endp

;------------------------------------------------------------------------
; atoi_8
;
; converts str to 8-based integer
;
; Entry:    SI -- addr of string
;
; Exit:     BX -- result of convertation
;
; Destr:    BX
;------------------------------------------------------------------------
atoi_8  proc
    push ax si bp
    mov bp, sp
    
    mov si, [bp + 2]

    xor bx, bx
    jmp @@start_cycle
    
    @@convert_str_to_num:
        shl bx, 3           ; this is the only thing different from atoi_2, maybe add macros (cringe)
        sub al, '0'
        add bl, al
    @@start_cycle:
        lodsb
        cmp al, 0
    jne @@convert_str_to_num

    pop bp si ax
    ret
atoi_8  endp

;------------------------------------------------------------------------
; atoi_2
;
; converts str to 2-based integer
;
; Entry:    SI -- addr of string
;
; Exit:     BX -- result of convertation
;
; Destr:    BX
;------------------------------------------------------------------------
atoi_2  proc
    push ax si bp
    mov bp, sp

    mov si, [bp + 2]

    xor bx, bx
    jmp @@start_cycle
    
    @@convert_str_to_num:
        shl bx, 1
        sub al, '0'
        add bl, al
    @@start_cycle:
        lodsb
        cmp al, 0
    jne @@convert_str_to_num

    pop bp si ax
    ret
atoi_2  endp

str_for_16  db "0123456789ABCDEF"
