@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "FLUTTER_HOME=D:\LOCAL-WORK-STATION\flutterSdk\flutter"
set "JAVA_HOME=D:\LOCAL-WORK-STATION\dev-tools\temurin-17.0.20"
set "ANDROID_HOME=D:\LOCAL-WORK-STATION\androidSDK"
set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
set "PATH=%FLUTTER_HOME%\bin;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\emulator;%PATH%"

cd /d "%PROJECT_DIR%"

echo.
echo ChildrenMathGame - Android phone run
echo Project: %CD%
echo Flutter: %FLUTTER_HOME%
echo Java:    %JAVA_HOME%
echo SDK:     %ANDROID_HOME%
echo.

if not exist "%FLUTTER_HOME%\bin\flutter.bat" (
    echo [ERROR] Flutter was not found at:
    echo %FLUTTER_HOME%\bin\flutter.bat
    goto :fail
)

if not exist "%JAVA_HOME%\bin\java.exe" (
    echo [ERROR] Java was not found at:
    echo %JAVA_HOME%\bin\java.exe
    goto :fail
)

if not exist "%ANDROID_HOME%\platform-tools\adb.exe" (
    echo [ERROR] adb was not found at:
    echo %ANDROID_HOME%\platform-tools\adb.exe
    goto :fail
)

echo Checking connected Android devices...
adb devices
echo.

for /f "skip=1 tokens=1,2" %%A in ('adb devices') do (
    if "%%B"=="device" (
        set "ANDROID_DEVICE=%%A"
        goto :device_found
    )
)

echo [ERROR] No authorized Android phone was found.
echo.
echo Check these items:
echo  1. Connect your phone by USB.
echo  2. Enable Developer options and USB debugging.
echo  3. Accept the USB debugging permission popup on the phone.
goto :fail

:device_found
echo Using Android device: %ANDROID_DEVICE%
echo.
echo Starting Flutter on the connected phone...
call "%FLUTTER_HOME%\bin\flutter.bat" run -d %ANDROID_DEVICE%
if errorlevel 1 goto :fail

echo.
echo Done.
goto :end

:fail
echo.
echo Failed. Review the message above.

:end
echo.
pause
endlocal
