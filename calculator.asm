
.data			# What follows will be data
inputString: .space 64	# set aside 64 bytes to store the input string
prompt: .asciiz ">>> "
parsedText: .space 64
invalidMsg: .asciiz "Invalid Input\n"
validMsg: .asciiz "Valid Input\n"
tooManyOps: .asciiz "Too many Operators!\n"
VarError: .asciiz "Var assignment should be one digit only!\n"
toomanyOperandDigits: .asciiz "Too many Operand Digits!\n"
DivByZero: .asciiz "Cant divide by Zero!\n"
post: .space 64


.text			# What follows will be actual code
	li $s3, 0
main: 
	jal clearPostSpace
	# Display prompt
	la	$a0, prompt	# display the prompt to begin
	li	$v0, 4	# system call code to print a string to console
	syscall
	# get the string from console
	la	$a0, inputString	# load $a0 with the address of inputString; procedure: $a0 = buffer, $a1 = length of buffer
	la	$a1, inputString	# maximum number of character
	li	$v0, 8	# The system call code to read a string input
	syscall

	#check conditions that make expresion false
	jal removeSpaces # parses input to remove any spaces if any
	jal checkParenthesis #check for balanced parenthesis
	jal checkFirstCharacterOfString
	jal checkLastCharacterOfString
	jal checkIfStringHasValidCharacters
	jal checkIfStringHasAdjacentOperators #check for 2 operatora in a row. ex: 2**2
	jal checkForMoreThan2EqualSign
	beq $s1, 1, checkIfValidLogicalComparison #check for == 
	jal checkIfFirstCharIsANumber
	jal checkIfThereIsAnOperatorToTheRightOnAnEqualSign #a+b =2 false
	jal checkIfVariableStartsWithNumber
	jal checkIfMoreThan4Operators
	jal checkforVaraibleAssignment
	jal handleDivByZero
	bne $a3, 0, pluginVar
	convert:
	jal checkifOperandMoreThanFour
	j infixToPost
	


	
	done:
	lw $t0, 0($sp)
	move $a0, $t0
	li $v0,1
	syscall
	li $a0, 10 #print new line
	li $v0,11
	syscall
	add $sp, $sp, 4
	j main
	li $v0, 10
	syscall
	
		
# removes all spaces so string is easier to parse
removeSpaces:
	li $t0,0
	la $t7, inputString
	li $t3, 0
	move $a2, $t7
	removeSpacesLoop:               
	add, $t2, $a2,$t0
   	lbu  $a0, 0($t2)
   	bne  $a0, 32, save
   	removeSpaces_next:
   	beqz $a0, exit # exit if null terminate
   	addi $t0, $t0, 1
   	j removeSpacesLoop
  
  #store  char to array	
  save:
  	sb $a0, parsedText($t3) #save character to new array 
  	addi $t3, $t3,1
  	j removeSpaces_next
  
  #save len on string and exit
  exit:
  	subi $t3,$t3,3
  	move $s0, $t3 # len of string
  	beq $s0, 0,checkChar
  	subi $t4, $zero, 1
  	beq $t4, $s0, valid 
	jr $ra
	
	#check if the first char is a valid char when the input is a single char (only letters and numbers)
	checkChar:
	la $t0, parsedText
	lb $t0, 0($t0)
	bge $t0, 97, checkz # if char  >= than 'a'
	bge $t0, 65, checkZ # if >= than 'A'
	bge $t0, 48, check9 #if char >=0
	j invalid
	   	checkz:
   	ble $t0, 122, valid #if <= than z 
   	j invalid
   	
   	checkZ:
   	ble $t0, 90, valid #if <= than Z
   	j invalid
   	
   	check9:
   	ble $t0, 57, valid #if <=9
   	j invalid
#check for balanced parenthesis
checkParenthesis:
	li $t0, 0 #increment
	la $t1, parsedText
	li $t2, 0 #stack counter
	li $t3, 0 # cur address
	checkParenthesis_loop:
	add $t3, $t0 ,$t1   
	lbu $a0, 0($t3)
	beqz $a0, checkParenthesis_exit
	beq $a0, 40, inc # check if a0 = '('
	bne $a0, 41, checkParenthesis_next  # check if a0 = ')'
	j dec	
checkParenthesis_next:
	
	addi $t0, $t0, 1
	j checkParenthesis_loop
	
checkParenthesis_exit:
	bne $t2,$zero, invalid
	jr $ra
	
