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

#define YY_USER_ACTION { listing(yytext); if (yytext[0]=='\n') { lineNumber++; lineLocation=1; } else { lineLocation+=strlen(yytext); } }

static int lineNumber = 1;
static int lineLocation = 1;
static int commentStack = 0;

static int listToken = true;

void scannerLog(const char* format, ...) {
  va_list args;
  va_start(args, format);
  if (listToken != false) {
    vfprintf(stderr, format, args);
  }
  va_end(args);
}

void listing(const char* format, ...) {
  va_list args;
  va_start(args, format);
  if (listToken != false) {
    vfprintf(stdout, format, args);
  }
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
INTEGER ([1-9][0-9]*)|[0]
REAL {INTEGER}("."0*{INTEGER})?
SCIENTIFIC {REAL}(?i:e)[+-]?{INTEGER}
NQUOTE [^']
ALPHA [a-zA-Z]
ALNUMUNDER [a-zA-Z0-9_]
IDENTIFIER {ALPHA}{ALNUMUNDER}*

%x CXXCOMMENT

%%

"#pragma\ list\ on"         { listToken = true; }
"#pragma\ list\ off"        { listToken = false; }

(?i:program)                  return(KPROGRAM);
"("                           return(LPAREN);
")"                           return(RPAREN);
";"                           return(SEMICOLON);
":"                           return(COLON);
"."                           return(DOT);
","                           return(COMMA);
(?i:var)                      return(KVAR);
(?i:array)                    return(KARRAY);
"["                           return(LBRAC);
"]"                           return(RBRAC);
[+-]?({REAL}|{SCIENTIFIC})    return(NUM);
(?i:string)                   return(KSTRING);
\"([^"])*\"                   return(STRINGCONST);
(?i:of)                       return(KOF);
(?i:integer)                  return(KINTEGER);
(?i:real)                     return(KREAL);
(?i:function)                 return(KFUNCTION);
(?i:procedure)                return(KPROCEDURE);
(?i:begin)                    return(KBEGIN);
(?i:end)                      return(KEND);
":="                          return(ASSIGNMENT);
(?i:if)                       return(KIF);
(?i:then)                     return(KTHEN);
(?i:else)                     return(KELSE);
(?i:while)                    return(KWHILE);
(?i:do)                       return(KDO);
"<"                           return(LESS);
">"                           return(GREATER);
"<="                          return(LESSEQUAL);
">="                          return(GREATEREQUAL);
"="                           return(EQUAL);
"!="                          return(NOTEQUAL);
"+"                           return(PLUS);
"-"                           return(MINUS);
"*"                           return(STAR);
"/"                           return(SLASH);
(?i:not)                      return(KNOT);
".."                          return(DOTDOT);
(?i:and)                      return(KAND);
(?i:or)                       return(KOR);

{IDENTIFIER}                  return(IDENTIFIER);

"//".*                        { scannerLog("[INFO ] line%5d:%3lu comment string\n", lineNumber, lineLocation-strlen(yytext)); }
"/*"                          { BEGIN(CXXCOMMENT); commentStack=1; 
                                scannerLog("[INFO ] line%5d:%3lu comment string start\n", 
                                  lineNumber, lineLocation-strlen(yytext), yytext);
                              }
<CXXCOMMENT>"/*"              { commentStack++; }
<CXXCOMMENT>"*/"              { 
                                commentStack--;
                                if (commentStack <= 0) {
                                  BEGIN(INITIAL);
                                  scannerLog("[INFO ] line%5d:%3lu comment string end\n", lineNumber, lineLocation-strlen(yytext));
                                }
                              }
<CXXCOMMENT>.|\n              { }

[ \t\f]    ;

\r    ;
<INITIAL>\n    ;


.    { fprintf(stderr,"[ERROR] line%5d:%3lu lexical analyzer error %s\n", lineNumber, lineLocation-strlen(yytext), yytext); }

%%

int main(int argc, char** argv) {
  int i, tok;

  if (argc != 2)
    fprintf(stderr, "Usage: ./scanner [filename]\n"), exit(0);

  if(!(yyin = fopen(argv[1], "r")))
    fprintf(stderr, "Error: file \"%s\" open failed.\n", argv[1]), exit(1);

  for (i = 0; 1==1; i ++) {
    tok = yylex();
    scannerLog("token(type:%-10s) on line%5d,%5lu : %s\n", 
          tokenName(tok), lineNumber, lineLocation-strlen(yytext), yytext);
  }
  return(0);
} /* end of main */

int yywrap() { fclose(yyin), exit(0); }

