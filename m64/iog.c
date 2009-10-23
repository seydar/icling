/* FILE:        iog.c
 * PURPOSE:     Machine to execute self-describing grammars
 * COPYRIGHT:   1988 W. M. McKeeman.  You may do anything you like
 *              with this file except remove or alter this notice.
 * METHOD:      Skating on thin ice -- this code is always on the edge
 *              of catastrophic failure.  See iog2.c for an implementation
 *              that pays attention to efficiency and reliability.
 * MODS:        2008.06.11 -- mckeeman -- ported to c89 MEX
 *              2009.01.16 -- mckeeman -- removed character classes
 */

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include "mex.h"

#define DATALIM  10000
#define STACKLIM 10000

#define C(c) case c:
#define ALPHA UPPER LOWER
#define LOWER \
C('a')C('b')C('c')C('d')C('e')C('f')C('g')C('h')C('i')C('j')C('k')C('l')C('m')\
C('n')C('o')C('p')C('q')C('r')C('s')C('t')C('u')C('v')C('w')C('x')C('y')C('z')
#define UPPER \
C('A')C('B')C('C')C('D')C('E')C('F')C('G')C('H')C('I')C('J')C('K')C('L')C('M')\
C('N')C('O')C('P')C('Q')C('R')C('S')C('T')C('U')C('V')C('W')C('X')C('Y')C('Z')

#define SEARCH 1
#define BACK   2
#define PARSE  3

#define pss (ps - &parsestack[0])
#define ess (es - &backstack[0])

static char  code[DATALIM];
static char  input[DATALIM];
static char  output[DATALIM];
static char *parsestack[STACKLIM];
static char *backstack[STACKLIM];
static char  ini[7];

static char *p0, *p, **ps, **es;                /* program pointers */
static int   pN;                                /* end of program */
static char *i0, *i;                            /* input pointers */
static char *o0, *o;                            /* output pointers */
static int   mode;                              /* PARSE/BACK/SEARCH */
static int   traceit;

/* ------------------- helper functions ------------------- */
static void 
TRACE(void) {
  if (pss>=0)
  printf("%s  stk:%d **ps:%c  p:%d *p:%c  i:%d *i:%c  o:%d *o:%c\n",
  mode == PARSE ? " PARSE" : mode == BACK ? "  BACK" : "SEARCH", 
  pss, **ps,
  p-p0, p-p0>=0&&*p!=0?*p:'#', 
  i-i0, i-i0>=0&&*i!=0?*i:'#',
  o-o0, o-o0>=0&&*o!=0?*o:'#');
}

static void
error(const char *msg) {
  printf("input: %s\n", input);
  printf("gem: %s p=%d  *p='%c'  i=%d  o=%d\n",
    msg, p-p0, *p==0?'#':*p, i-i0, o-o0);
  mexErrMsgTxt("gem error");
}

static void
clear(char *b, int n) {
  int idx;
  for (idx=0;idx<n;idx++) b[idx]=0;
}

/* set up static globals */
static void
pregem(const char *gr, const char *in, const char *flag) {
  char goal;
  int initlen;
  
  clear(code, sizeof(code));                /* make it all zeros */
  strcpy(code, "=G'X';");                   /* zero-th rule */
  initlen = strlen(code);                   /* size of init string */
  p = p0 = code+initlen-1;                  /* point at ; */
  goal = gr[0];                             /* user goal symbol */
  code[1] = goal;                           /* overwrite G */
  if (initlen+strlen(gr)>=sizeof(code)) error("input grammar too long");
  strcat(code, gr);                         /* add rest of user code */
  pN = strlen(code)-initlen+1;              /* end of code */
  code[3] = 0;                              /* overwrite X */
  
  clear(input, sizeof(input));              /* make it all zeros */
  i = i0 = input;                           /* start of "input" */
  if (strlen(in)>=sizeof(input)) error("input text too long");
  strcpy(input, in);                        /* null terminated */
  
  clear(output, sizeof(output));            /* make it all zeros */
  o = o0 = output;                          /* start of output */
  o--;                                      /* empty "output" */
  
  ps = &parsestack[0];                      /* code ptr stack empty */
  *ps = code;                               /* pretend previous progress */
  (*ps)++;                                  /* point at G */
  **ps = goal;                              /* replace G with goal symbol */
  es = &backstack[0];
  es--;                                     /* empty "parse" */

  mode = SEARCH;                            /* looking at ; in code[0] */
  traceit = strcmp(flag, "-gemTrace") == 0;
}

