%{
#include <stdio.h>
%}

%%

"//".*                  { /* skip single-line comments */ }

"/*"([^*]|\*+[^*/])*\*+"/"    { /* skip multi-line comments */ }

"#".*                   {  }  

\"([^\\\"]|\\.)*\"      { printf("%s", yytext); }     // keep string literals

[^\n]                   { putchar(yytext[0]); }       // print other characters
\n                      { putchar('\n'); }            // preserve newlines

%%

int yywrap() {
    return 1;
}
