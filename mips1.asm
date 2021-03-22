	.data
prompt:	.asciiz	"Enter a string: "
result:	.asciiz	"The result is: "
lenmsg:	.asciiz	"\nResult length: "
buf:	.space 80

	.text
main:
	la 	$a0, prompt
	li	$v0, 4
	syscall
	
	la	$a0, buf
	li	$a1, 80
	li	$v0, 8
	syscall
	
	la	$t0, buf	# source
	move	$t1, $t0	# destination
	
nextchar:
	lbu	$t2, ($t0)	# grab the character at address in $t0 and put in $t2
	addiu	$t0, $t0, 1	# increment $t0
	bltu	$t2, ' ', fin	# if value of $t2 smaller than value of ' ' jump to fin
	bltu	$t2, '0', copy
	bleu	$t2, '9', nextchar
copy:
	sb	$t2, ($t1)
	addiu	$t1, $t1, 1
	b	nextchar

fin:	
	sb	$zero, ($t1)
	
	la 	$a0, result
	li	$v0, 4
	syscall
	
	la 	$a0, buf
	li	$v0, 4
	syscall
	
	la 	$a0, lenmsg
	li	$v0, 4
	syscall
	
	la	$a0, buf	
	subu	$a0, $t1, $a0
	li	$v0, 1		# 1 is the code for print int
	syscall
	
	li $v0, 10
	syscall
	