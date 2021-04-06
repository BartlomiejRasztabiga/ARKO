						# MAX NUMBER OF LABELS IN FILE IS 128 (can be changed by modifying LABELS_SIZE)
						# MAX NUMBER OF LINES IN FILE IS 999 (3 bytes for line number as a string)
						# MAX SIZE OF FILE CAN BE SET BY PROGRAM ARGUMENTS
						# PROGRAM DOESN'T SUPPORT DUPLICATED LABEL DEFINITIONS
						# PASS 'INPUT FILE NAME' AND 'INPUT FILE LENGTH +1' AS PROGRAM ARGUMENT
						# MAX LENGTH OF LABEL IS 50 CHARS

.eqv	BUF_LEN 8 				# MIN 4, USED FOR CONVERTING INTS TO STRINGS
.eqv 	ITOA_BUF_LEN 16
.eqv	WORD_BUF_LEN 48
.eqv	LABELS_SIZE 5200			# TODO: dynamic

        .data  
output_fname:	.asciiz "output.txt"
opnfile_err_txt:.asciiz	"Error while opening the file"
read_err_txt:	.asciiz	"Error while reading the file"
write_err_txt:	.asciiz	"Error while writing the file"
.align 2
labels:			.space LABELS_SIZE		# labels array for 100 labels 48chars+line number (48-4)
content:		.space 4
output_content:		.space 4
itoa_buffer: 		.space ITOA_BUF_LEN
getc_buffer: 		.space BUF_LEN
getc_buffer_pointer:	.space 4
getc_buffer_chars:	.word 0
putc_buffer: 		.space BUF_LEN
putc_buffer_pointer:	.space 4
putc_buffer_chars:	.word BUF_LEN
input_file_descriptor:	.space 4
output_file_descriptor:	.space 4
word_buffer:		.space WORD_BUF_LEN
        
        .text
main:
	blt	$a0, 1, exit			# not enough arguments provided, argc < 2, TODO: add error string
allocate_memory:
	#li	$a0, LABELS_SIZE
	#li	$v0, 9
	#syscall				# allocate memory for labels
	#la	$s1, labels			# store address of labels
	#sw	$v0, ($s1)			# move allocated memory address to labels
process_file:
	lw	$a0, ($a1)			# load input file name
	li	$a1, 0				# read only flag
	la	$a3, input_file_descriptor
	jal	open_file			# call open_file
	bltz	$v0, exit			# if error during open_file, goto exit
	
	la	$a0, output_fname		# load output file name
	li	$a1, 1				# write only flag
	la	$a3, output_file_descriptor
	jal	open_file			# call open_file
	bltz	$v0, exit			# if error during open_file, goto exit
						# prepare putc buffer for future calls
	la	$t0, putc_buffer		# load address of putc_buffer
	sw	$t0, putc_buffer_pointer	# store new buffer_pointer

	jal	replace_labels			# replace labels in output_content
exit:
	jal	flush_buffer			# flush buffer

	li 	$v0, 10
  	syscall
  	
# ============================================================================  	
# replace_labels
# description: 
#	replaces labels in content with appropriate line numbers
# arguments: none
# variables:
#	$s0 - next free space at labels
#	$s1 - current char
#	$s2 - current line number of input file
#	$s3 - pointer to word buffer
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
	li	$s2, 1				# current line of content
	la	$s3, word_buffer		# load pointer to buffer
replace_labels_loop:
	jal	getc
	move	$s1, $v0			# load current char
	sb	$s1, ($s3)			# store current char at buffer pointer
	
	beq	$s1, ' ', end_of_word		# if space, goto end_of_word
	beq	$s1, '\t', end_of_word		# if tab, goto end_of_word
	beq	$s1, '\n', end_of_line		# if LF, goto end_of_line
	beq	$s1, ':', new_label		# label detected
	bltz	$s1, replace_labels_return	# if -1 (EOF) or NULL, goto replace_labels_return
	
	addiu	$s3, $s3, 1			# increment buffer pointer
	j	next_char			# goto next_char
