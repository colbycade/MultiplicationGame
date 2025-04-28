# Gamestate Data and Logic

.data
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
    # Save since we call get_board_index
    addi $sp, $sp, -8
    sw $ra, 0($sp)   
    sw $s0, 4($sp) # player number
    move $s0, $a1  # Store player number

    jal get_board_index  # Get the index of the product
    sll $t0, $v0, 2  # Multiply index by 4 (word size)
    la $t1, owner_matrix  # Load address of owner_matrix
    add $t1, $t0, $t1  # Get the address of the product in owner_matrix
    sw $s0, 0($t1)  # Store the player number at the index

    # Restore and return
    lw $ra, 0($sp)  
    lw $s0, 4($sp) 
    addi $sp, $sp, 8  
    jr $ra

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

# ==============================================================================
# Check if a move results in a win for the given player
# Input: $a0 = product of the move
#        $a1 = player (1=player, 2=computer)
# Output: $v0 = 1 if win, 0 if not
check_win_for_product: # cwp_ for helpers
    # Save registers and stack frame
    addi $sp, $sp, -12      # Space for $ra, $s0, $s1
    sw $ra, 8($sp)
    sw $s0, 4($sp)          # s0: playerID
    sw $s1, 0($sp)          # s1: product index (idx)

    move $s0, $a1          # Save playerID
    # Find the board index for the product
    jal get_board_index    # $a0 still holds product
    move $s1, $v0          # $v0 = index (0-35)

    # --- Check all lines passing through idx ($s1) ---
    # For each direction, check if the other 3 squares needed belong to playerID ($s0)

    # 1. Check Horizontal Lines through idx
    jal cwp_check_horizontal
    bnez $v0, cwp_found_win # If horizontal win found, return 1

    # 2. Check Vertical Lines through idx
    jal cwp_check_vertical
    bnez $v0, cwp_found_win # If vertical win found, return 1

    # 3. Check Diagonal (Down-Right) Lines through idx
    jal cwp_check_diag_dr
    bnez $v0, cwp_found_win # If diag DR win found, return 1

    # 4. Check Diagonal (Down-Left) Lines through idx
    jal cwp_check_diag_dl
    bnez $v0, cwp_found_win # If diag DL win found, return 1

    # If no win found in any direction
    li $v0, 0   # Return 0 (no win)
    j cwp_exit

cwp_found_win:
    li $v0, 1   # Return 1 (win)

cwp_exit:
    # stack frame cleanup
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

# Helper: Check Horizontal Lines for check_win_for_product
# Checks horizontal lines of 4 passing through idx ($s1) for playerID ($s0)
# Output: $v0 = 1 if win found, 0 otherwise
cwp_check_horizontal:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Calculate row and col of idx ($s1)
    li $t0, 6
    divu $s1, $t0          
    mflo $t1               # $t1 = row = idx / 6
    mfhi $t2               # $t2 = col = idx % 6

    # Check 4 possible horizontal lines containing 'col'
    # Line 1: [c-3, c-2, c-1, c] (needs c >= 3)
    li $t3, 3
    blt $t2, $t3, hor_skip1 # Skip if col < 3
    # Indices to check: idx-3, idx-2, idx-1
    addi $a0, $s1, -3
    addi $a1, $s1, -2
    addi $a2, $s1, -1
    move $a3, $s0
    jal cwp_check_3_squares # Checks if owner[a0,a1,a2] == a3
    bnez $v0, hor_win       # If check returns 1, we have a win

hor_skip1:
    # Line 2: [c-2, c-1, c, c+1] (needs c >= 2 and c <= 4)
    li $t3, 2
    blt $t2, $t3, hor_skip2 # Skip if col < 2
    li $t3, 4
    bgt $t2, $t3, hor_skip2 # Skip if col > 4
    # Indices to check: idx-2, idx-1, idx+1
    addi $a0, $s1, -2
    addi $a1, $s1, -1
    addi $a2, $s1, 1
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, hor_win

hor_skip2:
    # Line 3: [c-1, c, c+1, c+2] (needs c >= 1 and c <= 3)
    li $t3, 1
    blt $t2, $t3, hor_skip3 # Skip if col < 1
    li $t3, 3
    bgt $t2, $t3, hor_skip3 # Skip if col > 3
    # Indices to check: idx-1, idx+1, idx+2
    addi $a0, $s1, -1
    addi $a1, $s1, 1
    addi $a2, $s1, 2
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, hor_win

hor_skip3:
    # Line 4: [c, c+1, c+2, c+3] (needs c <= 2)
    li $t3, 2
    bgt $t2, $t3, hor_skip4 # Skip if col > 2
    # Indices to check: idx+1, idx+2, idx+3
    addi $a0, $s1, 1
    addi $a1, $s1, 2
    addi $a2, $s1, 3
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, hor_win

hor_skip4:
    # No horizontal win found
    li $v0, 0
    j hor_exit

hor_win:
    li $v0, 1

hor_exit:
    lw $ra, 0($sp)  
    addi $sp, $sp, 4 
    jr $ra           

