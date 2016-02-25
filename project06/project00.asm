TITLE Programming Assignment 6    (project05-hillyer.asm)
; =====================================================================================
; Author:                  Shawn S Hillyer
; Email:                   hillyers@oregonstate.edu
; CS271-400 / Project ID:  Programming Assignment 6
; Due Date:                03/13/2016
; =====================================================================================

; =====================================================================================
; [Problem Definition]
; + Implement and test your own ReadVal and WriteVal procedures for unsigned integers.
; + Implement macros getString and displayString. The macros may use Irvine�s ReadString 
;   to get input from the user, and WriteString to display output.
;   - getString should display a prompt, then get the user�s keyboard input into a 
;     memory location
;   - displayString should the string stored in a specified memory location.
;   - readVal should invoke the getString macro to get the user�s string of digits. 
;     It should then convert the digit string to numeric, while validating the user�s 
;     input.
;   - writeVal should convert a numeric value to a string of digits, and invoke the 
;     displayString macro to produce the output.
; + Write a small test program that gets 10 valid integers from the user and stores 
;   the numeric values in an array. The program then displays the integers, 
;   their sum, and their average.
; =====================================================================================

; =====================================================================================
; [Requirements]
;  1) User�s numeric input must be validated the hard way: Read the user's input as a 
;     string, and convert the string to numeric form. If the user enters non-digits or 
;     the number is too large for 32-bit registers, an error message should be displayed
;     and the number should be discarded.
;  2) Conversion routines must appropriately use the lodsb and/or stosb operators.
;  3) All procedure parameters must be passed on the system stack.
;  4) Addresses of prompts, identifying strings, and other memory locations should be 
;     passed by address to the macros.
;  5) Used registers must be saved and restored by the called procedures and macros.
;  6) The stack must be �cleaned up� by the called procedure.
;  7) The usual requirements regarding documentation, readability, user-friendliness, etc., apply.
;  8) Submit your text code file (.asm) to Canvas by the due date.
; =====================================================================================

; =====================================================================================
; [Extra-credit options]
; [Not Implemented]	1. [1 point ]: Number each line of user input and display a 
;                          running subtotal of the user's numbers
; [Not Implemented]	2. [2 points]: Handle signed integers.
; [Not Implemented]	3. [3 points]: make your ReadVal and WriteVal procedures recursive.
; [Not Implemented]	4. [4 points]: implement procedures ReadVal and WriteVal for 
;                          floating point values, using the FPU.

INCLUDE Irvine32.inc


; *********************
; Macros              *
; *********************

; +============================================================+
; getString MACRO promptAddr:REQ, outStringAddr:REQ
; Description: Displays a prompt then get user's keyboard input 
; into a memory location stored as a string into outString	
; Receives:		
; +------------------------------------------------------------+
getString MACRO promptAddr:REQ, outStringAddr:REQ
;; Save used registers
	push	edx
	push	ecx

; Display prompt for user
	displayString promptAddr

; Get user's keyboard input into the outString variable location
	mov		edx, outStringAddr
	mov		ecx, BUFFER_SIZE 
	call	ReadString

;; Restore registers
	pop		ecx
	pop		edx

;; +------------------------------------------------------------+	
ENDM
; +============================================================+


; +============================================================+
; displayString MACRO stringAddr:REQ
; Description: Displays the string stored in specified mem location
; Receives:
; +------------------------------------------------------------+
displayString MACRO stringAddr:REQ
;; Save used registers
	push	edx

;; Use WriteString to display the string stored in memory address	
	mov		edx, stringAddr
	call	WriteString

;; Restore registers
	pop		edx

;; +------------------------------------------------------------+
ENDM
; +============================================================+


; Set up the stack frame pointer
mSetStackFrame MACRO
	push	ebp
	mov		ebp, esp
ENDM

; Restores a stack before returning with optional arguments to restore with ret call
mCleanStackFrame MACRO numArgs
	mov		esp, ebp ;; remove any locals from stack
	pop		ebp
	ret		numArgs
ENDM

; *********************
; Constants           *
; *********************
MAX_UNSIGNED_INT EQU 4294967295   ; maximum value that fits in 32 bit unsigned DWORD
MAX_DIGITS = 10                 ; maximum digits that a user can enter and still (possibly) be 32 bit unsigned int
DATA_ARRAY_SIZE = 10
BUFFER_SIZE = DATA_ARRAY_SIZE + 30
MAX_BUFFER_SIZE = DATA_ARRAY_SIZE + 1

; *********************
; Variables           *
; *********************
.data

; Strings - Output
	intro			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",0Dh,0Ah
					BYTE	"Written by Shawn S Hillyer",0
