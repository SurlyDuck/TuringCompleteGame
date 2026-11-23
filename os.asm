; NR--RETURN--ARG0--ARG1--ARG2--ARG3--ARG4--ARG5
; R1--R1------R2----R3----R4----R5----R6----R7

; NR----NAME---------ARG0--ARG1---ARG2--ARG3--ARG4--ARG5
; 0x00--HALT---------****--****---****--****--****--****
; 0x01--GETC---------BUFR--BLCK---****--****--****--****
; 0x02--GETS---------BUFR--BYTES--TERM--****--****--****
; 0x03--PUTC---------SCRP--CHAR---****--****--****--****
; 0x04--PUTS---------STRP--TERM---SCRP--BASE--****--****
; 0x05--DISPLAY------SETT--VALUE--****--****--****--****

const HALT    = 0x00
const GETC    = 0x01
const PUTC    = 0x03
const PUTS    = 0x04
const DISPLAY = 0x05

const nr     = r1
const return = r1
const arg0   = r2
const arg1   = r3
const arg2   = r4
const arg3   = r5
const arg4   = r6
const arg5   = r7


; --------------- VECTORS ---------------
; 0x00000000 - user space
jmp orig 

; 0x00000004
__syscall:
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	
	; --------------- SYSCALL CALLING ROUTINES ---------------
	cmp nr, DISPLAY
	je sys_display
	cmp nr, GETC
	je sys_getc
	cmp nr, PUTS
	je sys_puts
	cmp nr, PUTC
	je sys_putc
	
	jmp sys_invalid
	
	sys_display:
		call __SYSCALL_display
		jmp end
	sys_getc:
		call __SYSCALL_getc
		jmp end
	sys_puts:
		call __SYSCALL_puts
		jmp end
	sys_putc:
		call __SYSCALL_putc
		jmp end
	sys_invalid:
		call __SYSCALL_halt
		jmp end
	
	end:
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	
	ret

__SYSCALL_getc:
	; NR----NAME---------ARG0--ARG1---ARG2--ARG3--ARG4--ARG5
	; 0x01--GETC---------BUFR--BLCK---****--****--****--****
	; Get one character from the keyboard device and store it at BUFR.
	; Ignores `up event` key
	; BUFR   - Address in memory to store the character
	; BLCK   - 0x00 for blocking polling, 0x01 for one reading
	; Return - 0x00 for success, 0x01 for when theres nothing to read
	cmp arg1, 0x1
	jae __SYSCAL_GETC_BLOCK_LOOP
	
	__SYSCAL_GETC_NONBLOCK_LOOP:
		keyboard r13
		; Ignoring up event keys
		lsr r12, r13, 8
		cmp r12, 0
		je __SYSCAL_GETC_NONBLOCK_LOOP
		
		store_8 [arg0], r13
		cmp r13, 0
		je __SYSCALL_GETC_RET_FAILURE
		jmp __SYSCALL__GETC_RET_SUCESS
		
	__SYSCAL_GETC_BLOCK_LOOP:
		keyboard r13
		cmp r13, 0x00
		je __SYSCAL_GETC_BLOCK_LOOP
		
		; Ignoring up event keys
		lsr r12, r13, 8
		cmp r12, 0
		je __SYSCAL_GETC_BLOCK_LOOP
		
		store_8 [arg0], r13
		cmp r13, 0
		je __SYSCALL_GETC_RET_FAILURE
		jmp __SYSCALL__GETC_RET_SUCESS
		
		
	__SYSCALL__GETC_RET_SUCESS:
		mov return, 0x00
		ret
		
	__SYSCALL_GETC_RET_FAILURE:
		mov return, 0x01
		ret
	

__SYSCALL_gets:

__SYSCALL_putc:
	; 0x03--PUTC---------STRP--CHAR---****--****--****--****
	; Copy one character to STRP
	; SCRP   - Screen pointer, char destination
	; CHAR   - character to be copied to SCRP
	; Return - 0x00 on success, 0x01 on error
	store_8 [arg0], arg1
	mov return, 0x00
	ret

