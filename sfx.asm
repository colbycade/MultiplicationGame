# Sound effects for the game
.data

.text
.globl sfx_user_move, sfx_user_win, sfx_computer_win

sfx_user_move:
    # Play sound effect for user move
    li $a0, 50        # Pitch
    li $a1, 300       # 500 ms
    li $a2, 115       # Instrument 115 = Woodblock
    li $a3, 100       # Volume
    li $v0, 31        # Syscall 33 = MIDI out asynchronous
    syscall

    jr $ra

sfx_user_win:
    # Play sound effect for user win
    li $a1, 150       # 200 ms
    li $a2, 80        # Instrument 80 = Synth Voice
    li $a3, 120       # Volume
    li $v0, 33        # Syscall 31 = MIDI out synchronous (wait to finish)
    syscall

    li $a0, 60          # C4
    syscall
    li $a0, 64          # E4
    syscall
    li $a0, 67          # G4
    syscall
    li $a0, 72          # C5
    li $a1, 500
    syscall

    jr $ra

sfx_computer_win:
    # Play sound for player loss
    li $a1, 150       # 200 ms
    li $a2, 80        # Instrument 80 = Synth Voice
    li $a3, 120       # Volume
    li $v0, 33        # Syscall 31 = MIDI out synchronous (wait to finish)
    syscall

    li $a0, 64          # E4
    syscall
    li $a0, 62          # D4
    syscall
    li $a0, 60          # C4
    syscall
    li $a0, 57          # A3
    li $a1, 500
    syscall

    jr $ra