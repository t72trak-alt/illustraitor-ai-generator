Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# ============================================
# ILLUSTRAITOR AI - ДВОЙНАЯ ГЕНЕРАЦИЯ
# OpenAI DALL-E 3 + Unsplash поиск
# Оба источника равноценны и независимы
# ============================================
# --- КОНСТАНТЫ И ПЕРЕМЕННЫЕ ---
$API_URL = "https://illustraitor-ai-generator.onrender.com"
$CONFIG_PATH = "$env:APPDATA\AI_Image_Generator\config.json"
$generatedImageUrl = $null
$currentSource = $null # "dalle" или "unsplash"
$form = $null
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
    return $CONFIG_PATH
}
function Load-Config {
    if (Test-Path $CONFIG_PATH) {
        try {
            return Get-Content $CONFIG_PATH -Raw | ConvertFrom-Json
        }
        catch {
            Write-Host "Ошибка загрузки конфига: $_" -ForegroundColor Yellow
            return $null
        }
    }
    return $null
}
function Test-OpenAIKey {
    param([string]$apiKey)
    if (-not $apiKey -or -not $apiKey.StartsWith("sk-")) {
        return $false
    }
    try {
        $body = @{ api_key = $apiKey } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$API_URL/validate/openai" `
            -Method Post -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 10
        return $response.valid -eq $true
    }
    catch {
        Write-Host "Ошибка проверки ключа OpenAI: $_" -ForegroundColor Red
        return $false
    }
}
function Test-UnsplashKey {
    param([string]$apiKey)
    if (-not $apiKey) {
        return $false
    }
    try {
        $body = @{ api_key = $apiKey } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$API_URL/validate/unsplash" `
            -Method Post -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 10
        return $response.valid -eq $true
    }
    catch {
        Write-Host "Ошибка проверки ключа Unsplash: $_" -ForegroundColor Red
        return $false
    }
}
function Generate-DALLE {
    param(
        [string]$prompt,
        [string]$apiKey,
        [string[]]$styles,
        [string]$size = "1024x1024"
    )
    try {
        # Формируем полный промпт со стилями
        $fullPrompt = $prompt
        if ($styles.Count -gt 0) {
            $styleText = $styles -join ", "
            $fullPrompt = "$prompt, в стиле: $styleText"
        }
        $body = @{
            prompt = $fullPrompt
            source = "dalle"
            api_key = $apiKey
            size = $size
        } | ConvertTo-Json
        Write-Host "Отправка запроса к DALL-E API..." -ForegroundColor Cyan
        $response = Invoke-RestMethod -Uri "$API_URL/generate" `
            -Method Post -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 60
        if ($response.image_url) {
            return @{
                success = $true;
                image_url = $response.image_url;
                source = "DALL-E 3";
                message = "Изображение сгенерировано DALL-E 3!"
            }
        }
        else {
            return @{ success = $false; error = "DALL-E API не вернул URL изображения" }
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $errorMsg = $reader.ReadToEnd() | ConvertFrom-Json | Select-Object -ExpandProperty detail
                $reader.Close()
            }
            catch { }
        }
        return @{ success = $false; error = $errorMsg }
    }
}
function Search-Unsplash {
    param(
        [string]$query,
        [string]$apiKey
    )
    try {
        $body = @{
            prompt = $query
            source = "unsplash"
            api_key = $apiKey
        } | ConvertTo-Json
        Write-Host "Поиск изображений в Unsplash..." -ForegroundColor Cyan
        $response = Invoke-RestMethod -Uri "$API_URL/generate" `
            -Method Post -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 30
        if ($response.image_url) {
            return @{
                success = $true;
                image_url = $response.image_url;
                source = "Unsplash";
                message = "Изображение найдено в Unsplash!"
            }
        }
        else {
            return @{ success = $false; error = "Unsplash API не вернул изображение" }
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $errorMsg = $reader.ReadToEnd() | ConvertFrom-Json | Select-Object -ExpandProperty detail
                $reader.Close()
            }
            catch { }
        }
        return @{ success = $false; error = $errorMsg }
    }
}
function Download-Image {
    param([string]$url, [string]$savePath)
    try {
        Write-Host "Скачивание изображения..." -ForegroundColor Cyan
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $savePath)
        $webClient.Dispose()
        return $true
    }
    catch {
        Write-Host "Ошибка скачивания: $_" -ForegroundColor Red
        return $false
    }
}
# --- СОЗДАНИЕ ИНТЕРФЕЙСА ---
function Create-GUI {
    # Основная форма
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "🎨 Illustraitor AI - Двойная генерация"
    $form.Size = New-Object System.Drawing.Size(850, 750)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 46)
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    # Заголовок
    $labelTitle = New-Object System.Windows.Forms.Label
    $labelTitle.Text = "Illustraitor AI - Двойная генерация"
    $labelTitle.ForeColor = [System.Drawing.Color]::FromArgb(94, 234, 212)
    $labelTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $labelTitle.Location = New-Object System.Drawing.Point(20, 15)
    $labelTitle.Size = New-Object System.Drawing.Size(810, 40)
    $labelTitle.TextAlign = "MiddleCenter"
    $form.Controls.Add($labelTitle)
    # --- Секция API ключей (РАВНОЦЕННЫЕ) ---
    $groupAPI = New-Object System.Windows.Forms.GroupBox
    $groupAPI.Text = "API Ключи (оба источника независимы)"
    $groupAPI.ForeColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
    $groupAPI.Location = New-Object System.Drawing.Point(20, 70)
    $groupAPI.Size = New-Object System.Drawing.Size(810, 160)
    $groupAPI.BackColor = [System.Drawing.Color]::FromArgb(49, 51, 68)
    $form.Controls.Add($groupAPI)
    # ===== OPENAI API KEY (СЛЕВА) =====
    $labelOpenAI = New-Object System.Windows.Forms.Label
    $labelOpenAI.Text = "OpenAI API Key (DALL-E 3):"
    $labelOpenAI.ForeColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
    $labelOpenAI.Location = New-Object System.Drawing.Point(15, 25)
    $labelOpenAI.Size = New-Object System.Drawing.Size(380, 20)
    $labelOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $groupAPI.Controls.Add($labelOpenAI)
    $panelOpenAI = New-Object System.Windows.Forms.Panel
    $panelOpenAI.Location = New-Object System.Drawing.Point(15, 50)
    $panelOpenAI.Size = New-Object System.Drawing.Size(380, 30)
    $panelOpenAI.BackColor = [System.Drawing.Color]::Transparent
    $groupAPI.Controls.Add($panelOpenAI)
    $textOpenAI = New-Object System.Windows.Forms.TextBox
    $textOpenAI.Location = New-Object System.Drawing.Point(0, 0)
    $textOpenAI.Size = New-Object System.Drawing.Size(345, 30)
    $textOpenAI.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $textOpenAI.ForeColor = [System.Drawing.Color]::White
    $textOpenAI.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textOpenAI.PasswordChar = '•'
    $panelOpenAI.Controls.Add($textOpenAI)
    $btnShowOpenAI = New-Object System.Windows.Forms.Button
    $btnShowOpenAI.Text = "👁"
    $btnShowOpenAI.Location = New-Object System.Drawing.Point(350, 0)
    $btnShowOpenAI.Size = New-Object System.Drawing.Size(30, 30)
    $btnShowOpenAI.BackColor = [System.Drawing.Color]::FromArgb(89, 91, 110)
    $btnShowOpenAI.ForeColor = [System.Drawing.Color]::White
    $btnShowOpenAI.FlatStyle = "Flat"
    $btnShowOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $panelOpenAI.Controls.Add($btnShowOpenAI)
    # Кнопки для OpenAI
    $panelOpenAIButtons = New-Object System.Windows.Forms.Panel
    $panelOpenAIButtons.Location = New-Object System.Drawing.Point(15, 85)
    $panelOpenAIButtons.Size = New-Object System.Drawing.Size(380, 30)
    $panelOpenAIButtons.BackColor = [System.Drawing.Color]::Transparent
    $groupAPI.Controls.Add($panelOpenAIButtons)
    $btnSaveOpenAI = New-Object System.Windows.Forms.Button
    $btnSaveOpenAI.Text = "💾 Сохранить"
    $btnSaveOpenAI.Location = New-Object System.Drawing.Point(0, 0)
    $btnSaveOpenAI.Size = New-Object System.Drawing.Size(90, 25)
    $btnSaveOpenAI.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $btnSaveOpenAI.ForeColor = [System.Drawing.Color]::Black
    $btnSaveOpenAI.FlatStyle = "Flat"
    $btnSaveOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $panelOpenAIButtons.Controls.Add($btnSaveOpenAI)
    $btnDeleteOpenAI = New-Object System.Windows.Forms.Button
    $btnDeleteOpenAI.Text = "🗑 Удалить"
    $btnDeleteOpenAI.Location = New-Object System.Drawing.Point(95, 0)
    $btnDeleteOpenAI.Size = New-Object System.Drawing.Size(90, 25)
    $btnDeleteOpenAI.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
    $btnDeleteOpenAI.ForeColor = [System.Drawing.Color]::White
    $btnDeleteOpenAI.FlatStyle = "Flat"
    $btnDeleteOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $panelOpenAIButtons.Controls.Add($btnDeleteOpenAI)
    $btnTestOpenAI = New-Object System.Windows.Forms.Button
    $btnTestOpenAI.Text = "🔍 Проверить"
    $btnTestOpenAI.Location = New-Object System.Drawing.Point(190, 0)
    $btnTestOpenAI.Size = New-Object System.Drawing.Size(90, 25)
    $btnTestOpenAI.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
    $btnTestOpenAI.ForeColor = [System.Drawing.Color]::Black
    $btnTestOpenAI.FlatStyle = "Flat"
    $btnTestOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $panelOpenAIButtons.Controls.Add($btnTestOpenAI)
    # ===== UNSPLASH API KEY (СПРАВА) =====
    $labelUnsplash = New-Object System.Windows.Forms.Label
    $labelUnsplash.Text = "Unsplash Access Key (поиск фото):"
    $labelUnsplash.ForeColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
    $labelUnsplash.Location = New-Object System.Drawing.Point(415, 25)
    $labelUnsplash.Size = New-Object System.Drawing.Size(380, 20)
    $labelUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $groupAPI.Controls.Add($labelUnsplash)
    $panelUnsplash = New-Object System.Windows.Forms.Panel
    $panelUnsplash.Location = New-Object System.Drawing.Point(415, 50)
    $panelUnsplash.Size = New-Object System.Drawing.Size(380, 30)
    $panelUnsplash.BackColor = [System.Drawing.Color]::Transparent
    $groupAPI.Controls.Add($panelUnsplash)
    $textUnsplash = New-Object System.Windows.Forms.TextBox
    $textUnsplash.Location = New-Object System.Drawing.Point(0, 0)
    $textUnsplash.Size = New-Object System.Drawing.Size(345, 30)
    $textUnsplash.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $textUnsplash.ForeColor = [System.Drawing.Color]::White
    $textUnsplash.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textUnsplash.PasswordChar = '•'
    $panelUnsplash.Controls.Add($textUnsplash)
    $btnShowUnsplash = New-Object System.Windows.Forms.Button
    $btnShowUnsplash.Text = "👁"
    $btnShowUnsplash.Location = New-Object System.Drawing.Point(350, 0)
    $btnShowUnsplash.Size = New-Object System.Drawing.Size(30, 30)
    $btnShowUnsplash.BackColor = [System.Drawing.Color]::FromArgb(89, 91, 110)
    $btnShowUnsplash.ForeColor = [System.Drawing.Color]::White
    $btnShowUnsplash.FlatStyle = "Flat"
    $btnShowUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $panelUnsplash.Controls.Add($btnShowUnsplash)
    # Кнопки для Unsplash
    $panelUnsplashButtons = New-Object System.Windows.Forms.Panel
    $panelUnsplashButtons.Location = New-Object System.Drawing.Point(415, 85)
    $panelUnsplashButtons.Size = New-Object System.Drawing.Size(380, 30)
    $panelUnsplashButtons.BackColor = [System.Drawing.Color]::Transparent
    $groupAPI.Controls.Add($panelUnsplashButtons)
    $btnSaveUnsplash = New-Object System.Windows.Forms.Button
    $btnSaveUnsplash.Text = "💾 Сохранить"
    $btnSaveUnsplash.Location = New-Object System.Drawing.Point(0, 0)
    $btnSaveUnsplash.Size = New-Object System.Drawing.Size(90, 25)
    $btnSaveUnsplash.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $btnSaveUnsplash.ForeColor = [System.Drawing.Color]::Black
    $btnSaveUnsplash.FlatStyle = "Flat"
    $btnSaveUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $panelUnsplashButtons.Controls.Add($btnSaveUnsplash)

    # --- ОБРАБОТЧИК СОХРАНЕНИЯ UNSPLASH ---
        $btnSaveUnsplash.Add_Click({
        $key = $textUnsplash.Text.Trim()
        if ($key) {
            $savedConfig = Load-Config
            $openAIKey = if ($savedConfig -and $savedConfig.OpenAIKey) { $savedConfig.OpenAIKey } else { "" }
            Save-Config -OpenAIKey $openAIKey -UnsplashKey $key
            $btnSaveUnsplash.Text = "✓ Сохранено"
            $btnSaveUnsplash.BackColor = [System.Drawing.Color]::FromArgb(116, 199, 110)
            Start-Sleep -Milliseconds 800
            $btnSaveUnsplash.Text = "💾 Сохранить"
            $btnSaveUnsplash.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
            $statusLabel.Text = "Ключ Unsplash сохранен!"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
        } else {
            $statusLabel.Text = "Ошибка: введите ключ Unsplash"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
        }
    }

    $btnDeleteUnsplash = New-Object System.Windows.Forms.Button
    $btnDeleteUnsplash.Text = "🗑 Удалить"
    $btnDeleteUnsplash.Location = New-Object System.Drawing.Point(95, 0)
    $btnDeleteUnsplash.Size = New-Object System.Drawing.Size(90, 25)
    $btnDeleteUnsplash.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
    $btnDeleteUnsplash.ForeColor = [System.Drawing.Color]::White
    $btnDeleteUnsplash.FlatStyle = "Flat"
    $btnDeleteUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $panelUnsplashButtons.Controls.Add($btnDeleteUnsplash)
    $btnTestUnsplash = New-Object System.Windows.Forms.Button
    $btnTestUnsplash.Text = "🔍 Проверить"
    $btnTestUnsplash.Location = New-Object System.Drawing.Point(190, 0)
    $btnTestUnsplash.Size = New-Object System.Drawing.Size(90, 25)
    $btnTestUnsplash.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
    $btnTestUnsplash.ForeColor = [System.Drawing.Color]::Black
    $btnTestUnsplash.FlatStyle = "Flat"
    $btnTestUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $panelUnsplashButtons.Controls.Add($btnTestUnsplash)
    # Подсказки под ключами
    $labelOpenAIHint = New-Object System.Windows.Forms.Label
    $labelOpenAIHint.Text = "Для генерации новых изображений через DALL-E 3"
    $labelOpenAIHint.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
    $labelOpenAIHint.Location = New-Object System.Drawing.Point(15, 120)
    $labelOpenAIHint.Size = New-Object System.Drawing.Size(380, 15)
    $labelOpenAIHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $groupAPI.Controls.Add($labelOpenAIHint)
    $labelUnsplashHint = New-Object System.Windows.Forms.Label
    $labelUnsplashHint.Text = "Для поиска реальных фото в библиотеке Unsplash"
    $labelUnsplashHint.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
    $labelUnsplashHint.Location = New-Object System.Drawing.Point(415, 120)
    $labelUnsplashHint.Size = New-Object System.Drawing.Size(380, 15)
    $labelUnsplashHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $groupAPI.Controls.Add($labelUnsplashHint)
    # --- Секция промпта (ОБЩАЯ ДЛЯ ОБОИХ ИСТОЧНИКОВ) ---
    $groupPrompt = New-Object System.Windows.Forms.GroupBox
    $groupPrompt.Text = "Запрос / промпт (общий для обоих источников)"
    $groupPrompt.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
    $groupPrompt.Location = New-Object System.Drawing.Point(20, 245)
    $groupPrompt.Size = New-Object System.Drawing.Size(810, 150)
    $groupPrompt.BackColor = [System.Drawing.Color]::FromArgb(49, 51, 68)
    $form.Controls.Add($groupPrompt)
    $labelPrompt = New-Object System.Windows.Forms.Label
    $labelPrompt.Text = "Опишите изображение или тему для поиска:"
    $labelPrompt.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $labelPrompt.Location = New-Object System.Drawing.Point(15, 25)
    $labelPrompt.Size = New-Object System.Drawing.Size(500, 20)
    $labelPrompt.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $groupPrompt.Controls.Add($labelPrompt)
    $textPrompt = New-Object System.Windows.Forms.TextBox
    $textPrompt.Multiline = $true
    $textPrompt.Location = New-Object System.Drawing.Point(15, 50)
    $textPrompt.Size = New-Object System.Drawing.Size(780, 90)
    $textPrompt.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $textPrompt.ForeColor = [System.Drawing.Color]::White
    $textPrompt.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $textPrompt.ScrollBars = "Vertical"
    $groupPrompt.Controls.Add($textPrompt)
    # --- Секция стилей (ТОЛЬКО ДЛЯ DALL-E) ---
    $groupStyles = New-Object System.Windows.Forms.GroupBox
    $groupStyles.Text = "Стили изображения (только для DALL-E 3)"
    $groupStyles.ForeColor = [System.Drawing.Color]::FromArgb(137, 220, 235)
    $groupStyles.Location = New-Object System.Drawing.Point(20, 410)
    $groupStyles.Size = New-Object System.Drawing.Size(810, 180)
    $groupStyles.BackColor = [System.Drawing.Color]::FromArgb(49, 51, 68)
    $form.Controls.Add($groupStyles)
    $styles = @(
        "🔮 Реализм", "🎨 Импрессионизм", "🌌 Сюрреализм", "🌀 Абстракционизм", "🟡 Поп-арт",
        "🤖 Киберпанк", "⚙️ Стимпанк", "🐉 Фэнтези", "🌸 Аниме", "🎮 Пиксель-арт",
        "🖌️ Масляная живопись", "💧 Акварель", "⚫ Черно-белое", "📜 Винтаж", "📺 Мультяшный"
    )
    $listStyles = New-Object System.Windows.Forms.CheckedListBox
    $listStyles.Location = New-Object System.Drawing.Point(15, 25)
    $listStyles.Size = New-Object System.Drawing.Size(780, 145)
    $listStyles.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $listStyles.ForeColor = [System.Drawing.Color]::White
    $listStyles.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $listStyles.BorderStyle = "FixedSingle"
    $listStyles.CheckOnClick = $true
    foreach ($style in $styles) {
        [void]$listStyles.Items.Add($style, $false)
    }
    $groupStyles.Controls.Add($listStyles)
    # --- КНОПКИ УПРАВЛЕНИЯ (ДВЕ РАВНОЦЕННЫЕ) ---
    $panelControls = New-Object System.Windows.Forms.Panel
    $panelControls.Location = New-Object System.Drawing.Point(20, 605)
    $panelControls.Size = New-Object System.Drawing.Size(810, 100)
    $panelControls.BackColor = [System.Drawing.Color]::Transparent
    $form.Controls.Add($panelControls)
    # Кнопка 1: Генерация через DALL-E
    $btnGenerateDALLE = New-Object System.Windows.Forms.Button
    $btnGenerateDALLE.Text = "🎨 ГЕНЕРИРОВАТЬ (DALL-E 3)"
    $btnGenerateDALLE.Location = New-Object System.Drawing.Point(10, 10)
    $btnGenerateDALLE.Size = New-Object System.Drawing.Size(390, 50)
    $btnGenerateDALLE.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
    $btnGenerateDALLE.ForeColor = [System.Drawing.Color]::White
    $btnGenerateDALLE.FlatStyle = "Flat"
    $btnGenerateDALLE.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $panelControls.Controls.Add($btnGenerateDALLE)
    # Кнопка 2: Поиск через Unsplash
    $btnSearchUnsplash = New-Object System.Windows.Forms.Button
    $btnSearchUnsplash.Text = "🔎 ПОИСК (Unsplash)"
    $btnSearchUnsplash.Location = New-Object System.Drawing.Point(410, 10)
    $btnSearchUnsplash.Size = New-Object System.Drawing.Size(390, 50)
    $btnSearchUnsplash.BackColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
    $btnSearchUnsplash.ForeColor = [System.Drawing.Color]::White
    $btnSearchUnsplash.FlatStyle = "Flat"
    $btnSearchUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $panelControls.Controls.Add($btnSearchUnsplash)
    # Кнопка скачивания (общая)
    $btnDownload = New-Object System.Windows.Forms.Button
    $btnDownload.Text = "💾 СКАЧАТЬ ИЗОБРАЖЕНИЕ"
    $btnDownload.Location = New-Object System.Drawing.Point(10, 65)
    $btnDownload.Size = New-Object System.Drawing.Size(790, 30)
    $btnDownload.BackColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
    $btnDownload.ForeColor = [System.Drawing.Color]::White
    $btnDownload.FlatStyle = "Flat"
    $btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnDownload.Enabled = $false
    $panelControls.Controls.Add($btnDownload)
    # Статусная строка
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "Готов к работе. Выберите источник: DALL-E 3 или Unsplash"
    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $statusLabel.Location = New-Object System.Drawing.Point(20, 710)
    $statusLabel.Size = New-Object System.Drawing.Size(810, 20)
    $statusLabel.TextAlign = "MiddleCenter"
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.Controls.Add($statusLabel)
    # --- ОБРАБОТЧИКИ СОБЫТИЙ ДЛЯ КНОПОК ПРОСМОТРА ---
    $script:openAIVisible = $false
    $btnShowOpenAI.Add_Click({
        $script:openAIVisible = -not $script:openAIVisible
        if ($script:openAIVisible) {
            $textOpenAI.PasswordChar = $null
            $btnShowOpenAI.Text = "🔒"
            $btnShowOpenAI.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
        } else {
            $textOpenAI.PasswordChar = '•'
            $btnShowOpenAI.Text = "👁"
            $btnShowOpenAI.BackColor = [System.Drawing.Color]::FromArgb(89, 91, 110)
        }
    })
    $script:unsplashVisible = $false
    $btnShowUnsplash.Add_Click({
        $script:unsplashVisible = -not $script:unsplashVisible
        if ($script:unsplashVisible) {
            $textUnsplash.PasswordChar = $null
            $btnShowUnsplash.Text = "🔒"
            $btnShowUnsplash.BackColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
        } else {
            $textUnsplash.PasswordChar = '•'
            $btnShowUnsplash.Text = "👁"
            $btnShowUnsplash.BackColor = [System.Drawing.Color]::FromArgb(89, 91, 110)
        }
    })
    # --- ОБРАБОТЧИКИ СОХРАНЕНИЯ/УДАЛЕНИЯ КЛЮЧЕЙ ---
    $btnSaveOpenAI.Add_Click({
        $key = $textOpenAI.Text.Trim()
        if ($key -and $key.StartsWith("sk-")) {
            $savedConfig = Load-Config
            $unsplashKey = if ($savedConfig -and $savedConfig.UnsplashKey) { $savedConfig.UnsplashKey } else { "" }
            Save-Config -OpenAIKey $key -UnsplashKey $unsplashKey
            $btnSaveOpenAI.Text = "✓ Сохранено"
            $btnSaveOpenAI.BackColor = [System.Drawing.Color]::FromArgb(116, 199, 110)
            Start-Sleep -Milliseconds 800
            $btnSaveOpenAI.Text = "💾 Сохранить"
            $btnSaveOpenAI.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
            $statusLabel.Text = "Ключ OpenAI сохранен!"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
        } else {
            $statusLabel.Text = "Ошибка: ключ OpenAI должен начинаться с 'sk-'"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
        }
    })
)
    $btnDeleteOpenAI.Add_Click({
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Удалить сохраненный ключ OpenAI?",
            "Подтверждение удаления",
            "YesNo",
            "Question"
        )
        if ($result -eq "Yes") {
            $savedConfig = Load-Config
            $unsplashKey = if ($savedConfig -and $savedConfig.UnsplashKey) { $savedConfig.UnsplashKey } else { "" }
            Save-Config -OpenAIKey "" -UnsplashKey $unsplashKey
            $textOpenAI.Text = ""
            $btnDeleteOpenAI.Text = "✓ Удалено"
            $btnDeleteOpenAI.BackColor = [System.Drawing.Color]::FromArgb(200, 100, 115)
            Start-Sleep -Milliseconds 800
            $btnDeleteOpenAI.Text = "🗑 Удалить"
            $btnDeleteOpenAI.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
            $statusLabel.Text = "Ключ OpenAI удален"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
        }
    })
    $btnDeleteUnsplash.Add_Click({
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Удалить сохраненный ключ Unsplash?",
            "Подтверждение удаления",
            "YesNo",
            "Question"
        )
        if ($result -eq "Yes") {
            $savedConfig = Load-Config
            $openAIKey = if ($savedConfig -and $savedConfig.OpenAIKey) { $savedConfig.OpenAIKey } else { "" }
            Save-Config -OpenAIKey $openAIKey -UnsplashKey ""
            $textUnsplash.Text = ""
            $btnDeleteUnsplash.Text = "✓ Удалено"
            $btnDeleteUnsplash.BackColor = [System.Drawing.Color]::FromArgb(200, 100, 115)
            Start-Sleep -Milliseconds 800
            $btnDeleteUnsplash.Text = "🗑 Удалить"
            $btnDeleteUnsplash.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
            $statusLabel.Text = "Ключ Unsplash удален"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
        }
    })
    # --- ОБРАБОТЧИКИ ПРОВЕРКИ КЛЮЧЕЙ ---
    $btnTestOpenAI.Add_Click({
        $key = $textOpenAI.Text.Trim()
        if (-not $key) {
            $statusLabel.Text = "Введите ключ OpenAI для проверки"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
            return
        }
        $btnTestOpenAI.Text = "⏳ Проверка..."
        $btnTestOpenAI.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
        $btnTestOpenAI.Enabled = $false
        $statusLabel.Text = "Проверяем ключ OpenAI..."
        $job = Start-Job -ScriptBlock {
            param($key, $API_URL)
            $body = @{ api_key = $key } | ConvertTo-Json
            try {
                $response = Invoke-RestMethod -Uri "$API_URL/validate/openai" `
                    -Method Post -Body $body `
                    -ContentType "application/json" `
                    -TimeoutSec 10
                return @{ valid = $response.valid; message = "Ключ OpenAI валиден!" }
            }
            catch {
                return @{ valid = $false; message = "Ошибка OpenAI: $_" }
            }
        } -ArgumentList $key, $API_URL
        while ($job.State -eq "Running") {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }
        $result = Receive-Job -Job $job
        Remove-Job -Job $job
        if ($result.valid) {
            $btnTestOpenAI.Text = "✅ Валиден"
            $btnTestOpenAI.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
            $statusLabel.Text = $result.message
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
        } else {
            $btnTestOpenAI.Text = "❌ Ошибка"
            $btnTestOpenAI.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
            $statusLabel.Text = $result.message
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
        }
        Start-Sleep -Seconds 2
        $btnTestOpenAI.Text = "🔍 Проверить"
        $btnTestOpenAI.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
        $btnTestOpenAI.Enabled = $true
    })
    $btnTestUnsplash.Add_Click({
        $key = $textUnsplash.Text.Trim()
        if (-not $key) {
            $statusLabel.Text = "Введите ключ Unsplash для проверки"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
            return
        }
        $btnTestUnsplash.Text = "⏳ Проверка..."
        $btnTestUnsplash.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
        $btnTestUnsplash.Enabled = $false
        $statusLabel.Text = "Проверяем ключ Unsplash..."
        $job = Start-Job -ScriptBlock {
            param($key, $API_URL)
            $body = @{ api_key = $key } | ConvertTo-Json
            try {
                $response = Invoke-RestMethod -Uri "$API_URL/validate/unsplash" `
                    -Method Post -Body $body `
                    -ContentType "application/json" `
                    -TimeoutSec 10
                return @{ valid = $response.valid; message = "Ключ Unsplash валиден!" }
            }
            catch {
                return @{ valid = $false; message = "Ошибка Unsplash: $_" }
            }
        } -ArgumentList $key, $API_URL
        while ($job.State -eq "Running") {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }
        $result = Receive-Job -Job $job
        Remove-Job -Job $job
        if ($result.valid) {
            $btnTestUnsplash.Text = "✅ Валиден"
            $btnTestUnsplash.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
            $statusLabel.Text = $result.message
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
        } else {
            $btnTestUnsplash.Text = "❌ Ошибка"
            $btnTestUnsplash.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
            $statusLabel.Text = $result.message
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
        }
        Start-Sleep -Seconds 2
        $btnTestUnsplash.Text = "🔍 Проверить"
        $btnTestUnsplash.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
        $btnTestUnsplash.Enabled = $true
    })
    # --- ОБРАБОТЧИКИ ГЕНЕРАЦИИ/ПОИСКА ---
    $btnGenerateDALLE.Add_Click({
        # Проверки для DALL-E
        if ($textOpenAI.Text.Trim() -eq "") {
            $statusLabel.Text = "Ошибка: для генерации нужен ключ OpenAI"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
            return
        }
        if ($textPrompt.Text.Trim() -eq "") {
            $statusLabel.Text = "Ошибка: введите промпт для генерации"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
            return
        }
        # Получаем выбранные стили
        $selectedStyles = @()
        for ($i = 0; $i -lt $listStyles.Items.Count; $i++) {
            if ($listStyles.GetItemChecked($i)) {
                $styleText = $listStyles.Items[$i] -replace "^[^\s]+\s+", ""
                $selectedStyles += $styleText
            }
        }
        if ($selectedStyles.Count -eq 0) {
            $selectedStyles = @("Реализм")
        }
        # Блокируем кнопки
        $btnGenerateDALLE.Enabled = $false
        $btnSearchUnsplash.Enabled = $false
        $btnGenerateDALLE.Text = "⏳ Генерация DALL-E..."
        $btnGenerateDALLE.BackColor = [System.Drawing.Color]::FromArgb(200, 100, 140)
        $statusLabel.Text = "Генерация изображения через DALL-E 3..."
        $script:currentSource = "dalle"
        # Асинхронная генерация через DALL-E
        $job = Start-Job -ScriptBlock {
            param($prompt, $apiKey, $styles, $size, $API_URL)
            # Импортируем функцию
            . $using:function:Generate-DALLE
            $result = Generate-DALLE -prompt $prompt -apiKey $apiKey -styles $styles -size $size
            return $result
        } -ArgumentList $textPrompt.Text.Trim(), $textOpenAI.Text.Trim(), $selectedStyles, "1024x1024", $API_URL
        # Мониторим прогресс
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 100
        $timer.Add_Tick({
            if ($job.State -eq "Completed") {
                $timer.Stop()
                $timer.Dispose()
                $result = Receive-Job -Job $job
                Remove-Job -Job $job
                if ($result.success) {
                    $script:generatedImageUrl = $result.image_url
                    $btnDownload.Enabled = $true
                    $btnGenerateDALLE.Text = "✅ Готово!"
                    $statusLabel.Text = $result.message
                    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
                    # Возвращаем обычный вид через 2 секунды
                    Start-Sleep -Seconds 2
                    $btnGenerateDALLE.Text = "🎨 ГЕНЕРИРОВАТЬ (DALL-E 3)"
                    $btnGenerateDALLE.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
                } else {
                    $btnGenerateDALLE.Text = "❌ Ошибка"
                    $statusLabel.Text = "Ошибка DALL-E: $($result.error)"
                    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
                    Start-Sleep -Seconds 2
                    $btnGenerateDALLE.Text = "🎨 ГЕНЕРИРОВАТЬ (DALL-E 3)"
                    $btnGenerateDALLE.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
                }
                $btnGenerateDALLE.Enabled = $true
                $btnSearchUnsplash.Enabled = $true
            }
            elseif ($job.State -eq "Failed") {
                $timer.Stop()
                $timer.Dispose()
                $btnGenerateDALLE.Text = "❌ Ошибка"
                $statusLabel.Text = "Ошибка при выполнении задачи DALL-E"
                $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
                Start-Sleep -Seconds 2
                $btnGenerateDALLE.Text = "🎨 ГЕНЕРИРОВАТЬ (DALL-E 3)"
                $btnGenerateDALLE.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
                $btnGenerateDALLE.Enabled = $true
                $btnSearchUnsplash.Enabled = $true
            }
        })
        $timer.Start()
    })
    $btnSearchUnsplash.Add_Click({
        # Проверки для Unsplash
        if ($textUnsplash.Text.Trim() -eq "") {
            $statusLabel.Text = "Ошибка: для поиска нужен ключ Unsplash"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
            return
        }
        if ($textPrompt.Text.Trim() -eq "") {
            $statusLabel.Text = "Ошибка: введите запрос для поиска"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
            return
        }
        # Блокируем кнопки
        $btnSearchUnsplash.Enabled = $false
        $btnGenerateDALLE.Enabled = $false
        $btnSearchUnsplash.Text = "⏳ Поиск Unsplash..."
        $btnSearchUnsplash.BackColor = [System.Drawing.Color]::FromArgb(170, 140, 220)
        $statusLabel.Text = "Поиск изображений в библиотеке Unsplash..."
        $script:currentSource = "unsplash"
        # Асинхронный поиск через Unsplash
        $job = Start-Job -ScriptBlock {
            param($query, $apiKey, $API_URL)
            # Импортируем функцию
            . $using:function:Search-Unsplash
            $result = Search-Unsplash -query $query -apiKey $apiKey
            return $result
        } -ArgumentList $textPrompt.Text.Trim(), $textUnsplash.Text.Trim(), $API_URL
        # Мониторим прогресс
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 100
        $timer.Add_Tick({
            if ($job.State -eq "Completed") {
                $timer.Stop()
                $timer.Dispose()
                $result = Receive-Job -Job $job
                Remove-Job -Job $job
                if ($result.success) {
                    $script:generatedImageUrl = $result.image_url
                    $btnDownload.Enabled = $true
                    $btnSearchUnsplash.Text = "✅ Найдено!"
                    $statusLabel.Text = $result.message
                    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
                    # Возвращаем обычный вид через 2 секунды
                    Start-Sleep -Seconds 2
                    $btnSearchUnsplash.Text = "🔎 ПОИСК (Unsplash)"
                    $btnSearchUnsplash.BackColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
                } else {
                    $btnSearchUnsplash.Text = "❌ Ошибка"
                    $statusLabel.Text = "Ошибка Unsplash: $($result.error)"
                    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
                    Start-Sleep -Seconds 2
                    $btnSearchUnsplash.Text = "🔎 ПОИСК (Unsplash)"
                    $btnSearchUnsplash.BackColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
                }
                $btnSearchUnsplash.Enabled = $true
                $btnGenerateDALLE.Enabled = $true
            }
            elseif ($job.State -eq "Failed") {
                $timer.Stop()
                $timer.Dispose()
                $btnSearchUnsplash.Text = "❌ Ошибка"
                $statusLabel.Text = "Ошибка при выполнении поиска Unsplash"
                $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
                Start-Sleep -Seconds 2
                $btnSearchUnsplash.Text = "🔎 ПОИСК (Unsplash)"
                $btnSearchUnsplash.BackColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
                $btnSearchUnsplash.Enabled = $true
                $btnGenerateDALLE.Enabled = $true
            }
        })
        $timer.Start()
    })
    # --- ОБРАБОТЧИК СКАЧИВАНИЯ ---
    $btnDownload.Add_Click({
        if (-not $script:generatedImageUrl) {
            $statusLabel.Text = "Ошибка: нет сгенерированного/найденного изображения"
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
            return
        }
        $sourceText = if ($script:currentSource -eq "dalle") { "DALL-E" } else { "Unsplash" }
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "PNG изображения (*.png)|*.png|JPEG изображения (*.jpg)|*.jpg"
        $saveDialog.FileName = "illustraitor_${sourceText}_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
        $saveDialog.InitialDirectory = [Environment]::GetFolderPath('Pictures')
        $saveDialog.OverwritePrompt = $true
        if ($saveDialog.ShowDialog() -eq "OK") {
            $btnDownload.Enabled = $false
            $btnDownload.Text = "⏳ Скачивание..."
            $statusLabel.Text = "Скачиваем изображение с $sourceText..."
            $downloadResult = Download-Image -url $script:generatedImageUrl -savePath $saveDialog.FileName
            if ($downloadResult) {
                $btnDownload.Text = "✅ Скачано!"
                $statusLabel.Text = "Изображение от $sourceText сохранено: $($saveDialog.FileName)"
                $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
                Start-Sleep -Seconds 2
                $btnDownload.Text = "💾 СКАЧАТЬ ИЗОБРАЖЕНИЕ"
                $btnDownload.BackColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
                $btnDownload.Enabled = $true
            } else {
                $btnDownload.Text = "❌ Ошибка"
                $statusLabel.Text = "Ошибка при скачивании с $sourceText"
                $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
                Start-Sleep -Seconds 2
                $btnDownload.Text = "💾 СКАЧАТЬ ИЗОБРАЖЕНИЕ"
                $btnDownload.BackColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
                $btnDownload.Enabled = $true
            }
        }
    })
    # Загрузка сохраненных ключей при старте
    $savedConfig = Load-Config
    if ($savedConfig) {
        if ($savedConfig.OpenAIKey) {
            $textOpenAI.Text = $savedConfig.OpenAIKey
            $statusLabel.Text = "Загружен сохраненный ключ OpenAI"
        }
        if ($savedConfig.UnsplashKey) {
            $textUnsplash.Text = $savedConfig.UnsplashKey
            if ($savedConfig.OpenAIKey) {
                $statusLabel.Text = "Загружены оба ключа: OpenAI и Unsplash"
            } else {
                $statusLabel.Text = "Загружен сохраненный ключ Unsplash"
            }
        }
    }
    return $form
}
# --- ЗАПУСК ПРИЛОЖЕНИЯ ---
try {
    Write-Host "Запуск Illustraitor AI с двойной генерацией..." -ForegroundColor Cyan
    Write-Host "API сервер: $API_URL" -ForegroundColor Yellow
    Write-Host "Два независимых источника: DALL-E 3 и Unsplash" -ForegroundColor Green
    $form = Create-GUI
    # Проверяем доступность API
    try {
        $health = Invoke-RestMethod -Uri "$API_URL/health" -TimeoutSec 5
        if ($health.status -eq "healthy") {
            $form.Text = "🎨 Illustraitor AI [API Online] - DALL-E 3 + Unsplash"
        }
    }
    catch {
        Write-Host "Внимание: API сервер недоступен" -ForegroundColor Yellow
        $form.Text = "🎨 Illustraitor AI [API Offline] - DALL-E 3 + Unsplash"
    }
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [void]$form.ShowDialog()
}
catch {
    Write-Host "Критическая ошибка: $_" -ForegroundColor Red
    [System.Windows.Forms.MessageBox]::Show(
        "Критическая ошибка:`n$_`n`nПроверьте настройки и попробуйте снова.",
        "Ошибка запуска",
        "OK",
        "Error"
    )
}
finally {
    if ($form -and $form.Visible) {
        $form.Close()
        $form.Dispose()
    }
}

