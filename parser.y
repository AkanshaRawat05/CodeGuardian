%union {
    char* str;
    int token_type;
}

%token <token_type> INT CHAR FLOAT RETURN IF ELSE FOR WHILE SEMI COMMA ASSIGN LPAREN RPAREN LBRACE RBRACE
%token <str> ID NUM STRING UNSAFE_FUNC
%token PRINTF
%token LBRACK RBRACK
%token PLUS MINUS MULT DIV

%type <token_type> type_specifier
%type <str> declaration
%type <str> expression
%left PLUS MINUS
%left MULT DIV

%start program

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(const char *s);
extern int line_num;

typedef enum { TYPE_INT, TYPE_CHAR, TYPE_FLOAT } VarType;

typedef struct {
    char name[64];
    VarType type;
    int is_initialized;
    int is_used;
    int is_array;
    int array_size;
    int declared_line;  
} Variable;


Variable symbol_table[100];
int var_count = 0;

int find_var(const char* name) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0)
            return i;
    }
    return -1;
}

void add_var(const char* name, VarType type) {
    int idx = find_var(name);
    if (idx != -1) {
        printf("[⚠️ Warning][Line %d] '%s' already declared earlier at line %d.\n", line_num, name, symbol_table[idx].declared_line);
        printf("[📘 Reference] Variable redeclaration issues in C: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n");
        return;
    }
    strcpy(symbol_table[var_count].name, name);
    symbol_table[var_count].type = type;
    symbol_table[var_count].is_initialized = 0;
    symbol_table[var_count].is_used = 0;
    symbol_table[var_count].is_array = 0;
    symbol_table[var_count].array_size = 0;
    symbol_table[var_count].declared_line = line_num;
    var_count++;
}


void add_array(const char* name, VarType type, int size) {
    int idx = find_var(name);
    if (idx != -1) {
        printf("[⚠️ Warning][Line %d] Array '%s' already declared earlier at line %d.\n", line_num, name, symbol_table[idx].declared_line);
        printf("[📘 Reference] Array redeclaration issues: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
        return;
    }
    strcpy(symbol_table[var_count].name, name);
    symbol_table[var_count].type = type;
    symbol_table[var_count].is_initialized = 1;
    symbol_table[var_count].is_used = 0;
    symbol_table[var_count].is_array = 1;
    symbol_table[var_count].array_size = size;
    symbol_table[var_count].declared_line = line_num;
    var_count++;

}



void mark_initialized(const char* name) {
    int idx = find_var(name);
    if (idx != -1) symbol_table[idx].is_initialized = 1;
}

void mark_used(const char* name) {
    int idx = find_var(name);
    if (idx != -1) symbol_table[idx].is_used = 1;
}

VarType get_type_from_token(int token) {
    switch (token) {
        case INT: return TYPE_INT;
        case CHAR: return TYPE_CHAR;
        case FLOAT: return TYPE_FLOAT;
        default: return TYPE_INT;
    }
}
%}

%%

program:
      functions
    ;

functions:
      function
    | functions function
    ;

function:
      type_specifier ID LPAREN RPAREN compound_stmt
    ;

compound_stmt:
      LBRACE stmts RBRACE
    ;

stmts:
      /* empty */
    | stmts stmt
    ;

