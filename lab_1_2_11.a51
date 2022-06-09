; Assembler programm that is used to controll stepper motor by controll system based
; Intel 8051 microcontroller.

org 0000H; Set next command address.
mov 30h, #00001000b; Constant value related to 1-st motor windings, makes the current flow.
mov 31h, #00000100b; Constant value related to 2-d motor windings, makes the current flow.
mov 32h, #00000010b; Constant value related to 3-d motor windings, makes the current flow.
mov 33h, #00000001b; Constant value related to 4-th motor windings, makes the current flow.
ljmp start; Go to start lable (entry point).
; Main entry point.
start:
		mov tmod, #00100001b; Set timer-iterator mode register flags.
		mov tcon, #00000000b; Set timer-iterator control register flags.
		mov scon, #01000000b; Set continues register flags.
		mov pcon, #00000000b; Set power control register flags.
		mov ie, #00000000b; Set interrupt mask register flags.
		mov ip, #00000000b; Set interrupt priority register flags.
		mov th1, #11111110b
		mov r0, #33h; Set the 4-th motor winding as the intitional turned on winding.
; Rotate the motor shaft to the left untill it reaches initial position.
set_init_position:
		mov r1, #01; Number of steps.
		lcall left; Call left, make r1 steps to the left.
		; If INT0 bit is set to 0, then the shaft have reached the initial postion.
		; Check if the 2-d bit (INT0) in port3 is set to 0.
		; If INT0=0, then continue, else go back to set_init_position lable.
		jb p3.2, set_init_position
		; Init UART
		setb ren; Set UART ren bit equal to 1, turn on UART.
		setb tr1; Set tr1 bit equal to 1, turn on timer-iterator.
receive_UART:
		; While receiving data UART ri bit is set to 0.
		; Once it is done receivng data ri UART bit is set to 1.
		jnb ri, receive_UART; loop until the UART is not done receiving data.
		clr ri; set ri to 0.
		; The received data is saved in sbuf.
		mov a, sbuf; Save sbuf into accumulator a, find the number of steps. 
		anl a, #01111111b; Perform logical & (and). Save the number of steps in acummulator.
		; The first bit indicates the direction of rotation: 0 - left, 1 - right.
		; The last 7 bits stores the number to steps (maximum 127 steps).
		mov r1, a; Set the ammount of steps that were stored in the last 7 bits.
		mov a, sbuf
		anl a, #10000000b; Perform logical &, find the rotataion direction, save it in acummulator.
		jz turn_left; If accumulator is equal to 0 (turn left), then jump to turn_left.
		jnz turn_right; If accumulator is equal to 1 (turn right), then jump to turn_right.
turn_left:
		lcall left
		ljmp receive_UART
turn_right:
		lcall right
		ljmp receive_UART
left:
		clr p1.0
		mov p0, @r0
		dec r0 
		mov r3, #2d; 45
ml1:
		mov th0, #100110b
		mov tl0, #11111011b
		setb tr0
ml2:
		jnb tf0, ml2
		clr tr0
		clr tf0
		dec r3
		cjne r3, #0d, ml1
		cjne r0, #2fh, ml3
		mov r0, 33h
ml3:
		djnz r1, left
		setb p1.0
		ret
right:
		clr p1.0 
		mov p0, @r0
		inc r0
		mov r3, #2d
mr1:
		mov th0, #100110b
		mov tl0, #11111011b
		setb tr0
mr2:
		jnb tf0, mr2
		clr tr0
		clr tf0
		dec r3
		cjne r3, #0d, mr1
		cjne r0, #34h, mr3
		mov r0, 30h
mr3:
		djnz r1, right
		setb p1.0
		ret
end
;left:
	;setb p3.0
	;mov p1, @r0 ; before change mov p1, @r0
	;dec r0; Switch to the next motor winding.
	;mov th0, #0100110b; Init T/C0 TH0=100110B (This value should be calculated).
	;mov tl0, #11111011b; Init T/C0 TL0=11111011B (This value should be calculated).
	;setb tr0; Turn on the timer.
;m1:
	;jnb tf0, m1; Loop until the timer finishes its work, tf0=1.
	;clr tf0
	;cjne r0, #2fh, m2; If r0 != #2fh, then jump to m2.
	;mov r0, 33h; else set r0, if r0 is less then 30h, then set it back to 33h (max).
;m2:
	;djnz r1, left; Decrement r1 and jump to left, if r1 not equal to 0.
	;setb p3.0
	;ret

;right:
	;setb p3.0
	;mov p1, @r0
	;inc r0
	;mov th0, #10111010b
	;mov tl0, #01000101b
	;setb tr0
;m3:
	;jnb tf0, m3
	;clr tf0
	;cjne r0, #38h, m4
	;mov r0, 30h
;m4:
	;djnz r1, right
	;setb p3.0
	;ret
;end
