# Makefile for ZX02 / DZX02
# -------------------------
#
# (c) 2022 DMSC
# Code under MIT license, see LICENSE file.

# Build folder:
BUILD=build

# Compiler flags
CFLAGS=-O3 -g -Wall -flto -DNDEBUG

# Cross compilation rule
CROSS=

# List of programs to build
PROGRAMS=\
      zx02\
      dzx02\

# Distribution ZIP file name
ZIPFILE=zx02-progs.zip

# Sources for all programs
SRC_zx02=\
    src/compress.c\
    src/optimize.c\
    src/memory.c\
    src/zx02.c\

SRC_dzx02=\
    src/dzx02.c\

include rules.mak
