/* FILE:        iog.c
 * PURPOSE:     Machine to execute self-describing grammars
 * COPYRIGHT:   1988 W. M. McKeeman.  You may do anything you like
 *              with this file except remove or alter this notice.
 * EXITS:	0-success  1-unused input  2-missing command line argument
 *		3/4/5-illegal op in PARSE/BACK/SEACH
 * MODS:        2008.06.11 -- mckeeman -- ported to c89 MEX
 */
/* NOTE: WORK IN PROGRESS  adding '*' to iog */

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include "mex.h"

#define DATALIM  10000
#define STACKLIM 10000

#define pss (ps - &codestack[0])

#define C(c) case c:
#define ALPHA UPPER LOWER
#define LOWER \
C('a')C('b')C('c')C('d')C('e')C('f')C('g')C('h')C('i')C('j')C('k')C('l')C('m')\
C('n')C('o')C('p')C('q')C('r')C('s')C('t')C('u')C('v')C('w')C('x')C('y')C('z')
#define UPPER \
C('A')C('B')            C('E')C('F')C('G')C('H')C('I')C('J')C('K')      C('M')\
C('N')C('O')C('P')C('Q')C('R')C('S')C('T')C('U')C('V')C('W')C('X')C('Y')C('Z')

#define SEARCH 1
#define BACK   2
#define PARSE  3

static char  code[DATALIM];
static char *codestack[STACKLIM];
static char  input[DATALIM];
static char  output[DATALIM];
static char *parse[STACKLIM];
static char  ini[7];

static char *p0, *p, **ps;                      /* program */
static char *i0, *i;                            /* input */
static char *o0, *o;                            /* output */
static char **es;                               /* parse */
static int   mode;                              /* PARSE/BACK/SEARCH */
static int   traceit;

/* ------------------- helper functions ------------------- */
static void 
TRACE(void) {
  printf("%s  stk:%d **ps:%c  p:%d *p:%c  i:%d *i:%c  o:%d *o:%c\n",
  mode == PARSE ? " PARSE" : mode == BACK ? "  BACK" : "SEARCH", 
  pss, pss>=0?**ps:'#',
  p-p0, p-p0>=0&&*p!=0?*p:'#', 
  i-i0, i-i0>=0&&*i!=0?*i:'#',
  o-o0, o-o0>=0&&*o!=0?*o:'#');
}

static void
error(const char *msg) {
  printf("input: %s\n", input);
  printf("gem: %s p=%d  *p='%c'  i=%d  o=%d\n",
    msg, p-p0, *p, i-i0, o-o0);
  mexErrMsgTxt("gem error");
}

static void
clear(char *b) {
  int idx;
  for (idx=0;idx<DATALIM;idx++) b[idx]=0;
}

/* set up static globals */
static void
pregem(const char *gr, const char *in, const char *flag) {
  char *k;                                    /* input pointer */
  clear(code);
  
  p = p0 = &code[0];                          /* start of "code" */
  *p0 = ';';                                  /* make first rule visible */
  ps = &codestack[0];                         /* code ptr stack empty */
  strcpy(ini, "=G'x';");                      /* fake initial rule */
  ini[3]=0;                                   /* embed a null */
  *ps = ini;                                  /* pretend previous progress */
  (*ps)++;                                    /* point at G */
  k = p0+1;                                   /* after gratuitous ; */
  **ps = *k++ = *gr++;                        /* goal symbol */
  
  strcpy(k, gr);                              /* into "code" */
  
  i = i0 = &input[0];                         /* start of "input" */
  k = i0;
  strcpy(k, in);
  
  o = o0 = &output[0];
  o--;                                        /* empty "output" */
  
  es = &parse[0];
  es--;                                       /* empty "parse" */
  
  mode = SEARCH;                              /* start searching */
  traceit = strcmp(flag, "-traceGem") == 0;
}

