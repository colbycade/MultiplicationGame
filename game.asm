# Gamestate Data and Logic

.data
newline : .asciiz "\n"
.globl factors, game_matrix, owner_matrix
# Two factors to be multiplied (factor1=0, factor2=1)
factors:   .word 0,0  # unassigned initially

# 6x6 matrix with unique products 1-9 × 1-9
game_matrix:    .word  1,  2,  3,  4,  5,  6
                .word  7,  8,  9, 10, 12, 14
                .word 15, 16, 18, 20, 21, 24
                .word 25, 27, 28, 30, 32, 35
                .word 36, 40, 42, 45, 48, 49
                .word 54, 56, 63, 64, 72, 81

# Ownership matrix (0=unclaimed, 1=player, 2=computer)
owner_matrix:   .word 0,0,0,0,0,0,
                .word 0,0,0,0,0,0,
                .word 0,0,0,0,0,0,
                .word 0,0,0,0,0,0,
                .word 0,0,0,0,0,0,
                .word 0,0,0,0,0,0

.text
.globl mark_claimed, is_claimed, get_board_index, check_win_for_product

# ==============================================================================
# Mark a product as claimed
# Input: $a0 = product, $a1 = player (1=player, 2=computer)
# Output: None
mark_claimed:
    la $t0, owner_matrix  # Load address of owner_matrix
    jal get_board_index  # Get the index of the product
    sll $t1, $v0, 2  # Multiply index by 4 (word size)
    add $t0, $t0, $t1  # Get the address of the product in owner_matrix
    sw $a1, 0($t0)  # Store the player number at the index
    jr $ra  # Return to caller

# ==============================================================================
# Check if the product is already claimed
# Input: $a0 = product
# Output: $v0 = 1 if claimed, 0 if not claimed
is_claimed:
    # Save return address since we call get_board_index
    addi $sp, $sp, -4
    sw $ra, 0($sp)     

    jal get_board_index  # Get the index of the product
    sll $t0, $v0, 2  # Multiply index by 4 (word size)
    la $t1, owner_matrix  # Load address of owner_matrix
    add $t1, $t0, $t1  # Get the address of the product in owner_matrix
    lw $t2, 0($t1)  # Load the value at the index

    lw $ra, 0($sp)  # Restore return address
    addi $sp, $sp, 4  # Restore stack pointer

    beqz $t2, not_claimed  
    li $v0, 1  # Product is claimed
    jr $ra  
not_claimed:
    li $v0, 0  # Product is not claimed
    jr $ra  

# ==============================================================================
# Get the board index from the product
# Input: $a0 = product
# Output: $v0 = index in the game_matrix (0-35)
get_board_index:
    la $t0, game_matrix  # Load address of game_matrix
    li $t1, 0            # Initialize index to 0

    # Loop through the game_matrix to find the product
find_product:
    lw $t2, 0($t0)       # Load the current product
    beq $t2, $a0, found  # If found, jump to found
    addi $t0, $t0, 4     # Move to the next product
    addi $t1, $t1, 1     # Increment index
    blt $t1, 36, find_product  # Loop until index < 36

    li $v0, -1           # Product not found (should not happen)
    jr $ra               # Return to caller
found:
    move $v0, $t1        # Set the index to $v0
    jr $ra               # Return to caller