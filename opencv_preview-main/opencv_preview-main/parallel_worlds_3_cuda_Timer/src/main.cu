/*
 * main.cu
 * Image processing pipeline with timing
 * displayed on screen
 */
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <string>

#include "CUDAInterface.hpp"
#include "GreyFilter.hpp"
#include "SobelFilter.hpp"
#include "EffectFilter.hpp"
#include "PixelationFilter.hpp"
#include "Timer.hpp"

// filter objects
GreyFilter       greyFilter(3, 1);
SobelFilter      sobelFilter(1, 1);
EffectFilter     effectFilter(3, 3);
PixelationFilter pixFilter8(3, 3, 8);
PixelationFilter pixFilter16(3, 3, 16);
PixelationFilter pixFilter32(3, 3, 32);

// CPU timer
Timer cpuTimer;

/// draws text with background onto image
// so it is always visible
void drawText(cv::Mat& img,
              const std::string& text,
              int x, int y)
{
    // draw black background first
    cv::putText(img, text,
        cv::Point(x+1, y+1),
        cv::FONT_HERSHEY_SIMPLEX,
        0.6,
        cv::Scalar(0, 0, 0),  // black shadow
        2
    );
    // draw white text on top
    cv::putText(img, text,
        cv::Point(x, y),
        cv::FONT_HERSHEY_SIMPLEX,
        0.6,
        cv::Scalar(255, 255, 255),  // white text
        1
    );
}

/// formats milliseconds as string
std::string msToString(
    const std::string& label,
    float ms)
{
    std::ostringstream ss;
    ss << label
       << ": "
       << std::fixed
       << std::setprecision(2)
       << ms
       << " ms";
    return ss.str();
}

__host__ int main(int argc, const char** argv) {
    cv::VideoCapture capture(0);
    cv::Mat frame;

    bool cameraOn = capture.isOpened() && false;

    if(cameraOn) {
        if(!capture.read(frame)) exit(3);
    } else {
        std::cerr << "No camera detected" << std::endl;
        frame = cv::imread("preview.png");
        if(frame.data == NULL) exit(3);
    }

    const unsigned int w = frame.cols;
    const unsigned int h = frame.rows;

    std::cout << "Image: "
              << w << "x" << h
              << " pixels" << std::endl;

    // output buffers
    cv::Mat convertedFrame(h, w, CV_8UC1);
    cv::Mat edgeFrame(h, w, CV_8UC1);
    cv::Mat effectFrame(h, w, CV_8UC3);

    // display windows
    cv::namedWindow("1-Original",    0);
    cv::namedWindow("2-Greyscale",   0);
    cv::namedWindow("3-Edges",       0);
    cv::namedWindow("4-Effect",      0);
    cv::namedWindow("5-Pixel 8x8",   0);
    cv::namedWindow("6-Pixel 16x16", 0);
    cv::namedWindow("7-Pixel 32x32", 0);

    // timing variables
    float gpuTime8   = 0.0f;
    float gpuTime16  = 0.0f;
    float gpuTime32  = 0.0f;
    double cpuTotal  = 0.0;

    while(((char)cv::waitKey(10)) <= -1) {
        if(cameraOn && !capture.read(frame)) exit(3);

        // make copies for drawing text on
        cv::Mat frameDisplay     = frame.clone();
        cv::Mat pixDisplay8      = cv::Mat(h, w, CV_8UC3);
        cv::Mat pixDisplay16     = cv::Mat(h, w, CV_8UC3);
        cv::Mat pixDisplay32     = cv::Mat(h, w, CV_8UC3);

        // START CPU TIMER
        cpuTimer.start();

        // Step 1: greyscale
        greyFilter(
            frame.data,
            convertedFrame.data,
            w, h
        );

        // Step 2: edges
        sobelFilter(
            convertedFrame.data,
            edgeFrame.data,
            w, h, .5f
        );

        // Step 3: effect
        effectFilter(
            frame.data,
            (char*)edgeFrame.data,
            effectFrame.data,
            w, h, 90.0f
        );

        // Step 4: pixelation filters
        // each measures its own GPU time
        pixFilter8(
            frame.data,
            pixDisplay8.data,
            w, h
        );
        gpuTime8 = pixFilter8.getLastGpuTime();

        pixFilter16(
            frame.data,
            pixDisplay16.data,
            w, h
        );
        gpuTime16 = pixFilter16.getLastGpuTime();

        pixFilter32(
            frame.data,
            pixDisplay32.data,
            w, h
        );
        gpuTime32 = pixFilter32.getLastGpuTime();

        // STOP CPU TIMER
        cpuTotal = cpuTimer.stop();

        // print to terminal every frame
        std::cout << "\r"
                  << "CPU: "
                  << std::fixed
                  << std::setprecision(2)
                  << cpuTotal
                  << "ms | "
                  << "8x8: "
                  << gpuTime8
                  << "ms | "
                  << "16x16: "
                  << gpuTime16
                  << "ms | "
                  << "32x32: "
                  << gpuTime32
                  << "ms          "
                  << std::flush;

        // draw timer ON each pixelation window
        drawText(pixDisplay8,
            msToString("GPU 8x8", gpuTime8),
            10, 30);
        drawText(pixDisplay8,
            msToString("CPU total", (float)cpuTotal),
            10, 60);

        drawText(pixDisplay16,
            msToString("GPU 16x16", gpuTime16),
            10, 30);
        drawText(pixDisplay16,
            msToString("CPU total", (float)cpuTotal),
            10, 60);

        drawText(pixDisplay32,
            msToString("GPU 32x32", gpuTime32),
            10, 30);
        drawText(pixDisplay32,
            msToString("CPU total", (float)cpuTotal),
            10, 60);

        // draw comparison on original
        drawText(frameDisplay, msToString("8x8",   gpuTime8),          10, 30);
        drawText(frameDisplay, msToString("16x16", gpuTime16),         10, 60);
        drawText(frameDisplay, msToString("32x32", gpuTime32),         10, 90);
        drawText(frameDisplay, msToString("Total", (float)cpuTotal),   10, 120);

        // show all 7 windows
        cv::imshow("1-Original",    frameDisplay);
        cv::imshow("2-Greyscale",   convertedFrame);
        cv::imshow("3-Edges",       edgeFrame);
        cv::imshow("4-Effect",      effectFrame);
        cv::imshow("5-Pixel 8x8",   pixDisplay8);
        cv::imshow("6-Pixel 16x16", pixDisplay16);
        cv::imshow("7-Pixel 32x32", pixDisplay32);
    }

    // final summary in terminal
    std::cout << "\n\n=== Final Timing ===" << std::endl;
    std::cout << "GPU 8x8:   " << gpuTime8  << " ms" << std::endl;
    std::cout << "GPU 16x16: " << gpuTime16 << " ms" << std::endl;
    std::cout << "GPU 32x32: " << gpuTime32 << " ms" << std::endl;
    std::cout << "CPU Total: " << cpuTotal  << " ms" << std::endl;

    cv::destroyAllWindows();
    return 0;
}