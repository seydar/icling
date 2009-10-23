/* FILE:        iog3.c
 * PURPOSE:     Extended machine to execute self-describing grammars
 * COPYRIGHT:   1988 W. M. McKeeman.  You may do anything you like
 *              with this file except remove or alter this notice.
 * MODS:        2008.06.11 -- mckeeman -- ported to c89 MEX
 *              2009.01.16 -- mckeeman -- added character builtins
 *              2009.02.24 -- mckeeman -- added reliability
 * METHOD:      Assume a syntactically correct argument g of o=GEM(i,g);
 *              There is some internal syntax checking to give more
 *              reliable operation and better error messages.
 *
 *              A manufactured zero-th rule
 *                   =G'\0';
 *              is prepended to the user grammar.  The lhs of the rule is 
 *              not needed, so not put in the rule.
 *              The user goal is supplied from code[0] in the place marked
 *              G. A null is placed between the input quotes.
 *
 *              In effect the literal null terminator of the input matches
 *              the zero above, completing the zero-th rule, and then
 *              terminating because the parse stack is empty.
 *
 *              Deblanking is built into iog3.
 */

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include "mex.h"

/* character class defintions for switch */
#define C(c) case c:
#define ALPHA UPPER LOWER
/* luad and LUAD special for lower, upper, digit and ascii */
#define LOWER \
      C('b')C('c')      C('e')C('f')C('g')C('h')C('i')C('j')C('k')      C('m')\
C('n')C('o')C('p')C('q')C('r')C('s')C('t')C('u')C('v')C('w')C('x')C('y')C('z')
#define UPPER \
      C('B')C('C')      C('E')C('F')C('G')C('H')C('I')C('J')C('K')      C('M')\
C('N')C('O')C('P')C('Q')C('R')C('S')C('T')C('U')C('V')C('W')C('X')C('Y')C('Z')

#define SEARCH 1                            /* parsing modes */
#define BACK   2
#define PARSE  3

#define traceit   1                         /* bits in flag */
#define digitCFG (1<<1)                     /* skip by digit */
#define lowerCFG (1<<2)                     /* skip by lower */
#define upperCFG (1<<3)                     /* skip by upper */ 
#define asciiCFG (1<<4)                     /* skip by anything */
#define digitIOG (1<<5)                     /* pass digit to output */
#define lowerIOG (1<<6)                     /* pass lower to output */
#define upperIOG (1<<7)                     /* pass upper to output */
#define asciiIOG (1<<8)                     /* pass anything to output */

#define pss (ps - &parsestack[0])           /* parse stack size */
#define ess (es - &backstack[0])            /* backtrack stack size */

#define DATALIM  10000                      /* biggest input/output */
#define STACKLIM  3000                      /* deepest stack */

#define SEARCHANDRECUR                                            \
  mode = SEARCH;                /* not builtin L: search on */    \
  ps++; *ps = p;                /* save return address */         \
  p = p0;                       /* start at beginning */

#define UNCALL                                                    \
  ps++; *ps = p;                /* save return address */         \
  p = *es; es--;                /* forget backtrack */

#define DEBLANK                                                   \
  while (*p==' ' || *p=='\n') p++;  /* skip blanks and newlines */

static char  input[DATALIM];                /* i  in o=GEM(i,g) */
static char  output[DATALIM];               /* o  in o=GEM(i,g) */
static char  code[DATALIM];                 /* g  in o=GEM(i,g) */
static char *parsestack[STACKLIM];          /* recursive descent */

/* the backstack is largest just at the end because it must be capable
 * of completely backtracking out of the parse if something goes wrong */
static char *backstack[DATALIM];            /* backing out */

static char *p0, *p1, *p, **ps;                  /* program pointers */
static int   pN;                            /* max program size */
static char *i0, *i;                        /* input pointers */
static int   iN;                            /* max input size */
static char *o0, *o;                        /* output pointers */
static char **es;                           /* back track stack */
static int   mode;                          /* PARSE/BACK/SEARCH */
static int   flagbits;                      /* trace and appendices */

/* ------------------- helper functions ------------------- */
static void 
TRACE(void) {                               /* activate with -gemTrace */
  if (pss>=0)
  printf("%s  stk:%d **ps:%c  bak:%d p:%2d *p:%c  i:%2d *i:%c  o:%2d *o:%c\n",
  mode == PARSE ? " PARSE" : mode == BACK ? "  BACK" : "SEARCH", 
  pss, **ps, ess,
  p-p0, p-p0>=0&&*p!=0?*p:'#', 
  i-i0, i-i0>=0&&*i!=0?*i:'#',
  o-o0, o-o0>=0&&*o!=0?*o:'#');
}

static void
error(const char *msg) {                    /* general iog error routine */
  printf("input: %s\n", i0);               /* whole input */
  printf("gem: %s p=%d  *p='%c'  i=%d  o=%d\n",  /* error state */
    msg, p-p0, *p, i-i0, o-o0);
  mexErrMsgTxt("gem error");                /* user-visible message */
}

static void
clear(char *b, int n) {                     /* clean out arrays */
  int idx;
  for (idx=0;idx<n;idx++) b[idx]=0;
}

