        .data
file_name:
	.asciiz "input.txt"
	
open_file_error_txt:
	.asciiz	"Error while opening the file"
	
read_file_error_txt:
	.asciiz	"Error while reading the file"
	
mapping:					# mapping 2d array for 100 of max 32-chars labels
	.space 3200
	
content:
	.space 3200	
	
buffer: 
	.space 16
        
        .text
						# main flow:

main:
  	jal	open_file			# call open_file
  	move	$t0, $v0			# store file descriptor in $t0	
  	bltz	$t0, open_file_error		# if eror occured, goto open_file_error
  	la	$s7, content			# put address of content to $s7

read_file_loop:
  	jal 	getc				# call getc
  	move	$t1, $v0			# store num of read chars in $t1
  	beqz	$t1, post_read_file_loop	# if num_of_read_chars == 0, goto post_read_file_loop
  	bltz	$t1, read_file_error		# if num_of_read_chars < 0, goto read_file_error

	j 	handle_buffer
	
handle_buffer:
	move	$a0, $s7			# put address of content to $a0, prepare for call
	jal	copy_buffer_to_dest		# call copy_buffer_to_dest
	move	$s7, $v0			# store address of next free char at content
	
	jal	clear_buffer			# call clear_buffer, 					TODO: NEEDS TO BE CALLED ONLY IN THE LAST BUFFER READ - less than buffer length chars read		
  	
  	j 	read_file_loop			# go back to read_file_loop
  	


post_read_file_loop:
	jal	print_content			# call print_content	
	j 	close_file
	
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
  	li 	$a2, 16       			# buffer length
  	move 	$a0, $t0    			# put the file descriptor in $a0		
  	syscall          			# read from file
  	jr	$ra				# returns number of characters read (0 if end-of-file, negative if error).
  	
print_buffer:
  	la 	$a0, buffer 			# load the address into $a0
  	li 	$v0, 4				# print the string out
  	syscall
  	
  	jr 	$ra				# return
  	
print_content:
  	la 	$a0, content			# load the address into $a0
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
	j	clear_buffer_loop		# if not met end of string, repeat loop
clear_buffer_return:
	jr	$ra				# return

		
copy_buffer_to_dest:				# takes address of destination as param
	la	$t8, buffer			# address of buffer
	move	$t9, $a0			# address of destination
copy_buffer_loop:
	lb	$t7, ($t8)			# store buffer char in $t7
	beqz	$t7, copy_buffer_return		# if met end of string, return
	
	sb	$t7, ($t9)			# else, store buffer char at destination address
	addiu	$t8, $t8, 1			# next buffer char
	addiu	$t9, $t9, 1			# next destination char
	j copy_buffer_loop			# if not met end of string, repeat loop
copy_buffer_return:
	move	$v0, $t9
	jr	$ra				# return new free char address of destination

  
