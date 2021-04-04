.eqv	BUF_LEN 512 				# MIN 4
.eqv	INPUT_FILE_SIZE 8192
.eqv	LABELS_SIZE 1536
# MAX NUMBER OF LABELS IN FILE IS 128
# MAX NUMBER OF LINES IN FILE IS 999
# MAX SIZE OF FILE IS 8192
# PROGRAM DOESN'T SUPPORT DUPLICATED LABEL DEFINITIONS

# PASS INPUT FILE NAME AS PROGRAM ARGUMENT

        .data  
output_fname:	.asciiz "output.txt"
opnfile_err_txt:.asciiz	"Error while opening the file"
getc_err_txt:	.asciiz	"Error while reading the file"
.align 2
labels:		.space LABELS_SIZE		# labels array for 128 of 4-4-4  max 12-byte labels, 2x address + line number
content:	.space INPUT_FILE_SIZE
output_content:	.space INPUT_FILE_SIZE
buffer: 	.space BUF_LEN
        
        .text
main:
	beqz	$a0, exit			# no filename provided
				
	lw	$a0, ($a1)			# load argv

  	jal	read_file			# read input file to content
  	bltz	$v0, exit			# if error during read_file, goto exit
  	
	jal	replace_labels			# replace labels in output_content
	
	jal	write_file			# write output_content to output file
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
#	$s5 - current line number of input file
#	$s6 - next free space at output_content
# returns: none
replace_labels:
	sub	$sp, $sp, 32
	sw	$ra, 32($sp)			# push $ra
	sw	$s0, 28($sp)			# push $s0
	sw	$s1, 24($sp)			# push $s1
	sw	$s2, 20($sp)			# push $s2
	sw	$s3, 16($sp)			# push $s3
	sw	$s4, 12($sp)			# push $s4
	sw	$s5, 8($sp)			# push $s5
	sw	$s6, 4($sp)			# push $s6
	
	la	$s0, labels			# store next free space of labels at $s0
	la	$s1, content			# start of current word
	la	$s2, content			# end of current word
	la	$s3, content			# current char address
	li	$s5, 1				# current line of content
	la	$s6, output_content		# store next free space of output_content
replace_labels_loop:
	lb	$s4, ($s3)			# load current char
	beq	$s4, ' ', end_of_word		# if space, goto end_of_word
	beq	$s4, '\t', end_of_word		# if tab, goto end_of_word
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
	
	j 	next_char
end_of_line:
	addiu	$s5, $s5, 1			# current_line++
end_of_word:					
	move	$a0, $s1			# check if found defined symbol, if yes, replace and copy to output_content
	move	$a1, $s2
	jal	get_symbol_for_word		# get line number for symbol
	move	$t0, $v0			# store found line number for symbol
	beq	$t0, -1, end_of_word_not_symbol	# if line number == -1, then word is not a symbol, goto end_of_word_not_symbol
end_of_word_symbol:
	move 	$a0, $t0
	jal	itoa				# address of string representation of line number
	move	$t0, $v0			# store address in $t0
	
	move	$a0, $t0			# source for copy
	move	$a1, $s6			# dest for copy
	jal	copy_src_to_dest		# copy string representation to output_content
	move	$s6, $v0			# update next free space of output_content
	
	lb	$t0, ($s2)			# get last char of current word (LF or space)
	sb	$t0, ($s6)			# store space or LF of the current word to output
	addiu	$s6, $s6, 1			# increment output_content pointer
	
	addiu	$s1, $s3, 1			# reset start of current word
	
	j	next_char				
end_of_word_not_symbol:
						# if word is not a symbol, copy string to output_content
	addiu	$t0, $s2, 1			# end_of_word++ to include whitespace
	move	$a0, $s1			# start of word
	move	$a1, $t0			# end of word
	move	$a2, $s6			# destination : output_content
	jal	copy_src_range_to_dest		# call copy_src_range_to_dest
	move	$s6, $v0			# update next free space of output_content
	
	addiu	$s1, $s3, 1			# reset start of current word
