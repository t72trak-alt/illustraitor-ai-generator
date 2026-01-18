Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# ============================================
# ILLUSTRAITOR AI - ПОЛНАЯ ВЕРСИЯ С API
# Двойная генерация: DALL-E 3 + Unsplash
# Реальные API вызовы
# ============================================
# --- КОНСТАНТЫ ---
$API_URL = "https://illustraitor-ai-generator.onrender.com"
$CONFIG_PATH = "$env:APPDATA\AI_Image_Generator\config.json"
$global:generatedImageUrl = $null
$global:currentSource = $null
$global:statusLabel = $null
# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---
function Save-Config {
    param([string]$OpenAIKey, [string]$UnsplashKey)
    $configDir = Split-Path $CONFIG_PATH -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    $config = @{
        OpenAIKey = $OpenAIKey
        UnsplashKey = $UnsplashKey
        LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    $config | ConvertTo-Json | Out-File -FilePath $CONFIG_PATH -Encoding UTF8
    return $true
}
function Load-Config {
    if (Test-Path $CONFIG_PATH) {
        try {
            return Get-Content $CONFIG_PATH -Raw | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}
function Show-Message {
    param([string]$Message, [string]$Type = "Info")
    $color = switch ($Type) {
        "Success" { [System.Drawing.Color]::FromArgb(166, 227, 161) }
        "Error"   { [System.Drawing.Color]::FromArgb(237, 135, 150) }
        "Warning" { [System.Drawing.Color]::FromArgb(249, 226, 175) }
        default   { [System.Drawing.Color]::FromArgb(137, 180, 250) }
    }
    if ($global:statusLabel -ne $null) {
        $global:statusLabel.Text = $Message
        $global:statusLabel.ForeColor = $color
    }
    $colorName = if ($Type -eq "Error") { "Red" } else { "Cyan" }
    Write-Host "${Type}: $Message" -ForegroundColor $colorName
}
# --- РЕАЛЬНЫЕ API ФУНКЦИИ ---
function Invoke-IllustraitorAPI {
    param(
        [string]$Endpoint,
        [hashtable]$Body,
        [string]$Method = "POST"
    )
    try {
        $jsonBody = $Body | ConvertTo-Json
        $uri = "$API_URL/$Endpoint"
        $response = Invoke-RestMethod -Uri $uri `
            -Method $Method `
            -Body $jsonBody `
            -ContentType "application/json" `
            -TimeoutSec 180
        return @{ Success = $true; Data = $response }
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            $streamReader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errorContent = $streamReader.ReadToEnd()
            $streamReader.Close()
            try {
                $errorJson = $errorContent | ConvertFrom-Json
                if ($errorJson.detail) {
                    $errorMsg = $errorJson.detail
                } elseif ($errorJson.error) {
                    $errorMsg = $errorJson.error
                }
            } catch {
                $errorMsg = $errorContent
            }
        }
        return @{ Success = $false; Error = $errorMsg }
    }
}
# --- СОЗДАНИЕ ИНТЕРФЕЙСА (ВАША ТЕКУЩАЯ ВЕРСИЯ) ---
function Create-GUI {
    # Ваш текущий код создания интерфейса здесь
    # Но нам нужно добавить недостающие обработчики
    # ... ваш текущий код создания элементов формы ...
    # После создания всех элементов и фиксации переменных
    # ДОБАВЛЯЕМ НОВЫЕ ОБРАБОТЧИКИ:
    # ========== ОБРАБОТЧИК ПРОВЕРКИ OPENAI ==========
    $btnTestOpenAI.Add_Click({
        $key = $script:textOpenAI.Text.Trim()
        if (-not $key) {
            Show-Message "Введите ключ OpenAI для проверки" "Warning"
            return
        }
        $script:btnTestOpenAI.Text = "⏳ Проверка..."
        $script:btnTestOpenAI.Enabled = $false
        Show-Message "Проверяем ключ OpenAI через API..." "Info"
        # Запускаем проверку в фоновом задании
        $job = Start-Job -ScriptBlock {
            param($key)
            $body = @{ api_key = $key }
            try {
                $response = Invoke-RestMethod `
                    -Uri "https://illustraitor-ai-generator.onrender.com/validate/openai" `
                    -Method POST `
                    -Body ($body | ConvertTo-Json) `
                    -ContentType "application/json" `
                    -TimeoutSec 30
                return @{ Success = $true; Message = "✅ Ключ OpenAI валиден и работает!" }
            }
            catch {
                return @{ Success = $false; Message = "❌ Ошибка проверки: $_" }
            }
        } -ArgumentList $key
        # Таймер для проверки завершения
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 100
        $timer.Add_Tick({
            if ($job.State -eq "Completed") {
                $timer.Stop()
                $result = Receive-Job -Job $job
                Remove-Job -Job $job
                if ($result.Success) {
                    Show-Message $result.Message "Success"
                    $script:btnTestOpenAI.Text = "✅ Валиден"
                    $script:btnTestOpenAI.BackColor = [System.Drawing.Color]::LightGreen
                } else {
                    Show-Message $result.Message "Error"
                    $script:btnTestOpenAI.Text = "❌ Ошибка"
                    $script:btnTestOpenAI.BackColor = [System.Drawing.Color]::LightCoral
                }
                # Возвращаем исходный вид через 3 секунды
                Start-Job -ScriptBlock {
                    Start-Sleep -Seconds 3
                    $script:btnTestOpenAI.Text = "🔍 Проверить"
                    $script:btnTestOpenAI.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
                    $script:btnTestOpenAI.Enabled = $true
                }
            }
        })
        $timer.Start()
    })
    # ========== ОБРАБОТЧИК ПРОВЕРКИ UNSPLASH ==========
    $btnTestUnsplash.Add_Click({
        $key = $script:textUnsplash.Text.Trim()
        if (-not $key) {
            Show-Message "Введите ключ Unsplash для проверки" "Warning"
            return
        }
        $script:btnTestUnsplash.Text = "⏳ Проверка..."
        $script:btnTestUnsplash.Enabled = $false
        Show-Message "Проверяем ключ Unsplash через API..." "Info"
        $job = Start-Job -ScriptBlock {
            param($key)
            $body = @{ api_key = $key }
            try {
                $response = Invoke-RestMethod `
                    -Uri "https://illustraitor-ai-generator.onrender.com/validate/unsplash" `
                    -Method POST `
                    -Body ($body | ConvertTo-Json) `
                    -ContentType "application/json" `
                    -TimeoutSec 30
                return @{ Success = $true; Message = "✅ Ключ Unsplash валиден и работает!" }
            }
            catch {
                return @{ Success = $false; Message = "❌ Ошибка проверки: $_" }
            }
        } -ArgumentList $key
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 100
        $timer.Add_Tick({
            if ($job.State -eq "Completed") {
                $timer.Stop()
                $result = Receive-Job -Job $job
                Remove-Job -Job $job
                if ($result.Success) {
                    Show-Message $result.Message "Success"
                    $script:btnTestUnsplash.Text = "✅ Валиден"
                    $script:btnTestUnsplash.BackColor = [System.Drawing.Color]::LightGreen
                } else {
                    Show-Message $result.Message "Error"
                    $script:btnTestUnsplash.Text = "❌ Ошибка"
                    $script:btnTestUnsplash.BackColor = [System.Drawing.Color]::LightCoral
                }
                Start-Job -ScriptBlock {
                    Start-Sleep -Seconds 3
                    $script:btnTestUnsplash.Text = "🔍 Проверить"
                    $script:btnTestUnsplash.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
                    $script:btnTestUnsplash.Enabled = $true
                }
            }
        })
        $timer.Start()
    })
    # ========== ОБРАБОТЧИК ГЕНЕРАЦИИ DALL-E 3 ==========
    $btnGenerateDALLE.Add_Click({
        if ($script:textOpenAI.Text.Trim() -eq "") {
            Show-Message "Ошибка: для генерации нужен ключ OpenAI" "Error"
            return
        }
        if ($script:textPrompt.Text.Trim() -eq "") {
            Show-Message "Ошибка: введите промпт для генерации" "Error"
            return
        }
        # Получаем выбранные стили
        $selectedStyles = @()
        for ($i = 0; $i -lt $script:listStyles.Items.Count; $i++) {
            if ($script:listStyles.GetItemChecked($i)) {
                $styleText = $script:listStyles.Items[$i] -replace "^[^\s]+\s+", ""
                $selectedStyles += $styleText
            }
        }
        if ($selectedStyles.Count -eq 0) {
            $selectedStyles = @("Реализм")
        }
        $script:btnGenerateDALLE.Text = "⏳ Генерация..."
        $script:btnGenerateDALLE.Enabled = $false
        $script:btnSearchUnsplash.Enabled = $false
        Show-Message "Генерация изображения через DALL-E 3..." "Info"
        # Запускаем генерацию в фоновом задании
        $job = Start-Job -ScriptBlock {
            param($prompt, $apiKey, $styles)
            # Формируем полный промпт
            $fullPrompt = $prompt
            if ($styles.Count -gt 0) {
                $styleText = $styles -join ", "
                $fullPrompt = "$prompt, в стиле: $styleText"
            }
            $body = @{
                prompt = $fullPrompt
                api_key = $apiKey
                source = "dalle"
                size = "1024x1024"
            }
            try {
                $response = Invoke-RestMethod `
                    -Uri "https://illustraitor-ai-generator.onrender.com/generate" `
                    -Method POST `
                    -Body ($body | ConvertTo-Json) `
                    -ContentType "application/json" `
                    -TimeoutSec 180
                if ($response.url) {
                    return @{ 
                        Success = $true; 
                        ImageUrl = $response.url;
                        Message = "✅ Изображение сгенерировано через DALL-E 3!"
                    }
                } else {
                    return @{ 
                        Success = $false; 
                        Message = "❌ API не вернул URL изображения" 
                    }
                }
            }
            catch {
                return @{ 
                    Success = $false; 
                    Message = "❌ Ошибка генерации: $_" 
                }
            }
        } -ArgumentList $script:textPrompt.Text.Trim(), $script:textOpenAI.Text.Trim(), $selectedStyles
        # Таймер для проверки завершения
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 100
        $timer.Add_Tick({
            if ($job.State -eq "Completed") {
                $timer.Stop()
                $result = Receive-Job -Job $job
                Remove-Job -Job $job
                if ($result.Success) {
                    $script:generatedImageUrl = $result.ImageUrl
                    $script:currentSource = "dalle"
                    $script:btnDownload.Enabled = $true
                    $script:btnGenerateDALLE.Text = "✅ Готово!"
                    Show-Message $result.Message "Success"
                } else {
                    $script:btnGenerateDALLE.Text = "❌ Ошибка"
                    Show-Message $result.Message "Error"
                }
                # Возвращаем исходный вид через 3 секунды
                Start-Job -ScriptBlock {
                    Start-Sleep -Seconds 3
                    $script:btnGenerateDALLE.Text = "🎨 ГЕНЕРИРОВАТЬ (DALL-E 3)"
                    $script:btnGenerateDALLE.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
                    $script:btnGenerateDALLE.Enabled = $true
                    $script:btnSearchUnsplash.Enabled = $true
                }
            }
        })
        $timer.Start()
    })
    # ========== ОБРАБОТЧИК ПОИСКА UNSPLASH ==========
    $btnSearchUnsplash.Add_Click({
        if ($script:textUnsplash.Text.Trim() -eq "") {
            Show-Message "Ошибка: для поиска нужен ключ Unsplash" "Error"
            return
        }
        if ($script:textPrompt.Text.Trim() -eq "") {
            Show-Message "Ошибка: введите запрос для поиска" "Error"
            return
        }
        $script:btnSearchUnsplash.Text = "⏳ Поиск..."
        $script:btnSearchUnsplash.Enabled = $false
        $script:btnGenerateDALLE.Enabled = $false
        Show-Message "Поиск изображений в библиотеке Unsplash..." "Info"
        $job = Start-Job -ScriptBlock {
            param($prompt, $apiKey)
            $body = @{
                prompt = $prompt
                api_key = $apiKey
                source = "unsplash"
            }
            try {
                $response = Invoke-RestMethod `
                    -Uri "https://illustraitor-ai-generator.onrender.com/generate" `
                    -Method POST `
                    -Body ($body | ConvertTo-Json) `
                    -ContentType "application/json" `
                    -TimeoutSec 180
                if ($response.url) {
                    return @{ 
                        Success = $true; 
                        ImageUrl = $response.url;
                        Message = "✅ Изображение найдено в Unsplash!"
                    }
                } else {
                    return @{ 
                        Success = $false; 
                        Message = "❌ API не вернул URL изображения" 
                    }
                }
            }
            catch {
                return @{ 
                    Success = $false; 
                    Message = "❌ Ошибка поиска: $_" 
                }
            }
        } -ArgumentList $script:textPrompt.Text.Trim(), $script:textUnsplash.Text.Trim()
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 100
        $timer.Add_Tick({
            if ($job.State -eq "Completed") {
                $timer.Stop()
                $result = Receive-Job -Job $job
                Remove-Job -Job $job
                if ($result.Success) {
                    $script:generatedImageUrl = $result.ImageUrl
                    $script:currentSource = "unsplash"
                    $script:btnDownload.Enabled = $true
                    $script:btnSearchUnsplash.Text = "✅ Найдено!"
                    Show-Message $result.Message "Success"
                } else {
                    $script:btnSearchUnsplash.Text = "❌ Ошибка"
                    Show-Message $result.Message "Error"
                }
                Start-Job -ScriptBlock {
                    Start-Sleep -Seconds 3
                    $script:btnSearchUnsplash.Text = "🔎 ПОИСК (Unsplash)"
                    $script:btnSearchUnsplash.BackColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
                    $script:btnSearchUnsplash.Enabled = $true
                    $script:btnGenerateDALLE.Enabled = $true
                }
            }
        })
        $timer.Start()
    })
    return $form
}
# --- ЗАПУСК ПРИЛОЖЕНИЯ ---
try {
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "🎨 ILLUSTRAITOR AI - ПОЛНАЯ ВЕРСИЯ" -ForegroundColor Yellow
    Write-Host "📡 API: $API_URL" -ForegroundColor Green
    Write-Host "⚡ Реальные API вызовы" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    $form = Create-GUI
    $form.Text = "🎨 Illustraitor AI - DALL-E 3 + Unsplash [API READY]"
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [void]$form.ShowDialog()
}
catch {
    Write-Host "Ошибка: $_" -ForegroundColor Red
}
