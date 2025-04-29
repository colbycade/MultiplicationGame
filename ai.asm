# Computer AI
.data
.eqv PLAYER 1
.eqv COMPUTER 2
# Constants used to evaluate potential moves
.eqv SCORE_NONE 0
.eqv SCORE_VALID 1
.eqv SCORE_ADJACENT 2
.eqv SCORE_BLOCKING 3
.eqv SCORE_WINNING 4

.text
.globl ai_select_initial_factor1, ai_select_move

# Select the initial factor for the computer's first move randomly
# Input: None
# Output: $v0 = selected factor (1-9)
ai_select_initial_factor1:
    li $v0, 42        # syscall 42: random integer with range
    li $a0, 0         # random seed
    li $a1, 9         # upper bound
    syscall

    addi $v0, $a0, 1  # shift range from [0-8] to [1-9]
    # li $v0, 1         # uncomment to always return 1 for testing
    jr $ra            # return to caller

# ==============================================================================
# Select the best move for the computer
# The following priorities are used to select the best move:
# 1. Winning Move: Can the computer make a move that results in 4-in-a-row?
# 2. Blocking Move: Can the player win on their next turn, and can the computer claim the square they need?
# 3. Adjacent Move: Can the computer make a move in a square next to an existing computer square?
# 4. Any Valid Move: If none of the above, just pick the first valid move found.
# Input: None
# Output: $v0 = factor index (0-1), $v1 = new value (1-9)
ai_select_move:
    # Save registers and stack frame
    addi $sp, $sp, -32      # Allocate space ($ra, $s0-$s7)
    sw $ra, 28($sp)
    sw $s0, 24($sp)         # s0: best_f (factor index of best move found)
    sw $s1, 20($sp)         # s1: best_v (value of best move found)
    sw $s2, 16($sp)         # s2: best_score (0=none, 1=valid, 2=adjacent, 3=blocking, 4=winning)
    sw $s3, 12($sp)         # s3: current factor index f
    sw $s4, 8($sp)          # s4: current value v
    sw $s5, 4($sp)          # s5: base address of factors array
    sw $s6, 0($sp)          # s6: current potential product being evaluated

    # Initialization
    li $s0, -1              # best_f = -1 (none found)
    li $s1, -1              # best_v = -1
    li $s2, SCORE_NONE      # best_score = 0 (none)
    la $s5, factors         # Load factors base address

    # Outer Loop: Iterate through factors to change (0 then 1)
    li $s3, 0               # f = 0
factor_loop:

    # Inner Loop: Iterate through possible new values (1 to 9)
    li $s4, 1               # v = 1
value_loop:
    # Verify move is valid
    # 1. Check if the value is different from the current value
    sll $t0, $s3, 2         # offset = f * 4
    add $t0, $s5, $t0       # address = factors + offset
    lw $t1, 0($t0)          # current_value = factors[f]
    beq $s4, $t1, skip_move # If v == current_value, skip this v

    # 2. Check if the product is unclaimed
    # Get the other factor's index and value
    li $t0, 1
    sub $t0, $t0, $s3       # other_factor_index = (1-f)
    sll $t2, $t0, 2         
    add $t2, $s5, $t2       
    lw $t2, 0($t2)          # $t2 = other_factor_value
    # Calculate product
    mul $s6, $t2, $s4       # $s6 = product  
    move $a0, $s6           
    jal is_claimed          # $v0=1 if product is claimed, 0 otherwise
    move $t7, $v0
    bnez $t7, skip_move     # If move is not valid (product claimed), skip

    # If we reach here, the move (f, v) is valid

    # Evaluate priorities
    # Priority 1: Check for Winning Move
    move $a0, $s6
    li $a1, COMPUTER        
    jal check_win_for_product  # Hypothetically check if this product wins for Computer
    li $t0, SCORE_WINNING
    bnez $v0, update_best_move # If it wins, this is the best possible move

    # Priority 2: Check for Blocking Move
    move $a0, $s6          
    li $a1, PLAYER          
    jal check_win_for_product  # Hypothetically check if Player wins by getting this product square
    bnez $v0, found_blocking_move # If Player would win, this move blocks them

    # Priority 3: Check for Adjacent Move
    move $a0, $s6
    jal is_adjacent         # Check if neighbors are COMPUTER squares
    bnez $v0, found_adjacent_move # If adjacent

    # Update best move if this is the first valid one found
    li $t0, SCORE_VALID
    beq $s2, SCORE_NONE, update_best_move # If best_score <= 0, update with this first valid move
    # Otherwise move to next iteration since move won't be better than current best
    j skip_move 

found_blocking_move:
    li $t0, SCORE_BLOCKING               
    # Check if this score is better than current best
    bgt $t0, $s2, update_best_move # If 3 > best_score, update
    j skip_move             # Otherwise, continue loop

found_adjacent_move:
    li $t0, SCORE_ADJACENT              
    # Check if this score is better than current best
    bgt $t0, $s2, update_best_move # If 2 > best_score, update
    j skip_move             # Otherwise, continue loop

update_best_move:
    move $s0, $s3           # Update best_f = f
    move $s1, $s4           # Update best_v = v
    move $s2, $t0           # Update best_score = current move's score

skip_move:
    # Inner Loop Control
    addi $s4, $s4, 1        # v++
    li $t0, 9
    ble $s4, $t0, value_loop # Loop if v <= 9

    # Outer Loop Control
    addi $s3, $s3, 1        # f++
    li $t0, 1
    ble $s3, $t0, factor_loop # Loop if f <= 1

    # Loops Finished

    # Return the best move found
    move $v0, $s0           # Return best_f
    move $v1, $s1           # Return best_v

    # Restore registers and stack frame
    lw $s6, 0($sp)
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    lw $s3, 12($sp)
    lw $s2, 16($sp)
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 32
    jr $ra


