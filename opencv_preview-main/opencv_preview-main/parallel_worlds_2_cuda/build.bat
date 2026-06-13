@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
cd "C:\Users\jabee\Documents\OpenCV-CUDA\opencv_preview-main\opencv_preview-main\parallel_worlds_2_cuda\build"
nmake
.\parallel_worlds.exe
pause