/* execute grammar */
static void
gem(void) {
  for (;;) {
    if (traceit) TRACE();                 /* iog(i,g,'-traceGem') */
    if (pss>=STACKLIM) error("PARSE stack overflow");
    if (ess>=STACKLIM) error("BACK stack overflow");
    switch (mode) {
      /* executing rules */
      case PARSE:
        switch (*p) {
        ALPHA                             /* call new rule */
          ps++; *ps = p;                    /*   save return address */
          p = p0; mode = SEARCH; break;     /*   search from beginning */
        case '\'':                        /* input */
          p++;                              /*   skip over 1rst ' */
          if (*p == *i) {i++; p++; p++;}    /*   read-match */
          else {mode = BACK; p--; p--;}     /*   read-mismatch */
          break;
        case '"':                         /* output */
          p++; o++;                         /*   skip over 1rst " */
          *o = *p;                          /*   move literal to output*/
          p++; p++; break;                  /*   skip over 2nd " */
        case ';':                         /* rule end (parsing) */
          p--;                              /*   back up over ; */
          es++; *es = p;                    /*   save backup pointer */
          if (pss < 0) return;              /*   empty stack: success */
          p = *ps; ps--;                    /*   return from rule */
          p++; break;                       /*   skip over rule name */
        default:                          /* bad char in grammar */
          error("Unexpected character (PARSE)");
        }
        break;                            /* end of parse step */
        
      /* backtracking */
      case BACK:
      switch (*p) {
        ALPHA                             /* un-return from rule */
          ps++; *ps = p;                    /* save return address */
          p = *es; es--; break;             /* end of previous rule */
        case '\'':                        /* input */
          i--;                              /* un-get input */
          p--; p--; p--; break;             /* un-skip literal */
        case '"':                         /* output */
          o--;                              /* un-put output */
          p--; p--; p--; break;             /* un-skip literal */
        case '=':                         /* rule begin (backtracking) */
          mode = SEARCH;                    /* forward again */
          p++; break;                       /* skip by = */
        default:
          error("Unexpected character (BACK)");
        }
        break;                            /* end of back step */
        
      /* searching for a rule */
      case SEARCH:
        switch (*p) {
        ALPHA                             /* phrase name */
          p++; break;                       /* skip over name */
        case '\'': case '"':              /* input/output */
          p++; p++; p++; break;             /* skip over 'x' or "x" */
        case ';':                         /* rule coming */
          p++;                              /* skip over ; */
          if (p-p0==pN) {                   /* end of code */
            if (pss == 0) error("Unparsable input");
            p = *ps; ps--;               /* back out one rule */
            mode = BACK;                    /* reverse direction */
            p--; break;                     /* un-skip over ; */
          }
          if (*p==**ps) mode = PARSE;       /* lhs is phrase name */
          p++; p++; break;                  /* skip over lhs = */
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
  
  /* check inputs */
  mxAssert(nrhs == 2 || nrhs == 3, "bad call: use gem(i,g) or gem(i,g,f)");    
  mxAssert(nlhs<=1, "bad call: use o = gem(i,g)");

  mxAssert(mxIsChar(prhs[0]), "bad call: requires char 1st arg");    
  i = mxArrayToString(prhs[0]);             /* the input */
  mxAssert(mxIsChar(prhs[1]), "bad call: requires char 2nd arg");   
  g = mxArrayToString(prhs[1]);             /* the grammar */
  if (nrhs == 3) {
    mxAssert(mxIsChar(prhs[2]), "bad call: requires char flag");   
    f = mxArrayToString(prhs[2]);           /* a flag */
  } else {
    f = "";                                 /* no flag */
  }
  
  pregem(g, i, f);                          /* set up globals */
  gem();                                    /* translate */
  o = postgem();                            /* report result */
  
  mxFree(g);
  mxFree(i);
  if (nrhs == 3) mxFree(f);
  
  plhs[0] = mxCreateString(o);
}

