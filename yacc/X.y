/*
 * FILE: X.y
 * PURPOSE: Yacc specification of the grammar for X
 */

%{
#include <stdio.h>
#include <string.h>
 
void yyerror(const char *str)
{
     fprintf(stderr,"error: %s\n",str);
}
 
main()
{
     yyparse();
} 

%}

%token ID TRUE FALSE INTEGER REAL RAND ASSGN
%token SEMI IF FI DO OD DCOLON QUESTION COMMA OR AND NOT
%token LT LEQ EQ NEQ GT GEQ PLUS MINUS STAR SLASH DSLASH
%token LPAREN RPAREN LSQUARE RSQUARE B2I I2R R2I

%start program

%%
program     : stmts                             { printf ("program1 accepted\n"); }
            ;

stmts       : stmt                              { printf ("stmts1\n"); }
            | stmts SEMI stmt                   { printf ("stmts2\n"); }
            ;

stmt        : /* empty rule */                  { printf ("stmt1\n"); }
            | selection                         { printf ("stmt2\n"); }
            | iteration                         { printf ("stmt2\n"); }
            | assignment                        { printf ("stmt3\n"); }
            ;

selection   : IF alts FI                        { printf ("selection1\n"); }
            ;

iteration   : DO alts OD                        { printf ("iteration1\n"); }
            ;

alts        : alt                               { printf ("alts1\n"); }
            | alts DCOLON alt                   { printf ("alts2\n"); }
            ;

alt         : guard QUESTION stmts              { printf ("alt1\n"); }
            ;

guard       : expr                              { printf ("guard1\n"); }
            ;

assignment  : vars ASSGN exprs                  { printf ("assignment1\n"); }
            | vars ASSGN subprogram ASSGN exprs { printf ("assignment2\n"); }
            |      ASSGN subprogram ASSGN exprs { printf ("assignment3\n"); }
            | vars ASSGN subprogram ASSGN       { printf ("assignment4\n"); }
            |      ASSGN subprogram ASSGN       { printf ("assignment5\n"); }
            ;

vars        : ID                                { printf ("vars1\n"); }
            | vars COMMA ID                     { printf ("vars2\n"); }
            ;

exprs       : expr                              { printf ("exprs1\n"); }
            | exprs COMMA expr                  { printf ("exprs2\n"); }
            ;

subprogram  : ID                                { printf ("subprogram1\n"); }
            ;

expr        : disjunction                       { printf ("expr1\n"); }
            ;

disjunction : conjunction                       { printf ("disjunction1\n"); }
            | disjunction OR conjunction        { printf ("disjunction2\n"); }
            ;

conjunction : negation                          { printf ("conjunction1\n"); }
            | conjunction AND negation          { printf ("conjunction2\n"); }
            ;

negation    : relation                          { printf("negation1\n"); }
            | NOT relation                      { printf("negation2\n"); }
            ;

relation    : sum                               { printf ("relation1\n"); }
            | sum LT sum                        { printf ("relation2\n"); }
            | sum LEQ sum                       { printf ("relation3\n"); }
            | sum EQ sum                        { printf ("relation4\n"); }
            | sum NEQ sum                       { printf ("relation5\n"); }
            | sum GEQ sum                       { printf ("relation6\n"); }
            | sum GT sum                        { printf ("relation7\n"); }
            ;

sum         : term                              { printf ("sum1\n"); }
            | MINUS term                        { printf ("sum2\n"); }
            | sum PLUS term                     { printf ("sum3\n"); }
            | sum MINUS term                    { printf ("sum4\n"); }
            ;

term        : factor                            { printf ("term1\n"); }
            | term STAR factor                  { printf ("term2\n"); }
            | term SLASH factor                 { printf ("term3\n"); }
            | term DSLASH factor                { printf ("term4\n"); }
            ;

factor      : TRUE                              { printf ("factor1\n"); }
            | FALSE                             { printf ("factor2\n"); }
            | INTEGER                           { printf ("factor3\n"); }
            | REAL                              { printf ("factor4\n"); }
            | ID                                { printf ("factor5\n"); }
            | LPAREN expr RPAREN                { printf ("factor6\n"); }
            | B2I factor                        { printf ("factor8\n"); }
            | I2R factor                        { printf ("factor9\n"); }
            | R2I factor                        { printf ("factor10\n"); }
            | RAND                              { printf ("factor11\n"); }
            ;
%%
