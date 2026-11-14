@echo off
setlocal
rem ===========================================================================
rem PurpleMagic launcher one-click build (Windows)
rem
rem Prerequisites:
rem   - Flutter SDK, .NET 8 SDK, Visual Studio 2022 Build Tools (C++ desktop)
rem   - this server's profile.json at runtime\launcher-input\profile.json
rem   - launcher\Flutter\assets\background.webp and announcement.webp
rem
rem Usage (from the PurpleMagic repo root):
rem   build-launcher.bat <flutter-dir> <dotnet.exe> <output-dir>
rem Example:
rem   build-launcher.bat D:\SDKs\flutter D:\SDKs\dotnet8\dotnet.exe dist\PurpleMagic-1.0.12
rem ===========================================================================

set "FLUTTER=%~1"
set "DOTNET=%~2"
set "OUTPUT=%~3"
if "%FLUTTER%"=="" set "FLUTTER=%FLUTTER_SDK%"
if "%DOTNET%"=="" set "DOTNET=dotnet"
if "%OUTPUT%"=="" set "OUTPUT=dist\PurpleMagic-custom"

if "%FLUTTER%"=="" (
  echo [ERROR] Flutter directory not given.
  echo         build-launcher.bat D:\SDKs\flutter D:\SDKs\dotnet8\dotnet.exe dist\PurpleMagic-1.0.12
  exit /b 1
)
if not exist "%FLUTTER%\bin\flutter.bat" (
  echo [ERROR] Flutter not found: %FLUTTER%\bin\flutter.bat
  exit /b 1
)
if not exist "runtime\launcher-input\profile.json" (
  echo [ERROR] missing runtime\launcher-input\profile.json
  exit /b 1
)
if not exist "launcher\Flutter\assets\background.webp" (
  echo [ERROR] missing launcher\Flutter\assets\background.webp
  exit /b 1
)
if not exist "launcher\Flutter\assets\announcement.webp" (
  echo [ERROR] missing launcher\Flutter\assets\announcement.webp
  exit /b 1
)

echo == 1/3 flutter pub get ==
call "%FLUTTER%\bin\flutter.bat" --no-version-check --suppress-analytics pub get --directory "launcher\Flutter" || exit /b 1

echo == 2/3 BUILD_FLUTTER ==
call BUILD_FLUTTER.bat --flutter "%FLUTTER%" --dotnet "%DOTNET%" --profile-dir "runtime\launcher-input" --output "%OUTPUT%" || exit /b 1

echo == 3/3 BUILD_PORTABLE ==
call BUILD_PORTABLE.bat --bundle "%OUTPUT%.zip" --output "%OUTPUT%.exe" --dotnet "%DOTNET%" || exit /b 1

echo.
echo DONE: %OUTPUT%\, %OUTPUT%.zip, %OUTPUT%-app-update.zip, %OUTPUT%.exe
echo Copy %OUTPUT%.exe as PurpleMagic.exe and ship it with the hosts helper.
endlocal
