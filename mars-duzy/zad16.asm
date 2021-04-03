.eqv	BUF_LEN 16 				# MIN 4
.eqv	INPUT_FILE_SIZE 1024
# MAX NUMBER OF LABELS IN FILE IS 128
# MAX NUMBER OF LINES IN FILE IS 999
# MAX SIZE OF FILE IS 1024

        .data  
input_fname:	.asciiz "input.txt"
output_fname:	.asciiz "output.txt"
opnfile_err_txt:.asciiz	"Error while opening the file"
getc_err_txt:	.asciiz	"Error while reading the file"
.align 2					# is 2 correct?
labels:		.space 1536			# labels array for 128 of 4-4-4  max 12-byte labels, 2x address + line number
content:	.space INPUT_FILE_SIZE		# TODO: should I end these 4 with NULL?
output_content:	.space INPUT_FILE_SIZE
buffer: 	.space BUF_LEN
        
        .text
main:
  	jal	read_file
  	bltz	$v0, exit			# if error during read_file, goto exit
	j 	post_read_file			# TODO: delete
	
post_read_file:
	la	$a0, content
	jal	print_str			# call print_str
	jal	replace_labels			# call replace_labels

	j 	post_replace_labels
post_replace_labels:
	jal	write_file
	
						# TODO: delete
	li	$a0, 999
	jal	itoa
	move	$a0, $v0
	jal 	print_str
	
	li	$a0, 1
	jal	itoa
	move	$a0, $v0
	jal 	print_str
	
	j exit
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
#	$s5 - current line of content
#	$s6 - next free space at output_content
# returns: none
replace_labels:
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw	$s1, 4($sp)			# push $s1
	sub	$sp, $sp, 4
	sw	$s2, 4($sp)			# push $s2
	sub	$sp, $sp, 4
	sw	$s3, 4($sp)			# push $s3
	sub	$sp, $sp, 4
	sw	$s4, 4($sp)			# push $s4
	sub	$sp, $sp, 4
	sw	$s5, 4($sp)			# push $s5
	sub	$sp, $sp, 4
	sw	$s6, 4($sp)			# push $s6
	
	la	$s0, labels			# store next free space of labels at $s0
	la	$s1, content			# start of current word
	la	$s2, content			# end of current word
	la	$s3, content			# current char address
	li	$s5, 1				# current line of content
	la	$s6, output_content		# store next free space of output_content
replace_labels_loop:
	lb	$s4, ($s3)			# current char
	beq	$s4, ' ', end_of_word		# if space, goto end_of_word
	beq	$s4, '\n', end_of_line		# if LF, goto end_of_line
	beq	$s4, ':', new_label		# label detected
	beqz	$s4, replace_labels_return	# if NULL goto replace_labels_return
	
	j	next_char			# goto next_char
new_label:
	subiu	$t0, $s2, 1			# get address of last char of label (s2 is ':' char)
						
	sw	$s1, ($s0)			# store start of label
	addiu	$s0, $s0, 4
	sw	$t0, ($s0)			# store end of label
	addiu	$s0, $s0, 4
	sw	$s5, ($s0)			# store label line number
	addiu	$s0, $s0, 4
	
	j 	next_char			# TODO
	
end_of_line:
	addiu	$s5, $s5, 1			# current_line++
	j 	end_of_word			# TODO: delete
end_of_word:
						# TODO: check if found defined symbol, if yes, replace and copy to output_content
	move	$a0, $s1
	move	$a1, $s2
	jal	get_symbol_for_word		# get line number for symbol
	move	$t0, $v0			# store found line number for symbol
	beq	$t0, -1, end_of_word_not_symbol	# if line number == -1, then word is not a symbol, goto end_of_word_not_symbol				
						# TODO: word is a symbol					
						
end_of_word_not_symbol:
						# if word is not a symbol, copy string to output_content
	addiu	$t0, $s2, 1			# end_of_word++ to include whitespace
	move	$a0, $s1			# start of word
	move	$a1, $t0			# end of word
	move	$a2, $s6			# destination : output_content
	jal	copy_src_range_to_dest		# call copy_src_range_to_dest
	move	$s6, $v0			# update next free space of output_content
	
	
	addiu	$s1, $s3, 1			# reset start of current word
	
	j 	next_char			# TODO for now
next_char:
	addiu	$s2, $s2, 1			# end of current word ++
	addiu	$s3, $s3, 1			# next char address
	j	replace_labels_loop		# go back to loop
	