__SYSCALL_puts:
	; 0x04--PUTS---------STRP--TERM---SCRP--BASE--****--****
	; Copy a string of characters pointed by STRP to SCRP.
	; Supports some escape codes, but expects a 96x40 character screen
	; STRP   - String pointer
	; TERM   - Character indicating end of string
	; SCRP   - Screen pointer, destination of the string
	; BASE   - Optional screen pointer base. For handling escape codes
	; Return - Amount of characters written to SCRP
	and r12, r12, 0x00 ; Characters written count
	__SYSCALL_puts_loop:
		load_8 r13, [arg0]
		cmp r13, arg1
		je __SYSCALL_puts_end
		
		cmp r13, 0x0A
		je __SYSCALL_puts_linefeed
		
		add r12, r12, 0x1
		
		store_8 [arg2], r13
		;cmp r12, arg1          ;This syscall used to accept predefined size strings
		;jae __SYSCALL_puts_end
		
		add arg2, arg2, 0x01
		add arg0, arg0, 0x01
		jmp __SYSCALL_puts_loop
	
	; ---- ESCAPE CODES ----
	__SYSCALL_puts_linefeed:
		mov r10, arg2
		sub r10, r10, arg3
		mod r10, r10, 96
		mov r9, 96
		sub r9, r9, r10
		add arg2, arg2, r9
		add r12, r12, r9
	
		add arg0, arg0, 0x01
		jmp __SYSCALL_puts_loop
		
	
	__SYSCALL_puts_end:
		mov return, r12
		ret
		
__SYSCALL_display:
	; NR----NAME---------ARG0--ARG1---ARG2--ARG3--ARG4--ARG5
	; 0x05--DISPLAY------SETT--VALUE--****--****--****--****
	; Change value of screen setting
	; SETT   - Screen setting to be changed
	; VALUE  - New value for the screen setting
	; Return - 0x00 for success, 0x01 for failure
	screen arg0, arg1
	mov return, 0x00
	ret
	
__SYSCALL_halt:
	; NR----NAME---------ARG0--ARG1---ARG2--ARG3--ARG4--ARG5
	; 0x00--HALT---------****--****---****--****--****--****
	; Just halts execution.
	nop
	nop
	jmp __SYSCALL_halt

; Devices parameters
const DISPLAY_MODE         = 0x00
const DISPLAY_OFFSET       = 0x01
const DISPLAY_FOREGROUND   = 0x02
const DISPLAY_BACKGROUND   = 0x03
const DISPLAY_FONT         = 0x02
const DISPLAY_ASCII_8      = 0x00
const DISPLAY_ASCII_32     = 0x01
const DISPLAY_PIXEL_8      = 0x02
const DISPLAY_PIXEL_32     = 0x03

; Reads two decimal numbers and output its sum
; Using Q16.16

; Made this program for testing the `OS` I'm writing
; Code is really bad, just tried to build a thing and 
; didn't give much thought.
; The kernel code above will be moved to a different file
orig:
	mov nr, DISPLAY
	mov arg0, DISPLAY_MODE
	mov arg1, DISPLAY_ASCII_8
	syscall
	
	mov nr, DISPLAY
	mov arg0, DISPLAY_OFFSET
	mov arg1, screen_data
	syscall
	
	const screen_ptr = r13
	mov screen_ptr, screen_data
