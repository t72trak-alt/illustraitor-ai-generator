# test_api.ps1 - Тестирование API
Write-Host "=== ТЕСТИРОВАНИЕ API СЕРВЕРА ===" -ForegroundColor Cyan
$apiServer = "https://illustraitor-ai-generator.onrender.com"
# 1. Проверка health
Write-Host "`n1. Проверка /health:" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$apiServer/health" -Method Get -TimeoutSec 10
    Write-Host "   ✓ Статус: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Ошибка: $_" -ForegroundColor Red
}
# 2. Тестовый запрос
Write-Host "`n2. Тестовый запрос к /generate:" -ForegroundColor Yellow
$testBody = @{
    prompt = "test sunset"
    source = "dalle"
    api_key = "test-key-123"
} | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "$apiServer/generate" `
        -Method Post `
        -ContentType "application/json" `
        -Body $testBody `
        -TimeoutSec 10
    Write-Host "   ✓ Ответ получен" -ForegroundColor Green
    Write-Host "   URL: $($response.url)" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Ошибка: $_" -ForegroundColor Red
}
# 3. Прямой запрос к Unsplash
Write-Host "`n3. Прямой запрос к Unsplash:" -ForegroundColor Yellow
try {
    $url = "https://source.unsplash.com/400x300/?sunset,mountains"
    $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10
    Write-Host "   ✓ Unsplash доступен" -ForegroundColor Green
    Write-Host "   URL: $url" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Ошибка: $_" -ForegroundColor Red
}
Write-Host "`n=== ТЕСТ ЗАВЕРШЕН ===" -ForegroundColor Cyan
Pause