/* set up static globals */
static void
pregem(char *itxt, int ilen, char *gtxt, int glen, int flag) {
  i = i0 = itxt;                            /* start of input */
  iN = ilen;                                /* input length */
  /* the inserted zero-rule has length 5 */
  p = p0 = gtxt+5;                          /* point at ; in zero-th rule*/
  pN = glen-5;                              /* code length */
  
  clear(output, sizeof(output));            /* make it all zeros */
  o = o0 = output;                          /* start of output */
  o--;                                      /* "output" is empty */
  
  ps = parsestack;                          /* code ptr stack empty */
  *ps = gtxt;                               /* pretend previous progress */
  (*ps)++;                                  /* point at call of 1srt rule */
  es = backstack;
  es--;                                     /* back stack is empty */

  mode = SEARCH;                            /* looking at ; in i */
  flagbits = flag;
}

/* execute grammar */
static void
gem(void) {
  int fl, fu, isl, isu;
  DEBLANK                                  /* skip ' ' and '\n' */
  for (;;) {
    if (flagbits&traceit) TRACE();         /* o=iog(i,g,'-traceGem') */
    if (pss>=STACKLIM) error("PARSE stack overflow");
    if (ess>=DATALIM)  error("BACK stack overflow");
    switch (mode) {
      /* executing rhs of rule */
      case PARSE:
        switch (*p) {
          case 'A':
            if (flagbits&asciiIOG){	        /* pass ascii */
              if (i-i0>=iN) {mode = BACK; p--;}
              else {o++; *o = *i; i++; p++;}  /* input match */
            } else {
              SEARCHANDRECUR
            }
            break;
          case 'a':
            if (flagbits&asciiCFG) {	      /* accept ascii */
              if (i-i0>=iN) {mode = BACK; p--;}
              else {i++; p++;}                /* input match */
            } else {
              SEARCHANDRECUR
            }
            break;
          case 'D':
            if (flagbits&digitIOG) {        /* pass digit */
              if (!isdigit(*i)) {mode = BACK; p--;}
              else {o++; *o = *i; i++; p++;}	/*   read-match */
            } else {
              SEARCHANDRECUR
            }
            break;
          case 'd':
            if (flagbits&digitCFG) {        /* accept digit */
              if (!isdigit(*i)) {mode = BACK; p--;}
              else {i++; p++;}	                 /*   read-match */
            } else {
              SEARCHANDRECUR
            }
            break;
          case 'L':
            fl = flagbits&lowerIOG;
            fu = flagbits&upperIOG;
            if (fl||fu) {
              isl = 'a'<=*i && *i<='z';
              isu = 'A'<=*i && *i<='Z';
              if ((fl&&isl) || (fu&&isu)) {
                o++; *o = *i; i++; p++;    /*   read-match */
              } else { 
                mode = BACK; p--;
              }
            } else {
              SEARCHANDRECUR
            }
            break;
          case 'l':
            fl = flagbits&lowerCFG;
            fu = flagbits&upperCFG;
            if (fl||fu) {
              isl = 'a'<=*i && *i<='z';
              isu = 'A'<=*i && *i<='Z';
              if ((fl&&isl) || (fu&&isu)) {
                i++; p++;     	            /*   read-match */
              } else { 
                mode = BACK; p--;
              }
            } else {
              SEARCHANDRECUR
            }
            break;
          ALPHA                             /* call new rule */
            SEARCHANDRECUR
            break;
          
          case '\'':                        /* input */
            p1 = p;                           /* in case match fails */
            p++;                              /*   skip initial ' */
            if (*p=='\'') {                   /* ''' case */
              i++; p++;                       /* skip middle ' */
              if (*p != '\'') {
                error("missing matching right ' (PARSE)");
              }
              break;
            }
            /* multi-character input symbol */
            while (*p != '\'') {              /* to end of input symbol */
              if (*p == *i) {                 /* match, continue */
                i++; p++;                     /* skip literal */
              } else {
                mode = BACK; p = p1; p--;     /* match failed */
                break;
              }
            }
            p++;                              /* skip final ' */
            break;
            
          case '"':                         /* output */
            if (o >= output+sizeof(output)) error("output text too long");
            p++; o++;                         /*   pass 1rst " */
            *o = *p;                          /*   move literal to output*/
            p++; 
            if (*p!='"') error("missing matching \" (PARSE)"); 
            p++; break; 
          case ' ': case '\n':              /* ignore blank and newline */
            p++; break;
          case ';':                    	    /* rule end (parsing) */
            p--;                              /* back over ; */
            es++; *es = p;                    /* save backup point */
            if (pss < 0) return;              /* SUCCESS */
            p = *ps; ps--;                    /* return from rule */
            p++; break;                       /* beyond nonterminal */
          default:
            error("Unexpected character (PARSE)");
        }
        break;
        
      /* backtracking */
      case BACK:
        switch (*p) {
          case 'A':
            if (flagbits&asciiIOG) {o--; i--; p--;}
            else {UNCALL}
            break;
          case 'L':
            if (flagbits&(lowerIOG|upperIOG)) {o--; i--; p--;}
            else {UNCALL}
            break;
          case 'D':
            if (flagbits&digitIOG) {o--; i--; p--;}
            else {UNCALL}
            break;
          case 'a':
            if (flagbits&asciiCFG) {i--; p--;}
            else {UNCALL}
            break;
          case 'l':
            if (flagbits&(lowerCFG|upperCFG)) {i--; p--;}
            else {UNCALL}
            break;
          case 'd':
            if (flagbits&digitCFG) {i--; p--;}
            else {UNCALL}
            break;
          ALPHA                             /* recall rule */
            UNCALL
            break;                            /* end of previous rule */
          case '\'':                        /* input */
            i--;                              /* un-read input */
            p--; p--; p--; break;             /* un-pass literal */
          case '"':                         /* output */
            o--;                              /* un-put output */
            p--; p--; p--; break;             /* un-pass literal */
          case ' ': case '\n':              /* ignore blank and newline */
            p--; break;
          case '=':                         /* rule begin (backtracking) */
            mode = SEARCH;                    /* forward again */
            p++; break;                       /* skip by = */
          default:
            error("Unexpected character (BACK)");
        }
        break;
        
      /* searching for a rule */
      case SEARCH:
        switch (*p) {
        case 'a': case 'A': case 'd': case 'D': case 'l': case 'L':
        ALPHA                             /* phrase name in rule */
          p++; break;                       /* skip by phrase name */
        case '\'':                       /* input symbols */
          p++; p++;                        /* skip by 'x */
          if (*p != '\'') error("missing matching '(SEARCH)");
          p++; break;                      /* skip by 2nd ' */
        case '"':                        /* output symbols */
          p++; p++;                        /* skip by "x */
          if (*p != '"') error("missing matching \" (SEARCH)");
          p++; break;                      /* skip by 2nd " */
        case ' ': case '\n':
          p++; break;                     /* skip blank and newline */
        case ';':                         /* rule coming */
          p++;                              /* skip over ; */
          DEBLANK                           /* skip ' ' and '\n' */
          if (p-p0==pN) {                   /* end of code */
            if (pss == 0) error("Unparsable input");
            p = *ps; ps--;               /* back out one rule */
            mode = BACK;                    /* reverse direction */
            p--; break;                     /* un-skip over ; */
          }
          if (*p==**ps) mode = PARSE;       /* lhs == phrase name */
          p++;                              /* skip over lhs */
          DEBLANK                           /* skip ' ' and '\n' */
          if (*p != '=') error("Expected '=' (SEARCH)");
          p++; break;                       /* skip over = */
        default:
          printf("bad (int)ch=%d\n", *p);
          error("Unexpected character (SEARCH)");
        }
        break;
    }
  }
}