inc:
	addi $t2,$t2,1
	j checkParenthesis_next
	
dec:
	beq $t2, $zero, invalid
	subi $t2, $t2, 1
	j checkParenthesis_next
	
invalid: # display invalid message
	la	$a0, invalidMsg	
	li	$v0, 4
	syscall
	j main

valid:  # display valid message
	la	$a0, validMsg	
	li	$v0, 4
	syscall
	j main
	
checkFirstCharacterOfString:
	la $t0 parsedText
	lb $t0, 0($t0)
	beq $t0, 42, invalid # if first char is '*'
	beq $t0, 47, invalid # if first char is '/'
	beq $t0, 61, invalid # if first char is '='
	jr $ra
	
checkLastCharacterOfString:
	la $t0 parsedText
	add $t0, $t0, $s0 # get final char of string
	lb $t0, 0($t0)	#load char
	beq $t0, 42, invalid # if last char is '*'
	beq $t0, 47, invalid # if last char is '/'
	beq $t0, 61, invalid # if last char is '='
	beq $t0, 43, invalid # if last char is '+'
	beq $t0, 45, invalid # if last char is '-'
	jr $ra

#iterates through a string and checks if there is an operator to the right for an '='
# if there is one then toggle a register to 1
#if registered was toggled and a character after that is '=', then it is invalid expression
#ex. a*=1 is invalid
checkIfThereIsAnOperatorToTheRightOnAnEqualSign:

	li $t0, 0 #increment
	la $t1, parsedText
	li $t7, 0 # has '=' been seen
	checkIfThereIsAnOperatorToTheRightOnAnEqualSign_loop:
	add $t3, $t0 ,$t1
	lbu $a0, 0($t3)
	beq $a0, 42, toggle # if  char is '*'
	beq $a0, 47, toggle # if  char is '/'
	beq $a0, 43, toggle # if  char is '+'
	beq $a0, 45, toggle # if  char is '-'
	beqz $t7, checkIfThereIsAnOperatorToTheRightOnAnEqualSign_next
	beq $a0, 61, invalid # if  char is '='
	checkIfThereIsAnOperatorToTheRightOnAnEqualSign_next:
	beqz $a0, exit_subroutine # exit if null terminate
   	addi $t0, $t0, 1
   	j checkIfThereIsAnOperatorToTheRightOnAnEqualSign_loop
   	
   	exit_subroutine:
   	jr $ra
	
	
toggle:
	li $t7, 1
	j checkIfThereIsAnOperatorToTheRightOnAnEqualSign_next

  checkIfStringHasValidCharacters:
 	li $t0, 0 #increment
	la $t1, parsedText
	checkIfStringHasValidCharacters_loop:
	add $t3, $t0 ,$t1
	lbu $a0, 0($t3)
	beq $a0, 42, continue # if  char is '*'
	beq $a0, 47, continue # if  char is '/'
	beq $a0, 43, continue # if  char is '+'
	beq $a0, 45, continue # if  char is '-'
	beq $a0, 61, continue # if  char is '='
	beq $a0, 40, continue # if char is '('
	beq $a0, 41, continue # if char is ')'
	bge $a0, 97, checkLessThan_z # if char  >= than 'a'
	bge $a0, 65, checkLessThan_Z # if >= than 'A'
	bge $a0, 48, checkLessThan_9 #if char >=0
	blt $a0, 48, invalid # char is not allowed
	
	continue:
	beq $t0,$s0, exit_subroutine # exit if null terminate
	addi $t0, $t0, 1
   	j checkIfStringHasValidCharacters_loop
   	
   	checkLessThan_z:
   	ble $a0, 122, continue #if <= than z 
   	j invalid
   	
   	checkLessThan_Z:
   	ble $a0, 90, continue #if <= than Z
   	j invalid
   	
   	checkLessThan_9:
   	ble $a0, 57, continue #if <=9
   	j invalid
   	