# ==============================================================================
# Check if any adjacent square is claimed by the computer
# Input: $a0 = product
# Output: $v0 = 1 if adjacent claimed by computer, 0 otherwise
is_adjacent:
    # Save registers and stack frame
    addi $sp, $sp, -20      # Space for $ra, $s0-$s3
    sw $ra, 16($sp)
    sw $s0, 12($sp)         # s0: product
    sw $s1, 8($sp)          # s1: index
    sw $s2, 4($sp)          # s2: row
    sw $s3, 0($sp)          # s3: col

    move $s0, $a0          # Save product

    # Find the board index for the product
    jal get_board_index    # $a0 holds product
    move $s1, $v0          # $s1 = index (0-35)

    # Calculate row and col of index ($s1)
    li $t0, 6
    divu $s1, $t0
    mflo $s2               # $s2 = row = index / 6
    mfhi $s3               # $s3 = col = index % 6

    # Check neighbors one by one. If a match is found, jump to ia_found_exit
    # May be a better way to do this, but this is simple and clear
    # Need to check boundaries before calculating index/address

    # Check Up-Left (row > 0, col > 0) Offset: -7
    li $t0, 0
    ble $s2, $t0, ia_skip_ul  # if row <= 0, skip
    ble $s3, $t0, ia_skip_ul  # if col <= 0, skip
    addi $t1, $s1, -7        # neighbor_index
    sll $t2, $t1, 2          # offset = neighbor_index * 4
    la $t3, owner_matrix     # base address of owner_matrix
    add $t3, $t3, $t2        # address = base + offset
    lw $t4, 0($t3)           # owner = owner_matrix[neighbor_index]
    li $t5, COMPUTER         # $t5 = COMPUTER (2)
    beq $t4, $t5, ia_found_exit  # if owner == COMPUTER, exit found

ia_skip_ul:
    # Check Up (row > 0) Offset: -6
    li $t0, 0
    ble $s2, $t0, ia_skip_u   # if row <= 0, skip
    addi $t1, $s1, -6        # neighbor_index
    sll $t2, $t1, 2
    la $t3, owner_matrix
    add $t3, $t3, $t2
    lw $t4, 0($t3)
    li $t5, COMPUTER
    beq $t4, $t5, ia_found_exit

ia_skip_u:
    # Check Up-Right (row > 0, col < 5) Offset: -5
    li $t0, 0
    ble $s2, $t0, ia_skip_ur  # if row <= 0, skip
    li $t0, 5
    bge $s3, $t0, ia_skip_ur  # if col >= 5, skip
    addi $t1, $s1, -5        # neighbor_index
    sll $t2, $t1, 2
    la $t3, owner_matrix
    add $t3, $t3, $t2
    lw $t4, 0($t3)
    li $t5, COMPUTER
    beq $t4, $t5, ia_found_exit

ia_skip_ur:
    # Check Left (col > 0) Offset: -1
    li $t0, 0
    ble $s3, $t0, ia_skip_l   # if col <= 0, skip
    addi $t1, $s1, -1        # neighbor_index
    sll $t2, $t1, 2
    la $t3, owner_matrix
    add $t3, $t3, $t2
    lw $t4, 0($t3)
    li $t5, COMPUTER
    beq $t4, $t5, ia_found_exit

ia_skip_l:
    # Check Right (col < 5) Offset: +1
    li $t0, 5
    bge $s3, $t0, ia_skip_r   # if col >= 5, skip
    addi $t1, $s1, 1         # neighbor_index
    sll $t2, $t1, 2
    la $t3, owner_matrix
    add $t3, $t3, $t2
    lw $t4, 0($t3)
    li $t5, COMPUTER
    beq $t4, $t5, ia_found_exit

ia_skip_r:
    # Check Down-Left (row < 5, col > 0) Offset: +5
    li $t0, 5
    bge $s2, $t0, ia_skip_dl  # if row >= 5, skip
    li $t0, 0
    ble $s3, $t0, ia_skip_dl  # if col <= 0, skip
    addi $t1, $s1, 5         # neighbor_index
    sll $t2, $t1, 2
    la $t3, owner_matrix
    add $t3, $t3, $t2
    lw $t4, 0($t3)
    li $t5, COMPUTER
    beq $t4, $t5, ia_found_exit

ia_skip_dl:
    # Check Down (row < 5) Offset: +6
    li $t0, 5
    bge $s2, $t0, ia_skip_d   # if row >= 5, skip
    addi $t1, $s1, 6         # neighbor_index
    sll $t2, $t1, 2
    la $t3, owner_matrix
    add $t3, $t3, $t2
    lw $t4, 0($t3)
    li $t5, COMPUTER
    beq $t4, $t5, ia_found_exit

ia_skip_d:
    # Check Down-Right (row < 5, col < 5) Offset: +7
    li $t0, 5
    bge $s2, $t0, ia_skip_dr  # if row >= 5, skip
    bge $s3, $t0, ia_skip_dr  # if col >= 5, skip
    addi $t1, $s1, 7         # neighbor_index
    sll $t2, $t1, 2
    la $t3, owner_matrix
    add $t3, $t3, $t2
    lw $t4, 0($t3)
    li $t5, COMPUTER
    beq $t4, $t5, ia_found_exit

ia_skip_dr:
    # If we checked all valid neighbors and none matched
ia_not_found_exit:
    li $v0, 0       # Return 0 (no adjacent found)
    j ia_exit

ia_found_exit:
    li $v0, 1       # Return 1 (adjacent found)

ia_exit:
    # Restore registers and stack frame
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra