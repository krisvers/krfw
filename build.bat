@echo off

if "%~1" == "release" (
    odin build ./src -out:build\demo.exe
) else (
    odin build ./src -debug -out:build\demo.exe
)

if %ERRORLEVEL% equ 0 (
    if "%~1" == "run" (
        "./build/demo.exe"
    )
) else (
    echo --- Build failed
)