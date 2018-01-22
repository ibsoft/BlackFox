# Makefile
#
#

.PHONY: all clean distclean

CC       = gcc
LD       = gcc
RM       = rm -f
CFLAGS   = -g -O2 -Wall
DEFS     = 
LIBS     = 
LDFLAGS  = 

all: dateutil

dateutil: dateutil.o
	$(LD) dateutil.o $(LDFLAGS) -o dateutil

# End of Makefile
