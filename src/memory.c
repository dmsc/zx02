/*
 * (c) Copyright 2021 by Einar Saukas. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * The name of its author may not be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>

#include "zx02.h"
#include "memory.h"

#define QTY_BLOCKS 10000

// Linked list of allocations
struct alloc_array_t {
    BLOCK data[QTY_BLOCKS];
    struct alloc_array_t *next;
};

struct block_mem_t {
    BLOCK *unused_list;
    struct alloc_array_t *free_list;
    int free_array_size;
};

struct block_mem_t *block_mem_new() {
    struct block_mem_t *bm = calloc(sizeof(struct block_mem_t), 1);
    bm->unused_list = NULL;
    bm->free_list = NULL;
    bm->free_array_size = 0;
    return bm;
}

void block_mem_free(struct block_mem_t *bm) {
    // Free the array list
    struct alloc_array_t *ptr = bm->free_list;
    while(ptr) {
        struct alloc_array_t *next = ptr->next;
        free(ptr);
        ptr = next;
    }
    free(bm);
}

BLOCK *allocate(struct block_mem_t *bm, int bits, int index, int offset, BLOCK *chain) {
    BLOCK *ptr;

    // Check if we have any unused block, and reuse
    if (bm->unused_list) {
        ptr = bm->unused_list;
        bm->unused_list = ptr->unused_chain;
        // If the unused block points to another block, check if that block
        // becomes unused also.
        if (ptr->chain && !--ptr->chain->references) {
            ptr->chain->unused_chain = bm->unused_list;
            bm->unused_list = ptr->chain;
        }
    } else {
        // Check if we have available new blocks
        if (!bm->free_array_size) {
            // No, we need to allocate a new array of blocks
            struct alloc_array_t *old = bm->free_list;
            bm->free_list = malloc(sizeof(struct alloc_array_t));
            if (!bm->free_list) {
                fprintf(stderr, "Error: Insufficient memory\n");
                exit(1);
            }
            bm->free_list->next = old;
            bm->free_array_size = QTY_BLOCKS;
        }
        ptr = &bm->free_list->data[--(bm->free_array_size)];
    }
    ptr->bits = bits;
    ptr->index = index;
    ptr->offset = offset;
    if (chain)
        chain->references++;
    ptr->chain = chain;
    ptr->references = 0;
    return ptr;
}

void assign(struct block_mem_t *bm, BLOCK **ptr, BLOCK *chain) {
    chain->references++;
    if (*ptr && !--(*ptr)->references) {
        (*ptr)->unused_chain = bm->unused_list;
        bm->unused_list = *ptr;
    }
    *ptr = chain;
}
