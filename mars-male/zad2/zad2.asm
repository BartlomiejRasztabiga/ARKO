	.data
buff:	.space 50	

	.text
main:
	# read string to buff
	la 	$a0, buff
	li 	$a1, 50
	li 	$v0, 8
	syscall
	
	la 	$t0, buff			# i = 0
	li	$t4, 0				# largest = 0
	li 	$t5, 0				# current_size = 0
	li 	$t6, 0				# largest_start = 0
	li 	$t7, 0				# largest_end = 0
	
loop:	
	lbu 	$t1, ($t0)			# current = buf[i]
	
	bltu 	$t1, '0', else			# if non digit, goto else
	bgtu	$t1, '9', else			# if non digit, goto else
	
	addiu	$t5, $t5, 1			# if digit, current_size++
	addiu	$t0, $t0, 1			# i++

	j 	loop				# goto loop
	
else:
	bgtu	$t5, $t4, cur_size_gt_larg	# if current_size > largest, goto cur_size_gt_larg

	li 	$t5, 0				# current_size = 0
	addiu	$t0, $t0, 1			# $t0++
	bltu	$t1, ' ', finish		# if null character, goto finish
	j 	loop				# goto loop

cur_size_gt_larg:
	move	$t4, $t5			# largest = current_size
	move 	$t7, $t0			# largest_end = i
	sub	$t6, $t0, $t5			# largest_start = i - current_size
	
	li 	$t5, 0				# current_size = 0
	addiu	$t0, $t0, 1			# $t0++
	bltu	$t1, ' ', finish		# if null character, goto finish
	j 	loop				# goto loop	

finish:
	li	$v0, 11				# print_char syscall setup

print_loop:
	bge	$t6, $t7, exit			# if largest_start > largest_end, goto exit
	
	# print char at $t6
	lbu	$a0, ($t6)
	syscall
	
	addiu	$t6, $t6, 1			# largest_start++
	j print_loop				# goto print_loop
	
exit:				
	# exit
	li 	$v0, 10
	syscall