checkIfStringHasAdjacentOperators: #example a*=2 is invalid
 	li $t0, 1 #increment (start at second char)
	la $t1, parsedText
	checkIfStringHasAdjacentOperators_loop:
	add $t3, $t0 ,$t1
	lbu $a0, 0($t3)
	beq $a0, 42, checkprev # if  char is '*' 
	beq $a0, 47, checkprev # if  char is '/'
	beq $a0, 61, checkprev # if  char is '='
	beq $a0, 40, checkprevParen # if char is '('
	beq $a0, 41, checkprevParen2 # if char is ')'
	bge $a0, 97, checkLessThan_z3 # if char  >= than 'a'
	bge $a0, 65, checkLessThan_Z3 # if >= than 'A'
	

	
	checkIfStringHasAdjacentOperators_next:
	beq $t0,$s0, exit_subroutine # exit if null terminate
	addi $t0, $t0, 1
   	j checkIfStringHasAdjacentOperators_loop
	
	#if previous character is also opertator, then it is invalid
	checkprev:
	subi $t2, $t3,1
	lbu $a1,0($t2)
	beq $a1, 42, invalid # if  char is '*'
	beq $a1, 47, invalid # if  char is '/'
	beq $a1, 43, invalid # if  char is '+'
	beq $a1, 45, invalid # if  char is '-'
	j checkIfStringHasAdjacentOperators_next
	
	checkprevParen:
	subi $t2, $t3,1
	lbu $a1,0($t2)
	beq $a1, 41, invalid # if  char is '('
	j checkIfStringHasAdjacentOperators_next
	
	checkprevParen2:
	subi $t2, $t3,1
	lbu $a1,0($t2)
	beq $a1, 40, invalid # if  char is ')'
	j checkIfStringHasAdjacentOperators_next
	
	checkLessThan_z3:
	ble $a0, 122, checkprevParen #if <= than z 
	j checkIfStringHasAdjacentOperators_next
	
	checkLessThan_Z3:
	ble $a0, 90, checkprevParen #if <= than z 
	j checkIfStringHasAdjacentOperators_next
	
	

#if there are more than 2 equal sign then it is invalid
checkForMoreThan2EqualSign:	
 	li $t0, 1 #increment (start at second char)
	la $t1, parsedText
	li $t2,0
	checkForMoreThan2EqualSign_loop:
	add $t3, $t0 ,$t1
	lbu $a0, 0($t3)
	beq $a0, 61, incrementEqualCount # if  char is '='
	checkForMoreThan2EqualSign_next:
   	beq $t0,$s0, countHowManyEqualSigns
   	addi $t0, $t0, 1
   	j checkForMoreThan2EqualSign_loop
   	
   	
   	incrementEqualCount:
   	addi $t2, $t2, 1
   	j checkForMoreThan2EqualSign_next
   	
   	countHowManyEqualSigns:
   	bgt $t2, 2, invalid
   	seq $s1, $t2,2 #if there are exacly 2 equal sign set $s1 to 1
   	seq $s2, $t2,1 #if there are exacly 1 equal sign set $s2 to 1
   	#seq $s3, $t2,0 #if there are exacly 0 equal sign set $s2 to 1
   	jr $ra
  
 checkIfValidLogicalComparison:
 	li $t0, 1 #increment (start at second char)
	la $t1, parsedText
	li $t2,0
	checkIfValidLogicalComparison_loop:
	add $t3, $t0 ,$t1
	lbu $a0, 0($t3)
	beq $a0, 61, checkPrevEq # if  char is '='
	checkIfValidLogicalComparison_next:
	beq $t0,$s0, invalid # exit if null terminate
	addi $t0, $t0, 1
   	j checkIfValidLogicalComparison_loop
   	
 	checkPrevEq:
 	subi $t2, $t3,1
	lbu $a1,0($t2)
	beq $a1, 61, valid # if  char is '='
	j checkIfValidLogicalComparison_next
	
#if first character is a number then its invalid	
checkIfFirstCharIsANumber:
	bne $s2, 1, else
	la $t0 parsedText
	lb $t0, 0($t0)
	bge $t0, 48, checkIfFistNumLessThan9 
  	jr $ra
  	checkIfFistNumLessThan9:
  	ble $t0, 57, invalid
  	jr $ra
	else:
	jr $ra
