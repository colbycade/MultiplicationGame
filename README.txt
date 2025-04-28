# Data
- Array of numbers [1, 2, 3, 4, 5, 6, 7, 8, 9]
- Two pointers: one "above" and one "below" the array (initially unassigned)
- 6×6 matrix with the 36 unique products from multiplying numbers 1-9
    - The unique products are: 
        1,  2,  3,  4,  5,  6, 
        7,  8,  9, 10, 12, 14, 
        15, 16, 18, 20, 21, 24, 
        25, 27, 28, 30, 32, 35, 
        36, 40, 42, 45, 48, 49, 
        54, 56, 63, 64, 72, 81
- Board state (initalized as all 0)
    - 0: Unclaimed
    - 1: Claimed by User
    - 2: Claimed by Computer

# Gameplay
1. Computer goes first by moving the "below" pointer to any position 1-9
2. User responds by moving the "above" pointer to any position 1-9
3. The product of the two pointers is "claimed" for the user
4. After initial moves, players take turns moving either pointer
    a. To be a valid move, the resulting product must not already be claimed
5. After each player makes a move, check if the player has won by having four claimed products in a row (horizontal, vertical, or diagonal)