/*
 * This is an s-function which calls randomly generated function "main"
 * "main()" is located in randgen.c
 */
#include "mex.h"
#include "randgen.c"

void karrayProduct(int m, double *y, double *z, int n){
    int i;
    for(i=0; i<n; i++){
        z[i] = y[i]*m;
    }
} 

void mexFunction(int nlhs, mxArray *plhs[], int rlhs, const mxArray *prhs[]){
    mexPrintf("-----------------S T A R T  S F U N-----------------\n");
    double multiplier = 1;  
    main();
    /*mexPrintf("CK %X\n", ret_main);*/
    double *inMatrix = mxGetPr(prhs[1]);               /* 1xN input matrix */
    size_t ncols = mxGetN(prhs[1]);                   /* size of matrix */
    plhs[0] = mxCreateDoubleMatrix(1,(mwSize)ncols,mxREAL);
    double *outMatrix = mxGetPr(plhs[0]);              /* output matrix */
    
    karrayProduct(multiplier,inMatrix,outMatrix,(mwSize)ncols);
    mexPrintf("-----------------E N D  S F U N-----------------\n");
} 