checkIfVariableStartsWithNumber:
	li $t7,1
 	li $t0, 1 #increment (start at second char)
	la $t1, parsedText
	checkIfVariableStartsWithNumber_loop:
	add $t3, $t0 ,$t1
	lbu $a0, 0($t3)
	bge $a0, 97, checkLessThan_z2 # if char  >= than 'a'
	bge $a0, 65, checkLessThan_Z2 # if >= than 'A'
	beq $a0, 42, toggle2 # if  char is '*'
	beq $a0, 47, toggle2 # if  char is '/'
	beq $a0, 43, toggle2 # if  char is '+'
	beq $a0, 45, toggle2 # if  char is '-'
	checkIfVariableStartsWithNumber_next:
	li $t7, 0
	then:
	beq $t0,$s0, after # exit if null terminate
	addi $t0, $t0, 1
   	j checkIfVariableStartsWithNumber_loop
   	
      	checkLessThan_z2:
   	ble $a0, 122, checkPrevChar #if <= than z 
   	j checkIfVariableStartsWithNumber_next
   	
   	checkLessThan_Z2:
   	ble $a0, 90, checkPrevChar #if <= than Z
   	j checkIfVariableStartsWithNumber_next
   	
   	toggle2:
   	 li $t7, 1
   	 j then
   	
   	
   	checkPrevChar:
	subi $t2, $t3,1
	lbu $a0, 0($t2)
	bge $a0, 48, check9_2 #if char >=0
	j checkIfVariableStartsWithNumber_next
	
	check9_2:
	ble $a0, 57, final #if <=9
   	j checkIfVariableStartsWithNumber_next
   	
   	after: jr $ra
   	
   	final:
   	beq $t7, 1, invalid
   	j checkIfVariableStartsWithNumber_next
   
   checkIfMoreThan4Operators:
   	li $t0, 0 #increment
	la $t1, parsedText
	li $t3, 0 # cur address
	li $t2, 0 #operator counter
	checkIfMoreThan4Operators_loop:
	add $t3, $t0 ,$t1   
	lbu $a0, 0($t3)
	beq $a0, 42, incrementOperator # if  char is '*'
	beq $a0, 47, incrementOperator # if  char is '/'
	beq $a0, 43, incrementOperator # if  char is '+'
	beq $a0, 45, incrementOperator # if  char is '-'
	checkIfMoreThan4Operators_next:
	addi $t0, $t0, 1
	bnez $a0, checkIfMoreThan4Operators_loop
	bge $t2, 5, tooManyOperators
	jr $ra
	
	
	
	incrementOperator:
	add $t2, $t2, 1
	j checkIfMoreThan4Operators_next
	

tooManyOperators:
	la	$a0, tooManyOps	
	li	$v0, 4
	syscall
	j main
	
	
	