begin:
	; 0x04--PUTS---------STRP--TERM---SCRP--BASE--****--****
	mov nr, PUTS
	mov arg0, msg_0
	mov arg1, 0x00
	mov arg2, screen_ptr
	mov arg3, screen_data
	syscall
	add screen_ptr, screen_ptr, r1
	
	const STATE                 = r4
	const BREAK_CHAR            = r5
	const STATE_READING_INT_ONE = 1
	const STATE_READING_DEC_ONE = 2
	const STATE_READING_INT_TWO = 3
	const STATE_READING_DEC_TWO = 4
	const STATE_PRINTING_RESULT = 4
	const DECIMAL_PLACES        = 10
	
	const misc3                 = r6
	const misc                  = r7
	const misc2                 = r8
	const i                     = r9
	
	const number_one            = r10
	const number_two            = r11
	
	mov r2, number_integer
	mov BREAK_CHAR, 0x2E
	mov STATE, STATE_READING_INT_ONE
	
	read_loop:
		; 0x01--GETC---------BUFR--BLCK---****--****--****--****
		mov nr, GETC
		mov arg0, r2
		mov arg1, 0x01
		syscall
		
		load_8 r3, [r2]
		store_8 [screen_ptr], r3
		
		push r2 ; save pointer, bit of a hack
		; 0x03--PUTC---------SCRP--CHAR---****--****--****--****
		mov nr, PUTC
		mov arg0, screen_ptr
		mov arg1, r3
		syscall
		pop r2 ; retrieve pointer
		
		add screen_ptr, screen_ptr, 1
		
		cmp r3, BREAK_CHAR
		je next_state
		
		add r2, r2, 1
		jmp read_loop
		
	print_int_loop_start:
		lsr misc, number_one, 16
		mov r2, number_integer
		store_32 [r2], zr
	print_int_loop_convert:
		mod misc2, misc, 10
		add misc2, misc2, 0x30
		
		store_8 [r2], misc2
		add r2, r2, 1
		
		div misc, misc, 10
		
		cmp misc, 0
		jne print_int_loop_convert
	print_int_loop:
		sub r2, r2, 1
		
		load_8 r3, [r2]
		push r2 ; save pointer, bit of a hack
		mov nr, PUTC
		mov arg0, screen_ptr
		mov arg1, r3
		syscall
		pop r2 ; retrieve pointer
		add screen_ptr, screen_ptr, 1
		
		mov misc2, number_integer
		cmp r2, misc2
		jne print_int_loop
		
	print_dec_start:
		mov nr, PUTC
		mov arg0, screen_ptr
		mov arg1, 0x2E
		syscall
		add screen_ptr, screen_ptr, 1
	
		; We're going to work with the decimal part now
		and number_one, number_one, 0x0000FFFF 
		mov i, 0
	print_dec_convert_loop:
		mul misc, number_one, 10
		mov misc2, mul_conversion
		load_32 misc2, [misc2]
		div misc2, misc, misc2
		add misc2, misc2, 0x30
		
		push r2 ; save pointer, bit of a hack
		; 0x03--PUTC---------SCRP--CHAR---****--****--****--****
		mov nr, PUTC
		mov arg0, screen_ptr
		mov arg1, misc2
		syscall
		pop r2 ; retrieve pointer
		
		add screen_ptr, screen_ptr, 1
		
		mov number_one, misc
		mov misc, mul_conversion
		load_32 misc, [misc]
		mod number_one, number_one, misc
		
		cmp i, DECIMAL_PLACES
		add i, i, 1
		jb print_dec_convert_loop
		
		; 0x04--PUTS---------STRP--TERM---SCRP--BASE--****--****
		mov nr, PUTS
		mov arg0, msg_3
		mov arg1, 0x00
		mov arg2, screen_ptr
		mov arg3, screen_data
		syscall
		add screen_ptr, screen_ptr, r1
		
		mov misc, number_integer
		store_32 [misc], zr
		mov misc, number_decimal
		store_32 [misc], zr
		mov r1, zr
		mov r2, zr
		mov r4, zr
		mov r5, zr
		mov r6, zr
		mov r7, zr
		mov r8, zr
		mov r9, zr
		mov r10, zr
		mov r11, zr
		mov r12, zr
		
		jmp begin
		
	next_state:
		cmp STATE, STATE_READING_INT_ONE
		je convert_int_one
		cmp STATE, STATE_READING_DEC_ONE
		je convert_dec_one
		cmp STATE, STATE_READING_INT_TWO
		je convert_int_two
		cmp STATE, STATE_READING_DEC_TWO
		je convert_dec_two
		
		convert_dec_two: mov misc, 1
		convert_dec_two_loop:
			sub r2, r2, 1
			load_8 misc2, [r2]
			sub misc2, misc2, 0x30
			mul misc2, misc2, misc
			add number_two, number_two, misc2
			
			mov misc2, number_decimal
			cmp r2, misc2
			je convert_dec_two_end
			mul misc, misc, 10
			jmp convert_dec_two_loop
			
			convert_dec_two_end: 
				mul misc, misc, 10
				mov misc2, 0
				mov r2, 0 ; Will be used for counting decimal places
			convert_dec_two_end_loop:
				add r2, r2, 1
				lsl number_two, number_two, 1
				cmp number_two, misc
				jae convert_dec_two_end_loop_add_1
				
				convert_dec_two_end_loop_add_0:
					lsl misc2, misc2, 1
					jmp convert_dec_two_end_loop_check
				
				convert_dec_two_end_loop_add_1:
					lsl misc2, misc2, 1
					or misc2, misc2, 1
					sub number_two, number_two, misc
				
				convert_dec_two_end_loop_check:
					cmp r2, 16
					jne convert_dec_two_end_loop
					add number_one, number_one, misc2
					
					mov nr, PUTS
					mov arg0, msg_2
					mov arg1, 0x00
					mov arg2, screen_ptr
					mov arg3, screen_data
					syscall
					add screen_ptr, screen_ptr, r1
					
					mov STATE, STATE_PRINTING_RESULT ;not needed
					jmp print_int_loop_start
						
					
		
		convert_int_two: mov misc, 1
		convert_int_two_loop:
			sub r2, r2, 1
			load_8 misc2, [r2]
			sub misc2, misc2, 0x30
			mul misc2, misc2, misc
			add number_two, number_two, misc2
			
			mov misc2, number_integer
			cmp r2, misc2
			je convert_int_two_end
			mul misc, misc, 10
			jmp convert_int_two_loop
			
			convert_int_two_end:
				; We can just add the integer part straight away to the first number
				mov misc, mul_conversion
				load_32 misc, [misc]
				mul number_two, misc, number_two
				add number_one, number_one, number_two
				mov STATE, STATE_READING_DEC_TWO
				mov r2, number_decimal
				mov BREAK_CHAR, 0x0A
				mov number_two, 0
				jmp read_loop
		
		convert_dec_one: mov misc, 1
		convert_dec_one_loop:
			sub r2, r2, 1
			load_8 misc2, [r2]
			sub misc2, misc2, 0x30
			mul misc2, misc2, misc
			add number_two, number_two, misc2 ; Using number two temporally only,
										      ; Don't forget two clear it
			mov misc2, number_decimal
			cmp r2, misc2
			je convert_dec_one_end
			mul misc, misc, 10
			jmp convert_dec_one_loop
			convert_dec_one_end: 
				mul misc, misc, 10
				mov r2, 0 ; Will be using to count decimal places
			convert_dec_one_end_loop:
				add r2, r2, 1
				lsl number_two, number_two, 1
				cmp number_two, misc
				jae add_one_bit_to_dec
				lsl misc3, misc3, 1
				jmp check_end_dec_one_loop
				
				add_one_bit_to_dec: 
					lsl misc3, misc3, 1
					or misc3, misc3, 1
					sub number_two, number_two, misc
				
				check_end_dec_one_loop: 
					cmp r2, 16
					jne convert_dec_one_end_loop
					or number_one, number_one, misc3
					and number_two, number_two, 0
					
					mov nr, PUTS
					mov arg0, msg_1
					mov arg1, 0x00
					mov arg2, screen_ptr
					mov arg3, screen_data
					syscall
					add screen_ptr, screen_ptr, r1
					
					mov misc, number_integer
					store_32 [misc], zr
					mov misc, number_decimal
					store_32 [misc], zr
					
					mov r2, number_integer
					mov BREAK_CHAR, 0x2E
					mov STATE, STATE_READING_INT_TWO
					jmp read_loop
					
					
		
		convert_int_one: mov misc, 1
		convert_int_one_loop:
			sub r2, r2, 1
			load_8 misc2, [r2]
			sub misc2, misc2, 0x30
			mul misc2, misc2, misc
			add number_one, number_one, misc2
			
			mov misc2, number_integer
			cmp r2, misc2
			je convert_int_one_end
			mul misc, misc, 10
			jmp convert_int_one_loop
			convert_int_one_end:
				mov misc, mul_conversion
				load_32 misc, [misc]
				mul number_one, number_one, misc
				mov STATE, STATE_READING_DEC_ONE
				mov BREAK_CHAR, 0x0A
				mov r2, number_decimal
				jmp read_loop
			
	
	mov nr, HALT
	syscall

number_integer:
U64 0x30

number_decimal:
U64 0x30

mul_conversion:
	U32 65536 ; 2^16. Multiply by it to convert to fixed point Q16.16

msg_0:
	"First number: "
	U8 0x00
msg_1:
	"\nSecond number: "
	U8 0x00
msg_2:
	"\nYour result is: "
	U8 0x00
msg_3:
	"\n---------------------------------\n"
	U8 0x00


screen_data:
U30720 0
