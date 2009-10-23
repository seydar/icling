#ifndef lint
static const char yysccsid[] = "@(#)yaccpar	1.9 (Berkeley) 02/21/93";
#endif

#include <stdlib.h>

#define YYBYACC 1
#define YYMAJOR 1
#define YYMINOR 9
#define YYPATCH 20050813

#define YYEMPTY (-1)
#define yyclearin    (yychar = YYEMPTY)
#define yyerrok      (yyerrflag = 0)
#define YYRECOVERING (yyerrflag != 0)

extern int yyparse(void);

static int yygrowstack(void);
#define YYPREFIX "yy"
#line 6 "foti.y"

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

#line 37 "y.tab.c"
#define ID 257
#define TRUE 258
#define FALSE 259
#define INTEGER 260
#define REAL 261
#define RAND 262
#define ASSGN 263
#define SEMI 264
#define IF 265
#define FI 266
#define DO 267
#define OD 268
#define DCOLON 269
#define QUESTION 270
#define COMMA 271
#define OR 272
#define AND 273
#define NOT 274
#define LT 275
#define LEQ 276
#define EQ 277
#define NEQ 278
#define GT 279
#define GEQ 280
#define PLUS 281
#define MINUS 282
#define STAR 283
#define SLASH 284
#define DSLASH 285
#define LPAREN 286
#define RPAREN 287
#define LSQUARE 288
#define RSQUARE 289
#define B2I 290
#define I2R 291
#define R2I 292
#define YYERRCODE 256
short yylhs[] = {                                        -1,
    0,    1,    1,    2,    2,    2,    2,    3,    4,    6,
    6,    7,    8,    5,    5,    5,    5,    5,   10,   10,
   13,   13,   11,   11,   12,    9,   14,   14,   15,   15,
   16,   16,   17,   17,   17,   17,   17,   17,   17,   18,
   18,   18,   18,   19,   19,   19,   19,   20,   20,   20,
   20,   20,   20,   20,   20,   20,   20,   20,
};
short yylen[] = {                                         2,
    1,    1,    3,    0,    1,    1,    1,    3,    3,    1,
    3,    3,    1,    3,    5,    4,    4,    3,    1,    3,
    1,    4,    1,    3,    1,    1,    1,    3,    1,    3,
    1,    2,    1,    3,    3,    3,    3,    3,    3,    1,
    2,    3,    3,    1,    3,    3,    3,    1,    1,    1,
    1,    1,    3,    3,    2,    2,    2,    1,
};
short yydefred[] = {                                      0,
   21,    0,    0,    0,    0,    0,    2,    5,    6,    7,
    0,    0,   25,    0,   48,   49,   50,   51,   58,    0,
    0,    0,    0,    0,    0,    0,    0,   10,    0,   13,
    0,    0,    0,   29,   31,    0,    0,   44,    0,    0,
    0,    0,    0,    0,   32,    0,    0,   23,    0,   55,
   56,   57,    8,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    9,    3,
    0,    0,    0,    0,    0,    0,   53,    0,   54,   11,
    0,    0,   30,    0,    0,    0,    0,    0,    0,    0,
    0,   45,   46,   47,    0,   22,   24,    0,
};
short yydgoto[] = {                                       5,
    6,    7,    8,    9,   10,   27,   28,   29,   48,   11,
   49,   14,   31,   32,   33,   34,   35,   36,   37,   38,
};
short yysindex[] = {                                   -248,
    0, -246, -222, -222,    0, -223,    0,    0,    0,    0,
 -253, -266,    0, -212,    0,    0,    0,    0,    0, -144,
 -134, -222, -222, -134, -134, -134, -204,    0, -207,    0,
 -266, -185, -187,    0,    0, -197, -176,    0, -242, -248,
 -186, -166, -222, -222,    0, -176, -194,    0, -264,    0,
    0,    0,    0, -222, -248, -222, -222, -144, -144, -144,
 -144, -144, -144, -134, -134, -134, -134, -134,    0,    0,
    0, -173, -164, -266, -192, -173,    0, -222,    0,    0,
 -223, -187,    0, -224, -224, -224, -224, -224, -224, -176,
 -176,    0,    0,    0, -222,    0,    0, -173,
};
short yyrindex[] = {                                      4,
    0,    0,    0,    0,    0,  101,    0,    0,    0,    0,
    0, -247,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    1,  209,  187,    0,    0,  111,   23,    0,    0,  221,
    0,    0,    0,  254,    0,   45,    0,    0,    0,    0,
    0,    0,    0,    0, -174,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
  231,  260,    0, -243,    0,  266,    0,    0,    0,    0,
 -219,  199,    0,  121,  133,  143,  155,  165,  177,   67,
   89,    0,    0,    0,  275,    0,    0,  297,
};
short yygindex[] = {                                      0,
   48,   70,    0,    0,    0,  108,   65,    0,   -1,    0,
  -36,   79,    6,    0,   66,   72,  110,  -29,  -21,  -12,
};
#define YYTABLESIZE 566
short yytable[] = {                                      46,
   52,   30,   30,    4,   72,   12,   78,   76,    1,   41,
   13,   50,   51,   52,    2,   19,    3,   42,    4,   20,
   47,   43,   40,   19,   79,   69,   54,   20,   84,   85,
   86,   87,   88,   89,    1,   15,   16,   17,   18,   19,
   40,   75,   90,   91,   41,   12,   12,   74,   12,   12,
   44,   20,   30,   92,   93,   94,   64,   65,   98,   21,
   12,   53,   55,   22,   54,   23,   42,   24,   25,   26,
   71,   15,   16,   17,   18,   19,   97,   58,   59,   60,
   61,   62,   63,   64,   65,   57,   56,   20,   43,    4,
    1,    4,   77,    4,    4,   21,   96,   78,   95,   22,
    1,   23,   81,   24,   25,   26,   66,   67,   68,   70,
   33,   39,    1,   15,   16,   17,   18,   19,   80,   73,
   34,   82,    1,   15,   16,   17,   18,   19,   83,   45,
    0,    0,   35,    0,    0,    0,    0,   21,    0,    0,
    0,   22,   36,   23,    0,   24,   25,   26,    0,    0,
    0,   22,    0,   23,   37,   24,   25,   26,    0,    0,
    0,    0,    0,    0,   39,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,   38,    0,    0,    0,
    0,    0,    0,    0,    0,    0,   27,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,   28,    0,
    0,    0,    0,    0,    0,    0,    0,    0,   26,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    4,    0,    0,    0,    0,    0,    0,    0,    0,    0,
   21,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,   18,    0,    0,    0,    0,    0,   14,
    0,    0,    0,    0,   52,   16,   52,    4,   52,   52,
   52,   52,   52,   52,   17,   52,   52,   52,   52,   52,
   52,   52,   52,   52,   52,   52,   40,   52,   40,   52,
   40,   40,   40,   40,   40,   40,   15,   40,   40,   40,
   40,   40,   40,   40,   40,    0,    0,    0,   41,   40,
   41,   40,   41,   41,   41,   41,   41,   41,    0,   41,
   41,   41,   41,   41,   41,   41,   41,    0,    0,    0,
   42,   41,   42,   41,   42,   42,   42,   42,   42,   42,
    0,   42,   42,   42,   42,   42,   42,   42,   42,    0,
    0,    0,   43,   42,   43,   42,   43,   43,   43,   43,
   43,   43,    0,   43,   43,   43,   43,   43,   43,   43,
   43,    0,    0,    0,   33,   43,   33,   43,   33,   33,
   33,   33,   33,   33,   34,    0,   34,    0,   34,   34,
   34,   34,   34,   34,    0,    0,   35,   33,   35,   33,
   35,   35,   35,   35,   35,   35,   36,   34,   36,   34,
   36,   36,   36,   36,   36,   36,    0,    0,   37,   35,
   37,   35,   37,   37,   37,   37,   37,   37,   39,   36,
   39,   36,   39,   39,   39,   39,   39,   39,    0,    0,
   38,   37,   38,   37,   38,   38,   38,   38,   38,   38,
   27,   39,   27,   39,   27,   27,   27,   27,   27,    0,
    0,    0,   28,   38,   28,   38,   28,   28,   28,   28,
   28,    0,   26,   27,   26,   27,   26,   26,   26,   26,
    0,    0,    0,    0,    4,   28,    4,   28,    4,    4,
    0,    0,    0,   25,   21,   26,   21,   26,   21,   21,
    0,   21,   21,   21,    0,   21,   21,   21,   21,   21,
   21,   21,   21,   21,   21,   21,    0,   18,   21,   18,
    0,   18,   18,   14,    0,   14,    0,   14,   14,   16,
    0,   16,    0,   16,   16,    0,    0,    0,   17,    0,
   17,    0,   17,   17,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
   15,    0,   15,    0,   15,   15,
};
short yycheck[] = {                                      21,
    0,    3,    4,    0,   41,    0,  271,   44,  257,  263,
  257,   24,   25,   26,  263,  263,  265,  271,  267,  263,
   22,  288,    0,  271,  289,  268,  269,  271,   58,   59,
   60,   61,   62,   63,  257,  258,  259,  260,  261,  262,
  264,   43,   64,   65,    0,   40,  266,   42,  268,  269,
  263,  274,   54,   66,   67,   68,  281,  282,   95,  282,
   55,  266,  270,  286,  269,  288,    0,  290,  291,  292,
  257,  258,  259,  260,  261,  262,   78,  275,  276,  277,
  278,  279,  280,  281,  282,  273,  272,  274,    0,  264,
  257,  266,  287,  268,  269,  282,  289,  271,  263,  286,
    0,  288,   55,  290,  291,  292,  283,  284,  285,   40,
    0,    4,  257,  258,  259,  260,  261,  262,   54,   41,
    0,   56,  257,  258,  259,  260,  261,  262,   57,   20,
   -1,   -1,    0,   -1,   -1,   -1,   -1,  282,   -1,   -1,
   -1,  286,    0,  288,   -1,  290,  291,  292,   -1,   -1,
   -1,  286,   -1,  288,    0,  290,  291,  292,   -1,   -1,
   -1,   -1,   -1,   -1,    0,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,    0,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,    0,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,    0,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,    0,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
    0,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
    0,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,    0,   -1,   -1,   -1,   -1,   -1,    0,
   -1,   -1,   -1,   -1,  264,    0,  266,  264,  268,  269,
  270,  271,  272,  273,    0,  275,  276,  277,  278,  279,
  280,  281,  282,  283,  284,  285,  264,  287,  266,  289,
  268,  269,  270,  271,  272,  273,    0,  275,  276,  277,
  278,  279,  280,  281,  282,   -1,   -1,   -1,  264,  287,
  266,  289,  268,  269,  270,  271,  272,  273,   -1,  275,
  276,  277,  278,  279,  280,  281,  282,   -1,   -1,   -1,
  264,  287,  266,  289,  268,  269,  270,  271,  272,  273,
   -1,  275,  276,  277,  278,  279,  280,  281,  282,   -1,
   -1,   -1,  264,  287,  266,  289,  268,  269,  270,  271,
  272,  273,   -1,  275,  276,  277,  278,  279,  280,  281,
  282,   -1,   -1,   -1,  264,  287,  266,  289,  268,  269,
  270,  271,  272,  273,  264,   -1,  266,   -1,  268,  269,
  270,  271,  272,  273,   -1,   -1,  264,  287,  266,  289,
  268,  269,  270,  271,  272,  273,  264,  287,  266,  289,
  268,  269,  270,  271,  272,  273,   -1,   -1,  264,  287,
  266,  289,  268,  269,  270,  271,  272,  273,  264,  287,
  266,  289,  268,  269,  270,  271,  272,  273,   -1,   -1,
  264,  287,  266,  289,  268,  269,  270,  271,  272,  273,
  264,  287,  266,  289,  268,  269,  270,  271,  272,   -1,
   -1,   -1,  264,  287,  266,  289,  268,  269,  270,  271,
  272,   -1,  264,  287,  266,  289,  268,  269,  270,  271,
   -1,   -1,   -1,   -1,  264,  287,  266,  289,  268,  269,
   -1,   -1,   -1,  263,  264,  287,  266,  289,  268,  269,
   -1,  271,  272,  273,   -1,  275,  276,  277,  278,  279,
  280,  281,  282,  283,  284,  285,   -1,  264,  288,  266,
   -1,  268,  269,  264,   -1,  266,   -1,  268,  269,  264,
   -1,  266,   -1,  268,  269,   -1,   -1,   -1,  264,   -1,
  266,   -1,  268,  269,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
  264,   -1,  266,   -1,  268,  269,
};
#define YYFINAL 5
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
#define YYMAXTOKEN 292
#if YYDEBUG
char *yyname[] = {
"end-of-file",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"ID","TRUE","FALSE","INTEGER",
"REAL","RAND","ASSGN","SEMI","IF","FI","DO","OD","DCOLON","QUESTION","COMMA",
"OR","AND","NOT","LT","LEQ","EQ","NEQ","GT","GEQ","PLUS","MINUS","STAR","SLASH",
"DSLASH","LPAREN","RPAREN","LSQUARE","RSQUARE","B2I","I2R","R2I",
};
char *yyrule[] = {
"$accept : program",
"program : stmts",
"stmts : stmt",
"stmts : stmts SEMI stmt",
"stmt :",
"stmt : selection",
"stmt : iteration",
"stmt : assignment",
"selection : IF alts FI",
"iteration : DO alts OD",
"alts : alt",
"alts : alts DCOLON alt",
"alt : guard QUESTION stmts",
"guard : expr",
"assignment : vars ASSGN exprs",
"assignment : vars ASSGN subprogram ASSGN exprs",
"assignment : ASSGN subprogram ASSGN exprs",
"assignment : vars ASSGN subprogram ASSGN",
"assignment : ASSGN subprogram ASSGN",
"vars : var",
"vars : vars COMMA var",
"var : ID",
"var : var LSQUARE expr RSQUARE",
"exprs : expr",
"exprs : exprs COMMA expr",
"subprogram : ID",
"expr : disjunction",
"disjunction : conjunction",
"disjunction : disjunction OR conjunction",
"conjunction : negation",
"conjunction : conjunction AND negation",
"negation : relation",
"negation : NOT relation",
"relation : sum",
"relation : sum LT sum",
"relation : sum LEQ sum",
"relation : sum EQ sum",
"relation : sum NEQ sum",
"relation : sum GEQ sum",
"relation : sum GT sum",
"sum : term",
"sum : MINUS term",
"sum : sum PLUS term",
"sum : sum MINUS term",
"term : factor",
"term : term STAR factor",
"term : term SLASH factor",
"term : term DSLASH factor",
"factor : TRUE",
"factor : FALSE",
"factor : INTEGER",
"factor : REAL",
"factor : var",
"factor : LPAREN expr RPAREN",
"factor : LSQUARE exprs RSQUARE",
"factor : B2I factor",
"factor : I2R factor",
"factor : R2I factor",
"factor : RAND",
};
#endif
#ifndef YYSTYPE
typedef int YYSTYPE;
#endif
#if YYDEBUG
#include <stdio.h>
#endif

