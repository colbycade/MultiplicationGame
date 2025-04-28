# Handle user input and validation
.data
msg_factor_prompt:      .asciiz "\nChoose which factor to change (1=first, 2=second): "
msg_factor_error:       .asciiz "Invalid input, must enter '1' or '2'.\n"
msg_value_prompt:         .asciiz "Enter a value 1-9: "
msg_value_range_error:     .asciiz "Invalid value, must be 1-9.\n"
msg_value_taken_error:     .asciiz "You must choose a new value.\n"
msg_product_error:      .asciiz "Product has already been claimed, try again.\n"

.text
.globl input_choose_factor, input_choose_value
# ==============================================================================
# Get user's choice of factor to change
# Input: None
# Output: $v0 = factor number (0=first, 1=second)
input_choose_factor:
    li $v0, 4  # Print prompt
    la $a0, msg_factor_prompt
    syscall

    li $v0, 5 # Read integer input
    syscall
    move $t0, $v0

    # Verify input is 1 or 2
    li $t1, 1
    beq $t0, $t1, valid_input
    li $t2, 2
    beq $t0, $t2, valid_input

    li $v0, 4  # Print error message
    la $a0, msg_factor_error
    syscall
    j input_choose_factor  # Retry

valid_input:
    subi $v0, $t0, 1  # Convert to 0-based index
    jr $ra

# ==============================================================================
# Get user's new value for the selected factor
# Input: $a0 = factor number (0=first, 1=second)
# Output: $v0 = new value (1-9)
input_choose_value:
    # Save return address since we call get_board_index
    addi $sp, $sp, -12
    sw $ra, 0($sp) 
    sw $s0, 4($sp)  
    sw $s1, 8($sp) 
    
    move $s0, $a0 # Store factor number in $s0

input_value_loop:
    # Print prompt
    li $v0, 4  
    la $a0, msg_value_prompt
    syscall

    # Read integer input
    li $v0, 5 
    syscall
    move $s1, $v0   # $s1 = potential new value

    # Verify the value is different from current
    sll $t0, $s0, 2  # Multiply factor number by 4 (word size)
    la $t1, factors
    add $t1, $t1, $t0  # Get address of the selected factor
    lw $t1, 0($t1)  # Load the current value
    beq $s1, $t1, repeat_error  # If same value, jump to error

    # Verify input is within range (1-9)
    move $a0, $s1  # Pass new value to is_between_1_and_9
    jal is_between_1_and_9
    beqz $v0, range_error

    # Verify product is not already claimed
    # Get other factor
    li $t2, 1
    sub $t2, $t2, $s0   # other factor index (1-0=1, 1-1=0)
    sll $t2, $t2, 2     # other factor index * 4
    la $t3, factors
    add $t3, $t3, $t2   # Get address of the other factor
    lw $t3, 0($t3)      # Load the other factor value

    # Check if product is already claimed
    mul $a0, $s1, $t3
    jal is_claimed
    bnez $v0, product_error  # If claimed, jump to error

    # If all checks pass, return the new value
    move $v0, $s1

    # Restore registers and return
    lw $ra, 0($sp)
    lw $s0, 4($sp)  
    lw $s1, 8($sp)  
    addi $sp, $sp, 12
    jr $ra

repeat_error:
    li $v0, 4  # Print error message
    la $a0, msg_value_taken_error
    syscall
    j input_value_loop  # Retry

range_error:
    li $v0, 4  # Print error message
    la $a0, msg_value_range_error
    syscall
    j input_value_loop  # Retry

product_error:
    li $v0, 4  # Print error message
    la $a0, msg_product_error
    syscall
    j input_value_loop  # Retry    

# ==============================================================================
# Verify value is within range (1-9)
# Input: $a0 = value
# Output: $v0 = 1 if within range, 0 if not
is_between_1_and_9:
    li $t1, 1
    li $t2, 9
    blt $a0, $t1, not_between
    bgt $a0, $t2, not_between
    li $v0, 1  # Value is within range
    jr $ra

not_between:
    li $v0, 0  # Value is not within range
    jr $ra
