	.data
buf:		.space 50
digits_buf:	.space 50

	.text
main:
	# read string to buff
	la 	$a0, buf
	li 	$a1, 50
	li 	$v0, 8
	syscall
	
	la 	$s0, digits_buf			# digit_count = 0
	
	# call get_last_char_addr
	la	$a0, buf
	jal	get_last_char_addr
	move	$s1, $v0			# len = get_last_char_addr(buf)
	
	subi	$t0, $s1, 1			# i = len -1
	
loop:	
	lbu 	$t1, ($t0)			# current = buf[i]
	blt	$t1, ' ', after_loop		# if ended iteration, goto after_loop	
	
	blt	$t1, '0', next_char		# if not digit, goto next_char
	bgt	$t1, '9', next_char		# if not digit, goto next_char
	
	sb	$t1, ($s0)			# digits_buf[digit_count] = current
	addi	$s0, $s0, 1			# digit_count++

next_char:
	subi	$t0, $t0, 1
	j loop
	
after_loop:
	la 	$s0, digits_buf			# digit_count = 0
	la	$t0, buf			# i = 0
loop2:
	lbu 	$t1, ($t0)			# current = buf[i]
	blt	$t1, ' ', exit			# if ended iteration, goto exit	
	
	blt	$t1, '0', next_char2		# if not digit, goto next_char2
	bgt	$t1, '9', next_char2		# if not digit, goto next_char2
	
	lbu	$t2, ($s0)			# tmp = digits_buf[digit_count]
	sb	$t2, ($t0)			# buf[i] = tmp
	addi 	$s0, $s0, 1			# digit_count++
	
next_char2:
	addi	$t0, $t0, 1
	j loop2
	
exit:		
	# print buf
	la $a0, buf
	li $a1, 50
	li $v0, 4
	syscall
				
	# exit
	li 	$v0, 10
	syscall
	
get_last_char_addr:
	forloop:
		lbu 	$t0, ($a0)		# current = str[i]
		blt 	$t0, ' ', end_forloop	# if current == '\0' goto end_forloop
		addi 	$a0, $a0, 1		# i++
		j forloop
	end_forloop:
		move	$v0, $a0		
		jr	$ra			# return $a0, pointer to the last character
	
