/* FILE:     runX86.c
 * PURPOSE:  execute x86 code
 * METHOD:   pass the assembled X86 code and a frame.
 *           cast the code into a pointer to a function
 *           call the function (the code better be right)
 *           report the return code to the caller.
 */

# include "mex.h"

typedef unsigned char byte;

void
mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
  void *frame;
  int flen, len, r;
  void *code;
  uint64_T (*t)(void*);
  uint64_T res;
  const int dims[] = {1,1};
  
  mxAssert(nrhs == 2, "bad call: use runx86(code,frame)");    

  len = (mxGetM(prhs[0]) * mxGetN(prhs[0]));      /* code length */
  code = mxGetData(prhs[0]);                      /* code address */
  
  flen = (mxGetM(prhs[1]) * mxGetN(prhs[1]));     /* frame length */
  frame = mxGetData(prhs[1]);                     /* frame address */
  
  t = (uint64_T (*)(void*))code; 
  res = t(frame);                                 /* into hyperspace */
  
  mxAssert(nlhs<=1, "bad call: use rc = runx86(code,frame)");
  plhs[0] = mxCreateNumericArray(2, dims, mxUINT64_CLASS, mxREAL);
  *(uint64_T*)mxGetData(plhs[0]) = res; 
}

