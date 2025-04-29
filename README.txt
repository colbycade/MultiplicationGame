# The Multiplication Game
This is a MIPS Assembly implementation of the following game: https://www.mathsisfun.com/games/multiplication-game.html

# Instructions
To run this program, 
1. Download the MARS MIPS Assembler
2. Identify the path to the Mars.jar file
3. Navigate to the project folder:
    `cd Path/To/MultiplicationGame`
4. Compile and run the files:
    `java -jar ~/Desktop/UTD/Spring25/SE2340/Mars.jar sm *.asm`
5. Enter input and press enter in the command line to play!

# Gameplay
1. Computer goes first by choosing a value 1-9.
2. User responds by choosing a second value 1-9.
3. The product of these two numbers is "claimed" for the user and can no longer be used.
4. After these initial moves, players take turns changing either factor.
    a. To be a valid move, the resulting product must not already be claimed.
5. A player wins by having four claimed products in a row (horizontal, vertical, or diagonal).