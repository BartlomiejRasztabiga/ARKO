	.data
prompt:	.asciiz	"Enter a string: "
buf:	.space 80

	.text
main:
	la 	$a0, prompt
	li	$v0, 4
	syscall

fin:	
	li $v0, 10
	syscall
	