# Helper: Check Vertical Lines for check_win_for_product
# Checks vertical lines of 4 passing through idx ($s1) for playerID ($s0)
# Output: $v0 = 1 if win found, 0 otherwise
cwp_check_vertical:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Calculate row and col of idx ($s1)
    li $t0, 6
    divu $s1, $t0          
    mflo $t1               # $t1 = row = idx / 6 (column not used for vertical check)

    # Check 4 possible vertical lines containing 'row'
    # Line 1: [r-3, r-2, r-1, r] => indices idx-18, idx-12, idx-6 (needs row >= 3)
    li $t3, 3
    blt $t1, $t3, ver_skip1 # Skip if row < 3
    # Indices to check: idx-18, idx-12, idx-6
    addi $a0, $s1, -18
    addi $a1, $s1, -12
    addi $a2, $s1, -6
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, ver_win

ver_skip1:
    # Line 2: [r-2, r-1, r, r+1] => indices idx-12, idx-6, idx+6 (needs row >= 2 and row <= 4)
    li $t3, 2
    blt $t1, $t3, ver_skip2 # Skip if row < 2
    li $t3, 4
    bgt $t1, $t3, ver_skip2 # Skip if row > 4
    # Indices to check: idx-12, idx-6, idx+6
    addi $a0, $s1, -12
    addi $a1, $s1, -6
    addi $a2, $s1, 6
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, ver_win

ver_skip2:
    # Line 3: [r-1, r, r+1, r+2] => indices idx-6, idx+6, idx+12 (needs row >= 1 and row <= 3)
    li $t3, 1
    blt $t1, $t3, ver_skip3 # Skip if row < 1
    li $t3, 3
    bgt $t1, $t3, ver_skip3 # Skip if row > 3
    # Indices to check: idx-6, idx+6, idx+12
    addi $a0, $s1, -6
    addi $a1, $s1, 6
    addi $a2, $s1, 12
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, ver_win

ver_skip3:
    # Line 4: [r, r+1, r+2, r+3] => indices idx+6, idx+12, idx+18 (needs row <= 2)
    li $t3, 2
    bgt $t1, $t3, ver_skip4 # Skip if row > 2
    # Indices to check: idx+6, idx+12, idx+18
    addi $a0, $s1, 6
    addi $a1, $s1, 12
    addi $a2, $s1, 18
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, ver_win

ver_skip4:
    # No vertical win found
    li $v0, 0
    j ver_exit

ver_win:
    li $v0, 1

ver_exit:
    lw $ra, 0($sp)  
    addi $sp, $sp, 4 
    jr $ra       

# Helper: Check Diagonal Down-Right Lines for check_win_for_product
# Checks diagonal (top-left to bottom-right) lines of 4 passing through idx ($s1) for playerID ($s0)
# Output: $v0 = 1 if win found, 0 otherwise
cwp_check_diag_dr:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Calculate row and col of idx ($s1)
    li $t0, 6
    divu $s1, $t0          
    mflo $t1               # $t1 = row = idx / 6
    mfhi $t2               # $t2 = col = idx % 6

    # Check 4 possible diagonal DR lines containing 'idx' (offset +7 per step down-right)
    # Line 1: [idx-21, idx-14, idx-7, idx] (needs row >= 3 AND col >= 3)
    li $t3, 3
    blt $t1, $t3, dr_skip1 # Skip if row < 3
    blt $t2, $t3, dr_skip1 # Skip if col < 3
    # Indices to check: idx-21, idx-14, idx-7
    addi $a0, $s1, -21
    addi $a1, $s1, -14
    addi $a2, $s1, -7
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, dr_win

dr_skip1:
    # Line 2: [idx-14, idx-7, idx, idx+7] (needs row >= 2, col >= 2 AND row <= 4, col <= 4)
    li $t3, 2
    blt $t1, $t3, dr_skip2 # Skip if row < 2
    blt $t2, $t3, dr_skip2 # Skip if col < 2
    li $t3, 4
    bgt $t1, $t3, dr_skip2 # Skip if row > 4
    bgt $t2, $t3, dr_skip2 # Skip if col > 4
    # Indices to check: idx-14, idx-7, idx+7
    addi $a0, $s1, -14
    addi $a1, $s1, -7
    addi $a2, $s1, 7
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, dr_win

dr_skip2:
    # Line 3: [idx-7, idx, idx+7, idx+14] (needs row >= 1, col >= 1 AND row <= 3, col <= 3)
    li $t3, 1
    blt $t1, $t3, dr_skip3 # Skip if row < 1
    blt $t2, $t3, dr_skip3 # Skip if col < 1
    li $t3, 3
    bgt $t1, $t3, dr_skip3 # Skip if row > 3
    bgt $t2, $t3, dr_skip3 # Skip if col > 3
    # Indices to check: idx-7, idx+7, idx+14
    addi $a0, $s1, -7
    addi $a1, $s1, 7
    addi $a2, $s1, 14
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, dr_win

