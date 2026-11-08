mov r1, 1
add r2, zr, screen_data
screen r1, r2

mov r1, 2
mov r2, 0xFF00 ;0xGGBB
screen r1, r2

const screen_data_ptr = r1
const key_input       = r2
const temp            = r3

mov screen_data_ptr, screen_data

loop:
	keyboard key_input
	cmp key_input, 0
	jne write_to_screen
	
	jmp loop

write_to_screen:
	lsr temp, key_input, 8
	cmp temp, 1
	jne loop
	
	store_8 [screen_data_ptr], key_input
	add screen_data_ptr, screen_data_ptr, 1
	
	jmp loop


screen_data:
U8 0x00
U8 0x00
U8 0x00
