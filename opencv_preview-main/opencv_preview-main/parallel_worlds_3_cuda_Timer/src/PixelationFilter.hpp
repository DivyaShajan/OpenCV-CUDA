/*
 * PixelationFilter.hpp
 * Pixelates image using NxN blocks
 * Supports 8x8, 16x16, 32x32 block sizes
 */
#ifndef PIXELATIONFILTER_HPP_
#define PIXELATIONFILTER_HPP_

#include "ImageFilter.hpp"

class PixelationFilter : public ImageFilter {
private:
    /// block size for pixelation (8, 16, or 32)
    unsigned int blockSize;

    /// CUDA timer events
    cudaEvent_t startEvent;
    cudaEvent_t stopEvent;

    /// last measured GPU time in milliseconds
    float lastGpuTime;

public:
    PixelationFilter(
        unsigned int dIn,
        unsigned int dOut,
        unsigned int blockSize = 16) :
        ImageFilter(dIn, dOut),
        blockSize(blockSize),
        lastGpuTime(0.0f)
    {
        // create CUDA timer events
        SAFE_CALL(cudaEventCreate(&startEvent));
        SAFE_CALL(cudaEventCreate(&stopEvent));
    };

    /// get last GPU execution time
    float getLastGpuTime() const {
        return lastGpuTime;
    }

    /// change pixelation block size at runtime
    void setBlockSize(unsigned int newSize) {
        blockSize = newSize;
    }

    unsigned int getBlockSize() const {
        return blockSize;
    }

    virtual void resizeGrid(
            unsigned int w,
            unsigned int h) {
        this->threads = dim3(BSIZE, BSIZE, 1);
        this->grid = dim3(
            (w + this->threads.x - 1) / this->threads.x,
            (h + this->threads.y - 1) / this->threads.y
        );
    }

    virtual ~PixelationFilter() {
        SAFE_CALL(cudaEventDestroy(startEvent));
        SAFE_CALL(cudaEventDestroy(stopEvent));
    };

    void operator()(
        const unsigned char* input,
        unsigned char* output,
        const unsigned int w,
        const unsigned int h
    );
};

#endif /* PIXELATIONFILTER_HPP_ */