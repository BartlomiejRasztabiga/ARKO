# MAX NUMBER OF LABELS IN FILE IS 100 (can be changed by modifying LABELS_SIZE)
# MAX LENGTH OF LABEL IS 47 CHARS
# LAST LABEL HAS TO BE AT MAX LINE 999 (3 bytes for line number as a string)
# PROGRAM DOESN'T SUPPORT DUPLICATED LABEL DEFINITIONS (WILL USE FIRST DECLARED)
# PASS INPUT FILE NAME AS PROGRAM ARGUMENT

	.eqv	BUF_LEN 512			# ANY REASONABLE VALUE
	.eqv 	ITOA_BUF_LEN 4			# AT LEAST 4, HAS TO SUPPORT NUMBERS UP TO 999
	.eqv	WORD_BUF_LEN 48			# AT LEAST AS LONG AS LONGEST WORD IN FILE +1, SAME AS NUMBER OF CHARS IN LABEL (SEE BELOW)
	.eqv	LABELS_SIZE 5200		# SPACE FOR 100 LABELS (48 CHARS + 4 CHARS AS LINE NUMBER = 52 * 100)

        .data  

itoa_buffer: 		.space 	ITOA_BUF_LEN
getc_buffer: 		.space 	BUF_LEN
			.word 	0
putc_buffer: 		.space 	BUF_LEN
			.word 	0
word_buffer:		.space 	WORD_BUF_LEN
			.word 	0
getc_buffer_pointer:	.space 	4
getc_buffer_chars:	.word 	0
putc_buffer_pointer:	.space 	4
putc_buffer_chars:	.word 	BUF_LEN
input_file_descriptor:	.space 	4
output_file_descriptor:	.space 	4
labels_pointer:		.space 	4
output_fname:		.asciiz "output.txt"
opnfile_err_txt:	.asciiz	"Error while opening the file, check file name."

        .text
        .globl	main
main:
	blt	$a0, 1, exit			# not enough arguments provided, argc < 1
allocate_memory:
	li	$a0, LABELS_SIZE
	li	$v0, 9
	syscall					# allocate memory for labels
	la	$s1, labels_pointer		# store address of labels
	sw	$v0, ($s1)			# move allocated memory address to labels
open_files:
	lw	$a0, ($a1)			# load input file name
	li	$a1, 0				# read only flag
	la	$t0, input_file_descriptor
	
	li 	$v0, 13       			# system call to open file
  	syscall          			# open a file (file descriptor returned in $v0)
  	sw	$v0, ($t0) 			# save file descriptor in input_file_descriptor
	bltz	$v0, open_file_err		# if error during open_file, goto open_file_err
	
	
	la	$a0, output_fname		# load output file name
	li	$a1, 1				# write only flag
	la	$t0, output_file_descriptor
	
	li 	$v0, 13       			# system call to open file
  	syscall          			# open a file (file descriptor returned in $v0)
  	sw	$v0, ($t0) 			# save file descriptor in output_file_descriptor
	bltz	$v0, open_file_err		# if error during open_file, goto open_file_err
	
						# prepare putc buffer pointer for future putc calls
	la	$t0, putc_buffer		# load address of putc_buffer
	sw	$t0, putc_buffer_pointer	# store new buffer_pointer
process_file:
	jal	replace_labels			# replace labels in output_content
	jal	flush_buffer			# flush buffer
close_files:
	la	$a0, input_file_descriptor
	lw	$a0, ($a0)			# load input file descriptor
	li	$v0, 16
	syscall
	
	la	$a0, output_file_descriptor
	lw	$a0, ($a0)			# load output file descriptor
	li	$v0, 16
	syscall
exit:
	li 	$v0, 10
  	syscall
open_file_err:
	la	$a0, opnfile_err_txt
	li	$v0, 4
	syscall					# print error string
	j	close_files
  	
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
	subu	$sp, $sp, 20
	sw	$ra, 16($sp)			# push $ra
	sw	$s0, 12($sp)			# push $s0
	sw	$s1, 8($sp)			# push $s1
	sw	$s2, 4($sp)			# push $s2
	sw	$s3, 0($sp)			# push $s3
	
	la	$s0, labels_pointer		# address of labels pointer
	lw	$s0, ($s0)			# store next free space of labels at $s0
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
	j	replace_labels_loop		# go back to loop
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
						
	j 	next_word
end_of_line:
	addiu	$s2, $s2, 1			# current_line++
end_of_word:					
	jal	get_symbol_for_word		# get line number for symbol
	move	$t0, $v0			# store found line number for symbol
	beq	$t0, -1, end_of_word_not_symbol	# if line number == -1, then word is not a symbol, goto end_of_word_not_symbol
end_of_word_symbol:
	move 	$a0, $t0
	jal	itoa				# address of string representation of line number
	move	$a0, $v0			# store address in $a0
	jal	put_str				# put string representation of line number for symbol
	
	move	$a0, $s1			
	jal	putc				# put LF or space (last char of symbol-word)
	
	j	next_word				
end_of_word_not_symbol:			
	la	$a0, word_buffer		# if word is not a symbol, write string to file
	jal	put_str
