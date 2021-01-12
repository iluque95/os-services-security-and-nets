CC=gcc
CXX=g++
RM=rm -f
#CPPFLAGS=-g $(shell root-config --cflags)
#LDFLAGS=-g $(shell root-config --ldflags)
#LDLIBS=$(shell root-config --libs)

SRCS=seaxidx.cpp
OBJS=$(subst .cpp,.o,$(SRCS))

all: seaxidx

seaxidx: $(OBJS)
	$(CXX) -o /usr/bin/seaxidx $(OBJS)

seaxidx.o: seaxidx.cpp

clean:
	$(RM) $(OBJS)

distclean: clean
	$(RM) /usr/bin/seaxidx
