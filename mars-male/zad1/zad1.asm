	.data
buff:	.space 50	

	.text
main:
	# read string to buf
	la 	$a0, buff
	li 	$a1, 50
	li 	$v0, 8
	syscall
	
	la 	$t0, buff		# read buff first character address to $t0
	la	$t3, 105		# $t3 = 105
	
loop:	
	lbu 	$t1, ($t0)		# read char from $t0 to $t1
	
	beqz	$t1, exit		# if null character, goto exit
	bltu 	$t1, '0', next_char	# if non digit, goto next_char
	bgtu	$t1, '9', next_char	# if non digit, goto next_char
	
	# if digit
	subu	$t2, $t3, $t1		# $t2 = 105 - $t1 (current char); calculate 9's complement
	sb	$t2, ($t0)		# $t0 = $t2
	
next_char:
	addiu	$t0, $t0, 1		# $t0++
	b 	loop			# goto loop
	
		
exit:		
	# print string
	la 	$a0, buff
	li 	$v0, 4
	syscall
		
		
	# exit
	la 	$v0, 10
	syscall