/* ************************************************************** */
void
mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
  char *g;            /* M char array data reformatted for C */
  int  oN, iN, gN;    /* lengths of M char array data */
  int f; int* fp;     /* flag bits */
  int idx; short *pr; /* for M mxChar type */
  mwSize dims[2];
  
  /* check inputs */
  mxAssert(nrhs == 2 || nrhs == 3, "bad call: use gem(i,g) or gem(i,g,f)");    
  mxAssert(nlhs<=1, "bad call: use o = gem(i,g)");

  /* grab user input text */
  mxAssert(mxIsChar(prhs[0]),  "bad call 1rst arg: requires char");    
  iN = mxGetM(prhs[0])*mxGetN(prhs[0]);
  mxAssert(iN<DATALIM, "bad call 1rst arg: input is too long");
  pr = (short*)mxGetData(prhs[0]);
  for (idx=0; idx<iN; idx++) input[idx] = (unsigned char)*(pr+idx)&0xFF;
  input[iN] = 0;                            /* null terminate */
  i = input;                                /* the input */
  
  /* grab user grammar */
  mxAssert(mxIsChar(prhs[1]),  "bad call 2nd arg: requires char");   
  gN = mxGetM(prhs[1])*mxGetN(prhs[1]);
  mxAssert(gN<DATALIM, "bad call 2nd arg: input is too long");
  pr = (short*)mxGetData(prhs[1]);
  for (idx=0; idx<gN; idx++) code[idx] = (unsigned char)*(pr+idx)&0xFF;
  code[gN] = 0;                             /* null terminate */
  g = code;                                 /* the code */
  
  /* grab flags */
  if (nrhs == 3) {
    mxAssert(mxIsUint32(prhs[2]), "bad call 3rd arg: requires int32");   
    fp = (int*)mxGetData(prhs[2]);         /* flag bits */
    f = *fp;
  } else {
    f = 0;                                  /* no flags */
  }
  
  pregem(i, iN, g, gN, f);                  /* set up globals */
  gem();                                    /* translate */
  
  /* push output */
  oN = o-output+1;                          /* number of output chars */
  o = output;
  dims[0] = 1; dims[1] = oN;
  plhs[0] = mxCreateCharArray(2, (const mwSize*)&dims); 
  pr = (short*)mxGetData(plhs[0]);          /* 16 bits per char */
  for (idx=0; idx<oN; idx++) *(pr+idx) = (*o++)&0xFF;
}