replace_labels_return:
	lw	$s6, 4($sp)			# pop $s6
	add	$sp, $sp, 4	
	lw	$s5, 4($sp)			# pop $s5
	add	$sp, $sp, 4	
	lw	$s4, 4($sp)			# pop $s4
	add	$sp, $sp, 4	
	lw	$s3, 4($sp)			# pop $s3
	add	$sp, $sp, 4	
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
# write_file
# description: 
#	write output_content to output file
# arguments: none
# variables:
#	$s0 - output file descriptor
#	$s1 - number of written chars
#	$s2 - address of output_content
#	$s3 - number of chars left to write
#	$t0 - min of BUF_LEN and $s3
# returns:
#	$v0 - status code, negative if error
write_file:
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw 	$s1, 4($sp)			# push $s1
	sub	$sp, $sp, 4
	sw 	$s2, 4($sp)			# push $s2
	sub	$sp, $sp, 4
	sw 	$s3, 4($sp)			# push $s2

	la	$a0, output_fname		# input file name
	li	$a1, 1				# write only flag
	jal	open_file			# call open_file
  	move	$s0, $v0			# store file descriptor in $s0	
  	bltz	$s0, write_file_open_err	# if eror occured, goto open_file_error
  	la	$s2, output_content		# put address of output_content to $s2
  	
  	move    $a0, $s2			# address of output_content
	jal	str_len				# call str_len
	move	$s3, $v0			# save number of chars in output_content
write_file_loop:
	li	$a0, BUF_LEN
	move	$a1, $s3
	jal	min				# get min of BUF_LEN and num_of_chars_left_to_write
	move	$t0, $v0

	move	$a0, $s0			# file descriptor
	move	$a1, $s2			# output_content start
	move	$a2, $t0			# number of chars to write
  	jal 	putc				# call putc
  	move	$s1, $v0			# store num of written chars in $s1
  	
  	subu	$s3, $s3, $s1			# substract num of written chars from num of chars to write
  	beqz	$s3, write_file_ok		# if num_of_chars_left_to_write == 0, goto write_file_ok
  	beqz	$s1, putc_err			# if num_of_written_chars == 0, goto putc_err, because num_of_chars_left_to_write > 0
  	bltz	$s1, putc_err			# if num_of_written_chars < 0, goto putc_err
  	
  	addu	$s2, $s2, $s1			# move output_content pointer by buffer length	
  	
  	j 	write_file_loop			# go back to write_file_loop
write_file_open_err: 
	la 	$a0, opnfile_err_txt		# load the address into $a0
  	j 	write_file_err
putc_err:
	la 	$a0, getc_err_txt		# load the address into $a0
  	j 	write_file_err
write_file_err:
	jal	print_str			# call print_str
	li	$v0, -1				# set error flag
  	j 	write_file_close		# goto write_file_close
write_file_ok:
	li	$v0, 0				# all good, no error flag set
	j 	write_file_close		# goto write_file_close TODO: delete
write_file_close:
	move	$a0, $s0			# move file descriptor to $a0
  	li 	$v0, 16       			# system call for close file
  	syscall          			# close file
  	
  	j 	write_file_loop_return		# TODO: delete	
write_file_loop_return:
	lw	$s3, 4($sp)			# pop $s3
	add	$sp, $sp, 4			
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

	la	$a0, input_fname		# input file name
	li	$a1, 0				# read only flag
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
	la 	$a0, getc_err_txt		# load the address into $a0
  	j 	read_file_err
read_file_err:
	jal	print_str			# call print_str
	li	$v0, -1				# set error flag
  	j 	read_file_close			# goto read_file_close
read_file_ok:
	li	$v0, 0				# all good, no error flag set
	j 	read_file_close			# goto read_file_close TODO: delete
read_file_close:
	move	$a0, $s0			# move file descriptor to $a0
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
# arguments:
#	$a0 - file name to open
#	$a1 - file open flag
# variables:
#	$a0 - file name to open
#	$a1 - file open flag
# returns:
#	$v0 - opened file descriptor, negative if error
open_file:
	# TODO: delete stack operations if getc is a leaf
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw	$s1, 4($sp)			# push $s1
	
	move	$s0, $a0			# file name to open
	move	$s1, $a1			# file open flag

	li 	$v0, 13       			# system call to open file
  	move 	$a0, $s0			# put file name string to $a0
  	move 	$a1, $s1      			# read_only flag
  	syscall          			# open a file (file descriptor returned in $v0)
  	
  	lw	$s1, 4($sp)
  	add	$sp, $sp, 4			# pop $s1
  	lw	$s0, 4($sp)
  	add	$sp, $sp, 4			# pop $s0
  	lw	$ra, 4($sp)
  	add	$sp, $sp, 4			# pop $ra
  	
  	jr	$ra				# return