next_char:
	addiu	$s2, $s2, 1			# end of current word ++
	addiu	$s3, $s3, 1			# next char address
	j	replace_labels_loop		# go back to loop
replace_labels_return:
	lw	$s6, 4($sp)			# pop $s6
	lw	$s5, 8($sp)			# pop $s5
	lw	$s4, 12($sp)			# pop $s4
	lw	$s3, 16($sp)			# pop $s3
	lw	$s2, 20($sp)			# pop $s2
	lw	$s1, 24($sp)			# pop $s1
	lw	$s0, 28($sp)			# pop $s0
	lw	$ra, 32($sp)			# pop $ra
	add	$sp, $sp, 32

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
	sub	$sp, $sp, 20
	sw	$ra, 20($sp)			# push $ra
	sw	$s0, 16($sp)			# push $s0
	sw 	$s1, 12($sp)			# push $s1
	sw 	$s2, 8($sp)			# push $s2
	sw 	$s3, 4($sp)			# push $s3

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
write_file_err:
	jal	print_str			# call print_str
	li	$v0, -1				# set error flag
  	j 	write_file_close		# goto write_file_close
write_file_ok:
	li	$v0, 0				# all good, no error flag set
write_file_close:
	move	$a0, $s0			# move file descriptor to $a0
  	li 	$v0, 16       			# system call for close file
  	syscall          			# close file
write_file_loop_return:
	lw	$s3, 4($sp)			# pop $s3		
	lw	$s2, 8($sp)			# pop $s2		
	lw	$s1, 12($sp)			# pop $s1			
	lw	$s0, 16($sp)			# pop $s0			
	lw	$ra, 20($sp)			# pop $ra
	add	$sp, $sp, 20

	jr	$ra				# return	
	
# ============================================================================  	
# read_file (LEAF)
# description: 
#	reads file to content buffer
# arguments: 
#	$a0 - pointer to string containing input file name
# variables:
#	$s0 - input file descriptor
#	$s1 - number of read chars
#	$s2 - address of next free char at content
# returns:
#	$v0 - status code, negative if error
read_file:
	sub	$sp, $sp, 16
	sw	$ra, 16($sp)			# push $ra
	sw	$s0, 12($sp)			# push $s0
	sw 	$s1, 8($sp)			# push $s1
	sw 	$s2, 4($sp)			# push $s2

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
  	bltz	$s1, getc_err			# if num_of_read_chars < 0, goto getc_err

	la	$a0, buffer			# put address of buffer to $a0, prepare for call
	move	$a1, $s2			# put address of content to $a1, prepare for call
	jal	copy_src_to_dest		# call copy_buffer_to_dest
	move	$s2, $v0			# store address of next free char at content
	
	jal	clear_buffer			# call clear_buffer, TODO: NEEDS TO BE CALLED ONLY IN THE LAST BUFFER READ - less than buffer length chars read		
  	
  	j 	read_file_loop			# go back to read_file_loop
open_file_err: 
	la 	$a0, opnfile_err_txt		# load the address into $a0
  	j 	read_file_err
getc_err:
	la 	$a0, getc_err_txt		# load the address into $a0
read_file_err:
	jal	print_str			# call print_str
	li	$v0, -1				# set error flag
  	j 	read_file_close			# goto read_file_close
read_file_ok:
	li	$v0, 0				# all good, no error flag set
read_file_close:
	move	$a0, $s0			# move file descriptor to $a0
  	li 	$v0, 16       			# system call for close file
  	syscall          			# close file
read_file_loop_return:
	lw	$s2, 4($sp)			# pop $s2		
	lw	$s1, 8($sp)			# pop $s1			
	lw	$s0, 12($sp)			# pop $s0			
	lw	$ra, 16($sp)			# pop $ra
	add	$sp, $sp, 16

	jr	$ra				# return
  	
# ============================================================================  	
# open_file (LEAF)
# description: 
#	opens file and returns file descriptor
# arguments:
#	$a0 - file name to open
#	$a1 - file open flag
# variables: none
# returns:
#	$v0 - opened file descriptor, negative if error
open_file:
	li 	$v0, 13       			# system call to open file
  	syscall          			# open a file (file descriptor returned in $v0)

  	jr	$ra				# return

