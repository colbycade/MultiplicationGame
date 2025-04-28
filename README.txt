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
        54, 56, 63, 64, 72, 81.

# Gameplay
1. Computer goes first by moving the "below" pointer to any position 1-9
2. User responds by moving the "above" pointer to any position 1-9
3. After initial moves, players take turns moving either pointer
4. Rules for valid moves:
    - The pointer must change to a different number than before
    - The resulting product must not have been already claimed
5. After each player makes a move, check if the player has won by having four claimed products in a row (horizontal, vertical, or diagonal)