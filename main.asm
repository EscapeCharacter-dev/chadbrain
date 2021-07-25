[BITS	16]
[ORG	0x7C00]

lowMemAddr:		equ 0
inputBuf:		equ 0
stackLow:		equ 0
inputBufLength:	equ 0xFFFF
highMemAddr:	equ 0xFFFF
stackHigh:		equ 0xFFFF
memAddrLength:	equ highMemAddr - lowMemAddr - 1

index:
	DW	0

_start:
	; clearing screen
	XOR	AH, AH
	MOV	AL, 0x03
	INT	0x10

	IN	AL, 0x92	; a20 line
	OR	AL, 2		; a20 line
	OUT	0x92, AL	; a20 line
	; set ES to 0xFFFF
	MOV	BX, 0x1300
	MOV	ES, BX		; cell segment
	MOV	BX, 0x1600
	MOV	GS, BX		; input buffer segment
	MOV	BX, 0x1900
	MOV	SS, BX		; stack segment
	MOV	SP, stackHigh	; stack top
.reset:
	MOV WORD [inputBufUsed], 0
	MOV	AH, 0x0E
	XOR	BH, BH
	MOV	BL, 0x07
	MOV	AL, 0x0A	; newline
	INT 0x10
	MOV	AL, 0x0D	; return carriage
	INT	0x10
	MOV	AL, 'O'		; O
	INT 0x10
	MOV	AL, 'k'
	INT 0x10
	MOV	AL, '>'		; >
	INT 0x10
	MOV AL, ' '		; (whitespace)
	INT 0x10
	XOR CX, CX
.loop:
	XOR AH, AH
	INT 0x16
	CMP AL, 0x0D	; newline
	JE	.continue
	CMP	AL, 0x08	; backspace
	JE	.delete
	CMP CX, inputBufLength
	JE	.continue
	INC CX
	MOV BX, CX
	ADD BX, inputBuf
	MOV [GS:BX], AL
	
	MOV	AH, 0x0E
	XOR BH, BH
	MOV	BL, 0x07
	INT	0x10
	JMP .loop
.delete:
	CMP CX, 0
	PUSH CX
	JE	.loop
	; getting current character position
	MOV	AH, 0x03
	XOR	BH, BH
	INT	0x10
	DEC	DL
	; setting character position
	MOV	AH, 0x02
	INT 0x10
	
	; displaying
	MOV	AH, 0x0E
	XOR	BH, BH
	MOV	BL, 0x07
	MOV	AL, ' '
	INT 0x10
	
	; going back again
	MOV	AH, 0x02
	INT 0x10

	POP CX
	DEC	CX	
	JMP	.loop
.continue:
	MOV	AH, 0x0E
	XOR	BH, BH
	MOV	BL, 0x07
	MOV	AL, 0x0A	; newline
	INT 0x10
	MOV	AL, 0x0D	; return carriage
	INT	0x10
	
	; here we do code execution
	INC CX
	MOV [inputBufUsed], CX
	XOR	CX, CX
.execl:
	; out of bounds checking
	CMP	CX, [inputBufUsed]
	JGE	.reset
	
	MOV	AH, 1
	INT 0x16
	JZ	.skipesc
	MOV BH, AH
	MOV AH, 0
	INT 0x16
	MOV AH, BH
	CMP	AH, 1
	JE	.reset
.skipesc:
	
	; fetching character
	LEA BX, inputBuf
	ADD	BX, CX
	MOV	AL, [GS:BX]
	
	CMP	AL, '+'
	JE	.incr
	CMP	AL, '-'
	JE	.decr
	CMP	AL, '>'
	JE	.incp
	CMP	AL, '<'
	JE	.decp
	CMP	AL, '.'
	JE	.disp
	CMP	AL, ','
	JE	.read
	CMP	AL, '['
	JE	.bjne
	CMP	AL, ']'
	JE	.bje
	CMP	AL, '^'
	JE	.max
		
.execle:
	INC	CX
	JMP	.execl
	
.incr:
	LEA	BX, lowMemAddr
	ADD	BX, [index]
	MOV DL, [ES:BX]
	INC DL
	MOV	[ES:BX], DL
	JMP	.execle

.decr:
	LEA BX, lowMemAddr
	ADD BX, [index]
	MOV	DL, [ES:BX]
	DEC DL
	MOV [ES:BX], DL
	JMP	.execle

.incp:
	CMP	WORD [index], memAddrLength
	JE	.execle
	INC	WORD [index]
	JMP	.execle

.decp:
	CMP WORD [index], 0
	JE	.execle
	DEC WORD [index]
	JMP	.execle

.disp:
	LEA	BX, lowMemAddr
	ADD BX, [index]
	MOV	AL, [ES:BX]
	MOV	AH, 0x0E
	XOR BH, BH
	MOV	BL, 0x07
	INT	0x10
	JMP	.execle

.read:
	LEA	BX, lowMemAddr
	ADD BX, [index]
	MOV	AH, 0x00
	INT	0x16
	MOV	[ES:BX], AL
	JMP	.execle

.bjne:
	LEA	BX, lowMemAddr
	ADD BX, [index]
	MOV	DL, [ES:BX]
	CMP	DL, 0
	JNE	.execle
	; here we go foward
.bjnel:
	LEA BX, inputBuf
	ADD	BX, CX
	MOV	AL, [GS:BX]
	CMP	AL, ']'
	JE	.bjneb
	CMP	CX, inputBufLength
	JE	.execle
	INC	CX
	JMP	.bjnel
.bjneb:
	JMP	.execle
	
.bje:
	LEA	BX, lowMemAddr
	ADD BX, [index]
	MOV	DL, [ES:BX]
	CMP	DL, 0
	JE	.execle	
.bjel:
	LEA BX, inputBuf
	ADD BX, CX
	MOV	AL, [GS:BX]
	CMP	AL, '['
	JE	.bjeb
	CMP	CX, 0
	JE	.execle
	DEC	CX
	JMP	.bjel
.bjeb:
	;INC	CX
	JMP	.execle
	
.max:
	LEA	BX, inputBuf
	ADD BX, [index]
	MOV	BYTE [ES:BX], 0xFF
	JMP .execle
	
inputBufUsed:
	DW	0
TIMES	510 - ($ - $$) DB 0
DW		0xAA55