# ============================================================================  	
# getc (LEAF)
# description: 
#	reads BUF_LEN bytes from opened file to buffer
# arguments:
#	$a0 - file descriptor
# variables: none
# returns:
#	$v0 - number of characters read, 0 if end-of-file, negative if error
getc:
	li 	$v0, 14       			# system call for read to file
  	la 	$a1, buffer   			# address of buffer to store file content
  	li 	$a2, BUF_LEN       		# buffer length
  	syscall          			# read from file

  	jr	$ra				# return
  	
# ============================================================================  	
# putc (LEAF)
# description: 
#	writes n bytes from buffer to opened file
# arguments:
#	$a0 - file descriptor
#	$a1 - start of content to write
#	$a2 - number of chars to write
# variables: none
# returns:
#	$v0 - number of characters written, negative if error
putc:
	li 	$v0, 15       			# system call for write to file
  	syscall          			# write to file
  	
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
# clear_buffer (LEAF)
# description: 
#	clears buffer by setting all bytes to /0
# arguments: none
# variables:
#	$t0 - address of buffer to clear
#	$t1 - current char of buffer
# returns: none
clear_buffer:
	la	$t0, buffer			# load the address of buffer into $s0
clear_buffer_loop:
	lbu	$t1, ($t0)			# store char in $s1
	beqz 	$t1, clear_buffer_return	# if met end of string, return
	
	sb	$zero, ($t0)			# else, store 0 at current char address
	addiu	$t0, $t0, 1			# next char
	j	clear_buffer_loop		# if not met end of string, repeat loop
clear_buffer_return:
	jr	$ra				# return
	
# ============================================================================  	
# copy_src_to_dest (LEAF)
# description: 
#	copies src string to dest
# arguments:
#	$a0 - src address
#	$a1 - dest address
# variables:
#	#t0 - current char
# returns:
#	$v0 - address of next free char at destination
copy_src_to_dest:
	lb	$t0, ($a0)			# store buffer char in $t0
	beqz	$t0, copy_src_return		# if met end of string, return
	
	sb	$t0, ($a1)			# else, store src char at destination address
	addiu	$a0, $a0, 1			# next src char
	addiu	$a1, $a1, 1			# next destination char
	j copy_src_to_dest			# if not met end of string, repeat loop
copy_src_return:
	move	$v0, $a1
	jr	$ra				# return new free char address of destination
	
# ============================================================================
# copy_src_range_to_dest (LEAF)
# description: 
#	copies src string from given range to dest
# arguments:
#	$a0 - src address start
#	$a1 - src address end (won't be copied)
#	$a2 - dest address
# variables:
#	$t0 - current char
# returns:
#	$v0 - address of next free char at destination
copy_src_range_to_dest:
	lb	$t0, ($a0)			# store buffer char in $t0
	beq	$a0, $a1, copy_src_range_return	# if met end of range, return
	
	sb	$t0, ($a2)			# else, store src char at destination address
	addiu	$a0, $a0, 1			# next src char
	addiu	$a2, $a2, 1			# next destination char
	j copy_src_range_to_dest		# if not met end of string, repeat loop
copy_src_range_return:
	move	$v0, $a2
	jr	$ra				# return new free char address of destination

# ============================================================================
# str_len (LEAF)
# description:
#	returns length of string in memory
# arguments:
#	$a0 - string address
# variables:
#	$t0 - string address
#	$t1 - length
# 	$t2 - current char
# returns:
#	$v0 - length of string in bytes
str_len:
	move 	$t0, $a0			# string address
	li	$t1, 0				# length = 0
str_len_loop:
	lb	$t2, ($t0)			# get current char
	beqz	$t2, str_len_return		# if NULL, goto str_len_return
	addiu	$t1, $t1, 1			# if not NULL, length++
str_len_next_char:
	addiu	$t0, $t0, 1			# next char
	j 	str_len_loop
