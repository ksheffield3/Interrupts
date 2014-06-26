!************************************************************************!
!									 !
! general calling convention:						 !
!									 !
! (1) Register usage is as implied in the assembler names		 !
!									 !
! (2) Stack convention							 !
!									 !
!	  The stack grows towards higher addresses.  The stack pointer	 !
!	  ($sp) points to the next available (empty) location.		 !
!									 !
! (3) Mechanics								 !
!									 !
!	  (3a) Caller at call time:					 !
!	       o  Write any caller-saved stuff not saved at entry to	 !
!		  space on the stack that was reserved at entry time.	 !
!	       o  Do a JALR leaving the return address in $ra		 !
!									 !
!	  (3b) Callee at entry time:					 !
!	       o  Reserve all stack space that the subroutine will need	 !
!		  by adding that number of words to the stack pointer,	 !
!		  $sp.							 !
!	       o  Write any callee-saved stuff ($ra) to reserved space	 !
!		  on the stack.						 !
!	       o  Write any caller-saved stuff if it makes sense to	 !
!		  do so now.						 !
!									 !
!	  (3c) Callee at exit time:					 !
!	       o  Read back any callee-saved stuff from the stack ($ra)	 !
!	       o  Deallocate stack space by subtract the number of words !
!		  used from the stack pointer, $sp			 !
!	       o  return by executing $jalr $ra, $zero.			 !
!									 !
!	  (3d) Caller after return:					 !
!	       o  Read back any caller-saved stuff needed.		 !
!									 !
!************************************************************************!

!vector table
 vector0: .fill 0x00000000 !0
vector1: beq $zero, $zero, ti_inthandler!1
 .fill 0x00000000 !2
 .fill 0x00000000
 .fill 0x00000000 !4
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000 !8
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000 !15
!end vector table

!my implementation uses two stacks since that is the normal for interrupts
!But since we dont have a mode bit, I wont be switching stacks
!I just intialize my stack for the interrupts in a separate location
!and use it during the interrupt handler

main:
	ei
	addi $sp, $zero, initsp ! initialize the stack pointer
	lw $sp, 0($sp)
	! Install timer interrupt handler into the vector table
	la $s0, ti_inthandler
	lw $s0, 0($s0)
	la $s1, vector1
	lw $s1, 0($s1)
	sw $s0, 1($s1)


	!FIX ME
	 			!Dont forget to enable interrupts...

		
	addi $a0, $zero, 2	!load base for pow
	addi $a1, $zero, 8	!load power for pow
	addi $at, $zero, POW			!load address of pow
	jalr $at, $ra		!run pow
		
	halt	
		
		

POW: 
  addi $sp, $sp, 2   ! push 2 slots onto the stack
  sw $ra, -1($sp)   ! save RA to stack
  sw $a0, -2($sp)   ! save arg 0 to stack
  beq $zero, $a1, RET1 ! if the power is 0 return 1
  beq $zero, $a0, RET0 ! if the base is 0 return 0
  addi $a1, $a1, -1  ! decrement the power
  la $at, POW	! load the address of POW
  jalr $at, $ra   ! recursively call POW
  add $a1, $v0, $zero  ! store return value in arg 1
  lw $a0, -2($sp)   ! load the base into arg 0
  la $at, MULT		! load the address of MULT
  jalr $at, $ra   ! multiply arg 0 (base) and arg 1 (running product)
  lw $ra, -1($sp)   ! load RA from the stack
  addi $sp, $sp, -2  ! pop the RA and arg 0 off the stack
  jalr $ra, $zero   ! return
RET1: addi $v0, $zero, 1  ! return a value of 1
  addi $sp, $sp, -2
  jalr $ra, $zero
RET0: add $v0, $zero, $zero ! return a value of 0
  addi $sp, $sp, -2
  jalr $ra, $zero		
	
MULT: add $v0, $zero, $zero ! zero out return value
AGAIN: add $v0,$v0, $a0  ! multiply loop
  addi $a1, $a1, -1
  beq $a1, $zero, DONE ! finished multiplying
  beq $zero, $zero, AGAIN ! loop again