;	ecIntro_1		BYTE	"**EC: ",0
;	ecIntro_2		BYTE	"**EC: ",0
;	ecIntro_3		BYTE	"**EC: ",0
;	ecIntro_4		BYTE	"**EC: ",0
	pIntro			DWORD	OFFSET intro
	
	instructions	BYTE	"Please provide 10 unsigned decimal integers.",0Dh,0Ah
					BYTE	"Each number needs to be small enough to fit inside a 32 bit register.",0Dh,0Ah
					BYTE	"After you have finished inputting the raw numbers I will display a list",0Dh,0Ah
					BYTE	"of the integers, their sum, and their average value.",0
	pInstructions	DWORD	OFFSET instructions

	valuePrompt		BYTE	"Please enter an unsigned number:  ",0
	pValuePrompt	DWORD	OFFSET valuePrompt

	badInputMsg		BYTE	"ERROR: You did not enter an unsigned number or your number was too big.",0Dh,0Ah
					BYTE	"Please try again:  ",0
	pBadInputMsg	DWORD	OFFSET badInputMsg

	numbersMsg		BYTE	"You entered the following numbers: ",0
	pNumbersMsg		DWORD	OFFSET numbersMsg
	sumMsg			BYTE	"The sum of these numbers is: ",0
	pSumMsg			DWORD	OFFSET sumMsg
	avgMsg			BYTE	"The average is: ",0
	pAvgMsg			DWORD	OFFSET avgMsg

	goodbye		BYTE	"Getting down low with the in and the out was fun!",0
	pGoodbye		DWORD	OFFSET goodbye

; Data Variables
	userData		DWORD	DATA_ARRAY_SIZE DUP(?)	; Array to store Unsigned Integers
	userDataSize = ($ - userData)
	pUserData		DWORD	OFFSET userData
	
	singleInt		DWORD	?
	rawStringIn		BYTE	BUFFER_SIZE DUP(?)
	pRawStringIn	DWORD	rawStringIn
	dataSum			DWORD	0		; The sum of the userData array
	dataAvg			DWORD	0		; Average of the data stored in userData array
	


.code

; +============================================================+
main PROC
; Description:	Main program logic. Generates random numbers, prints
;   in unsorted order, then sorts and prints median and sorted order.
; Receives:		None
; Returns:		None
; Pre:			None
; Reg Changed:	Potentially all - main entrypoint
; +------------------------------------------------------------+

; Display the program title and programmer's name & Get the user's name, and greet the user.
	displayString 	pIntro
	call			CrLf
	call			CrLF

; Display instructions for the user.
	displayString 	pInstructions
	call			CrLf
	call			CrLF

; Prompt user for the 10 values and store them in an array
	call	getUserData
	call	CrLF

; Calculate the sum and average of the array
;	call	sumAvgArray
	
; Print the values entered
	displayString pNumbersMsg
	call	CrLf
;	call	printArray
	call	CrLf

; Print the sum
	displayString pSumMsg
;	push dataSum
	call	WriteVal
	call	CrLf

; Print the average
	displayString pAvgMsg
;	push	dataAvg
	call	WriteVal
	call	CrLf

; Print FareWell message
	call	CrLf
	displayString 	pGoodbye
	call	CrLF
	call	CrLF

; exit to operating system
	exit	

; +------------------------------------------------------------+
main ENDP
; +============================================================+






; +============================================================+
ReadVal PROC
; Description:	Gets string of digits from user, then convert to
;               numeric and validate input.
; Receives:		@buffer (reference), @result (reference)
; Returns:		
; Pre:			
; Reg Changed:	
; +------------------------------------------------------------+
	buffer		EQU [ebp + 8]
	result		EQU PTR DWORD [ebp + 12]

	mSetStackFrame
	push	ebx
	push	esi

; Get string from user, setup ESI to point to buffer for lodsb and ensure we're moving forward
	getString	pValuePrompt, buffer
	mov			esi, buffer
	mov			ebx, 0			; make sure all of eax is 0'd out before using lodsb

; Convert digit string to numeric while validating user's input	
TEST_VALUES:
	lodsb	; load value pointed at by esi into al register


; move the value into eax and compare to max int possible
	; DEBUG PURPOSES:
	mov		eax, 10

; if good, jump to valid block
	mov		ebx, MAX_UNSIGNED_INT
	cmp		eax, ebx
	jb		GOOD_INPUT

; if bad, reprompt:
BAD_INPUT:
	getString	pBadInputMsg, buffer
	call		CrLF
	jmp			TEST_VALUES

GOOD_INPUT:

; return value by reference


; Clean up stack and return
	pop		esi
	pop		ebx
	mCleanStackFrame 8

; +------------------------------------------------------------+
ReadVal ENDP
; +============================================================+


; +============================================================+
WriteVal PROC
; Description:	Convert numeric value to a string of digits and
;	        invoke the displayString macro to produce output
; Receives:		
; Returns:		
; Pre:			
; Reg Changed:	
; +------------------------------------------------------------+
	mSetStackFrame


; Clean up stack and return
	mCleanStackFrame

; +------------------------------------------------------------+
WriteVal ENDP
; +============================================================+



; +============================================================+
getUserData PROC
; Description:	
;	        
; Receives:		
; Returns:		
; Pre:			
; Reg Changed:	
; +------------------------------------------------------------+
	
	mSetStackFrame

	mov		edi, pRawStringIn
	push	singleInt
	push	edi ; TODO: Pass this parameter in to this function
	call	ReadVal

; Clean up stack and return
	mCleanStackFrame

; +------------------------------------------------------------+
getUserData ENDP
; +============================================================+






; +============================================================+
END main
; +============================================================+





; +============================================================+
; The below should not compile - template for functions


; +============================================================+
someprocess PROC
; Description:	
;	
; Receives:		
; Returns:		
; Pre:			
; Reg Changed:	
; +============================================================+

	
	ret
; +------------------------------------------------------------+
someprocess ENDP
; +------------------------------------------------------------+