str_len_return:
	move	$v0, $t1
	jr	$ra
	
# ============================================================================
# min (LEAF)
# description:
#	returns less of two ints
# arguments:
#	$a0 - first int
#	$a1 - second int
# variables: none
# returns:
#	$v0 - less of two ints
min:
	blt	$a0, $a1, min_first		# if $a0 < $a1, goto min_first
	move	$v0, $a1			# return $a1
	j 	min_return			# TODO: refactor?
min_first:
	move	$v0, $a0			# return $a0
min_return:
	jr	$ra				# return
	
# ============================================================================
# get_symbol_for_word (LEAF)
# description:
#	returns line number for symbol if word is a defined symbol, -1 if not defined
# arguments:
#	$a0 - address of first char of word
#	$a1 - address of last char of word
# variables:
#	$t0 - address of labels
#	$t1 - address of label's start string
#	$t2 - address of label's end string
#	$t3 - current label's char
#	$t4 - current word's char
#	$t5 - pointer for current label section
#	$t6 - flag if label has ended
#	$t7 - flag if word has ended
# returns:
#	$v0 - line number for symbol if word is a defined symbol, -1 if not defined
get_symbol_for_word:	
	la	$t0, labels			# first label pointer
	move	$t5, $a0			# store $a0 in $t5
get_symbol_for_word_loop:
	lw	$t1, ($t0)			# get start address of label
	beqz	$t1, symbol_not_found		# if label's start is NULL, there is no label = symbol_not_found
	lw	$t2 4($t0)			# get end address of label
compare_word:
	sgt	$t6, $t1, $t2			# if label has ended
	sge	$t7, $t5, $a1			# if word has ended
	and	$t6, $t6, $t7
	beq	$t6, 1, symbol_found		# if label ended AND word has ended, symbol_found
	bgt	$t1, $t2, compare_word_not_equal# if label has ended BUT word has not ended, try next label
	
	lb	$t3, ($t1)			# load label's char
	lb	$t4, ($t5)			# load word's char
	
	bne	$t3, $t4, compare_word_not_equal# if label's char != word's char, symbol not found, try next label
	addiu	$t1, $t1, 1			# next label's char
	addiu	$t5, $t5, 1			# next word's char
	j compare_word
compare_word_not_equal:	
	addiu	$t0, $t0, 12			# next label
	move	$t5, $a0			# reset word's pointer
	j 	get_symbol_for_word_loop
symbol_not_found:
	li	$v0, -1				# set 'symbol not found' flag
	j 	get_symbol_for_word_return
symbol_found:
	addiu	$t0, $t0, 8			# move to v0 address of label's line number
	lw	$v0, ($t0)			# load line number as return value
get_symbol_for_word_return:
	jr 	$ra
	
# ============================================================================
# itoa (LEAF)
# description:
#	moves string representation of given integer to buffer
# arguments:
#	$a0 - int
# variables:
# 	$t0 - pointer to place for the next char
#	$t1 - '0' char
#	$t2 - '10' int
#	$t3 - digit as ascii
# returns:
#	$v0 - address of first ascii char of string representation
itoa:
      	la   	$t0, buffer+14 			# pointer to almost-end of buffer, BUF_LEN-2
      	sb   	$zero, 1($t0)      		# null-terminated str
      	li   	$t1, '0'  
      	sb   	$t1, ($t0)     			# init. with ascii 0
      	li   	$t2, 10        			# load 10

      	beq  	$a0, $0, itoa_return  		# end if number is 0
itoa_loop:
      	div  	$a0, $t2       			# a /= 10
      	mflo 	$a0
      	mfhi 	$t3            			# get remainder
      	add  	$t3, $t3, $t1  			# convert to ASCII digit
      	sb   	$t3, ($t0)     			# store it
      	sub  	$t0, $t0, 1    			# decrement buffer pointer
      	bne  	$a0, $0, itoa_loop  			# if not zero, loop
itoa_return:
	addi 	$t0, $t0, 1    			# adjust buffer pointer
	move 	$v0, $t0      			# return the addres for first ascii char
      	jr   	$ra
