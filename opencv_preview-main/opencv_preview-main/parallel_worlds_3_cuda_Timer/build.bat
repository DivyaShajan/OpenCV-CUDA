@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

cd "C:\Users\jabee\Documents\OpenCV-CUDA\opencv_preview-main\opencv_preview-main\parallel_worlds_3_cuda_Timer"

mkdir build
cd build

cmake .. -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release

nmake

cd ..
.\build\parallel_worlds.exe
pause