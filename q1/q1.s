# Node struct (24 bytes):
#   0: int val (4 bytes)
#   8: left pointer (8 bytes)
#  16: right pointer (8 bytes)

    .text

    .globl make_node
    .globl insert
    .globl get
    .globl getAtMost


# make_node - create a new BST node with the given value
# a0 holds the value to store
# Returns pointer to new node in a0 (0 if allocation fails)
make_node:
    # Save return address and registers
    addi    sp, sp, -32
    sd      ra, 24(sp)          # save return address
    sd      s0, 16(sp)          # save frame pointer
    sd      s1, 8(sp)           # save s1 (we'll use it to hold val)

    # Set up frame pointer
    addi    s0, sp, 32

    # Save input value
    mv      s1, a0              # s1 = val

    # Call malloc(24) to get memory for node
    li      a0, 24
    call    malloc              # malloc(24) -> a0 (or 0 if failed)

    # If malloc failed, return 0
    beqz    a0, make_node_done

    # Set node fields to value and NULL pointers
    sw      s1, 0(a0)           # node->val = val
    sd      zero, 8(a0)         # node->left = NULL
    sd      zero, 16(a0)        # node->right = NULL

make_node_done:
    # Restore registers and return
    ld      ra, 24(sp)
    ld      s0, 16(sp)
    ld      s1, 8(sp)
    addi    sp, sp, 32
    ret


# insert: Add a value to the BST (no duplicates)
#   a0 = root pointer
#   a1 = value to add
#   returns root pointer in a0
insert:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    sd      s1, 24(sp)          # save root
    sd      s2, 16(sp)          # save val
    sd      s3, 8(sp)           # temp

    addi    s0, sp, 48

    mv      s1, a0              # s1 = root
    mv      s2, a1              # s2 = val

    # If root is NULL, make a new node
    bnez    s1, insert_not_empty

    mv      a0, s2
    call    make_node
    j       insert_done

insert_not_empty:
    # Compare value with root->val
    lw      t0, 0(s1)           # t0 = root->val

    # If value < root->val, go left
    blt     s2, t0, insert_go_left

    # If value > root->val, go right
    bgt     s2, t0, insert_go_right

    # If value == root->val, do nothing (no duplicates)
    mv      a0, s1
    j       insert_done

insert_go_left:
    # Insert into left subtree
    ld      a0, 8(s1)           # a0 = root->left
    mv      a1, s2
    call    insert
    sd      a0, 8(s1)           # root->left = result
    mv      a0, s1
    j       insert_done

insert_go_right:
    # Insert into right subtree
    ld      a0, 16(s1)          # a0 = root->right
    mv      a1, s2
    call    insert
    sd      a0, 16(s1)          # root->right = result
    mv      a0, s1

insert_done:
    ld      ra, 40(sp)
    ld      s0, 32(sp)
    ld      s1, 24(sp)
    ld      s2, 16(sp)
    ld      s3, 8(sp)
    addi    sp, sp, 48
    ret


# get: Find a value in the BST
#   a0 = root pointer
#   a1 = value to find
#   returns pointer to node (or 0 if not found)
get:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s0, 16(sp)
    sd      s1, 8(sp)           # save root
    sd      s2, 0(sp)           # save val

    addi    s0, sp, 32

    mv      s1, a0              # s1 = root
    mv      s2, a1              # s2 = val

    # If root is NULL, return 0
    beqz    s1, get_not_found

    lw      t0, 0(s1)           # t0 = root->val

    # If found, return node
    beq     s2, t0, get_found

    # If value < root->val, search left
    blt     s2, t0, get_go_left

    # Else, search right
    j       get_go_right

get_go_left:
    ld      a0, 8(s1)           # a0 = root->left
    mv      a1, s2
    call    get
    j       get_done

get_go_right:
    ld      a0, 16(s1)          # a0 = root->right
    mv      a1, s2
    call    get
    j       get_done

get_found:
    mv      a0, s1
    j       get_done

get_not_found:
    li      a0, 0

get_done:
    ld      ra, 24(sp)
    ld      s0, 16(sp)
    ld      s1, 8(sp)
    ld      s2, 0(sp)
    addi    sp, sp, 32
    ret


# getAtMost_helper: Helper for getAtMost (not global)
#   a0 = value (upper limit)
#   a1 = root pointer
#   a2 = best value found so far
#   returns biggest value <= input, or best so far
getAtMost_helper:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    sd      s1, 24(sp)          # save val
    sd      s2, 16(sp)          # save root
    sd      s3, 8(sp)           # save best_so_far
    sd      s4, 0(sp)           # temp

    addi    s0, sp, 48

    mv      s1, a0              # s1 = val
    mv      s2, a1              # s2 = root
    mv      s3, a2              # s3 = best_so_far

    # If root is NULL, return best_so_far
    beqz    s2, helper_return_best

    lw      t0, 0(s2)           # t0 = root->val

    # If perfect match, return value
    beq     t0, s1, helper_return_val

    # If root->val > value, go left
    bgt     t0, s1, helper_go_left

    # If root->val <= value, update best_so_far and go right
    mv      s3, t0              # best_so_far = root->val

helper_go_right:
    ld      a1, 16(s2)          # a1 = root->right
    mv      a0, s1
    mv      a2, s3
    call    getAtMost_helper
    j       helper_done

helper_go_left:
    ld      a1, 8(s2)           # a1 = root->left
    mv      a0, s1
    mv      a2, s3
    call    getAtMost_helper
    j       helper_done

helper_return_val:
    mv      a0, s1
    j       helper_done

helper_return_best:
    mv      a0, s3

helper_done:
    ld      ra, 40(sp)
    ld      s0, 32(sp)
    ld      s1, 24(sp)
    ld      s2, 16(sp)
    ld      s3, 8(sp)
    ld      s4, 0(sp)
    addi    sp, sp, 48
    ret


# getAtMost: Find biggest value <= input value
#   a0 = value
#   a1 = root pointer
#   returns biggest value <= input, or -1 if none
getAtMost:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    sd      s0, 0(sp)

    # Start with best_so_far = -1
    li      a2, -1

    call    getAtMost_helper

    ld      ra, 8(sp)
    ld      s0, 0(sp)
    addi    sp, sp, 16
    ret

