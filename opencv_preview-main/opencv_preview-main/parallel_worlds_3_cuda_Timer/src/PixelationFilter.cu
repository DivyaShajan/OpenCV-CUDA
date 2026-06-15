#include "PixelationFilter.hpp"

__global__ void pixelationKernel(
    const unsigned char* inImg,
    unsigned char* outImg,
    unsigned int w,
    unsigned int h,
    unsigned int blockSize)
{
    unsigned int x = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int y = blockIdx.y * blockDim.y + threadIdx.y;

    if(x < w && y < h) {
        unsigned int blockX = (x / blockSize) * blockSize;
        unsigned int blockY = (y / blockSize) * blockSize;

        float sumR = 0.0f;
        float sumG = 0.0f;
        float sumB = 0.0f;
        unsigned int count = 0;

        for(unsigned int by = blockY;
            by < blockY + blockSize && by < h; by++) {
            for(unsigned int bx = blockX;
                bx < blockX + blockSize && bx < w; bx++) {
                sumB += inImg[(bx + by*w)*3 + 0];
                sumG += inImg[(bx + by*w)*3 + 1];
                sumR += inImg[(bx + by*w)*3 + 2];
                count++;
            }
        }

        unsigned char avgB = (unsigned char)(sumB / count);
        unsigned char avgG = (unsigned char)(sumG / count);
        unsigned char avgR = (unsigned char)(sumR / count);

        outImg[(x + y*w)*3 + 0] = avgB;
        outImg[(x + y*w)*3 + 1] = avgG;
        outImg[(x + y*w)*3 + 2] = avgR;
    }
}

__host__ void PixelationFilter::operator()(
    const unsigned char* input,
    unsigned char* output,
    const unsigned int w,
    const unsigned int h)
{
    this->prepareBuffers(w, h);

    // copy input CPU → GPU
    SAFE_CALL(cudaMemcpy(
        this->dInput,
        reinterpret_cast<const void*>(input),
        w * h * 3 * sizeof(unsigned char),
        cudaMemcpyHostToDevice
    ));

    // START GPU TIMER
    SAFE_CALL(cudaEventRecord(startEvent));

    // launch kernel
    pixelationKernel<<<this->grid, this->threads>>>(
        this->dInput,
        this->dOutput,
        w, h,
        this->blockSize
    );

    // STOP GPU TIMER
    SAFE_CALL(cudaEventRecord(stopEvent));
    SAFE_CALL(cudaEventSynchronize(stopEvent));
    SAFE_CALL(cudaEventElapsedTime(
        &lastGpuTime,
        startEvent,
        stopEvent
    ));

    // copy result GPU → CPU
    SAFE_CALL(cudaMemcpy(
        reinterpret_cast<void*>(output),
        this->dOutput,
        w * h * 3 * sizeof(unsigned char),
        cudaMemcpyDeviceToHost
    ));
}