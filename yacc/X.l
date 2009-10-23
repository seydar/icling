/*
 * FILE: X.l
 * PURPOSE: Lexer for the X grammar, to be used in conjunction with X.y
 */

%{
#include <stdio.h>
#include "y.tab.h"
%}

%%
`.*\n       ;  /* eat up comments */
;           { return SEMI; }
"if"        { return IF; }
"fi"        {return FI; }
"do"        { return DO; }
"od"        { return OD; }
::          { return DCOLON; }
\?          { return QUESTION; }
,           { return COMMA; }
\|          { return OR; }
&           { return AND; }
~           { return NOT; }
"<"         { return LT; }
"<="        { return LEQ; }
=           { return EQ; }
"~="        { return NEQ; }
">"         { return GT; }
">="        { return GEQ; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return STAR; }
"/"         { return SLASH; }
"//"        { return DSLASH; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"["         { return LSQUARE; }
"]"         { return RSQUARE; }
"b2i"       { return B2I; }
"i2r"       { return I2R; }
"r2i"       { return R2I; }
true        { return TRUE; }
false       { return FALSE; }
rand        { return RAND; }
[A-Za-z][A-Za-z0-9]*     { return ID; }
[0-9]+ ;                 { return INTEGER; }
[0-9]+.[0-9]* ;          { return REAL; }
:=          { return ASSGN; }
%%

