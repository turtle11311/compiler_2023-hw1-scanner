%{
/*
 * scan.l
 *
 * lex input file for pascal scanner
 *
 * extensions: two ways to spell "external" and "->" ok for "^".
 */

#include <stdio.h>
#include <stdbool.h>
#include <stdarg.h>
#include "parser.tab.h"

#define YY_USER_ACTION { if (yytext[0]=='\n') { lineNumber++; lineLocation=1; } else { lineLocation+=strlen(yytext); } }

#define LIST_SRC { if (isListSrc) fprintf(stdout, "%s", yytext); }

static int lineNumber = 1;
static int lineLocation = 1;
static int commentStack = 0;

static int isListSrc = true;

void scannerLog(const char* format, ...) {
  va_list args;
  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
}

enum TokenType
{
  TokenTypeUNKNOW=0, TokenTypeIDENTIFIER, TokenTypeKEYWORD, TokenTypeNUMBER, TokenTypeSTRING
};

const char const TokenTypeName[][11] = {
  "UNKNOW", "IDENTIFIER", "KEYWORD", "NUMBER", "STRING"
};

const char* tokenName(int tok) {
  switch (tok) {
    case KPROGRAM:
    case LPAREN:
    case RPAREN:
    case SEMICOLON:
    case COLON:
    case DOT:
    case COMMA:
    case KVAR:
    case KARRAY:
    case LBRAC:
    case RBRAC:
    case KSTRING:
    case KOF:
    case KINTEGER:
    case KREAL:
    case KFUNCTION:
    case KPROCEDURE:
    case KBEGIN:
    case KEND:
    case ASSIGNMENT:
    case KIF:
    case KTHEN:
    case KELSE:
    case KWHILE:
    case KDO:
    case LESS:
    case GREATER:
    case LESSEQUAL:
    case GREATEREQUAL:
    case EQUAL:
    case NOTEQUAL:
    case PLUS:
    case MINUS:
    case STAR:
    case SLASH:
    case KNOT:
    case DOTDOT:
    case KAND:
    case KOR:
      return TokenTypeName[TokenTypeKEYWORD];
      break;
    case STRINGCONST:
      return TokenTypeName[TokenTypeSTRING];
      break;
    case NUM:
      return TokenTypeName[TokenTypeNUMBER];
    case IDENTIFIER:
      return TokenTypeName[TokenTypeIDENTIFIER];
  }
  return TokenTypeName[TokenTypeUNKNOW];
}

%}
INTEGER [0-9]+
REAL {INTEGER}("."0*{INTEGER})?
SCIENTIFIC {REAL}(?i:e)[+-]?{INTEGER}
NQUOTE [^']
ALPHA [a-zA-Z]
ALNUMUNDER [a-zA-Z0-9_]
IDENTIFIER {ALPHA}{ALNUMUNDER}*

%x CXXCOMMENT

%%

#\ *pragma\ +list\ +on        { isListSrc = true; LIST_SRC; }
#\ *pragma\ +list\ +off       { isListSrc = false; LIST_SRC; }

(?i:program)                  { LIST_SRC; return(KPROGRAM); }
"("                           { LIST_SRC; return(LPAREN); }
")"                           { LIST_SRC; return(RPAREN); }
";"                           { LIST_SRC; return(SEMICOLON); }
":"                           { LIST_SRC; return(COLON); }
"."                           { LIST_SRC; return(DOT); }
","                           { LIST_SRC; return(COMMA); }
(?i:var)                      { LIST_SRC; return(KVAR); }
(?i:array)                    { LIST_SRC; return(KARRAY); }
"["                           { LIST_SRC; return(LBRAC); }
"]"                           { LIST_SRC; return(RBRAC); }
({REAL}|{SCIENTIFIC})         { LIST_SRC; return(NUM); }
(?i:string)                   { LIST_SRC; return(KSTRING); }
\"([^"])*\"                   { LIST_SRC; return(STRINGCONST); }
(?i:of)                       { LIST_SRC; return(KOF); }
(?i:integer)                  { LIST_SRC; return(KINTEGER); }
(?i:real)                     { LIST_SRC; return(KREAL); }
(?i:function)                 { LIST_SRC; return(KFUNCTION); }
(?i:procedure)                { LIST_SRC; return(KPROCEDURE); }
(?i:begin)                    { LIST_SRC; return(KBEGIN); }
(?i:end)                      { LIST_SRC; return(KEND); }
":="                          { LIST_SRC; return(ASSIGNMENT); }
(?i:if)                       { LIST_SRC; return(KIF); }
(?i:then)                     { LIST_SRC; return(KTHEN); }
(?i:else)                     { LIST_SRC; return(KELSE); }
(?i:while)                    { LIST_SRC; return(KWHILE); }
(?i:do)                       { LIST_SRC; return(KDO); }
"<"                           { LIST_SRC; return(LESS); }
">"                           { LIST_SRC; return(GREATER); }
"<="                          { LIST_SRC; return(LESSEQUAL); }
">="                          { LIST_SRC; return(GREATEREQUAL); }
"="                           { LIST_SRC; return(EQUAL); }
"!="                          { LIST_SRC; return(NOTEQUAL); }
"+"                           { LIST_SRC; return(PLUS); }
"-"                           { LIST_SRC; return(MINUS); }
"*"                           { LIST_SRC; return(STAR); }
"/"                           { LIST_SRC; return(SLASH); }
(?i:not)                      { LIST_SRC; return(KNOT); }
".."                          { LIST_SRC; return(DOTDOT); }
(?i:and)                      { LIST_SRC; return(KAND); }
(?i:or)                       { LIST_SRC; return(KOR); }

{IDENTIFIER}                  { LIST_SRC; return(IDENTIFIER); }

"//".*                        { scannerLog("[INFO ] line%5d:%3lu comment string\n", lineNumber, lineLocation-strlen(yytext)); LIST_SRC; }
"/*"                          { BEGIN(CXXCOMMENT); commentStack=1; 
                                scannerLog("[INFO ] line%5d:%3lu comment string start\n", 
                                  lineNumber, lineLocation-strlen(yytext), yytext); LIST_SRC;
                              }
<CXXCOMMENT>"/*"              { commentStack++; LIST_SRC;}
<CXXCOMMENT>"*/"              { 
                                commentStack--;
                                if (commentStack <= 0) {
                                  BEGIN(INITIAL);
                                  scannerLog("[INFO ] line%5d:%3lu comment string end\n", lineNumber, lineLocation-strlen(yytext));
                                }
                                LIST_SRC; 
                              }
<CXXCOMMENT>.|\n              { LIST_SRC; }

[ \t\f]                       { LIST_SRC; }

\r                            { LIST_SRC; }
<INITIAL>\n                   { LIST_SRC; }


.    { fprintf(stderr,"[ERROR] line%5d:%3lu lexical analyzer error %s\n", lineNumber, lineLocation-strlen(yytext), yytext); LIST_SRC; }

%%

int main(int argc, char** argv) {
  int i, tok;

  if (argc != 2)
    fprintf(stderr, "Usage: ./scanner [filename]\n"), exit(0);

  if(!(yyin = fopen(argv[1], "r")))
    fprintf(stderr, "Error: file \"%s\" open failed.\n", argv[1]), exit(1);

  for (i = 0; 1==1; i ++) {
    tok = yylex();
    scannerLog("token(type:%-10s) on line%5d,%4lu : %s\n", 
          tokenName(tok), lineNumber, lineLocation-strlen(yytext), yytext);
  }
  return(0);
} /* end of main */

int yywrap() { fclose(yyin), exit(0); }

