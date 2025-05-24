#!/bin/bash

# $1 is the path to the uploaded C file to analyze
INPUT_FILE="$1"
CLEANED_FILE="clean_input.c"
ANALYSIS_JSON="../backend/analysis.json"

if [ -z "$INPUT_FILE" ]; then
  echo "No input file provided!"
  exit 1
fi

echo "Running bison..."
bison -d parser.y || { echo "Bison failed."; exit 1; }

echo "Running flex for lexer..."
flex lexer.l || { echo "Flex (lexer) failed."; exit 1; }

echo "Running flex for comment_remover..."
flex -o comment_remover.c comment_remover.l || { echo "Flex (comment_remover) failed."; exit 1; }

echo "Compiling comment_remover..."
gcc -o comment_remover comment_remover.c -lfl || { echo "Compilation of comment_remover failed."; exit 1; }

echo "Compiling lexer and parser..."
gcc -o compiler lex.yy.c parser.tab.c -lfl -ljson-c || { echo "Compilation of compiler failed."; exit 1; }

echo "Cleaning input file..."
./comment_remover < "$INPUT_FILE" > "$CLEANED_FILE" || { echo "Comment remover failed."; exit 1; }

echo "Running compiler..."
./compiler < "$CLEANED_FILE" || { echo "Compiler execution failed."; exit 1; }

# Move analysis.json to backend folder with full path to avoid confusion
if [ -f "analysis.json" ]; then
  echo "Done! JSON analysis saved to analysis.json"
else
  echo "analysis.json not found!"
  exit 1
fi
