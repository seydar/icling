/* FILE:     getCfun.c
 * PURPOSE:  provide C runtime routines
 * MODS:     mckeeman@dartmouth.edu -- May 2007 -- original
 * METHOD:   provide address of named external C function (as uint32)
 * USAGE:    adr = getCfun(name)
 * EXAMPLE:  adr = getCfun('rand')
 *
 * EXTENDING run-time
 * Anything callable from C can be added.  Any needed include files must
 * be provided, the name used in xcom added to the CFUNCTIONS macros, and 
 * the C call wrapped in a stylized static call here as seen in the example
 * for rand. 
 *
 * IMPLEMENTATION:
 * Each C function f must be provided in a static wrapper XCOMf.  
 * The run-time module looks up the required function by name, 
 * and then returns its memory address as an unsigned int for use in the
 * Intel callRi instruction.
 */

# include <stdlib.h>
# include <string.h>
# include "mex.h"

# define SIZE(a) (sizeof(a)/sizeof(*a))

/* --- New names callable from xcom must be added to this macro --- */
# define CFUNCTIONS(X) \
  X(rand)     \
  X(div)      \
  X(rem)      \
  X(frame)    \
  X(free)     \
  X(link)     \

/* --- Automatically generated master list of names as strings --- */
# undef X
# define X(a) #a,

typedef unsigned int uint32;
typedef          int  int32;

static char *Cnames[] = {
  CFUNCTIONS(X)
  0
};

/* ---- New wrappers for implemented C functions go here ---- */

/* result passed back as int to avoid differences in X86 and A64 */
static int 
XCOMrand(void) {
 float tmp = (float)(rand()/((double)RAND_MAX+1));
 return *(int*)&tmp;   /* pass bits along */
}

static int
XCOMdiv(int a, int b) {
 return a/b;
}


static int 
XCOMrem(int a, int b) {
 return a%b;
}

static int*
XCOMframe(int sz) {          /* 32-bit wide call frame */
  return (int*) malloc(sz*4);
}

static int
XCOMfree(void *frm) {        /* done with frame */
  (void)free(frm);
  return 1;
}

/* -------------------- Calling subprograms in X --------------------
 *
 *  The X syntax
 *
 *      x,y,z := f := 13, z+1
 *
 *  requires that the called function f has two inputs and three outputs,
 *  all type-correct with respect to the caller.
 *
 *  Suppose that the called function f has input variables a and b,
 *  and output variables c, d and e.
 *
 *  While still executing the caller, the two rhs values be be computed.  
 *  Before resuming the caller, three output values must be stored into the 
 *  lhs variables in the caller frame. 
 *
 *  The above calling sequence is accomplished by a linker written in C 
 *  (and placed in getCfun.c, which is here).
 *
 *  The linker needs access to the caller frame and the called frame.
 *  The caller frame is passed.  The called frame is allocated.
 *
 *  The rhs values (13, z+1) of the call are placed in the input variables
 *  in the called frame (a, b).
 *
 *  The called function f is entered and returns.
 *
 *  The output variables of the called function frame (c, d, e) 
 *  are copied into the named variables of the caller frame (x,y,z).
 *  
 *  The called frame is freed.
 *
 *  The linker is called with five explicit arguments
 *    the caller frame
 *    the called function address
 *    the input count
 *    the output count
 *    the size of the called frame
 * and two lists of pairs
 *    caller value/called offset  (subprogram inputs)      
 *    called offset/caller offset (subprogram outputs)
 * which are accessed as passed vararg-style.
 *
 * The tricky part is finding the first vararg entry.
 * The trick is to add one to the address of the last explict arg.
 */

/*             stack data from a simple call  (x := f := y)

   0xbffff6c4          caller offset         8
   0xbffff6c0          called offset         0
   0xbffff6bc    +     called offset         4
   0xbffff6b8          caller value         17<--+
   0xbffff6b4    ^     n                     3   |
   0xbffff6b0    |     no                    1   |
   0xbffff6ac    v     ni                    1   |
   0xbffff6a8          entry         0x8065df0   |
   0xbffff6a4    -     ofr           0x8065e90   |
   0xbffff6a0          old EIP       0x806629f   |
   0xbffff69c          old EBP      0xbffffbc8   | <-- EBP
   0xbffff698          nfr           0x8065d68   |
   0xbffff694          b            0xbffff6b8 --+
*/   

# define LT          /* exchange to enable/disable trace */
# undef  LT
# define LT if (0)   /* exchange to enable/disable trace */

