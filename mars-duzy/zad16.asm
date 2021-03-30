        .data
file_name:
	.asciiz "input.txt"
	
open_file_error_txt:
	.asciiz	"Error while opening the file"
	
read_file_error_txt:
	.asciiz	"Error while reading the file"
	
buffer: 
	.space 10
        
        .text
						# main flow:
main:
  	jal	open_file			# call open_file
  	move	$t0, $v0			# store file descriptor in $t0	
  	bltz	$t0, open_file_error		# if eror occured, goto open_file_error

read_file_loop:
  	jal 	getc				# call getc
  	move	$t1, $v0			# store num of read chars in $t1
  	beqz	$t1, post_read_file_loop	# if num_of_read_chars == 0, goto post_read_file_loop
  	bltz	$t1, read_file_error		# if num_of_read_chars < 0, goto read_file_error

	j 	handle_buffer
	
handle_buffer:
	jal	print_buffer			# call print_buffer
	jal	clear_buffer			# call clear_buffer
  	
  	j 	read_file_loop			# go back to read_file_loop

post_read_file_loop:
						# TODO ADD LOGIC
	j close_file
	
close_file:
						# Close the file 
  	li 	$v0, 16       			# system call for close file
  	syscall          			# close file
  	
  	j 	exit

exit:
	li 	$v0, 10
  	syscall

						# UTILITY METHODS:
					
open_file_error: 
	la 	$a0, open_file_error_txt	# load the address into $a0
  	li 	$v0, 4				# print the string out
  	syscall

  	j close_file				# goto close_file
  	
read_file_error: 
	la 	$a0, read_file_error_txt	# load the address into $a0
  	li 	$v0, 4				# print the string out
  	syscall

  	j close_file				# goto close_file
  	
  						# UTILITY METHODS WITH JUMP_REGISTER ONLY:
  	
open_file:					# no args
	li 	$v0, 13       			# system call to open file
  	la 	$a0, file_name			# put file name string to $a0
  	li 	$a1, 0        			# read_only flag
  	syscall          			# open a file (file descriptor returned in $v0)
  	jr	$ra				# returns file descriptor in $v0 (negative if error)
	
getc:						# no args
	li 	$v0, 14       			# system call for read to file
  	la 	$a1, buffer   			# address of buffer to store file content
  	li 	$a2, 10       			# buffer length
  	move 	$a0, $t0    			# put the file descriptor in $a0		
  	syscall          			# read from file
  	jr	$ra				# returns number of characters read (0 if end-of-file, negative if error).
  	
print_buffer:
  	la 	$a0, buffer 			# load the address into $a0
  	li 	$v0, 4				# print the string out
  	syscall
  	
  	jr 	$ra				# return


clear_buffer:
	la	$t8, buffer			# load the address of buffer into $t8
clear_buffer_loop:
	lbu	$t9, ($t8)			# store char in $t9
	beqz 	$t9, clear_buffer_return	# if met end of string, return
	
	sb	$zero, ($t8)			# else, store 0 at current char address
	addiu	$t8, $t8, 1			# next char
	j	clear_buffer_loop		# if not met end of string
clear_buffer_return:
	jr	$ra				# return
  