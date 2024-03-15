
.model tiny
.386
.code
org 100h
locals @@

BUFFER_SIZE equ 85
PASSWORD    equ 026Ch

SYMBOLS_IN_ONE_LINE_COUNT equ 00A0h
CMD_STR_BEGINING          equ 0082h

BORDER_WIDTH            equ 001Ah
BORDER_HEIGHT           equ 000Ch
INTRO_BORDER_COLOR      equ 1Ah

PASSED_BORDER_COLOR     equ 2Ah
NOT_PASSED_BORDER_COLOR equ 4Bh
PASSWORD_SPACE_OFFSET   equ 07BDh
PASSWORD_SPACE_LENGTH   equ 16d

PASSED_STRING_LEN       equ 21d
NOT_PASSED_STRING_LEN   equ 18d
INTRO_STRING_LEN        equ 0016h

BACKSPACE equ 8d
ENTER     equ 13d

.CountLineStart macro
		nop

		push si

		imul di, SYMBOLS_IN_ONE_LINE_COUNT
		mov si, offset BORDER_HORIZONTAL_OFFSET
		add di, [si]

		pop si

		nop
		endm

.CountShadowLineStart macro
		nop

		push si

		imul di, SYMBOLS_IN_ONE_LINE_COUNT
		mov si, offset SHADOW_HORIZONTAL_OFFSET
		add di, [si]

		pop si

		nop
		endm

.ColorBorder	macro
		nop

		mov byte ptr ah, [bp+6] ; border color
		mov byte ptr bh, [bp+6] ; border color
		mov byte ptr ch, [bp+6] ; border color

		nop
		endm

.GetBorder		macro
		nop

		mov byte ptr al, [si]
		inc si
		mov byte ptr bl, [si]
		inc si
		mov byte ptr cl, [si]
		inc si

		nop
		endm

Start:
	push 0B800h
	pop es

	call PrintIntro
	call ReadPassword
	call HashInput
	call CheckPassword

	ret


;-----------------------------------------------
; CheckPassword FUNC
; Entry: dx - PASSWORD
;-----------------------------------------------
PasswordString   db '00000000000000'

CheckPassword proc

		cmp dx, PASSWORD
		jne @@NotPassed

		mov ah, 10011010b			; GREEN HEARTS
		mov al, 3					; GREEN HEARTS
		call FillVideoRAM

		push offset PassedString BORDER_WIDTH BORDER_HEIGHT PASSED_BORDER_COLOR offset BorderStyle
		mov TEXT_LEN, PASSED_STRING_LEN

		call DrawBorder
		add sp, 10

		jmp @@End

		@@NotPassed:

		mov ah, 10011100b			; RED HEARTS
		mov al, 3					; RED HEARTS
		call FillVideoRAM

		push offset NotPassedString BORDER_WIDTH BORDER_HEIGHT NOT_PASSED_BORDER_COLOR offset BorderStyle
		mov TEXT_LEN, NOT_PASSED_STRING_LEN

		call DrawBorder
		add sp, 10

		@@End:

		ret
		endp


;-----------------------------------------------
; ReadPassword FUNC
;-----------------------------------------------
ReadPassword proc
		xor cx,cx

		mov di, PASSWORD_SPACE_OFFSET + 1

		@@Cycle:

		mov ah, 08h
		int 21h

		mov si, offset PasswordString
		add si, cx

		cmp al, BACKSPACE
		jne @@EnterPassword
		sub di, 2
		dec cx
		dec si

		mov byte ptr [si],    00h
		mov byte ptr es:[di], 00h

		jmp @@Cycle
		@@EnterPassword:

		mov byte ptr [si],    al
		mov byte ptr es:[di], 002Ah

		cmp al, ENTER
		je @@CycleEnd

		add di, 2
		inc cx
		jmp @@Cycle
		@@CycleEnd:

		ret
		endp

;-----------------------------------------------
; Hash FUNC
;-----------------------------------------------
HashInput proc

		xor dx, dx
		xor cx, cx
		xor ax, ax

		@@Cycle:

		mov si, offset PasswordString
		add si, cx

		cmp byte ptr [si], 13
		je @@CycleEnd

		mov byte ptr al, [si]
		add dx, ax

		inc cx
		jmp @@Cycle
		@@CycleEnd:

		shr dx, 2
		shl dx, 1

		ret
		endp

;-----------------------------------------------
; PrintIntro FUNC
;-----------------------------------------------
PrintIntro proc

		mov ah, 10011000b			; GRAY HEARTS
		mov al, 3					; GRAY HEARTS
		call FillVideoRAM

		push BORDER_WIDTH BORDER_HEIGHT
		call DrawShadow
		add sp, 4

		push offset IntroString BORDER_WIDTH BORDER_HEIGHT INTRO_BORDER_COLOR offset BorderStyle
		mov TEXT_LEN, INTRO_STRING_LEN

		call DrawBorder
		add sp, 10

		call DrawPasswordSpace

		ret
		endp

;----------------------------------------------
;FillVideoRAM: fills video ram with shit
;Destr: ax, cx, di
;Assumes: es = 0B800h
;Entry:   ax - BACKGROUND SYMB+COLOR
;----------------------------------------------
FillVideoRAM	proc

		cld

		mov di, 0
		mov cx, 80 * 60

		rep stosw

		ret
		endp

