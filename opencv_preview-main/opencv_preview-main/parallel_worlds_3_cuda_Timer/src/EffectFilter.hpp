/*
 * EffectFilter.hpp
 * Converted from OpenCL to CUDA
 */
#ifndef EFFECTFILTER_HPP_
#define EFFECTFILTER_HPP_

#include "ImageFilter.hpp"

class EffectFilter : public ImageFilter {
private:
    /// separate GPU buffer for edge image
    char* dEdge;
    /// separate GPU buffer for color output
    unsigned char* dOut;

public:
    EffectFilter(unsigned int dIn, unsigned int dOut) :
        ImageFilter(dIn, dOut),
        dEdge(nullptr),
        dOut(nullptr) {};

    virtual void resizeGrid(unsigned int w, unsigned int h) {
        this->threads = dim3(BSIZE, BSIZE, 1);
        this->grid = dim3(
            (w + this->threads.x - 1) / this->threads.x,
            (h + this->threads.y - 1) / this->threads.y
        );
    }

    /// allocates ALL three GPU buffers
    virtual void resizeBuffers(
            unsigned int currWidth,
            unsigned int currHeight) {

        this->resizeGrid(currWidth, currHeight);

        // always reallocate if bigger
        if (currWidth * currHeight > this->width * this->height) {

            // free old buffers
            if(this->dInput != nullptr)
                SAFE_CALL(cudaFree(this->dInput));
            if(dEdge != nullptr)
                SAFE_CALL(cudaFree(dEdge));
            if(dOut != nullptr)
                SAFE_CALL(cudaFree(dOut));

            // allocate color input buffer
            SAFE_CALL(cudaMalloc(
                reinterpret_cast<void**>(&this->dInput),
                currWidth * currHeight * 3 * sizeof(unsigned char)
            ));

            // allocate edge buffer
            SAFE_CALL(cudaMalloc(
                reinterpret_cast<void**>(&dEdge),
                currWidth * currHeight * sizeof(char)
            ));

            // allocate color output buffer
            SAFE_CALL(cudaMalloc(
                reinterpret_cast<void**>(&dOut),
                currWidth * currHeight * 3 * sizeof(unsigned char)
            ));

            this->width  = currWidth;
            this->height = currHeight;
        }
    }

    virtual ~EffectFilter() {
        if(dEdge != nullptr)
            SAFE_CALL(cudaFree(dEdge));
        if(dOut != nullptr)
            SAFE_CALL(cudaFree(dOut));
    };

    void operator()(
        const unsigned char* colorInput,
        const char* edgeInput,
        unsigned char* colorOutput,
        const unsigned int w,
        const unsigned int h,
        const float threshold
    );
};

#endif /* EFFECTFILTER_HPP_ */