# Node struct (24 bytes):
#   0: int val (4 bytes)
#   8: left pointer (8 bytes)
#  16: right pointer (8 bytes)

    .text

    .globl make_node
    .globl insert
    .globl get
    .globl getAtMost


# make_node - create a new BST node
# a0 = val
# returns pointer in a0 (or 0 if malloc fails)
make_node:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      t0, 16(sp)
    sd      t1, 8(sp)

    mv      t0, a0              # t0 = val

    li      a0, 24
    call    malloc

    beqz    a0, make_node_fail

    sw      t0, 0(a0)           # node->val = val
    sd      zero, 8(a0)         # left = NULL
    sd      zero, 16(a0)        # right = NULL
    j       make_node_done

make_node_fail:
    li      a0, 0

make_node_done:
    ld      ra, 24(sp)
    ld      t0, 16(sp)
    ld      t1, 8(sp)
    addi    sp, sp, 32
    ret


# insert - add a value to BST (no duplicates)
# a0 = root, a1 = val
# returns root
insert:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      t0, 32(sp)          # root
    sd      t1, 24(sp)          # val
    sd      t2, 16(sp)
    sd      t3, 8(sp)

    mv      t0, a0
    mv      t1, a1

    bnez    t0, insert_not_empty

    mv      a0, t1
    call    make_node
    j       insert_done

insert_not_empty:
    lw      t2, 0(t0)           # root->val

    blt     t1, t2, insert_left
    bgt     t1, t2, insert_right

    # duplicate
    mv      a0, t0
    j       insert_done

insert_left:
    ld      a0, 8(t0)
    mv      a1, t1
    call    insert
    sd      a0, 8(t0)
    mv      a0, t0
    j       insert_done

insert_right:
    ld      a0, 16(t0)
    mv      a1, t1
    call    insert
    sd      a0, 16(t0)
    mv      a0, t0

insert_done:
    ld      ra, 40(sp)
    ld      t0, 32(sp)
    ld      t1, 24(sp)
    ld      t2, 16(sp)
    ld      t3, 8(sp)
    addi    sp, sp, 48
    ret


# get - search for a value
# a0 = root, a1 = val
# returns pointer to node (or 0)
get:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      t0, 16(sp)          # root
    sd      t1, 8(sp)           # val
    sd      t2, 0(sp)

    mv      t0, a0
    mv      t1, a1

    beqz    t0, get_not_found

    lw      t2, 0(t0)

    beq     t1, t2, get_found
    blt     t1, t2, get_left

    # right
    ld      a0, 16(t0)
    mv      a1, t1
    call    get
    j       get_done

get_left:
    ld      a0, 8(t0)
    mv      a1, t1
    call    get
    j       get_done

get_found:
    mv      a0, t0
    j       get_done

get_not_found:
    li      a0, 0

get_done:
    ld      ra, 24(sp)
    ld      t0, 16(sp)
    ld      t1, 8(sp)
    ld      t2, 0(sp)
    addi    sp, sp, 32
    ret


# getAtMost_helper - internal helper
# a0 = val, a1 = root, a2 = best_so_far
# returns best value <= val
getAtMost_helper:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      t0, 32(sp)          # val
    sd      t1, 24(sp)          # root
    sd      t2, 16(sp)          # best_so_far
    sd      t3, 8(sp)
    sd      t4, 0(sp)

    mv      t0, a0
    mv      t1, a1
    mv      t2, a2

    beqz    t1, helper_ret_best

    lw      t3, 0(t1)           # root->val

    beq     t3, t0, helper_ret_val
    bgt     t3, t0, helper_left

    # root->val <= val: update best and go right
    mv      t2, t3
    ld      a1, 16(t1)
    mv      a0, t0
    mv      a2, t2
    call    getAtMost_helper
    j       helper_done

helper_left:
    ld      a1, 8(t1)
    mv      a0, t0
    mv      a2, t2
    call    getAtMost_helper
    j       helper_done

helper_ret_val:
    mv      a0, t0
    j       helper_done

helper_ret_best:
    mv      a0, t2

helper_done:
    ld      ra, 40(sp)
    ld      t0, 32(sp)
    ld      t1, 24(sp)
    ld      t2, 16(sp)
    ld      t3, 8(sp)
    ld      t4, 0(sp)
    addi    sp, sp, 48
    ret


# getAtMost - public wrapper
# a0 = val, a1 = root
# returns greatest value <= val, or -1
getAtMost:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    sd      t0, 0(sp)

    li      a2, -1
    call    getAtMost_helper

    ld      ra, 8(sp)
    ld      t0, 0(sp)
    addi    sp, sp, 16
    ret