/* inputs and outputs passed as typeless 32 bit values */
static int
XCOMlink(                                        /* pass and call */
  int  *callerFrame,                             /* caller frame */
  void *calledSubp,                              /* called address*/
  int ni,                                        /* input count */
  int no,                                        /* output count */
  int n                                          /* called local count */
  ) {   
    
  int   *calledFrame = XCOMframe(n);             /* new frame */
  uint32 calledOffset;                           /* called offset(for C) */
  int32 *calledPtr;                              /* ptr to 32 bit var */
  uint32 callerOffset;                           /* caller offset */
  int32 *callerPtr;                              /* ptr to caller var */
  int32  callerArg;                              /* caller supplied val */

  int (*t)(void*) = (int(*)(void*))calledSubp;   /* correct signature */
  int rc;
  uint32 *b = (uint32*)&n+1;                    /* start vararg pairs */
  int i;

  LT printf("XCOMlink: callerFrame before run\n");
  LT for (i=0; i<3; i++)
    printf("%4d: %x\n", i, callerFrame[i]);
  
  LT printf("XCOMlink new frame = 0x%x, size=%d bytes\n", calledFrame,4*n);
  LT printf("XCOMlink n=%d, no=%d, ni=%d calledSubp=0x%x callerFrame=0x%x\n", 
          n, no, ni, calledSubp, callerFrame);
  LT printf("XCOMlink: calledFrame before input\n");
  LT for (i=0; i<n; i++)
    printf("%4d: 0x%x\n", i, calledFrame[i]);
  

  for (i=0; i<ni; i++) {                         /* each called input */
    callerArg    = *(b+2*i);                     /* caller supplied value */
    calledOffset = *(b+2*i+1)-1;                 /* called offset(for C) */
    calledFrame[calledOffset] = callerArg;       /* ptr to 32 bit var */
    LT printf(
      "XCOMlink input i=%d calledOffset=%d callerArg=0x%x\n", 
      i, calledOffset, callerArg);
  }
  
  LT printf("XCOMlink: calledFrame after input\n");
  LT for (i=0; i<n; i++) printf("%4d: %x\n", i, calledFrame[i]);
  
  
  LT printf("XCOMlink enter X subfunction adr=0x%x\n", t);
  rc = t(calledFrame);                           /* call X subprogram */
  LT printf("XCOMlink returned from X subfunction, rc=%d\n", rc);

  LT printf("XCOMlink: calledFrame after run\n");
  LT for (i=0; i<n; i++)
    printf("%d: %x\n", i, calledFrame[i]);
  
  b = b + 2*ni;                                  /* skip over inputs */
  for (i=0; i<no; i++) {                         /* each called output*/
    callerOffset = *(b+2*i)-1;                   /* caller offset */
    calledOffset = *(b+2*i+1)-1;                 /* called offset */
    LT printf(
     "XCOMlink res i=%d callerOffset=%d calledOffset=%d calledRes=0x%x\n", 
     i, callerOffset, calledOffset, calledFrame[calledOffset]);
    callerFrame[callerOffset] = calledFrame[calledOffset];
  }
  LT printf("XCOMlink: callerFrame after run\n");
  LT for (i=0; i<3; i++)
    printf("%d: %x\n", i, callerFrame[i]);
  
  LT printf("XCOMlink done\n");

  XCOMfree(calledFrame);                         /* no leaks */
  return rc;                                     /* 0 means no error */
}

/* --- Automatically generated list of addresses ---- */

# undef X
# define X(a) XCOM##a,

static void* Cadrs[] = {
  CFUNCTIONS(X)
  0
};

/* --- the implementation of mex function getCfun ----------- */
void
mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
  
  void *res = 0;
  int i, cid, rows, len;
  char *cname;
  const int dims[] = {1,1};
  
  if (nrhs != 1) mexErrMsgTxt("xcom getCfun: use getCfun(name)");
  if (nlhs > 1) mexErrMsgTxt("xcom getCfun: use adr = getCfun(name)");
  
  cid = mxGetClassID(prhs[0]);
  if (cid != mxCHAR_CLASS) mexErrMsgTxt("xcom getCfun: name must be string");
  
  rows = mxGetM(prhs[0]);
  if (rows != 1)  mexErrMsgTxt("xcom getCfun input: use getCfun(name)");

  len = mxGetN(prhs[0]);
  cname = mxArrayToString(prhs[0]);
  
  /* look up user-supplied name in available function table */
  for (i=0; i<SIZE(Cnames); i++) {
    if (strcmp(cname, Cnames[i]) == 0) {
      res = Cadrs[i];
      break;
    }
  }
  mxFree(cname);
  if (res == 0) mexErrMsgTxt("xcom getCfun: unknown function name");
  
  /* prepare output (allow for 64-bit pointers) */
  plhs[0] = mxCreateNumericArray(2, dims, mxUINT64_CLASS, mxREAL);
  *(void**)mxGetData(plhs[0]) = res; 
}