DONE: jalr $ra, $zero	
		
		
ti_inthandler:
	!FIX ME
	la $fp, secondstack
	lw $fp, 0($fp)
	!addi $fp, $zero, secondstack 
	!lw $fp, 0($fp) !store all the reg values on this stack
	addi $fp, $fp, 1
	sw $k0, 0($fp)
	addi $fp, $fp, 1
	sw $at, 0($fp)
	addi $fp, $fp, 1
	sw $v0, 0($fp)
	addi $fp, $fp, 1
	sw $a0, 0($fp)
	addi $fp, $fp, 1
	sw $a1, 0($fp)
	addi $fp, $fp, 1
	sw $a2, 0($fp)
	addi $fp, $fp, 1
	sw $a3, 0($fp)
	addi $fp, $fp, 1
	sw $a4, 0($fp)
	addi $fp, $fp, 1
	sw $s0, 0($fp)
	addi $fp, $fp, 1
	sw $s1, 0($fp)
	addi $fp, $fp, 1
	sw $s2, 0($fp)
	addi $fp, $fp, 1
	sw $s3, 0($fp)
	addi $fp, $fp, 1
	sw $sp, 0($fp)
	addi $fp, $fp, 1
	sw $fp, 0($fp)
	addi $fp, $fp, 1
	sw $ra, 0($fp)

	ei
	
	
	!seconds, minutes, hours
	!at every 60 second interval, add 1 to minutes
	!at every 60 minute interval, add 1 to hours 
	!seconds: FFFFC
	!minutes: FFFFD
	!hours: FFFFE

	add $s0, $zero, $zero 
	add $s1, $zero, $zero
	add $s2, $zero, $zero
	add $a0, $zero, $zero
	addi $a0, $zero, 60 !minutes and hours comparison  

!cant seem to get this right
!I want to load the contents at the seconds address
!into a register so I can increment it
!instead, I keep just getting the address and adding to it
!which is wrong...
!will fix if I have time
sec:
	la $a1, seconds  
	lw $s0, 0($a1)
	addi $s0, $s0, 1 !seconds
	sw $s0, 0($a1)
	beq $a0, $s0, min
	beq $s0, $s0, exit
min:
	la $a1, minutes
	lw $a1, 0($a1)  
	!addi $a1, $zero, minutes 
	!lw $a1, 0($a1)
	add $a1, $a1, $zero
	addi $s1, $a1, 1 
	sw $s1, 0($a1) 
	beq $a0, $s1, hour
	beq $s1, $s1, exit
hour:
	la $a1, hours
	lw $a1, 0($a1) 
	!addi $a1, $zero, hours 
	!lw $a1, 0($a1)
	add $a1, $a1, $zero
	addi $s2, $a1, 1
	sw $s2, 0($a1) 
	beq $s2, $s2, exit 

exit:
!exiting the interrupt
!restore processor registers 
!disable interrupts
!restore $k0  
!RETI 
la $fp, secondstack
	lw $fp, 0($fp)
	!lw $k0, 0($fp)
	addi $fp, $fp, 1
	addi $fp, $fp, 1
	lw $at, 0($fp)
	addi $fp, $fp, 1
	lw $v0, 0($fp)
	addi $fp, $fp, 1
	lw $a0, 0($fp)
	addi $fp, $fp, 1
	lw $a1, 0($fp)
	addi $fp, $fp, 1
	lw $a2, 0($fp)
	addi $fp, $fp, 1
	lw $a3, 0($fp)
	addi $fp, $fp, 1
	lw $a4, 0($fp)
	addi $fp, $fp, 1
	lw $s0, 0($fp)
	addi $fp, $fp, 1
	lw $s1, 0($fp)
	addi $fp, $fp, 1
	lw $s2, 0($fp)
	addi $fp, $fp, 1
	lw $s3, 0($fp)
	addi $fp, $fp, 1
	lw $sp, 0($fp)
	addi $fp, $fp, 1
	lw $fp, 0($fp)
	addi $fp, $fp, 1
	lw $ra, 0($fp)


	di
	addi $fp, $zero, secondstack 
	lw $fp, 0($fp) !store all the reg values on this stack
	lw $k0, 0($fp)

	reti 
	
	
	
initsp: .fill 0xA00000
secondstack: .fill 0xD00000
seconds: .fill 0xFFFFC
minutes: .fill 0xFFFFD
hours:   .fill 0xFFFFE
