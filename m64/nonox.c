/* FILE:     nonox.c
 * PURPOSE:  set memory executable
 * MODS:     mckeeman@dartmouth.edu -- Mar 2007 -- original
 *           Andrew Scott Parker -- fixed mac section
 * METHOD:   Use OS primitives
 *           On Windows, compile with 'mex -DMSWIND nonox.c'
 */

typedef unsigned char byte;

#include "mex.h"

#if defined(_WIN32) || defined(_WIN64)

#include <windows.h> 

#define HOT  PAGE_EXECUTE_READWRITE
#define COLD PAGE_READWRITE

static int
setProt(int prot, byte *code, int len) {
  bool res;
  DWORD old;
  res = VirtualProtect(code, len, prot, &old);
  return res;
}

#elif defined(__linux__) /* linux */

#include <sys/mman.h>
#include <sys/user.h>

#define HOT (PROT_EXEC|PROT_READ|PROT_WRITE)
#define COLD (PROT_READ|PROT_WRITE)

static int
setProt(int prot, byte *code, int len) {
  bool res;
  void *page = (void*) ((unsigned long)code & PAGE_MASK);
  uint32_T os = ((unsigned long)code & (PAGE_SIZE-1));
  res = (mprotect(page, os+len, prot)==0);  
  return res;
}

#elif defined(__APPLE__) /* the Mac */

#include </System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/CarbonCore.framework/Versions/A/Headers/OSUtils.h>
#include <sys/mman.h>

#define HOT (PROT_EXEC|PROT_READ|PROT_WRITE)
#define COLD (PROT_READ|PROT_WRITE)

static int
setProt(int prot, byte *code, int len) {
  bool res;
  int psize = getpagesize();
  void *page = (void*)((unsigned long)code & ~(psize-1));
  uint32_T os = ((unsigned long)code & (psize-1));
  res = (mprotect(page, os+len, prot) == 0); 
  return res; 
}

#endif /* platform defines */

void
mexFunction(
  int nlhs, mxArray *plhs[],
  int nrhs, const mxArray *prhs[]
) {
  unsigned int *frame;
  int len;
  unsigned char *code;
  unsigned int res;
  const int dims[] = {1,1};
  
  mxAssert(nrhs == 1, "bad call: use nonox(code)");    
  len = (mxGetM(prhs[0]) * mxGetN(prhs[0]));
  code = (unsigned char*)mxGetData(prhs[0]);
  res = setProt(HOT, code, len);
  
  mxAssert(nlhs<=1, "bad call: use rc = nonox(code)");
  plhs[0] = mxCreateNumericArray(2, dims, mxUINT32_CLASS, mxREAL);
  *(unsigned int*)mxGetData(plhs[0]) = res; 
}
