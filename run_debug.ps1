# Открываю новое окно PowerShell с отладочным выводом
$debugFile = "C:\Users\Пользователь\Documents\illustraitor-ai-generator\image_generator_gui_fixed_DEBUG.ps1"
Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command", "& {`$Host.UI.RawUI.WindowTitle = 'Illustraitor AI Generator - DEBUG MODE'; . '$debugFile'}"
) -Wait