infixToPost:
	li $t0,0
	li $t4, 0 #index of array
	la $t7, parsedText
	li $t3, 0
	move $a2, $t7
	move $t1, $sp #empty stack
	infixToPost_loop:               
	add $t2, $a2,$t0
   	lbu  $a0, 0($t2)
   	beq $a0, 42, addSpace # if  char is '*'
	beq $a0, 47, addSpace # if  char is '/'
	beq $a0, 43, addSpace # if  char is '+'
	beq $a0, 45, addSpace # if  char is '-'
  	bge $a0, 48, check9_9 #if char >=0
	infixToPostnext2:
   	beq $a0, 40, pushtoStack
   	infixToPostnext3:
   	beq $a0, 41, popMany
   	
   	#pop remaining
   	
   	infixToPost_next:
   	beqz $a0, popRemaining # exit if null terminate
   	addi $t0, $t0, 1
   	j infixToPost_loop
   	
   	##done
   	donez:
   	j getlength
  	############
   	
   	addSpace:
   	j isOP
	
	
	isOP:
	li $t7, 32
   	sb $t7, post($t4)
   	addi $t4, $t4,1
	beq $sp, $t1, pushExpression #if stack is empty
	lb $s4, 0($sp)
	beq $s4,40, pushExpression #if top of stack is  '('
	beq $s4,43 comparePrecedencePlus #+
	beq $s4,45 comparePrecedenceMinus #-
	beq $s4,42 comparePrecedenceMult #*
	beq $s4,47 comparePrecedenceDiv #/
	
	writePostfix:
	lb $s4, 0($sp)
	sb $s4, post($t4) #save character to new array 
  	addi $t4, $t4,1
  	addi $sp, $sp,4
  	j isOP
	
	
	pushExpression:
	addi $sp, $sp, -4
	sb $a0, 0($sp)
	j infixToPost_next
	
	comparePrecedencePlus:
	beq $a0, 42, lower #*
	beq $a0, 47, lower #/
	beq $a0, 43, higher #+
	beq $a0, 45, higher  #- 
	
	comparePrecedenceMinus:
	beq $a0, 42, lower #*
	beq $a0, 47, lower #/
	beq $a0, 43, higher #+
	beq $a0, 45, higher  #- 
	
	comparePrecedenceMult:
	beq $a0, 42, higher #*
	beq $a0, 47, higher #/
	beq $a0, 43, higher #+
	beq $a0, 45, higher  #- 
	
	comparePrecedenceDiv:
	beq $a0, 42, higher #*
	beq $a0, 47, higher #/
	beq $a0, 43, higher #+
	beq $a0, 45, higher  #- 
	
	
	lower:
	j pushExpression
	
	higher:
	j writePostfix
	
	check9_9:
   	ble $t0, 57, writeToPostfix2 #if <=9
   	j infixToPostnext2
	
   	
   	writeToPostfix2:
   	sb $a0, post($t4) #save character to new array 
  	addi $t4, $t4,1
  	j infixToPost_next
	
	
	pushtoStack:
	addi $sp, $sp, -4
	sb $a0, 0($sp)
	j infixToPost_next
	
	popMany:

	beq $sp, $t1, popManyThen #if stack is empty
	lb $s4, 0($sp) # get top of stack
	beq $s4, 40, popManyThen # if top of stack = '('
	li $t7, 32 
   	sb $t7, post($t4) #add a space
   	addi $t4, $t4,1
	sb $s4, post($t4) #save character to new array 
	addi $sp, $sp,4
  	addi $t4, $t4,1
  	j popMany
	
	
	
	popManyThen:
	addi $sp, $sp,4
	j infixToPost_next
	
	popRemaining:
	popRemaining_loop:
	beq $sp, $t1, donez #if stack is empty
	lb $s4, 0($sp) # get top of stack
	li $t7, 32 
   	sb $t7, post($t4) #add a space
   	addi $t4, $t4,1
	sb $s4, post($t4) #save character to new array 
  	addi $t4, $t4,1 # increment to next index of postfix string
  	addi $sp, $sp, 4 #pop stack
  	j popRemaining_loop
	
	################get length of Postfix################
	getlength:
	li $s0, 0 #postfix length
	li $t0, 0 #increment
	la $t1, post
	li $t3, 0 # cur address
	getlengthloop:
	add $t3, $t0 ,$t1   
	lbu $a0, 0($t3)
	beqz $a0, eval
	addi $t0, $t0, 1
	addi $s0, $s0, 1
	j getlengthloop
	
	
	
	
	#################Evaluate Postix#######################
	eval:
	li $t0, 0 #increment
	la $t1, post
	move $t2, $sp #empty stack
	li $t3, 0 # cur address

	eval_loop:
	add $t3, $t0 ,$t1   
	lbu $a0, 0($t3)
	beqz $a0, done
	beq $a0, 32, eval_next # continue of chart is a space
	beq $a0, 42, isOperator # if  char is '*'
	beq $a0, 47, isOperator # if  char is '/'
	beq $a0, 43, isOperator # if  char is '+'
	beq $a0, 45, isOperator # if  char is '-'
	bge $a0, 48, isaNum #if char >=0
	eval_next:

	addi $t0, $t0, 1
	j eval_loop
	
	isOperator:
	lw $s4, 0($sp) #operand 2
	addi $sp, $sp, 4
	lw $s5, 0($sp) #operand 1
	addi $sp, $sp, 4

	#perform operation
	beq $a0, 42, performMult # if  char is '*'
	beq $a0, 47, performDiv # if  char is '/'
	beq $a0, 43, performAdd # if  char is '+'
	beq $a0, 45, performSub # if  char is '-'
	
	performMult:
	mul $s6, $s4, $s5
	addi $sp, $sp, -4 #save res to stack
	sw $s6, 0($sp)
	j eval_next

	

	performDiv:
	div $s6, $s5, $s4 
	addi $sp, $sp, -4 #save res to stack
	sw $s6, 0($sp)
	j eval_next

	

	performAdd:
	add $s6, $s4, $s5
	addi $sp, $sp, -4 #save res to stack
	sw $s6, 0($sp)
	j eval_next

	performSub:
	sub $s6, $s5, $s4
	addi $sp, $sp, -4 #save res to stack
	sw $s6, 0($sp)
	j eval_next

	

	isaNum:
   	ble $a0, 57, isaNumThen #if <=9
   	j eval_next

	isaNumThen:
	li $s7, 0 #operand
	isaNumThen_loop:
	beq $t0, $s0, pushAndDecrement 
	add $t3, $t0 ,$t1  
	lbu $a0, 0($t3)
	bge $a0, 48, isaNum2 #if char >=0
	j pushAndDecrement
	isaNumThen_next:
	mul $t6, $s7, 10
	sub $t7, $a0, 48
	add $s7, $t6, $t7
	addi $t0, $t0, 1
	j isaNumThen_loop
	
	
	## push operand to stack ##
	pushAndDecrement:
	subi $t0, $t0, 1
	addi $sp, $sp, -4
	sw $s7, 0($sp) #push onto stack
	j eval_next
	
	isaNum2:
	ble $a0, 57, isaNumThen_next #if <=9
   	j pushAndDecrement
	
	##clear postfix string after each input##
	clearPostSpace:
	li $t0, 0 #increment
	li $t2, 0
	clearPostSpaceLoop:
	sb $t2, post($t0)
	beq $t0, 64, returnToMain
	addi $t0, $t0, 1
	j clearPostSpaceLoop
   
	returnToMain:
	jr $ra

	checkforVaraibleAssignment:
   	la $t1, parsedText
   	lbu $a0, 0($t1)
   	bge $a0, 97, checkLessThan_z4 # if char  >= than 'a'
	bge $a0, 65, checkLessThan_Z4 # if >= than 'A'
	check2ndChar:
	lbu $a0, 1($t1)
	bne $a0, 61, ret

	

	#####extract values right of equal sign###### goes into var

	lbu $a0, 2($t1)
	move $s3, $a0 
	lbu $a0, 0($t1)
	move $a3, $a0
	lbu $a0, 3($t1)
	bne $a0, 10, displayVarError #\n
	j exitCheckVariable
	
	checkLessThan_z4:
	ble $a0, 122, check2ndChar #if <= than z 
	jr $ra

	

	checkLessThan_Z4:
	ble $a0, 90, check2ndChar #if <= than z 
	jr $ra

	ret:
	jr $ra
	
	exitCheckVariable:
	j main

	#var can not be more than 1 digit
	displayVarError:
	la $a0, VarError
	li $v0,4
	syscall
	j main 
	
	###Loop through string to check for varaible ###
	pluginVar:
	li $t0, 0 #increment
	la $t1, parsedText
	li $t3, 0 # cur address
	pluginVarLoop:
	add $t3, $t0 ,$t1   
	lbu $a0, 0($t3)
	beq $a0, $a3, swap
	pluginVarNext:
	beqz $a0, convert
	addi $t0, $t0, 1
	j pluginVarLoop
	
	#swap variable with numerical value 
	swap:
	sb $s3, parsedText($t0)
	j pluginVarNext
	
	#check for more than 4 digits in operand
	checkifOperandMoreThanFour:
	li $t4, 0 #consecutiveDigits
	li $t0, 0 #increment
	la $t1, parsedText
	li $t3, 0 # cur address
	checkifOperandMoreThanFour_loop:
	add $t3, $t0 ,$t1   
	lbu $a0, 0($t3)
	beq $a0, 42, resetCounter # if  char is '*'
	beq $a0, 47, resetCounter # if  char is '/'
	beq $a0, 43, resetCounter # if  char is '+'
	beq $a0, 45, resetCounter # if  char is '-'
	beq $a0, 40, resetCounter # if  char is '('
	beq $a0, 41, resetCounter # if  char is ')'
	beq $a0, 10, resetCounter # if  char is '\n'
	addi $t4, $t4, 1
	beq $t4, 5, printTooManyDigits  #if counter is 5
	beqz $a0, ret
	checkifOperandMoreThanFour_next:
	addi $t0, $t0, 1
	j checkifOperandMoreThanFour_loop
	
	#if operand is reached, then reset digit count
	resetCounter:
	li $t4, 0
	j checkifOperandMoreThanFour_next

	##Too many digits error
	printTooManyDigits:
	li $v0, 4
	la $a0, toomanyOperandDigits
	syscall
	j main
	
	handleDivByZero:
	li $t0, 0 #increment
	la $t1, parsedText
	li $t3, 0 # cur address
	handleDivByZeroLoop:
	add $t3, $t0 ,$t1   
	lbu $a0, 0($t3)
	beq $a0, 47,checkIfNextIs0
	
	handleDivByZeroNext:
	addi $t0, $t0, 1
	beqz $a0, ret
	j handleDivByZeroLoop
	checkIfNextIs0:
	
	addi $t2, $t3 ,1
	lbu $a0, 0($t2)
	beq $a0, 48, printDivError #if char is 0
	j handleDivByZeroNext
	
	
	
	printDivError:
	li $v0, 4
	la $a0, DivByZero
	syscall
	j main
	

	


   	
   	
