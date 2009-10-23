/* FILE:     getpr.c
 * PURPOSE:  get the address of the data in a MATLAB array
 * METHOD:   grab it out of the mxArray header
 */

# include "mex.h"

void
mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
  void *ptr;
  const int dims[] = {1,1};
  
  mxAssert(nrhs == 1, "bad call: use getpr(var)");    
  ptr = mxGetData(prhs[0]);
  
  mxAssert(nlhs<=1, "bad call: use pr = getpr(var)");
  plhs[0] = mxCreateNumericArray(2, dims, mxUINT32_CLASS, mxREAL);
  *(void**)mxGetData(plhs[0]) = ptr; 
}