next_word:
	la	$a0, word_buffer
	jal	clear_buffer
	la	$s3, word_buffer		# reset word buffer

	j	replace_labels_loop		# go back to loop
replace_labels_return:
	lw	$s3, 0($sp)			# pop $s3
	lw	$s2, 4($sp)			# pop $s2
	lw	$s1, 8($sp)			# pop $s1
	lw	$s0, 12($sp)			# pop $s0
	lw	$ra, 16($sp)			# pop $ra
	addu	$sp, $sp, 20

	jr	$ra				# return

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
	la	$t0, labels_pointer		# address of labels pointer
	lw	$t0, ($t0)			# first label pointer
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
	slti 	$t7, $t4, 33			# if word has ended (char is less than or equal space)
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
	lw	$v0, ($t2)			# move to v0 address of label's line number
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
      	la   	$t0, itoa_buffer+2 		# pointer to almost-end of buffer, BUF_LEN-2
      	sb   	$zero, 1($t0)      		# null-terminated str
      	li   	$t1, '0'  
      	sb   	$t1, ($t0)     			# init. with ascii 0
      	li   	$t2, 10        			# load 10

      	beq  	$a0, $zero, itoa_return  		# end if number is 0
itoa_loop:
      	div  	$a0, $t2       			# a /= 10
      	mflo 	$a0
      	mfhi 	$t3            			# get remainder
      	addu  	$t3, $t3, $t1  			# convert to ASCII digit
      	sb   	$t3, ($t0)     			# store it
      	subu  	$t0, $t0, 1    			# decrement buffer pointer
      	bne  	$a0, $zero, itoa_loop  		# if not zero, loop
itoa_return:
	addi 	$t0, $t0, 1    			# adjust buffer pointer
	move 	$v0, $t0      			# return the addres for first ascii char
      	jr   	$ra

# ============================================================================
# put_str
# description:
#	writes string to output file
# arguments:
#	$a0 - address of string to write
# variables: none
# returns: none
put_str:
	subu	$sp, $sp, 16
	sw	$ra, 12($sp)			# push $ra
	sw	$s0, 8($sp)			# push $s0
	sw 	$s1, 4($sp)			# push $s1
	sw 	$s2, 0($sp)			# push $s2
	
	move	$s0, $a0			# set address of string
	lb	$s1, ($s0)			# load next char
put_str_loop:
	move	$a0, $s1			# char to put
	jal	putc				# call putc
	
	addiu	$s0, $s0, 1			# next char pointer
	lb	$s1, ($s0)			# load next char
	bnez	$s1, put_str_loop		# if not NULL, go back to loop
put_str_return:
	lw	$s2, 0($sp)			# pop $s2		
	lw	$s1, 4($sp)			# pop $s1			
	lw	$s0, 8($sp)			# pop $s0			
	lw	$ra, 12($sp)			# pop $ra
	addu	$sp, $sp, 16

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
	subu	$sp, $sp, 16
	sw	$ra, 12($sp)			# push $ra
	sw	$s0, 8($sp)			# push $s0
	sw 	$s1, 4($sp)			# push $s1
	sw 	$s2, 0($sp)			# push $s2

	move	$s2, $a0			# save char to store
	lw	$s0, putc_buffer_chars		# load available buffer chars
	bnez	$s0, putc_next_char		# if chars available, goto putc_next_char
	
	jal	flush_buffer			# flush buffer
	
	la	$a0, putc_buffer		
	jal	clear_buffer			# clear putc buffer
	
	lw	$s0, putc_buffer_chars		# load available buffer chars
putc_next_char:
	lw	$s1, putc_buffer_pointer	# store buffer pointer address in $s1
	sb	$s2, ($s1)			# store char at next available space in buffer
	addiu	$s1, $s1, 1			# move buffer_pointer to next available space
	sw	$s1, putc_buffer_pointer	# store new buffer_pointer
	subiu	$s0, $s0, 1			# decrement available buffer chars
	sw	$s0, putc_buffer_chars		# store available buffer chars
putc_return:
	lw	$s2, 0($sp)			# pop $s2		
	lw	$s1, 4($sp)			# pop $s1			
	lw	$s0, 8($sp)			# pop $s0			
	lw	$ra, 12($sp)			# pop $ra
	addu	$sp, $sp, 16

	jr	$ra
	
# ============================================================================
# flush_buffer
# description:
#	flushes putc_buffer to file
# arguments: none
# variables:
#	$t0 - available number of chars in buffer
#	$t1 - pointer to buffer
#	$t2 - number of chars left to write
#	$t3 - value of BUF_LEN
# returns: none
flush_buffer:
	lw	$t2, putc_buffer_chars		# load available buffer chars
	li	$t3, BUF_LEN			# load value of BUF_LEN
	subu	$t2, $t3, $t2			# set t2 to number of chars left to write to file

	li 	$v0, 15       			# system call for write to file
	lw	$a0, output_file_descriptor	# load output file descriptor to $a0
  	la 	$a1, putc_buffer   		# address of buffer which is being stored to file
  	move 	$a2, $t2       			# number of chars left to write
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
