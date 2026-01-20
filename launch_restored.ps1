Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ILLUSTRAITOR AI GENERATOR - RESTORED VERSION" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "После запуска GUI проверьте:" -ForegroundColor White
Write-Host "1. Кнопки 'Проверить' (OpenAI и Unsplash)" -ForegroundColor Gray
Write-Host "2. Кнопка 'Найти фото через Unsplash'" -ForegroundColor Gray
Write-Host "3. Кнопка 'Генерировать изображение через DALL-E'" -ForegroundColor Gray
Write-Host "4. Кнопка 'Скачать изображение'" -ForegroundColor Gray
Write-Host ""
Write-Host "Если кнопки не работают, проверьте:" -ForegroundColor Magenta
Write-Host "• Сообщения об ошибках в этом окне" -ForegroundColor Gray
Write-Host "• Не закрывайте это окно до завершения теста" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
# Запускаю основной GUI
. "C:\Users\Пользователь\Documents\illustraitor-ai-generator\image_generator_gui_RESTORED.ps1"
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "GUI закрыт. Нажмите Enter для выхода..." -ForegroundColor Yellow
Read-Host
