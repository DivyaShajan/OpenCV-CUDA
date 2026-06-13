/*
 * main.cu
 * Converted from OpenCL main.cpp to CUDA
 */
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#include "CUDAInterface.hpp"
#include "GreyFilter.hpp"
#include "SobelFilter.hpp"
#include "EffectFilter.hpp"

// create filter objects globally
// depthIn=3 (RGB), depthOut=1 (grey)
GreyFilter   greyFilter(3, 1);
// depthIn=1 (grey), depthOut=1 (grey)
SobelFilter  sobelFilter(1, 1);
// depthIn=3 (RGB), depthOut=3 (RGB)
EffectFilter effectFilter(3, 3);

__host__ int main(int argc, const char** argv) {
    cv::VideoCapture capture(0);
    cv::Mat frame;

    // set to true if you have a webcam
    bool cameraOn = capture.isOpened() && false;

    if (cameraOn) {
        if (!capture.read(frame))
            exit(3);
    } else {
        std::cerr << "No camera detected" << std::endl;
        frame = cv::imread("preview.png");
        if(frame.data == NULL)
            exit(3);
    }

    const unsigned int w = frame.cols;
    const unsigned int h = frame.rows;

    // greyscale image
    cv::Mat convertedFrame(h, w, CV_8UC1);

    // edge detected image
    cv::Mat edgeFrame(h, w, CV_8UC1);

    // effect image (color with dark edges)
    cv::Mat effectFrame(h, w, CV_8UC3);

    // create display windows
    cv::namedWindow("preview",   0);
    cv::namedWindow("converted", 0);
    cv::namedWindow("edge",      0);
    cv::namedWindow("effect",    0);

    while (((char)cv::waitKey(10)) <= -1) {
        if (cameraOn && !capture.read(frame))
            exit(3);

        // Step 1: RGB → greyscale
        greyFilter(
            frame.data,
            convertedFrame.data,
            w, h
        );

        // Step 2: greyscale → edge image
        sobelFilter(
            convertedFrame.data,
            edgeFrame.data,
            w, h,
            .5f
        );

        // Step 3: darken edges on color image
        effectFilter(
            frame.data,              // color input
            (char*)edgeFrame.data,   // edge input
            effectFrame.data,        // color output
            w, h,
            90.0f                    // threshold
        );

        // show all 4 windows
        cv::imshow("preview",   frame);
        cv::imshow("converted", convertedFrame);
        cv::imshow("edge",      edgeFrame);
        cv::imshow("effect",    effectFrame);
    }

    cv::destroyWindow("preview");
    cv::destroyWindow("converted");
    cv::destroyWindow("edge");
    cv::destroyWindow("effect");

    return 0;
}