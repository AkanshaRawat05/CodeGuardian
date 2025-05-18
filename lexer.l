%{
#include "parser.tab.h"
#include <string.h>
#include <stdlib.h>
int line_num = 1;
%}

%%

[ \t\r]+    { /* ignore whitespace except newline */ }
\n          { line_num++; }

"int"       { return INT; }
"char"      { return CHAR; }
"float"     { return FLOAT; }
"return"    { return RETURN; }
"gets"      { yylval.str = strdup("gets"); return UNSAFE_FUNC; }
"strcpy"    { yylval.str = strdup("strcpy"); return UNSAFE_FUNC; }
"scanf"     { yylval.str = strdup("scanf"); return UNSAFE_FUNC; }
"printf"     { return PRINTF; }
\".*\"       { yylval.str = strdup(yytext); return STRING; }
"["          { return LBRACK; }
"]"          { return RBRACK; }


"if"        { return IF; }
"else"      { return ELSE; }
"for"       { return FOR; }
"while"     { return WHILE; }

[a-zA-Z_][a-zA-Z0-9_]*  {
    yylval.str = strdup(yytext);
    return ID;
}

[0-9]+      {
    yylval.str = strdup(yytext);
    return NUM;
}
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MULT; }
"/"         { return DIV; }

"="         { return ASSIGN; }
";"         { return SEMI; }
","         { return COMMA; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }

.           { /* ignore unknown characters */ }

%%

int yywrap(void) {
    return 1;
}