/* execute grammar */
static void
gem(void) {
  for (;;) {
    if (traceit) TRACE();                 /* iog(g,i,'-traceGem') */
    
    /* executing rules */
    switch (mode) {
      case PARSE:
        switch (*p) {
          case 'C':                         /* generic character */
            if (*i == '\0') {mode = BACK; p--;}
            else {o++; *o = *i; i++; p++;}    /*   read-match */
            break;
          case 'D':                         /* generic digit */
            if (!isdigit(*i)) {mode = BACK; p--;}
            else {o++; *o = *i; i++; p++;}	  /*   read-match */
            break;
          case 'L':                         /* generic letter */
            if (!isalpha(*i)) {mode = BACK; p--;}
            else {o++; *o = *i; i++; p++;}    /*   read-match */
            break;
            ALPHA                             /* call new rule */
            mode = SEARCH;                    /*   search on */
            ps++; *ps = p;                    /*   save return address */
            p = p0; break;                    /*   start at beginning */
          case '\'':                        /* input */
            p++;                              /*   pass 1rst ' */
            if (*p == *i) {i++; p++; p++;}    /*   read-match */
            else {mode = BACK; p--; p--;}     /*   read-mismatch */
            break;
          case '"':                         /* output */
            p++; o++;                         /*   pass 1rst " */
            *o = *p;                          /*   move literal to output*/
            p++; p++; break;                  /*   pass literal and 2nd " */
          case ';':                    	    /* rule end (parsing) */
            p--;                              /* back over ; */
            es++; *es = p;                    /* code pointer for backup */
            if (pss < 0) {
              return;                         /* success */
            }
            p = *ps; ps--;                    /* return from rule */
            p++; break;                       /* beyond nonterminal */
            default:
              error("Unexpected character (PARSE)");
        }
        break;
        
        /* backtracking */
      case BACK:
        switch (*p) {
          case 'C': case 'D': case 'L':	    /* special letters */
            o--; i--; p--; break;             /* undo everything */
            ALPHA                             /* recall rule */
            ps++; *ps = p;                    /* save return address */
            p = *es; es--; break;             /* end of previous rule */
          case '\'':                        /* input */
            i--;                              /* un-read input */
            p--; p--; p--; break;             /* un-pass literal */
          case '"':                         /* output */
            o--;                              /* un-put output */
            p--; p--; p--; break;             /* un-pass literal */
          case '=':                         /* rule begin (backtracking) */
            mode = SEARCH;                    /* forward again */
            p++; break;                       /* pass = */
            default:
              error("Unexpected character (BACK)");
        }
        break;
        
        /* searching for a rule */
      case SEARCH:
        switch (*p) {
          case 'C': case 'D': case 'L': ALPHA /* letter */
          p++; break;                         /* skip it */
          case '\'': case '"':              /* terminals */
            p++; p++; p++; break;             /* skip 'x' or "x" */
          case ';':                         /* rule coming */
            p++;                              /* pass ; */
            if (*p==**ps) mode = PARSE;       /* lhs=nonterminal */
            p++; p++; break;                  /* skip lhs = */
          case '\0':                        /* out of choices */
            if (pss == 0) error("Unparsable input");  /* incorrect input */
            p = *ps; ps--;                    /* back out one rule */
            mode = BACK;                      /* reverse direction */
            p--; break;                       /* skip nonterminal */
            default:
              error("Unexpected character (SEARCH)");
        }
        break;
    }
  }
}

/* clean up and report result */
static char *
postgem(void) {
  o++; *o = '\0';                           /* null terminate "output" */
  return output;
}

/* ************************************************************** */
void
mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
  char *o, *g, *i, *f;
  const int dims[] = {1,1};
  
  /* check inputs */
  mxAssert(nrhs == 2 || nrhs == 3, "bad call: use gem(g,i) or gem(g,i,f)");    
  mxAssert(nlhs<=1, "bad call: use o = gem(g,i)");

  mxAssert(mxIsChar(prhs[0]), "bad call: requires char 1st arg");    
  g = mxArrayToString(prhs[0]);             /* the grammar */
  mxAssert(mxIsChar(prhs[1]), "bad call: requires char 2nd arg");   
  i = mxArrayToString(prhs[1]);             /* the input */
  if (nrhs == 3) {
    mxAssert(mxIsChar(prhs[2]), "bad call: requires char flag");   
    f = mxArrayToString(prhs[2]);           /* a flag */
  } else {
    f = "";                                 /* trace off */
  }
  
  pregem(g, i, f);                          /* set up globals */
  gem();                                    /* translate */
  o = postgem();                            /* report result */
  
  mxFree(g);
  mxFree(i);
  if (nrhs == 3) mxFree(f);
  
  plhs[0] = mxCreateString(o);
}

