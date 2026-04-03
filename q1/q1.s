

# This file has code for a binary search tree (BST).
#
# Node struct in memory:
#   0: int value (4 bytes)
#   8: left pointer (8 bytes)
#  16: right pointer (8 bytes)
#   (Total size: 24 bytes)

    .text

    .globl make_node
    .globl insert
    .globl get
    .globl getAtMost

# make_node: Makes a new node for the tree.
#   %edi = value to store
#   returns pointer in %rax (0 if failed)
make_node:
    pushq   %rbp
    movq    %rsp, %rbp
	pushq   %rbx  # Save the value of rbx
	subq    $8, %rsp  # Make stack 16-byte aligned

	movl    %edi, %ebx  # Save the input value (malloc will change edi)

	movq    $24, %rdi  # Ask malloc for 24 bytes (size of Node)
	call    malloc

	cmpq    $0, %rax  # If malloc failed, rax is 0
	je      make_node_done

	movl    %ebx, 0(%rax)  # Set node->val = value
	movq    $0, 8(%rax)  # Set node->left = NULL
	movq    $0, 16(%rax)  # Set node->right = NULL

make_node_done:
    addq    $8, %rsp
    popq    %rbx
    popq    %rbp
    ret

# insert: This function puts a value into the BST.
# Input:  %rdi is the root node
#         %esi is the value to add
# Output: %rax is the root node (maybe new if tree was empty)
insert:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    subq    $8, %rsp

	movq    %rdi, %rbx  # Save the root pointer
	movl    %esi, %r12d  # Save the value to insert

	cmpq    $0, %rbx  # If root is NULL, make a new node
	jne     insert_not_empty

	movl    %r12d, %edi
	call    make_node
	jmp     insert_done

insert_not_empty:
	movl    0(%rbx), %ecx  # Get root->val

	cmpl    %ecx, %r12d  # If value < root->val, go left
	jge     insert_check_right

	movq    8(%rbx), %rdi  # Call insert on left child
	movl    %r12d, %esi
	call    insert
	movq    %rax, 8(%rbx)  # Set root->left = result
	movq    %rbx, %rax
	jmp     insert_done

insert_check_right:
	cmpl    %ecx, %r12d
	jle     insert_duplicate  # If value == root->val, do nothing

	movq    16(%rbx), %rdi  # Call insert on right child
	movl    %r12d, %esi
	call    insert
	movq    %rax, 16(%rbx)  # Set root->right = result
	movq    %rbx, %rax
	jmp     insert_done

insert_duplicate:
	movq    %rbx, %rax  # Value already exists, return root

insert_done:
    addq    $8, %rsp
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

# get: This function looks for a value in the BST.
# Input:  %rdi is the root node
#         %esi is the value to find
# Output: %rax is the pointer to the node with the value, or 0 if not found
get:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    subq    $8, %rsp

	movq    %rdi, %rbx  # Save the root pointer
	movl    %esi, %r12d  # Save the value to search for

	cmpq    $0, %rbx  # If root is NULL, value not found
	jne     get_not_empty

	movq    $0, %rax  # Not found, return 0
	jmp     get_done

get_not_empty:
	movl    0(%rbx), %ecx  # Get root->val

	cmpl    %ecx, %r12d  # If value == root->val, found it
	jne     get_not_equal

	movq    %rbx, %rax  # Return pointer to node
	jmp     get_done

get_not_equal:
	cmpl    %ecx, %r12d
	jge     get_go_right  # If value > root->val, go right

	movq    8(%rbx), %rdi  # Call get on left child
	movl    %r12d, %esi
	call    get
	jmp     get_done

get_go_right:
	movq    16(%rbx), %rdi  # Call get on right child
	movl    %r12d, %esi
	call    get

get_done:
    addq    $8, %rsp
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

# getAtMost_helper: This function finds the biggest value in the BST that is less than or equal to a given value.
# Input:  %edi is the value to compare
#         %rsi is the root node
#         %edx is the best value found so far
# Output: %eax is the biggest value <= input value, or the best so far
getAtMost_helper:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    subq    $8, %rsp

	movl    %edi, %r12d  # Save the value to compare
	movq    %rsi, %rbx  # Save the root pointer
	movl    %edx, %r13d  # Save the best value so far

	cmpq    $0, %rbx  # If root is NULL, return best value so far
	jne     helper_not_null

	movl    %r13d, %eax  # Return best value so far
	jmp     helper_done

helper_not_null:
	movl    0(%rbx), %ecx  # Get root->val

	cmpl    %r12d, %ecx  # If root->val == value, found it
	jne     helper_check_too_big

	movl    %r12d, %eax  # Return the value
	jmp     helper_done

helper_check_too_big:
	cmpl    %r12d, %ecx
	jle     helper_qualifies  # If root->val < value, maybe go right

	movl    %r12d, %edi
	movq    8(%rbx), %rsi  # Call on left child
	movl    %r13d, %edx
	call    getAtMost_helper
	jmp     helper_done

helper_qualifies:
	movl    %ecx, %r13d  # Update best value so far

	movl    %r12d, %edi
	movq    16(%rbx), %rsi  # Call on right child
	movl    %r13d, %edx
	call    getAtMost_helper

helper_done:
    addq    $8, %rsp
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

# getAtMost: This is a wrapper for getAtMost_helper.
# Input:  %edi is the value to compare
#         %rsi is the root node
# Output: %eax is the biggest value <= input value, or -1 if nothing found
getAtMost:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp

	movl    $-1, %edx  # Start with best value = -1

    call    getAtMost_helper

    addq    $8, %rsp
    popq    %rbp
    ret