new_label:
	la	$a0, word_buffer		# start of copied string
	move	$a1, $s3			# end of copied string
	move	$a2, $s0			# destination of copied string
	jal	copy_src_range_to_dest

	addiu	$t0, $s0, 48			# get address of place in labels to store line number
	sw	$s2, ($t0)			# store label line number
	addiu	$s0, $s0, 52			# next free space at labels
	
	la	$a0, word_buffer
	jal	put_str
						
	la	$a0, word_buffer
	jal	clear_buffer
	
	la	$s3, word_buffer		# reset word buffer
	
	j 	next_char
end_of_line:
	addiu	$s2, $s2, 1			# current_line++
end_of_word:					
	jal	get_symbol_for_word		# get line number for symbol
	move	$t0, $v0			# store found line number for symbol
	beq	$t0, -1, end_of_word_not_symbol	# if line number == -1, then word is not a symbol, goto end_of_word_not_symbol
end_of_word_symbol:
	move 	$a0, $t0
	jal	itoa				# address of string representation of line number
	move	$t0, $v0			# store address in $t0
	
	move	$a0, $t0
	jal	put_str				# put string representation of line number for symbol
	
	move	$a0, $s1			
	jal	putc				# put LF or space
	
	move	$a0, $t0
	jal	clear_buffer			# clear itoa buffer
	
	la	$a0, word_buffer
	jal	clear_buffer
	
	la	$s3, word_buffer		# reset word buffer
	
	j	next_char				
end_of_word_not_symbol:
						# if word is not a symbol, write string to file
	la	$a0, word_buffer
	jal	put_str
	
	la	$a0, word_buffer
	jal	clear_buffer
	
	la	$s3, word_buffer		# reset word buffer
						
next_char:
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
# open_file (LEAF)
# description: 
#	opens file and returns file descriptor
# arguments:
#	$a0 - file name to open
#	$a1 - file open flag
#	$a3 - address where to store file descriptor
# variables: none
# returns: none
open_file:
	li 	$v0, 13       			# system call to open file
  	syscall          			# open a file (file descriptor returned in $v0)

	sw	$v0, ($a3) 			# save file descriptor in $a2
  	jr	$ra				# return
  	

# ============================================================================  	
# read_to_buffer (LEAF)
# description: 
#	reads BUF_LEN bytes from opened file to buffer
# arguments:
#	$a0 - file descriptor
# variables: none
# returns:
#	$v0 - number of characters read, 0 if end-of-file, negative if error
read_to_buffer:
	li 	$v0, 14       			# system call for read to file
  	la 	$a1, getc_buffer   			# address of buffer to store file content
  	li 	$a2, BUF_LEN       		# buffer length
  	syscall          			# read from file

  	jr	$ra				# return
  	
# ============================================================================  	
# write_to_buffer (LEAF)
# description: 
#	writes n bytes from buffer to opened file
# arguments:
#	$a0 - file descriptor
#	$a1 - start of content to write
#	$a2 - number of chars to write
# variables: none
# returns:
#	$v0 - number of characters written, negative if error
write_to_buffer:
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
# arguments:
#	$a0 - address of buffer to clear
# variables:
#	$t0 - address of buffer to clear
#	$t1 - current char of buffer
# returns: none
clear_buffer:
	move	$t0, $a0			# load the address of buffer into $s0
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
# arguments: none
# variables:
#	$t0 - address of labels
#	$t1 - address of label's start string
#	$t2 - address of label's end string
#	$t3 - current label's char
#	$t4 - current word's char
#	$t5 - pointer for current word's char
#	$t6 - flag if label has ended
#	$t7 - flag if word has ended
# returns:
#	$v0 - line number for symbol if word is a defined symbol, -1 if not defined
get_symbol_for_word:	
	la	$t0, labels			# first label pointer
	la	$t5, word_buffer		# store word_buffer pointer in $t5