# ============================================================================  	
# getc
# description: 
#	reads BUF_LEN bytes from opened file to buffer
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
  	li 	$a2, BUF_LEN       		# buffer length
  	syscall          			# read from file
  	
  	lw	$s0, 4($sp)
  	add	$sp, $sp, 4			# pop $s0
  	lw	$ra, 4($sp)
  	add	$sp, $sp, 4			# pop $ra
  	
  	jr	$ra				# return
  	
# ============================================================================  	
# putc
# description: 
#	writes n bytes from buffer to opened file
# arguments:
#	$a0 - file descriptor
#	$a1 - start of content to write
#	$a2 - number of chars to write
# variables:
#	$s0 - file descriptor
#	$s1 - start of content to write
#	$s2 - number of chars to write
# returns:
#	$v0 - number of characters written, negative if error
putc:
	# TODO: delete stack operations if putc is a leaf
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw	$s1, 4($sp)			# push $s1
	sub	$sp, $sp, 4
	sw	$s2, 4($sp)			# push $s2
	
	move	$s0, $a0			# store file descriptor
	move	$s1, $a1			# store start of content to write
	move	$s2, $a2			# store number of chars to write
	
	li 	$v0, 15       			# system call for write to file
	move 	$a0, $s0    			# put the file descriptor in $a0
  	move 	$a1, $s1   			# address of buffer to read content from
  	move	$a2, $s2      			# number of chars to write
  	syscall          			# write to file
  	
  	lw	$s2, 4($sp)
  	add	$sp, $sp, 4			# pop $s2
  	lw	$s1, 4($sp)
  	add	$sp, $sp, 4			# pop $s1
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
#	#s2 - current char
# returns:
#	$v0 - address of next free char at destination
copy_src_to_dest:				# takes addresses of src and destination as params
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw 	$s1, 4($sp)			# push $s1
	sub	$sp, $sp, 4
	sw 	$s2, 4($sp)			# push $s2

	move	$s0, $a0			# address of src
	move	$s1, $a1			# address of destination
copy_src_loop:
	lb	$s2, ($s0)			# store buffer char in $s2
	beqz	$s2, copy_src_return		# if met end of string, return
	
	sb	$s2, ($s1)			# else, store src char at destination address
	addiu	$s0, $s0, 1			# next src char
	addiu	$s1, $s1, 1			# next destination char
	j copy_src_loop				# if not met end of string, repeat loop
copy_src_return:
	move	$v0, $s1

	lw	$s2, 4($sp)			# pop $s2
	add	$sp, $sp, 4			
	lw	$s1, 4($sp)			# pop $s1
	add	$sp, $sp, 4			
	lw	$s0, 4($sp)			# pop $s0
	add	$sp, $sp, 4			
	lw	$ra, 4($sp)			# pop $ra
	add	$sp, $sp, 4

	jr	$ra				# return new free char address of destination
	
# ============================================================================  	
# TODO: delete if not used
# copy_src_range_to_dest
# description: 
#	copies src string from given range to dest
# arguments:
#	$a0 - src address start
#	$a1 - src address end (won't be copied)
#	$a2 - dest address
# variables:
#	$s0 - src address
#	$s1 - src address end
#	$s2 - dest address
#	$s3 - current char
# returns:
#	$v0 - address of next free char at destination
copy_src_range_to_dest:				# takes addresses of src and destination as params
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw 	$s1, 4($sp)			# push $s1
	sub	$sp, $sp, 4
	sw 	$s2, 4($sp)			# push $s2
	sub	$sp, $sp, 4
	sw 	$s3, 4($sp)			# push $s3

	move	$s0, $a0			# address of src
	move	$s1, $a1			# address of src ending
	move	$s2, $a2			# address of destination
