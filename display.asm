# Display Functions
.data
# Display strings
msg_mult_matrix_label:   .asciiz "Multiplication Matrix:\n"
msg_owner_matrix_label:  .asciiz "Matrix of Claimed Positions (0=unclaimed, 1=player, 2=computer):\n"
msg_prod_label:      .asciiz "The current product is: "
mult:            .asciiz " x "
equals:          .asciiz " = "
space:           .asciiz " "
double_space:    .asciiz "  "
newline:         .asciiz "\n"
horiz_line:      .asciiz "+----+----+----+----+----+----+\n"
vert_line:       .asciiz "|"

# --- Strings for display_move ---
msg_player:           .asciiz "Player"
msg_computer:         .asciiz "Computer"
msg_changed:          .asciiz " changed the "
msg_first:            .asciiz "first"
msg_second:           .asciiz "second"
msg_factor_to:        .asciiz " factor to be "
msg_period_newline:   .asciiz ".\n"

.text
.globl display_move
# ==============================================================================
# Display a move
# Input: $a0 = player ID (1=player, 2=computer), 
#        $a1 = index of factor changed (0=first, 1=second),
#        $a2 = new value of factor
# Output: None
display_move:
    # Stack frame setup
    addi $sp, $sp, -20     # Allocate space for $ra, $s0-$s3
    sw $ra, 16($sp)        # Save return address
    sw $s0, 12($sp)        # Save $s0 (used for player ID)
    sw $s1, 8($sp)         # Save $s1 (factor index)
    sw $s2, 4($sp)         # Save $s2 (new value)
    sw $s3, 0($sp)         # Save $s3 (factor values)        

    move $s0, $a0          # Store player ID
    move $s1, $a1          # Store factor index
    move $s2, $a2          # Store new value

    # --- Print Move Description Sentence ---
    # "{Player/Computer} changed the {first/second} factor to be {value}."
    # Player or Computer
    li $t0, 1
    beq $s0, $t0, display_player_name
    # If not 1, assume 2 (Computer)
    li $v0, 4
    la $a0, msg_computer
    syscall
    j display_changed_msg

display_player_name:
    li $v0, 4
    la $a0, msg_player
    syscall

display_changed_msg:
    li $v0, 4
    la $a0, msg_changed
    syscall

    # first or second
    beqz $s1, display_first_name
    # If not 0, assume 1 (second)
    li $v0, 4
    la $a0, msg_second
    syscall
    j display_factor_to_msg

display_first_name:
    li $v0, 4
    la $a0, msg_first
    syscall

display_factor_to_msg:
    li $v0, 4
    la $a0, msg_factor_to
    syscall

    li $v0, 1
    move $a0, $s2  # print the new value
    syscall

    li $v0, 4
    la $a0, msg_period_newline   # print period and newline
    syscall

    # --- Print Product Equation ---
    # "The product is now {factors[0]} x {factors[1]} = {product}."
    li $v0, 4
    la $a0, msg_prod_label
    syscall

    la $t0, factors        # Base address of factors
    lw $t1, 0($t0)         # Load factors[0] into $t1
    lw $t2, 4($t0)         # Load factors[1] into $t2
    move $s3, $t1          # Keep factor1 safe in $s3

    li $v0, 1
    move $a0, $t1          # Print factors[0]
    syscall

    li $v0, 4
    la $a0, mult       # Print " x "
    syscall

    li $v0, 1
    move $a0, $t2          # Print factors[1]
    syscall

    li $v0, 4
    la $a0, equals     # Print " = "
    syscall

    # Calculate and print product
    mul $a0, $s3, $t2   # $a0 = factors[0] * factors[1]
    li $v0, 1           # Print product
    syscall                

    li $v0, 4
    la $a0, newline   # Newline after equation
    syscall

    # --- Display Matrices ---
    # Display Game Matrix (Products)
    la $a0, msg_mult_matrix_label
    la $a1, game_matrix
    jal print_matrix

    # Display Owner Matrix (Current claims)
    la $a0, msg_owner_matrix_label
    la $a1, owner_matrix
    jal print_matrix

    # --- Stack Frame Teardown ---
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20   # restore stack pointer
    jr $ra                

# ==============================================================================
# Prints a 6x6 matrix of words stored linearly in memory, with formatting.
# Input: $a0 = Address of the label string to print before the matrix
#        $a1 = Base address of the 6x6 matrix (36 words)
# Output: None
print_matrix:
    move $t0, $a1          # $t0 = current matrix address pointer

    # Print the label
    li $v0, 4
    syscall

    li $t1, 0              # $t1 = row counter (0-5)
    li $t2, 6              # Loop limit (rows and columns)

matrix_row_loop:
    # Print horizontal line before each row
    li $v0, 4
    la $a0, horiz_line
    syscall

    li $t3, 0              # $t3 = column counter (0-5)

matrix_col_loop:
    # Print vertical line separator
    li $v0, 4
    la $a0, vert_line
    syscall

    # Load the matrix element
    lw $t4, 0($t0)

    # Print the number ($t4) with padding for alignment
    # Check if number < 10 for padding
    li $t5, 10
    blt $t4, $t5, print_single_digit

    # Print number (>= 10)
    li $v0, 4             # Print leading space
    la $a0, space
    syscall
    li $v0, 1             # Print the number (2 digits)
    move $a0, $t4
    syscall
    li $v0, 4             # Print trailing space
    la $a0, space
    syscall
    j after_print_num     # Jump over single-digit printing

print_single_digit:
    # Print number (< 10)
    li $v0, 4
    la $a0, double_space  # Print leading double space
    syscall
    li $v0, 1
    move $a0, $t4
    syscall
    li $v0, 4             # Print trailing space
    la $a0, space
    syscall

after_print_num:
    addi $t0, $t0, 4       # Move pointer to next word
    addi $t3, $t3, 1       # Increment column counter
    blt $t3, $t2, matrix_col_loop # Loop if col < 6

    # End of row: print closing vertical line and newline
    li $v0, 4
    la $a0, vert_line
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    addi $t1, $t1, 1       # Increment row counter
    blt $t1, $t2, matrix_row_loop # Loop if row < 6

    # Print final horizontal line after the last row
    li $v0, 4
    la $a0, horiz_line
    syscall

    jr $ra