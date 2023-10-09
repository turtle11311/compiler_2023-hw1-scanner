PROGRAM=scanner

LEX=flex
YACC=bison
CC=gcc

CFLAGS=

default: $(PROGRAM)

$(PROGRAM): scanner.yy.c parser.tab.h
	$(CC) $(CFLAGS) -o $@ $<

scanner.yy.c: scanner.l
	$(LEX) -o $@ $<

parser.tab.h: parser.y
	$(YACC) -d $^ -b parser

.PHONY: clean
clean:
	rm -f $(PROGRAM) *.tab.* *.yy.* 
