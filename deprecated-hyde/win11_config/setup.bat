@echo off
setlocal enabledelayedexpansion

:: Set the paths
set "WINDOWS_WEZTERM_PATH=%USERPROFILE%\.wezterm.lua"
set "WINDOWS_IOSEVKA_PATH=%USERPROFILE%\private-build-plans.toml"
set "WSL_WEZTERM_PATH=\\wsl$\Arch\home\andre\dotfiles\win11_config\.wezterm.lua"
set "WSL_IOSEVKA_PATH=\\wsl$\Arch\home\andre\dotfiles\win11_config\private-build-plans.toml"

echo Current user profile: %USERPROFILE%
echo.

:: Function to create symlink
:create_symlink
set "WIN_PATH=%~1"
set "WSL_PATH=%~2"
echo Attempting to create symlink:
echo From: %WSL_PATH%
echo To: %WIN_PATH%
echo.

if exist "%WIN_PATH%" (
    echo Backing up existing %~nx1 file...
    ren "%WIN_PATH%" "%~nx1.backup"
    if !errorlevel! neq 0 echo Failed to create backup.
)

mklink "%WIN_PATH%" "%WSL_PATH%"
if %errorlevel% equ 0 (
    echo Symbolic link created successfully for %~nx1.
    echo Verifying symlink:
    dir "%WIN_PATH%"
) else (
    echo Failed to create symbolic link for %~nx1.
    echo Error code: %errorlevel%
)
echo.
goto :eof

:: Create symlinks
call :create_symlink "%WINDOWS_WEZTERM_PATH%" "%WSL_WEZTERM_PATH%"
call :create_symlink "%WINDOWS_IOSEVKA_PATH%" "%WSL_IOSEVKA_PATH%"

:: Final verification
echo Final verification:
echo Checking .wezterm.lua:
if exist "%WINDOWS_WEZTERM_PATH%" (
    dir "%WINDOWS_WEZTERM_PATH%"
) else (
    echo .wezterm.lua not found in %USERPROFILE%
)
echo.
echo Checking private-build-plans.toml:
if exist "%WINDOWS_IOSEVKA_PATH%" (
    dir "%WINDOWS_IOSEVKA_PATH%"
) else (
    echo private-build-plans.toml not found in %USERPROFILE%
)

:: Exit with a specific code
exit /b 0