copy_src_range_loop:
	lb	$s3, ($s0)			# store buffer char in $t7
	beq	$s0, $s1, copy_src_range_return	# if met end of range, return
	
	sb	$s3, ($s2)			# else, store src char at destination address
	addiu	$s0, $s0, 1			# next src char
	addiu	$s2, $s2, 1			# next destination char
	j copy_src_range_loop			# if not met end of string, repeat loop
copy_src_range_return:
	move	$v0, $s2
	
	lw	$s3, 4($sp)			# pop $s3
	add	$sp, $sp, 4	
	lw	$s2, 4($sp)			# pop $s2
	add	$sp, $sp, 4	
	lw	$s1, 4($sp)			# pop $s1
	add	$sp, $sp, 4			
	lw	$s0, 4($sp)			# pop $s0
	add	$sp, $sp, 4			
	lw	$ra, 4($sp)			# pop $ra
	add	$sp, $sp, 4

	jr	$ra				# return new free char address of destination

# ============================================================================
# str_len
# description:
#	returns length of string in memory
# arguments:
#	$a0 - string address
# variables:
#	$s0 - string address
#	$s1 - length
# 	$s2 - current char
# returns:
#	$v0 - length of string in bytes
str_len:
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	sub	$sp, $sp, 4
	sw	$s0, 4($sp)			# push $s0
	sub	$sp, $sp, 4
	sw 	$s1, 4($sp)			# push $s1
	sub	$sp, $sp, 4
	sw 	$s2, 4($sp)			# push $s2

	move 	$s0, $a0			# string address
	li	$s1, 0				# length = 0
str_len_loop:
	lb	$s2, ($s0)			# get current char
	beqz	$s2, str_len_return		# if NULL, goto str_len_return

	addiu	$s1, $s1, 1			# if not NULL, length++
str_len_next_char:
	addiu	$s0, $s0, 1			# next char
	j 	str_len_loop

str_len_return:
	move	$v0, $s1

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
# min (LEAF FUNCTION)
# description:
#	returns less of two ints
# arguments:
#	$a0 - first int
#	$a1 - second int
# variables: none
# returns:
#	$v0 - less of two ints
min:
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra

	blt	$a0, $a1, min_first		# if $a0 < $a1, goto min_first
	move	$v0, $a1			# return $a1
	j 	min_return			# TODO: refactor?
min_first:
	move	$v0, $a0			# return $a0
min_return:
	lw	$ra, 4($sp)			# pop $ra
	add	$sp, $sp, 4

	jr	$ra				# return
	
# ============================================================================
# get_symbol_for_word
# description:
#	returns line number for symbol if word is a defined symbol, -1 if not defined
# arguments:
#	$a0 - first int
# variables: none
# returns:
#	$v0 - line number for symbol if word is a defined symbol, -1 if not defined
get_symbol_for_word:
	sub	$sp, $sp, 4
	sw	$ra, 4($sp)			# push $ra
	
get_symbol_for_word_return:
	lw	$ra, 4($sp)			# pop $ra
	add	$sp, $sp, 4
	
	jr 	$ra
	
# ============================================================================
# itoa(LEAF)
# description:
#	moves string representation of given integer to buffer
# arguments:
#	$a0 - int
# variables:none
# returns:
#	$v0 - address of first ascii char of string representation
						# https://stackoverflow.com/questions/20531292/convert-an-int-to-a-string-of-characters
						# maybe already store the string into predefined place in memory?
						# https://stackoverflow.com/questions/2934126/saving-integers-as-strings-in-mips
						# wrong, writes chars right to lef
itoa:
      	la   	$t0, buffer+14 			# pointer to almost-end of buffer, BUF_LEN-2
      	sb   	$zero, 1($t0)      		# null-terminated str
      	li   	$t1, '0'  
      	sb   	$t1, ($t0)     			# init. with ascii 0
      	li   	$t3, 10        			# preload 10

      	beq  	$a0, $0, iend  			# end if 0
loop:
      	div  	$a0, $t3       			# a /= 10
      	mflo 	$a0
      	mfhi 	$t4            			# get remainder
      	add  	$t4, $t4, $t1  			# convert to ASCII digit
      	sb   	$t4, ($t0)     			# store it
      	sub  	$t0, $t0, 1    			# dec. buf ptr
      	bne  	$a0, $0, loop  			# if not zero, loop
      	addi 	$t0, $t0, 1    			# adjust buf ptr
iend:
	move 	$v0, $t0      			# return the addres for first ascii char
      	jr   	$ra