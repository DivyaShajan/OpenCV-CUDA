/*
 * Timer.hpp
 * CPU wall clock timer for measuring
 * total pipeline execution time
 */
#ifndef TIMER_HPP_
#define TIMER_HPP_

#include <chrono>
#include <string>
#include <iostream>

class Timer {
private:
    /// time point when timer started
    std::chrono::high_resolution_clock::time_point startTime;

    /// name of what we are timing
    std::string name;

    /// last measured time in milliseconds
    double lastMs;

public:
    Timer(std::string name = "Timer") :
        name(name), lastMs(0.0) {}

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

    /// get last measured time
    double getLastMs() const { return lastMs; }

    /// print result to console
    void print() const {
        std::cout << name
                  << ": "
                  << lastMs
                  << " ms"
                  << std::endl;
    }
};

#endif /* TIMER_HPP_ */