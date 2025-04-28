# Main Game Controller
.data
msg_welcome:        .asciiz "\n=== MULTIPLICATION GAME ===\nThere are two factors being multiplied.\nCreate different products by changing a factor!\n"
msg_comp_first:     .asciiz "\nComputer set the first factor to: "
msg_player_first:   .asciiz "\nYou must choose an initial value for the second factor.\n"
msg_user_win:      .asciiz "\nCongratulations! You win!\n"
msg_comp_win:      .asciiz "\nYou lost!\n"
msg_newline:         .asciiz "\n"

.eqv PLAYER 1
.eqv COMPUTER 2

.text
.globl main
main:
    # Intro message
    li $v0, 4
    la $a0, msg_welcome
    syscall

    # --- Initial Moves ---
    # Computer picks first factor
    jal ai_select_initial_factor1
    move $t0, $v0
    # Update the factors array
    la $s3, factors # save in s3 since factors is referenced a lot
    sw $t0, 0($s3) # factors[0] = computer's choice
    # Display computer's first move choice
    li $v0, 4
    la $a0, msg_comp_first
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    li $v0, 4
    la $a0, msg_newline
    syscall

    # User picks second factor
    li $v0, 4
    la $a0, msg_player_first
    syscall
    # Prompt user for a value
    li $a0, 1 # factorNum = 1
    jal input_choose_value
    move $s2, $v0
    sw $s2, 4($s3) # factors[1] = user's choice
    # Calculate initial product
    lw $t0, 0($s3)
    lw $t1, 4($s3)
    mul $a0, $t0, $t1   # product = factors[0] * factors[1]
    # Mark the product as claimed for user
    li $a1, PLAYER
    jal mark_claimed
    # Display user's first move
    li $a0, PLAYER
    li $a1, 1
    move $a2, $s2
    jal display_move

    # Start the game loop with computer's turn
    li $s0, COMPUTER # s0 = current player
GameLoop:
    beq $s0, PLAYER, UserTurn
CompTurn:
    # Computer move
    jal ai_select_move   # $v0=factorNum, $v1=value
    move $s1, $v0   # s1 = factorNum
    move $s2, $v1   # s2 = value
    # Update the factors array
    sll $t0, $s1, 2 # factorNum * 4
    add $t0, $s3, $t0 
    sw $s2, 0($t0) # factors[factorNum] = value
    # Compute the product
    lw $t0, 0($s3)
    lw $t1, 4($s3)
    mul $s4, $t0, $t1   # product = factors[0] * factors[1]
    # Mark the product as claimed for computer
    move $a0, $s4
    li $a1, COMPUTER
    jal mark_claimed
    # Display computer's move
    li $a0, COMPUTER
    move $a1, $s1
    move $a2, $s2
    jal display_move
    # Check if computer wins
    move $a0, $s4
    li $a1, COMPUTER
    jal check_win_for_product
    bnez $v0, CompWins
    # Go to next turn
    li $s0, PLAYER
    j GameLoop
UserTurn:
    # User chooses factor
    jal input_choose_factor      # $v0=factorNum
    move $s1, $v0
    # User chooses value
    move $a0,$s1
    jal input_choose_value       # $v0=value
    move $s2, $v0
    # Update the factors array
    sll $t0, $s1, 2       
    add $t0, $s3, $t0      
    sw $s2, 0($t0)         # factors[factorNum] = newValue
    # Compute the product
    lw $t0, 0($s3)
    lw $t1, 4($s3)
    mul $s4, $t0, $t1   # product = factors[0] * factors[1]
    # Mark the product as claimed for user
    li $a1, PLAYER
    move $a0, $s4
    jal mark_claimed
    # Display user move
    li $a0, PLAYER
    move $a1, $s1
    move $a2, $s2
    jal display_move
    # Check if user wins
    move $a0, $s4
    li $a1, PLAYER
    jal check_win_for_product
    bnez $v0, UserWins
    # Go to next turn
    li $s0, COMPUTER
    j GameLoop

UserWins:
    li $v0, 4
    la $a0, msg_user_win
    syscall
    j Exit
CompWins:
    li $v0, 4
    la $a0, msg_comp_win
    syscall
Exit:
    li $v0, 10
    syscall