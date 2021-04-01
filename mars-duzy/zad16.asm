.eqv	INPUT_BUF_LEN 16
.eqv	INPUT_FILE_SIZE 1024

        .data  
file_name:	.asciiz "input.txt"
opnfile_err_txt:.asciiz	"Error while opening the file"
getc_err_txt:	.asciiz	"Error while reading the file"
labels:		.space 1600			# labels array for 100 of 4-4-8  max 16-byte labels, 2x address + line number
content:	.space INPUT_FILE_SIZE
output_content:	.space INPUT_FILE_SIZE
buffer: 	.space INPUT_BUF_LEN
        
        .text
main:
  	jal	read_file
  	bltz	$v0, exit			# if error during read_file, goto exit
	j 	post_read_file			# TODO: delete
	
post_read_file:
	la	$a0, content
	jal	print_str			# call print_str
	jal	replace_labels			# call replace_labels

	j 	exit
exit:
	li 	$v0, 10
  	syscall
  	
# ============================================================================  	
# replace_labels
# description: 
#	replaces labels in content with appropriate line numbers
# arguments: none
# variables:
#	$s0 - next free space at labels
#	$s1 - start of current word
#	$s2 - end of current word
#	$s3 - current char address
#	$s4 - current char
# returns: none
replace_labels:
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	
	la	$s0, labels			# store next free space of labels at $s0
	la	$s1, content			# start of current word
	la	$s2, content			# end of current word
	la	$s3, content			# current char address
replace_labels_loop:
	lb	$s4, ($s3)			# current char
	beq	$s4, ' ', end_of_word		# if space, goto end_of_word
	beq	$s4, '\n', end_of_word		# if LF, goto end_of_word 
	beqz	$s4, replace_labels_return	# if NULL goto replace_labels_return
	
	j	next_char			# goto next_char
end_of_word:
	j 	next_char			# TODO for now
next_char:
	addiu	$s3, $s3, 1			# next char address
	j	replace_labels_loop		# go back to loop
	
replace_labels_return:		
	lw	$s0, 4($sp)			# pop $s0
	add	$sp, $sp, 4			
	lw	$ra, 4($sp)			# pop $ra
	add	$sp, $sp, 4

	jr	$ra				# return	
	
# ============================================================================  	
# read_file
# description: 
#	reads file to content buffer
# arguments: none
# variables:
#	$s0 - input file descriptor
#	$s1 - number of read chars
#	$s2 - address of next free char at content
# returns:
#	$v0 - status code, negative if error
read_file:
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw 	$s1, 4($sp)			# push $s1
	sub	$sp, $sp, 4
	sw 	$s2, 4($sp)			# push $s2

	jal	open_file			# call open_file
  	move	$s0, $v0			# store file descriptor in $s0	
  	bltz	$s0, open_file_err		# if eror occured, goto open_file_error
  	la	$s2, content			# put address of content to $s2
read_file_loop:
	move	$a0, $s0			# prepare for call getc
  	jal 	getc				# call getc
  	move	$s1, $v0			# store num of read chars in $s1
  	
  	beqz	$s1, read_file_ok		# if num_of_read_chars == 0, goto read_file_ok
  	bltz	$s1, getc_err			# if num_of_read_chars < 0, goto read_file_error

	la	$a0, buffer			# put address of buffer to $a0, prepare for call
	move	$a1, $s2			# put address of content to $a1, prepare for call
	jal	copy_src_to_dest		# call copy_buffer_to_dest
	move	$s2, $v0			# store address of next free char at content
	
	jal	clear_buffer			# call clear_buffer 					TODO: NEEDS TO BE CALLED ONLY IN THE LAST BUFFER READ - less than buffer length chars read		
  	
  	j 	read_file_loop			# go back to read_file_loop
open_file_err: 
	la 	$a0, opnfile_err_txt		# load the address into $a0
  	j 	read_file_err
getc_err:
	la 	$a0, getc_err_txt	# load the address into $a0
  	j 	read_file_err
read_file_err:
	jal	print_str			# call print_str
	li	$v0, -1				# set error flag
  	j 	close_file			# goto close_file
read_file_ok:
	li	$v0, 0				# all good, no error flag set
	j 	close_file			# goto close_file TODO: delete
close_file:
  	li 	$v0, 16       			# system call for close file
  	syscall          			# close file
  	
  	j 	read_file_loop_return		# TODO: delete	
read_file_loop_return:
	lw	$s2, 4($sp)			# pop $s2
	add	$sp, $sp, 4			
	lw	$s1, 4($sp)			# pop $s1
	add	$sp, $sp, 4			
	lw	$s0, 4($sp)			# pop $s0
	add	$sp, $sp, 4			
	lw	$ra, 4($sp)			# pop $ra
	add	$sp, $sp, 4

	jr	$ra				# return
  	
# ============================================================================  	
# open_file
# description: 
#	opens file and returns file descriptor
# arguments: none
# variables: none
# returns:
#	$v0 - opened file descriptor, negative if error
open_file:
	# TODO: delete stack operations if getc is a leaf
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra

	li 	$v0, 13       			# system call to open file
  	la 	$a0, file_name			# put file name string to $a0
  	li 	$a1, 0        			# read_only flag
  	syscall          			# open a file (file descriptor returned in $v0)
  	
  	lw	$ra, 4($sp)
  	add	$sp, $sp, 4			# pop $ra
  	
  	jr	$ra				# return

# ============================================================================  	
# getc
# description: 
#	reads INPUT_BUF_LEN bytes from open file to buffer
# arguments:
#	$a0 - file descriptor
# variables:
#	$s0 - file descriptor
# returns:
#	$v0 - number of characters read, 0 if end-of-file, negative if error
getc:
	# TODO: delete stack operations if getc is a leaf
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	
	move	$s0, $a0			# store file descriptor as local variable
	
	li 	$v0, 14       			# system call for read to file
	move 	$a0, $s0    			# put the file descriptor in $a0
  	la 	$a1, buffer   			# address of buffer to store file content
  	li 	$a2, INPUT_BUF_LEN       	# buffer length
  	syscall          			# read from file
  	
  	lw	$s0, 4($sp)
  	add	$sp, $sp, 4			# pop $s0
  	lw	$ra, 4($sp)
  	add	$sp, $sp, 4			# pop $ra
  	
  	jr	$ra				# return
  		
# ============================================================================  	
# print_str
# description: 
#	prints string given in $a0
# arguments:
#	$a0 - address of string to print
# variables: none
# returns: none
print_str:
  	li 	$v0, 4				# print the string out
  	syscall
  	
  	jr 	$ra				# return
  	
 
# ============================================================================  	
# clear_buffer
# description: 
#	clears buffer by setting all bytes to /0
# arguments: none
# variables:
#	$s0 - address of buffer to clear
#	$s1 - current char of buffer
# returns: none
clear_buffer:
	# TODO: delete stack operations if clear_buffer is a leaf
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw	$s1, 4($sp)			# push $s1

	la	$s0, buffer			# load the address of buffer into $s0
clear_buffer_loop:
	lbu	$s1, ($s0)			# store char in $s1
	beqz 	$s1, clear_buffer_return	# if met end of string, return
	
	sb	$zero, ($s0)			# else, store 0 at current char address
	addiu	$s0, $s0, 1			# next char
	j	clear_buffer_loop		# if not met end of string, repeat loop
clear_buffer_return:
	lw	$s1, 4($sp)
  	add	$sp, $sp, 4			# pop $s1
	lw	$s0, 4($sp)
  	add	$sp, $sp, 4			# pop $s0
  	lw	$ra, 4($sp)
  	add	$sp, $sp, 4			# pop $ra

	jr	$ra				# return

	
# ============================================================================  	
# copy_src_to_dest
# description: 
#	copies src string to dest
# arguments:
#	$a0 - src address
#	$a1 - dest address
# variables:
#	$s0 - src address
#	$s1 - dest address
# returns:
#	$v0 - address of next free char at destination
copy_src_to_dest:				# takes addresses of src and destination as params
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw 	$s1, 4($sp)			# push $s1

	move	$s0, $a0			# address of src
	move	$t9, $a1			# address of destination
copy_src_loop:
	lb	$t7, ($s0)			# store buffer char in $t7
	beqz	$t7, copy_src_return		# if met end of string, return
	
	sb	$t7, ($t9)			# else, store src char at destination address
	addiu	$s0, $s0, 1			# next src char
	addiu	$t9, $t9, 1			# next destination char
	j copy_src_loop				# if not met end of string, repeat loop
copy_src_return:
	lw	$s1, 4($sp)			# pop $s1
	add	$sp, $sp, 4			
	lw	$s0, 4($sp)			# pop $s0
	add	$sp, $sp, 4			
	lw	$ra, 4($sp)			# pop $ra
	add	$sp, $sp, 4

	move	$v0, $t9
	jr	$ra				# return new free char address of destination