get_symbol_for_word_loop:
	move	$t1, $t0			# get start address of label
	lb	$t3, ($t1)			# load label's char
	beqz	$t3, symbol_not_found		# if label's first char is NULL, there is no label = symbol_not_found
	addiu	$t2, $t0, 48			# get end address of label
compare_word:
	lb	$t4, ($t5)			# load word's char
	lb	$t3, ($t1)			# load label's char

	seq	$t6, $t3, $zero			# if label has ended
	slti 	$t7, $t4, 11			# if word has ended (char is less than LF)
	and	$t6, $t6, $t7
	beq	$t6, 1, symbol_found		# if label ended AND word has ended, symbol_found
	beqz	$t3, compare_word_not_equal	# if label has ended BUT word has not ended, try next label
	
	bne	$t3, $t4, compare_word_not_equal# if label's char != word's char, symbol not found, try next label
	addiu	$t1, $t1, 1			# next label's char
	addiu	$t5, $t5, 1			# next word's char
	j compare_word
compare_word_not_equal:	
	addiu	$t0, $t0, 52			# next label
	la	$t5, word_buffer		# reset word's pointer
	j 	get_symbol_for_word_loop
symbol_not_found:
	li	$v0, -1				# set 'symbol not found' flag
	j 	get_symbol_for_word_return
symbol_found:
	addiu	$t0, $t0, 48			# move to v0 address of label's line number
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
      	la   	$t0, itoa_buffer+14 		# pointer to almost-end of buffer, BUF_LEN-2
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
      	bne  	$a0, $0, itoa_loop  		# if not zero, loop
itoa_return:
	addi 	$t0, $t0, 1    			# adjust buffer pointer
	move 	$v0, $t0      			# return the addres for first ascii char
      	jr   	$ra
      	
# ============================================================================
# atoi (LEAF)
# description:
#	returns int representation of string at given address
# arguments:
#	$a0 - address of string
# variables: none
# returns:
#	$v0 - int
atoi:
	li	$t1, 10
	li	$t2, 0				# result
atoi_loop:
	lbu 	$t0, ($a0)       		# load char from address
  	beq 	$t0, $zero, atoi_return     	# end of string, goto atoi_return
  	andi 	$t0, $t0, 0x0F   		# converts ascii value to dec
  	mul 	$t2, $t2, $t1    		# result *= 10
  	add 	$t2, $t2, $t0    		# result += dec_value
  	addi 	$a0, $a0, 1     		# next char
  	j 	atoi_loop                 	# go back to loop
atoi_return:
	move	$v0, $t2			# return result
	jr 	$ra

# ============================================================================
# put_str
# description:
#	writes string to output file
# arguments:
#	$a0 - address of string to write
# variables: none
# returns: none
put_str:
	sub	$sp, $sp, 16
	sw	$ra, 16($sp)			# push $ra
	sw	$s0, 12($sp)			# push $s0
	sw 	$s1, 8($sp)			# push $s1
	sw 	$s2, 4($sp)			# push $s2
	
	move	$s0, $a0			# set address of string
put_str_loop:
	lb	$s1, ($s0)			# load next char
	beqz	$s1, put_str_return		# if NULL, goto put_str_return
	
	move	$a0, $s1			# char to put
	jal	putc				# call putc
	
	addiu	$s0, $s0, 1			# next char pointer
	j 	put_str_loop
	
put_str_return:
	lw	$s2, 4($sp)			# pop $s2		
	lw	$s1, 8($sp)			# pop $s1			
	lw	$s0, 12($sp)			# pop $s0			
	lw	$ra, 16($sp)			# pop $ra
	add	$sp, $sp, 16

	jr	$ra

	
