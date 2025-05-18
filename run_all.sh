#!/bin/bash

echo "Running bison..."
bison -d parser.y
if [ $? -ne 0 ]; then
    echo "Bison failed."
    exit 1
fi

echo "Running flex for lexer..."
flex lexer.l
if [ $? -ne 0 ]; then
    echo "Flex (lexer) failed."
    exit 1
fi

echo "Running flex for comment_remover..."
flex -o comment_remover.c comment_remover.l
if [ $? -ne 0 ]; then
    echo "Flex (comment_remover) failed."
    exit 1
fi

echo "Compiling comment_remover..."
gcc -o comment_remover comment_remover.c -lfl
if [ $? -ne 0 ]; then
    echo "Compilation of comment_remover failed."
    exit 1
fi

echo "Compiling lexer and parser..."
gcc -o compiler lex.yy.c parser.tab.c -lfl
if [ $? -ne 0 ]; then
    echo "Compilation of compiler failed."
    exit 1
fi

echo "Cleaning input file..."
./comment_remover < test_input.c > clean_input.c
if [ $? -ne 0 ]; then
    echo "Comment remover failed."
    exit 1
fi

echo "Running compiler..."
./compiler < clean_input.c
if [ $? -ne 0 ]; then
    echo "Compiler execution failed."
    exit 1
fi

echo "Done!"