;------------------------------------
; Draws Password Space
;------------------------------------
DrawPasswordSpace	proc

		mov di, PASSWORD_SPACE_OFFSET
		mov cx, PASSWORD_SPACE_LENGTH

		@@Cycle:

		cmp cx, 0

		je @@CycleEnd

		mov es:[di], 70h

		add di, 2
		dec cx
		jmp @@Cycle

		@@CycleEnd:

		endp
		ret

;------------------------------------
; DrawsBorder in the centre of screen
; Entry: none; Assumes: ES = 0b800h
; Destr:   ax, bx, cx, dx, di, si
;------------------------------------
DrawBorder	proc
		push bp
		mov bp, sp

		dec [bp+8]

		.ColorBorder
		mov si, [bp+4]
		.GetBorder

		push si									; PUSH SI
		mov si, offset BORDER_VERTICAL_OFFSET
		mov di, [si]							; line num
		pop si									; POP SI

		push di									; PUSH DI
		.CountLineStart

		push [bp+10]							; border height
		call DrawLine
		add sp, 2

		pop di									; POP DI

		.GetBorder

		@@Cycle:
		inc di
		dec [bp+8]

		cmp [bp+8], 0h
		je @@CycleEnd

		push di
		.CountLineStart

		push [bp+10]							; border height
		call DrawLine
		add sp, 2
		pop di

		jmp @@Cycle

		@@CycleEnd:

		.GetBorder
		push di
		.CountLineStart

		push [bp+10]							; border height
		call DrawLine
		add sp, 2
		pop di

		push di
		mov si, offset TEXT_VERTICAL_OFFSET
		mov di, [si]

		.CountLineStart

		mov si, offset TEXT_HORIZONTAL_OFFSET
		add di, [si]

		mov si, [bp+12]
		call DrawText

		pop di
		mov si, offset TEXT_VERTICAL_OFFSET
		mov di, [si]

		.CountLineStart

		mov si, offset TEXT_HORIZONTAL_OFFSET
		add di, [si]

		mov si, [bp+12]

		pop bp
		ret
		endp

;---------------------------------
; DrawPasswordSpace FUNC
;---------------------------------
DrawLine	proc
		push bp
		mov bp, sp

		mov ES:[di], ax
		add di, 2

		mov dx, 0h
		@@Cycle:
			cmp dx, [bp+4]
			je @@CycleEnd

			mov ES:[di], bx

			add di, 2

			inc dx
			jmp @@Cycle
		@@CycleEnd:

		mov ES:[di], cx
		add di, 2

		pop bp
		ret
		endp

STYLE_ARRAY:
BorderStyle db 201, 205, 187, 186, ' ', 186, 200, 205, 188

;---------------------------------
;DrawText: Draws Text in some place
;Assumes: ES = 06800h
;Entry: di - where to copy, si - copying source
;Destr: si, di, ax, cx
;---------------------------------

DrawText	proc

		cld

		; Making sure we writing letters
		mov ax, di
		and ax, 1
		add di, ax

		mov cx, TEXT_LEN

		@@Cycle:

		cmp cx, 0
		je @@CycleEnd

		movsb
		inc di

		dec cx
		jmp @@Cycle

		@@CycleEnd:

		ret
		endp

;---------------------------------
;Draws Shadow in some place
;Assumes: ES = 06800h
;Entry: none
;Destr: ax, dx, di
;---------------------------------

DrawShadow	proc

		push bp
		mov bp, sp

		dec [bp+4]

		push si
		mov si, offset SHADOW_VERTICAL_OFFSET
		mov di, [si]
		pop si

		push di								; PUSH DI
		.CountShadowLineStart

		push [bp+6]							; border width
		call DrawShadowLine
		add sp, 2

		pop di								; POP DI

		@@Cycle:
		inc di
		dec [bp+4]							; border height

		cmp [bp+4], 0h
		je @@CycleEnd

		push di
		.CountShadowLineStart

		push [bp+6]							; border width
		call DrawShadowLine
		add sp, 2

		pop di

		jmp @@Cycle

		@@CycleEnd:

		push di
		.CountShadowLineStart

		push [bp+6]							; border height
		call DrawShadowLine
		add sp, 2

		pop di

		pop bp
		ret

		endp

BORDER_HORIZONTAL_OFFSET  dw 0030h
BORDER_VERTICAL_OFFSET    dw 0006h
SHADOW_HORIZONTAL_OFFSET  dw 0034h
SHADOW_VERTICAL_OFFSET    dw 0007h
TEXT_HORIZONTAL_OFFSET    dw 0008h
TEXT_VERTICAL_OFFSET      dw 000Ah
TEXT_LEN                  dw 0000h

;---------------------------------
;DrawShadowLine : Draws Line of Shadow in some place
;Assumes: ES = 06800h
;Entry: di - where to draw shadow, [bp+4] - border length
;Destr: ax, dx, di
;---------------------------------
DrawShadowLine	proc

		push bp
		mov bp, sp

		add [bp+4], 2

		xor dx, dx

		; Making sure we painting background
		mov ax, di
		and ax, 1
		cmp ax, 1

		je @@Cycle
		inc di

		@@Cycle:
			cmp dx, [bp+4]
			je @@CycleEnd

			and byte ptr ES:[di], 10000111b

			add di, 2

			inc dx
			jmp @@Cycle
		@@CycleEnd:

		pop bp
		ret

		endp

IntroString	db 'For Pidor Hacker Rusal'

PassedString    db 'Ah ti pidor! Vzlomal!$' ;21
NotPassedString db 'Loh, Daun. Otmena.$'    ; 18
end Start