/* define the initial stack-sizes */
#ifdef YYSTACKSIZE
#undef YYMAXDEPTH
#define YYMAXDEPTH  YYSTACKSIZE
#else
#ifdef YYMAXDEPTH
#define YYSTACKSIZE YYMAXDEPTH
#else
#define YYSTACKSIZE 500
#define YYMAXDEPTH  500
#endif
#endif

#define YYINITSTACKSIZE 500

int      yydebug;
int      yynerrs;
int      yyerrflag;
int      yychar;
short   *yyssp;
YYSTYPE *yyvsp;
YYSTYPE  yyval;
YYSTYPE  yylval;

/* variables for the parser stack */
static short   *yyss;
static short   *yysslim;
static YYSTYPE *yyvs;
static int      yystacksize;
#line 129 "foti.y"

#line 372 "y.tab.c"
/* allocate initial stack or double stack size, up to YYMAXDEPTH */
static int yygrowstack(void)
{
    int newsize, i;
    short *newss;
    YYSTYPE *newvs;

    if ((newsize = yystacksize) == 0)
        newsize = YYINITSTACKSIZE;
    else if (newsize >= YYMAXDEPTH)
        return -1;
    else if ((newsize *= 2) > YYMAXDEPTH)
        newsize = YYMAXDEPTH;

    i = yyssp - yyss;
    newss = (yyss != 0)
          ? (short *)realloc(yyss, newsize * sizeof(*newss))
          : (short *)malloc(newsize * sizeof(*newss));
    if (newss == 0)
        return -1;

    yyss  = newss;
    yyssp = newss + i;
    newvs = (yyvs != 0)
          ? (YYSTYPE *)realloc(yyvs, newsize * sizeof(*newvs))
          : (YYSTYPE *)malloc(newsize * sizeof(*newvs));
    if (newvs == 0)
        return -1;

    yyvs = newvs;
    yyvsp = newvs + i;
    yystacksize = newsize;
    yysslim = yyss + newsize - 1;
    return 0;
}

