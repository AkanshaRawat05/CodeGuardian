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
typedef struct {
    char severity[16]; // e.g. "Warning", "Error", "Info"
    int line;
    char message[256];
    char reference[256];
} Issue;

Issue issues[100];
int issue_count = 0;

void add_issue(const char* severity, int line, const char* message, const char* reference) {
    if (issue_count >= 100) return;
    strncpy(issues[issue_count].severity, severity, 15);
    issues[issue_count].line = line;
    strncpy(issues[issue_count].message, message, 255);
    strncpy(issues[issue_count].reference, reference, 255);
    issue_count++;
}


void add_var(const char* name, VarType type) {
    int idx = find_var(name);
    if (idx != -1) {
        // Log warning to console
        printf("[⚠️ Warning][Line %d] '%s' already declared earlier at line %d.\n", line_num, name, symbol_table[idx].declared_line);
        printf("[📘 Reference] Variable redeclaration issues in C: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n");

        // Log warning to issues array for JSON output
        char msg[256];
        snprintf(msg, sizeof(msg), "'%s' already declared earlier at line %d.", name, symbol_table[idx].declared_line);
        add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/");

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
        // Print warning to console
        printf("[⚠️ Warning][Line %d] Array '%s' already declared earlier at line %d.\n", line_num, name, symbol_table[idx].declared_line);
        printf("[📘 Reference] Array redeclaration issues: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");

        // Log warning to issues array for JSON output
        char msg[256];
        snprintf(msg, sizeof(msg), "Array '%s' already declared earlier at line %d.", name, symbol_table[idx].declared_line);
        add_issue("Warning", line_num, msg, "https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language");

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
    if (idx == -1) {
        // Variable used without declaration - log warning
        char msg[256];
        snprintf(msg, sizeof(msg), "Variable '%s' used without declaration.", name);
        printf("[⚠️ Warning][Line %d] Variable '%s' used without declaration.\n", line_num, name);
        printf("[📘 Reference] Declaring variables before use: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n");
        add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/");
    } else {
        symbol_table[idx].is_used = 1;
    }
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
      int size = atoi($4);  // $4 is NUM, token - might be int already or char*?
      add_array($2, get_type_from_token($1), size);
      free($2); // ID is string, free
      // No need to free $4, $8, $10 if they are tokens (integers or literals)
    }
  | ID ASSIGN expression SEMI {
      int lhs = find_var($1);
      if (lhs == -1) {
          printf("[⚠️ Warning][Line %d] Variable '%s' used without declaration.\n", line_num, $1);
          printf("[📘 Reference] Declaring variables before use: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n\n");

          char msg[256];
          snprintf(msg, sizeof(msg), "Variable '%s' used without declaration.", $1);
          add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/");
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
    char msg[512];
    snprintf(msg, sizeof(msg), "Unsafe function '%s' used .Consider using '%s' instead.", unsafe_func,safe_func);
    printf("[⚠️ Warning][Line %d] %s", line_num, msg);
    if (safe_func)
        printf(" Consider using '%s' instead.\n", safe_func);
    else
        printf("\n");

    add_issue("Warning", line_num, msg, info_link ? info_link : "");

    // 📘 Add reference link info line separately for info type
    

    // 🔍 Check the variable usage
    int idx = find_var($3);
    if (idx == -1) {
        snprintf(msg, sizeof(msg), "Variable '%s' used without declaration.", $3);
        printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
        add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/");
    } else if (!symbol_table[idx].is_initialized) {
        snprintf(msg, sizeof(msg), "Variable '%s' used before initialization.", $3);
        printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
        add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/uninitialized-primitive-data-types-in-c-c/");
    }

    free($1);
    free($3);
}


   | ID LBRACK NUM RBRACK ASSIGN NUM SEMI {
    int idx = find_var($1);
    char msg[256];
    if (idx == -1) {
        snprintf(msg, sizeof(msg), "Variable '%s' used without declaration.", $1);
        printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
        printf("[📘 Reference] Variable declaration before use: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n\n");
        add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/");
    } else if (!symbol_table[idx].is_array) {
        snprintf(msg, sizeof(msg), "Variable '%s' is not an array.", $1);
        printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
        printf("[📘 Reference] Understanding arrays in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
        add_issue("Warning", line_num, msg, "https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language");
    } else {
        int index = atoi($3);
        if (index < 0 || index >= symbol_table[idx].array_size) {
            snprintf(msg, sizeof(msg), "Array index out of bounds: %s[%d] (size: %d)", $1, index, symbol_table[idx].array_size);
            printf("[❌ Error][Line %d] %s\n", line_num, msg);
            printf("[📘 Reference] Array index bounds in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
            add_issue("Error", line_num, msg, "https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language");
        }
    }

    free($1);
    free($3);
    free($6);
}


| PRINTF LPAREN STRING COMMA ID LBRACK NUM RBRACK RPAREN SEMI {
    int idx = find_var($5);
    char msg[256];

    if (idx == -1) {
        snprintf(msg, sizeof(msg), "Variable '%s' used without declaration.", $5);
        printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
        printf("[📘 Reference] Variable declaration before use: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n\n");
        add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/");
    } else if (!symbol_table[idx].is_array) {
        snprintf(msg, sizeof(msg), "Variable '%s' is not declared as an array.", $5);
        printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
        printf("[📘 Reference] Understanding arrays in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
        add_issue("Warning", line_num, msg, "https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language");
    } else {
        int index = atoi($7);
        if (index >= symbol_table[idx].array_size) {
            snprintf(msg, sizeof(msg), "Array index out of bounds: %s[%d] (size: %d)", $5, index, symbol_table[idx].array_size);
            printf("[❌ Error][Line %d] %s\n", line_num, msg);
            printf("[📘 Reference] Array index bounds in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
            add_issue("Error", line_num, msg, "https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language");
        }
    }

    free($3);
    free($5);
    free($7);
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
    char msg[256];

    if (idx == -1) {
        snprintf(msg, sizeof(msg), "Variable '%s' used without declaration.", $1);
        printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
        printf("[📘 Reference] Variable declaration before use: https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/\n\n");
        add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/how-to-avoid-compile-error-while-defining-variables/");
    } else if (!symbol_table[idx].is_initialized) {
        snprintf(msg, sizeof(msg), "Variable '%s' used before initialization.", $1);
        printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
        printf("[📘 Reference] Uninitialized variables in C: https://www.geeksforgeeks.org/uninitialized-primitive-data-types-in-c-c/\n\n");
        add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/uninitialized-primitive-data-types-in-c-c/");
    }
    $$ = $1;
}

  | ID LBRACK NUM RBRACK {
    int idx = find_var($1);
    char msg[256];

    if (idx == -1) {
        snprintf(msg, sizeof(msg), "Array '%s' used without declaration.", $1);
        printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
        printf("[📘 Reference] Array declaration in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
        add_issue("Warning", line_num, msg, "https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language");
    } else {
        int index = atoi($3);
        if (!symbol_table[idx].is_array) {
            snprintf(msg, sizeof(msg), "Variable '%s' is not an array.", $1);
            printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
            printf("[📘 Reference] Arrays vs variables in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
            add_issue("Warning", line_num, msg, "https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language");
        } else {
            if (!symbol_table[idx].is_initialized) {
                snprintf(msg, sizeof(msg), "Array '%s' used before initialization.", $1);
                printf("[⚠️ Warning][Line %d] %s\n", line_num, msg);
                printf("[📘 Reference] Uninitialized arrays in C: https://www.geeksforgeeks.org/uninitialized-primitive-data-types-in-c-c/\n\n");
                add_issue("Warning", line_num, msg, "https://www.geeksforgeeks.org/uninitialized-primitive-data-types-in-c-c/");
            }
            if (index >= symbol_table[idx].array_size) {
                snprintf(msg, sizeof(msg), "Array index out of bounds: %s[%d] (size: %d)", $1, index, symbol_table[idx].array_size);
                printf("[❌ Error][Line %d] %s\n", line_num, msg);
                printf("[📘 Reference] Array index bounds in C: https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language\n\n");
                add_issue("Error", line_num, msg, "https://www.tutorialspoint.com/what-is-out-of-bounds-index-in-an-array-c-language");
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

#include <stdio.h>
#include <unistd.h>   // for getcwd
#include <errno.h>
#include <string.h>
#include <json-c/json.h>

void write_issues_to_json() {
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) != NULL) {
        printf("Current working directory: %s\n", cwd);
    } else {
        perror("getcwd() error");
    }

    struct json_object *root = json_object_new_object();
    struct json_object *issues_arr = json_object_new_array();

    for (int i = 0; i < issue_count; i++) {
        struct json_object *issue_obj = json_object_new_object();
        json_object_object_add(issue_obj, "severity", json_object_new_string(issues[i].severity));
        json_object_object_add(issue_obj, "line", json_object_new_int(issues[i].line));
        json_object_object_add(issue_obj, "message", json_object_new_string(issues[i].message));
        json_object_object_add(issue_obj, "reference", json_object_new_string(issues[i].reference));
        json_object_array_add(issues_arr, issue_obj);
    }

    json_object_object_add(root, "issues", issues_arr);

    FILE *fp = fopen("/home/akansharawat/security_compiler/analysis.json", "w");

    if (!fp) {
        fprintf(stderr, "Failed to open analysis.json for writing: %s\n", strerror(errno));
        json_object_put(root);
        return;
    }

    fputs(json_object_to_json_string_ext(root, JSON_C_TO_STRING_PRETTY), fp);
    fclose(fp);

    printf("JSON analysis saved to analysis.json\n");

    json_object_put(root);
}


int main() {
    int result = yyparse();
    write_issues_to_json();
    return result;
}