dr_skip3:
    # Line 4: [idx, idx+7, idx+14, idx+21] (needs row <= 2 AND col <= 2)
    li $t3, 2
    bgt $t1, $t3, dr_skip4 # Skip if row > 2
    bgt $t2, $t3, dr_skip4 # Skip if col > 2
    # Indices to check: idx+7, idx+14, idx+21
    addi $a0, $s1, 7
    addi $a1, $s1, 14
    addi $a2, $s1, 21
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, dr_win

dr_skip4:
    # No diagonal DR win found
    li $v0, 0
    j dr_exit

dr_win:
    li $v0, 1

dr_exit:
    lw $ra, 0($sp)  
    addi $sp, $sp, 4 
    jr $ra       

# Helper: Check Diagonal Down-Left Lines for check_win_for_product
# Checks diagonal (top-right to bottom-left) lines of 4 passing through idx ($s1) for playerID ($s0)
# Output: $v0 = 1 if win found, 0 otherwise
cwp_check_diag_dl:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Calculate row and col of idx ($s1)
    li $t0, 6
    divu $s1, $t0          
    mflo $t1               # $t1 = row = idx / 6
    mfhi $t2               # $t2 = col = idx % 6

    # Check 4 possible diagonal DL lines containing 'idx' (offset +5 per step down-left)
    # Line 1: [idx-15, idx-10, idx-5, idx] (needs row >= 3 AND col <= 2)
    li $t3, 3
    blt $t1, $t3, dl_skip1 # Skip if row < 3
    li $t3, 2
    bgt $t2, $t3, dl_skip1 # Skip if col > 2
    # Indices to check: idx-15, idx-10, idx-5
    addi $a0, $s1, -15
    addi $a1, $s1, -10
    addi $a2, $s1, -5
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, dl_win

dl_skip1:
    # Line 2: [idx-10, idx-5, idx, idx+5] (needs row >= 2, col <= 3 AND row <= 4, col >= 1)
    li $t3, 2
    blt $t1, $t3, dl_skip2 # Skip if row < 2
    li $t3, 3
    bgt $t2, $t3, dl_skip2 # Skip if col > 3
    li $t3, 4
    bgt $t1, $t3, dl_skip2 # Skip if row > 4
    li $t3, 1
    blt $t2, $t3, dl_skip2 # Skip if col < 1
    # Indices to check: idx-10, idx-5, idx+5
    addi $a0, $s1, -10
    addi $a1, $s1, -5
    addi $a2, $s1, 5
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, dl_win

dl_skip2:
    # Line 3: [idx-5, idx, idx+5, idx+10] (needs row >= 1, col <= 4 AND row <= 3, col >= 2)
    li $t3, 1
    blt $t1, $t3, dl_skip3 # Skip if row < 1
    li $t3, 4
    bgt $t2, $t3, dl_skip3 # Skip if col > 4
    li $t3, 3
    bgt $t1, $t3, dl_skip3 # Skip if row > 3
    li $t3, 2
    blt $t2, $t3, dl_skip3 # Skip if col < 2
    # Indices to check: idx-5, idx+5, idx+10
    addi $a0, $s1, -5
    addi $a1, $s1, 5
    addi $a2, $s1, 10
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, dl_win

dl_skip3:
    # Line 4: [idx, idx+5, idx+10, idx+15] (needs row <= 2 AND col >= 3)
    li $t3, 2
    bgt $t1, $t3, dl_skip4 # Skip if row > 2
    li $t3, 3
    blt $t2, $t3, dl_skip4 # Skip if col < 3
    # Indices to check: idx+5, idx+10, idx+15
    addi $a0, $s1, 5
    addi $a1, $s1, 10
    addi $a2, $s1, 15
    move $a3, $s0
    jal cwp_check_3_squares
    bnez $v0, dl_win

dl_skip4:
    # No diagonal DL win found
    li $v0, 0
    j dl_exit

dl_win:
    li $v0, 1

dl_exit:
    lw $ra, 0($sp)  
    addi $sp, $sp, 4 
    jr $ra       

# Helper: Check if 3 Squares are owned by the same player
# Input: $a0, $a1, $a2 = indices, $a3 = playerID to check against
# Output: $v0 = 1 if owner[a0]==playerID AND owner[a1]==playerID AND owner[a2]==playerID
cwp_check_3_squares:
    la $t7, owner_matrix # Load base address of owner matrix

    # Check owner[a0] == a3
    sll $t0, $a0, 2
    add $t0, $t7, $t0
    lw $t1, 0($t0)
    bne $t1, $a3, c3s_fail
    # Check owner[a1] == a3
    sll $t0, $a1, 2
    add $t0, $t7, $t0
    lw $t1, 0($t0)
    bne $t1, $a3, c3s_fail
    # Check owner[a2] == a3
    sll $t0, $a2, 2
    add $t0, $t7, $t0
    lw $t1, 0($t0)
    bne $t1, $a3, c3s_fail
    # All match
    li $v0, 1
    jr $ra
c3s_fail:
    li $v0, 0
    jr $ra