#define YYABORT goto yyabort
#define YYREJECT goto yyabort
#define YYACCEPT goto yyaccept
#define YYERROR goto yyerrlab
int
yyparse(void)
{
    register int yym, yyn, yystate;
#if YYDEBUG
    register const char *yys;

    if ((yys = getenv("YYDEBUG")) != 0)
    {
        yyn = *yys;
        if (yyn >= '0' && yyn <= '9')
            yydebug = yyn - '0';
    }
#endif

    yynerrs = 0;
    yyerrflag = 0;
    yychar = YYEMPTY;

    if (yyss == NULL && yygrowstack()) goto yyoverflow;
    yyssp = yyss;
    yyvsp = yyvs;
    *yyssp = yystate = 0;

yyloop:
    if ((yyn = yydefred[yystate]) != 0) goto yyreduce;
    if (yychar < 0)
    {
        if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, reading %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
    }
    if ((yyn = yysindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: state %d, shifting to state %d\n",
                    YYPREFIX, yystate, yytable[yyn]);
#endif
        if (yyssp >= yysslim && yygrowstack())
        {
            goto yyoverflow;
        }
        *++yyssp = yystate = yytable[yyn];
        *++yyvsp = yylval;
        yychar = YYEMPTY;
        if (yyerrflag > 0)  --yyerrflag;
        goto yyloop;
    }
    if ((yyn = yyrindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
        yyn = yytable[yyn];
        goto yyreduce;
    }
    if (yyerrflag) goto yyinrecovery;

    yyerror("syntax error");

#ifdef lint
    goto yyerrlab;
#endif

yyerrlab:
    ++yynerrs;

yyinrecovery:
    if (yyerrflag < 3)
    {
        yyerrflag = 3;
        for (;;)
        {
            if ((yyn = yysindex[*yyssp]) && (yyn += YYERRCODE) >= 0 &&
                    yyn <= YYTABLESIZE && yycheck[yyn] == YYERRCODE)
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: state %d, error recovery shifting\
 to state %d\n", YYPREFIX, *yyssp, yytable[yyn]);
#endif
                if (yyssp >= yysslim && yygrowstack())
                {
                    goto yyoverflow;
                }
                *++yyssp = yystate = yytable[yyn];
                *++yyvsp = yylval;
                goto yyloop;
            }
            else
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: error recovery discarding state %d\n",
                            YYPREFIX, *yyssp);
#endif
                if (yyssp <= yyss) goto yyabort;
                --yyssp;
                --yyvsp;
            }
        }
    }
    else
    {
        if (yychar == 0) goto yyabort;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, error recovery discards token %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
        yychar = YYEMPTY;
        goto yyloop;
    }

