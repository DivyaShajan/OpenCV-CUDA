/*
 * Timer.hpp
 * CPU wall clock timer for measuring
 * total pipeline execution time
 */
#ifndef TIMER_HPP_
#define TIMER_HPP_

#include <chrono>

class Timer {
private:
    std::chrono::high_resolution_clock::time_point startTime;
    double lastMs;

public:
    Timer() : lastMs(0.0) {}

    /// start the timer
    void start() {
        startTime =
            std::chrono::high_resolution_clock::now();
    }

    /// stop timer and return milliseconds
    double stop() {
        auto endTime =
            std::chrono::high_resolution_clock::now();
        lastMs = std::chrono::duration<double, std::milli>
            (endTime - startTime).count();
        return lastMs;
    }

    double getLastMs() const { return lastMs; }
};

#endif /* TIMER_HPP_ */