stmt:
      declaration SEMI
    | type_specifier ID LBRACK NUM RBRACK ASSIGN LBRACE NUM COMMA NUM RBRACE SEMI {
        int size = atoi($4);
        add_array($2, get_type_from_token($1), size);
        free($2); free($4); free($8); free($10);
      }
    | ID ASSIGN expression SEMI {
        int lhs = find_var($1);
        if (lhs == -1) {
            printf("[⚠️ Warning][Line %d] Variable '%s' used without declaration.\n", line_num, $1);
            printf("[📘 Reference] Declaring variables before use: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n\n");
        }
        if (lhs != -1) mark_initialized($1);
        free($1);
        free($3);
      }
  | UNSAFE_FUNC LPAREN ID RPAREN SEMI {
    const char *unsafe_func = $1;
    const char *safe_func = NULL;
    const char *info_link = NULL;

    // 🎯 Unsafe to safe mapping with working links
    if (strcmp(unsafe_func, "gets") == 0) {
        safe_func = "fgets";
        info_link = "https://www.geeksforgeeks.org/fgets-function-in-c/";
    } else if (strcmp(unsafe_func, "strcpy") == 0) {
        safe_func = "strncpy or strlcpy";
        info_link = "https://www.geeksforgeeks.org/why-strcpy-and-strncpy-are-not-safe-to-use/";
    } else if (strcmp(unsafe_func, "scanf") == 0) {
        safe_func = "fgets followed by sscanf";
        info_link = "https://stackoverflow.com/questions/51456934/why-does-everyone-say-not-to-use-scanf-in-c";
    } else if (strcmp(unsafe_func, "sprintf") == 0) {
        safe_func = "snprintf";
        info_link = "https://www.securecoding.cert.org/confluence/display/c/FIO30-C.+Exclude+user+input+from+format+strings";
    } else if (strcmp(unsafe_func, "strcat") == 0) {
        safe_func = "strncat or strlcat";
        info_link = "https://www.geeksforgeeks.org/strcat-vs-strncat-in-c/";
    } else if (strcmp(unsafe_func, "vsprintf") == 0) {
        safe_func = "vsnprintf";
        info_link = "https://wiki.sei.cmu.edu/confluence/display/c/FIO30-C.+Exclude+user+input+from+format+strings";
    }

    // 🔐 Warn and suggest alternative
    printf("[⚠️ Warning][Line %d] Unsafe function '%s' used.", line_num, unsafe_func);
    if (safe_func)
        printf(" Consider using '%s' instead.\n", safe_func);
    else
        printf("\n");

    // 📘 Add reference link
    if (info_link)
        printf("[ℹ️ Info][Line %d] Learn why '%s' is dangerous: %s\n\n", line_num, unsafe_func, info_link);

    // 🔍 Check the variable
    int idx = find_var($3);
    if (idx == -1) {
        printf("[⚠️ Warning][Line %d] Variable '%s' used without declaration.\n", line_num, $3);
    } else if (!symbol_table[idx].is_initialized) {
        printf("[⚠️ Warning][Line %d] Variable '%s' used before initialization.\n", line_num, $3);
    }

    free($1);
    free($3);
}


    | ID LBRACK NUM RBRACK ASSIGN NUM SEMI {
        int idx = find_var($1);
        if (idx == -1) {
            printf("[⚠️ Warning][Line %d] Variable '%s' used without declaration.\n", line_num, $1);
            printf("[📘 Reference] Variable declaration before use: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n\n");
        } else if (!symbol_table[idx].is_array) {
            printf("[⚠️ Warning][Line %d] Variable '%s' is not an array.\n", line_num, $1);
            printf("[📘 Reference] Understanding arrays in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
        } else {
            int index = atoi($3);
            if (index < 0 || index >= symbol_table[idx].array_size) {
                printf("[❌ Error][Line %d] Array index out of bounds: %s[%d] (size: %d)\n",
                       line_num, $1, index, symbol_table[idx].array_size);
                printf("[📘 Reference] Array index bounds in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
            }
        }
        free($1);
        free($3);
        free($6);
      }
;


   | PRINTF LPAREN STRING COMMA ID LBRACK NUM RBRACK RPAREN SEMI {
    int idx = find_var($5);
    if (idx == -1) {
        printf("[⚠️ Warning][Line %d] Variable '%s' used without declaration.\n", line_num, $5);
        printf("[📘 Reference] Variable declaration before use: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n\n");
    } else if (!symbol_table[idx].is_array) {
        printf("[⚠️ Warning][Line %d] Variable '%s' is not declared as an array.\n", line_num, $5);
        printf("[📘 Reference] Understanding arrays in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
    } else {
        int index = atoi($7);
        if (index >= symbol_table[idx].array_size) {
            printf("[❌ Error][Line %d] Array index out of bounds: %s[%d] (size: %d)\n", line_num, $5, index, symbol_table[idx].array_size);
            printf("[📘 Reference] Array index bounds in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
        }
    }
    free($3); free($5); free($7);
}
| RETURN NUM SEMI
;


declaration:
      type_specifier ID {
          add_var($2, get_type_from_token($1));
          free($2);
      }
    ;

expression:
    ID {
        int idx = find_var($1);
        if (idx == -1) {
            printf("[⚠️ Warning][Line %d] Variable '%s' used without declaration.\n", line_num, $1);
            printf("[📘 Reference] Variable declaration before use: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n\n");
        } else if (!symbol_table[idx].is_initialized) {
            printf("[⚠️ Warning][Line %d] Variable '%s' used before initialization.\n", line_num, $1);
            printf("[📘 Reference] Uninitialized variables in C: https://www.geeksforgeeks.org/uninitialized-primitive-data-types-in-c-c/\n\nn");
        }
        $$ = $1;
    }
  | ID LBRACK NUM RBRACK {
        int idx = find_var($1);
        if (idx == -1) {
            printf("[⚠️ Warning][Line %d] Array '%s' used without declaration.\n", line_num, $1);
            printf("[📘 Reference] Array declaration in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
        } else {
            int index = atoi($3);
            if (!symbol_table[idx].is_array) {
                printf("[⚠️ Warning][Line %d] Variable '%s' is not an array.\n", line_num, $1);
                printf("[📘 Reference] Arrays vs variables in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
            } else {
                if (!symbol_table[idx].is_initialized) {
                    printf("[⚠️ Warning][Line %d] Array '%s' used before initialization.\n", line_num, $1);
                    printf("[📘 Reference] Uninitialized arrays in C: https://www.geeksforgeeks.org/uninitialized-primitive-data-types-in-c-c/\n\n");
                }
                if (index >= symbol_table[idx].array_size) {
                    printf("[❌ Error][Line %d] Array index out of bounds: %s[%d] (size: %d)\n", line_num, $1, index, symbol_table[idx].array_size);
                    printf("[📘 Reference] Array index bounds in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
                }
            }
        }
        free($1);
        free($3);
        $$ = NULL;
    }
;

    | expression PLUS expression { $$ = NULL; /* check sub-expressions if needed */ }
    | expression MINUS expression { $$ = NULL; }
    | expression MULT expression { $$ = NULL; }
    | expression DIV expression { $$ = NULL; }
    | NUM { $$ = NULL; }
    ;

type_specifier:
      INT   { $$ = INT; }
    | CHAR  { $$ = CHAR; }
    | FLOAT { $$ = FLOAT; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "[❌ Error][Line %d]: %s\n", line_num, s);
}

int main() {
    return yyparse();
}