yyreduce:
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: state %d, reducing by rule %d (%s)\n",
                YYPREFIX, yystate, yyn, yyrule[yyn]);
#endif
    yym = yylen[yyn];
    yyval = yyvsp[1-yym];
    switch (yyn)
    {
case 1:
#line 30 "foti.y"
{ printf ("program1 accepted\n"); }
break;
case 2:
#line 33 "foti.y"
{ printf ("stmts1\n"); }
break;
case 3:
#line 34 "foti.y"
{ printf ("stmts2\n"); }
break;
case 4:
#line 37 "foti.y"
{ printf ("stmt1\n"); }
break;
case 5:
#line 38 "foti.y"
{ printf ("stmt2\n"); }
break;
case 6:
#line 39 "foti.y"
{ printf ("stmt2\n"); }
break;
case 7:
#line 40 "foti.y"
{ printf ("stmt3\n"); }
break;
case 8:
#line 43 "foti.y"
{ printf ("selection1\n"); }
break;
case 9:
#line 46 "foti.y"
{ printf ("iteration1\n"); }
break;
case 10:
#line 49 "foti.y"
{ printf ("alts1\n"); }
break;
case 11:
#line 50 "foti.y"
{ printf ("alts2\n"); }
break;
case 12:
#line 53 "foti.y"
{ printf ("alt1\n"); }
break;
case 13:
#line 56 "foti.y"
{ printf ("guard1\n"); }
break;
case 14:
#line 59 "foti.y"
{ printf ("assignment1\n"); }
break;
case 15:
#line 60 "foti.y"
{ printf ("assignment2\n"); }
break;
case 16:
#line 61 "foti.y"
{ printf ("assignment3\n"); }
break;
case 17:
#line 62 "foti.y"
{ printf ("assignment4\n"); }
break;
case 18:
#line 63 "foti.y"
{ printf ("assignment5\n"); }
break;
case 19:
#line 66 "foti.y"
{ printf ("vars1\n"); }
break;
case 20:
#line 67 "foti.y"
{ printf ("vars2\n"); }
break;
case 21:
#line 70 "foti.y"
{ printf("var1\n"); }
break;
case 22:
#line 71 "foti.y"
{ printf("var2\n"); }
break;
case 23:
#line 74 "foti.y"
{ printf ("exprs1\n"); }
break;
case 24:
#line 75 "foti.y"
{ printf ("exprs2\n"); }
break;
case 25:
#line 78 "foti.y"
{ printf ("subprogram1\n"); }
break;
case 26:
#line 81 "foti.y"
{ printf ("expr1\n"); }
break;
case 27:
#line 84 "foti.y"
{ printf ("disjunction1\n"); }
break;
case 28:
#line 85 "foti.y"
{ printf ("disjunction2\n"); }
break;
case 29:
#line 88 "foti.y"
{ printf ("conjunction1\n"); }
break;
case 30:
#line 89 "foti.y"
{ printf ("conjunction2\n"); }
break;
case 31:
#line 92 "foti.y"
{ printf("negation1\n"); }
break;
case 32:
#line 93 "foti.y"
{ printf("negation2\n"); }
break;
case 33:
#line 96 "foti.y"
{ printf ("relation1\n"); }
break;
case 34:
#line 97 "foti.y"
{ printf ("relation2\n"); }
break;
case 35:
#line 98 "foti.y"
{ printf ("relation3\n"); }
break;
case 36:
#line 99 "foti.y"
{ printf ("relation4\n"); }
break;
case 37:
#line 100 "foti.y"
{ printf ("relation5\n"); }
break;
case 38:
#line 101 "foti.y"
{ printf ("relation6\n"); }
break;
case 39:
#line 102 "foti.y"
{ printf ("relation7\n"); }
break;
case 40:
#line 105 "foti.y"
{ printf ("sum1\n"); }
break;
case 41:
#line 106 "foti.y"
{ printf ("sum2\n"); }
break;
case 42:
#line 107 "foti.y"
{ printf ("sum3\n"); }
break;
case 43:
#line 108 "foti.y"
{ printf ("sum4\n"); }
break;
case 44:
#line 111 "foti.y"
{ printf ("term1\n"); }
break;
case 45:
#line 112 "foti.y"
{ printf ("term2\n"); }
break;
case 46:
#line 113 "foti.y"
{ printf ("term3\n"); }
break;
case 47:
#line 114 "foti.y"
{ printf ("term4\n"); }
break;
case 48:
#line 117 "foti.y"
{ printf ("factor1\n"); }
break;
case 49:
#line 118 "foti.y"
{ printf ("factor2\n"); }
break;
case 50:
#line 119 "foti.y"
{ printf ("factor3\n"); }
break;
case 51:
#line 120 "foti.y"
{ printf ("factor4\n"); }
break;
case 52:
#line 121 "foti.y"
{ printf ("factor5\n"); }
break;
case 53:
#line 122 "foti.y"
{ printf ("factor6\n"); }
break;
case 54:
#line 123 "foti.y"
{ printf ("factor7\n"); }
break;
case 55:
#line 124 "foti.y"
{ printf ("factor8\n"); }
break;
case 56:
#line 125 "foti.y"
{ printf ("factor9\n"); }
break;
case 57:
#line 126 "foti.y"
{ printf ("factor10\n"); }
break;
case 58:
#line 127 "foti.y"
{ printf ("factor11\n"); }
break;
#line 782 "y.tab.c"
    }
    yyssp -= yym;
    yystate = *yyssp;
    yyvsp -= yym;
    yym = yylhs[yyn];
    if (yystate == 0 && yym == 0)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: after reduction, shifting from state 0 to\
 state %d\n", YYPREFIX, YYFINAL);
#endif
        yystate = YYFINAL;
        *++yyssp = YYFINAL;
        *++yyvsp = yyval;
        if (yychar < 0)
        {
            if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
            if (yydebug)
            {
                yys = 0;
                if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
                if (!yys) yys = "illegal-symbol";
                printf("%sdebug: state %d, reading %d (%s)\n",
                        YYPREFIX, YYFINAL, yychar, yys);
            }
#endif
        }
        if (yychar == 0) goto yyaccept;
        goto yyloop;
    }
    if ((yyn = yygindex[yym]) && (yyn += yystate) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yystate)
        yystate = yytable[yyn];
    else
        yystate = yydgoto[yym];
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: after reduction, shifting from state %d \
to state %d\n", YYPREFIX, *yyssp, yystate);
#endif
    if (yyssp >= yysslim && yygrowstack())
    {
        goto yyoverflow;
    }
    *++yyssp = yystate;
    *++yyvsp = yyval;
    goto yyloop;

yyoverflow:
    yyerror("yacc stack overflow");

yyabort:
    return (1);

yyaccept:
    return (0);
}
