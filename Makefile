# Makefile for ZX0 / DZX0
# -----------------------
#
# (c) 2022 DMSC
# Code under MIT license, see LICENSE file.

# Build folder:
BUILD=build

# Compiler flags
CFLAGS=-O2 -Wall -flto

# List of programs to build
PROGRAMS=\
      zx0\
      dzx0\

# Sources for all programs
SRC_zx0=\
    src/compress.c\
    src/optimize.c\
    src/memory.c\
    src/zx0.c\

SRC_dzx0=\
    src/dzx0.c\

include rules.mak