# ============================================================================
# putc
# description:
#	writes next char to buffer, if no space available - flushes buffer to file
# arguments:
#	$a0 - char to store
# variables:
#	$s0 - available number of chars in buffer
#	$s1 - pointer to buffer
#	$s2 - char to store
# returns: none
putc:
	sub	$sp, $sp, 16
	sw	$ra, 16($sp)			# push $ra
	sw	$s0, 12($sp)			# push $s0
	sw 	$s1, 8($sp)			# push $s1
	sw 	$s2, 4($sp)			# push $s2

	move	$s2, $a0			# save char to store
	lw	$s0, putc_buffer_chars		# load available buffer chars
	bnez	$s0, putc_next_char		# if chars available, goto putc_next_char
	
	jal	flush_buffer
putc_next_char:
	lw	$s1, putc_buffer_pointer	# store buffer pointer address in $s1
	sb	$s2, ($s1)			# store char at next available space in buffer
	addiu	$s1, $s1, 1			# move buffer_pointer to next available space
	sw	$s1, putc_buffer_pointer	# store new buffer_pointer
	subiu	$s0, $s0, 1			# decrement available buffer chars
	sw	$s0, putc_buffer_chars		# store available buffer chars
putc_return:
	lw	$s2, 4($sp)			# pop $s2		
	lw	$s1, 8($sp)			# pop $s1			
	lw	$s0, 12($sp)			# pop $s0			
	lw	$ra, 16($sp)			# pop $ra
	add	$sp, $sp, 16

	jr	$ra
	
# ============================================================================
# flush_buffer (LEAF)
# description:
#	flushes putc_buffer to file
# arguments: none
# variables:
#	$t0 - available number of chars in buffer
#	$t1 - pointer to buffer
# returns: none
flush_buffer:
	li 	$v0, 15       			# system call for write to file
	lw	$a0, output_file_descriptor	# load output file descriptor to $a0
  	la 	$a1, putc_buffer   		# address of buffer which is being stored to file
  	li 	$a2, BUF_LEN       		# buffer length
  	syscall          			# wrte to file
  	
  	li	$t0, BUF_LEN			# reset available buffer chars
  	sw	$t0, putc_buffer_chars		# store available chars
  	
  	la	$t1, putc_buffer		# store buffer address in $t1
  	sw	$t1, putc_buffer_pointer	# set buffer_pointer to start of buffer
  	
  	jr	$ra
						
# ============================================================================
# getc (LEAF)
# description:
#	returns next char from buffer, refreshes buffer from input_file beforehand if no char available
# arguments: none
# variables:
#	$t0 - available number of chars in buffer
#	$t1 - pointer to buffer
#	$t2 - next char from buffer
# returns:
#	$v0 - next available char, -1 if EOF
getc:
	lw	$t0, getc_buffer_chars		# load available buffer chars
	bnez	$t0, getc_next_char		# if chars available, goto getc_next_char
getc_refresh:
	li 	$v0, 14       			# system call for read to file
	lw	$a0, input_file_descriptor	# load input file descriptor to $a0
  	la 	$a1, getc_buffer   		# address of buffer to store file content
  	li 	$a2, BUF_LEN       		# buffer length
  	syscall          			# read from file
  	
  	move	$t0, $v0			# save read chars to $t0
  	sw	$t0, getc_buffer_chars		# store read chars as available chars
  	
  	beqz	$t0, getc_eof			# if no chars read (eof), goto getc_eof
  	
  	la	$t1, getc_buffer		# store buffer address in $t1
  	sw	$t1, getc_buffer_pointer	# set buffer_pointer to start of buffer
getc_next_char:
	lw	$t1, getc_buffer_pointer	# store buffer pointer address in $t1
	lb	$t2, ($t1)			# read available char from buffer
	addiu	$t1, $t1, 1			# move buffer_pointer to next char
	sw	$t1, getc_buffer_pointer	# store new buffer_pointer
	subiu	$t0, $t0, 1			# decrement available buffer chars
	sw	$t0, getc_buffer_chars		# store available buffer chars
	move	$v0, $t2			# return next char
	j	getc_return			# goto getc_return
getc_eof:
	li	$v0, -1				# return -1 eof flag
getc_return:
	jr	$ra