/*
 * EffectFilter.cu
 * Converted from OpenCL effectFilter.cl to CUDA
 */
#include "EffectFilter.hpp"

#define ARR(A,x,y,maxX) (A[(x)+(y)*(maxX)])
#define ARRC(A,x,y,maxX,channel) (A[((x)+(y)*(maxX))*3+channel])

__global__ void effectKernel(
    const unsigned char* inImg,
    const char* edgeImg,
    unsigned char* outImg,
    unsigned int w,
    unsigned int h,
    float threshold)
{
    unsigned int x = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int y = blockIdx.y * blockDim.y + threadIdx.y;

    if(x < w && y < h) {
        float G    = ((char)ARR(edgeImg, x, y, w));
        float absG = fabsf(G);

        if(absG > threshold) {
            // strong edge → darken by 50%
            ARRC(outImg,x,y,w,0) =
                (unsigned char)(ARRC(inImg,x,y,w,0) * .5f);
            ARRC(outImg,x,y,w,1) =
                (unsigned char)(ARRC(inImg,x,y,w,1) * .5f);
            ARRC(outImg,x,y,w,2) =
                (unsigned char)(ARRC(inImg,x,y,w,2) * .5f);
        } else {
            // no edge → keep original color
            ARRC(outImg,x,y,w,0) = ARRC(inImg,x,y,w,0);
            ARRC(outImg,x,y,w,1) = ARRC(inImg,x,y,w,1);
            ARRC(outImg,x,y,w,2) = ARRC(inImg,x,y,w,2);
        }
    }
}

__host__ void EffectFilter::operator()(
    const unsigned char* colorInput,
    const char* edgeInput,
    unsigned char* colorOutput,
    const unsigned int w,
    const unsigned int h,
    const float threshold)
{
    // use our OWN resizeBuffers
    // NOT the base class version
    this->resizeBuffers(w, h);

    // copy color image CPU → GPU
    SAFE_CALL(cudaMemcpy(
        this->dInput,
        reinterpret_cast<const void*>(colorInput),
        w * h * 3 * sizeof(unsigned char),
        cudaMemcpyHostToDevice
    ));

    // copy edge image CPU → GPU
    SAFE_CALL(cudaMemcpy(
        this->dEdge,
        reinterpret_cast<const void*>(edgeInput),
        w * h * sizeof(char),
        cudaMemcpyHostToDevice
    ));

    // launch kernel
    effectKernel<<<this->grid, this->threads>>>(
        this->dInput,
        this->dEdge,
        this->dOut,
        w, h,
        threshold
    );

    // copy result GPU → CPU
    SAFE_CALL(cudaMemcpy(
        reinterpret_cast<void*>(colorOutput),
        this->dOut,
        w * h * 3 * sizeof(unsigned char),
        cudaMemcpyDeviceToHost
    ));
}