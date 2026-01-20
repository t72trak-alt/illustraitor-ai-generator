# Тест кнопки скачивания
Write-Host "=== ТЕСТ КНОПКИ СКАЧИВАНИЯ ===" -ForegroundColor Cyan
# Имитируем сгенерированное изображение (тестовый URL)
$testImageUrl = "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=512&h=512"
Write-Host "Установлен тестовый URL изображения: $testImageUrl" -ForegroundColor Gray
Write-Host ""
Write-Host "Теперь в GUI:" -ForegroundColor Yellow
Write-Host "1. Кнопка 'Скачать изображение' должна быть активна" -ForegroundColor White
Write-Host "2. При нажатии откроется диалог сохранения" -ForegroundColor White
Write-Host "3. Можно выбрать место для сохранения тестового изображения" -ForegroundColor White
Write-Host ""
Write-Host "=== ЗАПУСК GUI ===" -ForegroundColor Cyan
# Устанавливаем глобальную переменную для теста
$global:generatedImageUrl = $testImageUrl
$global:currentSource = "unsplash"
# Запускаем GUI
. "C:\Users\Пользователь\Documents\illustraitor-ai-generator\image_generator_gui_COMPLETE.ps1"
