Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# Путь к файлу конфигурации
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$configPath = Join-Path $scriptDir "illustraitor_config.json"
# Демо-изображения для демо-режима
$demoImages = @(
    "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
    "https://images.unsplash.com/photo-1519681393784-d120267933ba", 
    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4",
    "https://images.unsplash.com/photo-1518837695005-2083093ee35b",
    "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05"
)
# Глобальные переменные
$global:lastImageUrl = $null
$global:lastImageSource = ""
$global:openAIKey = ""
$global:unsplashKey = ""
# Создание формы
$form = New-Object System.Windows.Forms.Form
$form.Text = "🎨 Генератор изображений AI"
$form.Size = New-Object System.Drawing.Size(850, 750)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 40)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
# Заголовок
$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = "Генератор изображений AI"
$labelTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255)
$labelTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$labelTitle.Location = New-Object System.Drawing.Point(20, 15)
$labelTitle.Size = New-Object System.Drawing.Size(800, 40)
$labelTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($labelTitle)
# --- Секция API ключей ---
$groupAPI = New-Object System.Windows.Forms.GroupBox
$groupAPI.Text = "API Ключи"
$groupAPI.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255)
$groupAPI.Location = New-Object System.Drawing.Point(20, 70)
$groupAPI.Size = New-Object System.Drawing.Size(800, 140)
$groupAPI.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 50)
$form.Controls.Add($groupAPI)
# Поле Unsplash с кнопкой 👁️
$labelUnsplash = New-Object System.Windows.Forms.Label
$labelUnsplash.Text = "Unsplash Access Key:"
$labelUnsplash.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
$labelUnsplash.Location = New-Object System.Drawing.Point(15, 25)
$labelUnsplash.Size = New-Object System.Drawing.Size(300, 20)
$labelUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$groupAPI.Controls.Add($labelUnsplash)
$panelUnsplash = New-Object System.Windows.Forms.Panel
$panelUnsplash.Location = New-Object System.Drawing.Point(15, 45)
$panelUnsplash.Size = New-Object System.Drawing.Size(380, 30)
$panelUnsplash.BackColor = [System.Drawing.Color]::Transparent
$groupAPI.Controls.Add($panelUnsplash)
$textUnsplash = New-Object System.Windows.Forms.TextBox
$textUnsplash.Location = New-Object System.Drawing.Point(0, 0)
$textUnsplash.Size = New-Object System.Drawing.Size(345, 30)
$textUnsplash.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 70)
$textUnsplash.ForeColor = [System.Drawing.Color]::White
$textUnsplash.Font = New-Object System.Drawing.Font("Consolas", 10)
$textUnsplash.PasswordChar = '•'
$panelUnsplash.Controls.Add($textUnsplash)
$btnShowUnsplash = New-Object System.Windows.Forms.Button
$btnShowUnsplash.Text = "👁️"
$btnShowUnsplash.Location = New-Object System.Drawing.Point(350, 0)
$btnShowUnsplash.Size = New-Object System.Drawing.Size(30, 30)
$btnShowUnsplash.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 90)
$btnShowUnsplash.ForeColor = [System.Drawing.Color]::White
$btnShowUnsplash.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnShowUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$panelUnsplash.Controls.Add($btnShowUnsplash)
$labelUnsplashHint = New-Object System.Windows.Forms.Label
$labelUnsplashHint.Text = "Для доступа к библиотеке изображений Unsplash"
$labelUnsplashHint.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$labelUnsplashHint.Location = New-Object System.Drawing.Point(15, 80)
$labelUnsplashHint.Size = New-Object System.Drawing.Size(380, 15)
$labelUnsplashHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$groupAPI.Controls.Add($labelUnsplashHint)
# Кнопки управления Unsplash
$btnSaveUnsplash = New-Object System.Windows.Forms.Button
$btnSaveUnsplash.Text = "Сохранить"
$btnSaveUnsplash.Location = New-Object System.Drawing.Point(15, 100)
$btnSaveUnsplash.Size = New-Object System.Drawing.Size(90, 25)
$btnSaveUnsplash.BackColor = [System.Drawing.Color]::FromArgb(0, 173, 181)
$btnSaveUnsplash.ForeColor = [System.Drawing.Color]::White
$btnSaveUnsplash.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSaveUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$groupAPI.Controls.Add($btnSaveUnsplash)
$btnDeleteUnsplash = New-Object System.Windows.Forms.Button
$btnDeleteUnsplash.Text = "Удалить"
$btnDeleteUnsplash.Location = New-Object System.Drawing.Point(110, 100)
$btnDeleteUnsplash.Size = New-Object System.Drawing.Size(90, 25)
$btnDeleteUnsplash.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$btnDeleteUnsplash.ForeColor = [System.Drawing.Color]::White
$btnDeleteUnsplash.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDeleteUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$groupAPI.Controls.Add($btnDeleteUnsplash)
# Поле OpenAI с кнопкой 👁️
$labelOpenAI = New-Object System.Windows.Forms.Label
$labelOpenAI.Text = "OpenAI API Key:"
$labelOpenAI.ForeColor = [System.Drawing.Color]::FromArgb(255, 165, 2)
$labelOpenAI.Location = New-Object System.Drawing.Point(405, 25)
$labelOpenAI.Size = New-Object System.Drawing.Size(300, 20)
$labelOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$groupAPI.Controls.Add($labelOpenAI)
$panelOpenAI = New-Object System.Windows.Forms.Panel
$panelOpenAI.Location = New-Object System.Drawing.Point(405, 45)
$panelOpenAI.Size = New-Object System.Drawing.Size(380, 30)
$panelOpenAI.BackColor = [System.Drawing.Color]::Transparent
$groupAPI.Controls.Add($panelOpenAI)
$textOpenAI = New-Object System.Windows.Forms.TextBox
$textOpenAI.Location = New-Object System.Drawing.Point(0, 0)
$textOpenAI.Size = New-Object System.Drawing.Size(345, 30)
$textOpenAI.BackColor = [System.Drawing.Color]::FromArgb(70, 60, 50)
$textOpenAI.ForeColor = [System.Drawing.Color]::White
$textOpenAI.Font = New-Object System.Drawing.Font("Consolas", 10)
$textOpenAI.PasswordChar = '•'
$panelOpenAI.Controls.Add($textOpenAI)
$btnShowOpenAI = New-Object System.Windows.Forms.Button
$btnShowOpenAI.Text = "👁️"
$btnShowOpenAI.Location = New-Object System.Drawing.Point(350, 0)
$btnShowOpenAI.Size = New-Object System.Drawing.Size(30, 30)
$btnShowOpenAI.BackColor = [System.Drawing.Color]::FromArgb(90, 70, 60)
$btnShowOpenAI.ForeColor = [System.Drawing.Color]::White
$btnShowOpenAI.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnShowOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$panelOpenAI.Controls.Add($btnShowOpenAI)
$labelOpenAIHint = New-Object System.Windows.Forms.Label
$labelOpenAIHint.Text = "Получите ключ на platform.openai.com"
$labelOpenAIHint.ForeColor = [System.Drawing.Color]::FromArgb(200, 150, 100)
$labelOpenAIHint.Location = New-Object System.Drawing.Point(405, 80)
$labelOpenAIHint.Size = New-Object System.Drawing.Size(380, 15)
$labelOpenAIHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$groupAPI.Controls.Add($labelOpenAIHint)
# Кнопки управления OpenAI
$btnSaveOpenAI = New-Object System.Windows.Forms.Button
$btnSaveOpenAI.Text = "Сохранить"
$btnSaveOpenAI.Location = New-Object System.Drawing.Point(405, 100)
$btnSaveOpenAI.Size = New-Object System.Drawing.Size(90, 25)
$btnSaveOpenAI.BackColor = [System.Drawing.Color]::FromArgb(255, 165, 2)
$btnSaveOpenAI.ForeColor = [System.Drawing.Color]::Black
$btnSaveOpenAI.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSaveOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$groupAPI.Controls.Add($btnSaveOpenAI)
$btnDeleteOpenAI = New-Object System.Windows.Forms.Button
$btnDeleteOpenAI.Text = "Удалить"
$btnDeleteOpenAI.Location = New-Object System.Drawing.Point(500, 100)
$btnDeleteOpenAI.Size = New-Object System.Drawing.Size(90, 25)
$btnDeleteOpenAI.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$btnDeleteOpenAI.ForeColor = [System.Drawing.Color]::White
$btnDeleteOpenAI.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDeleteOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$groupAPI.Controls.Add($btnDeleteOpenAI)
# --- Секция промпта ---
$groupPrompt = New-Object System.Windows.Forms.GroupBox
$groupPrompt.Text = "Промпт для генерации"
$groupPrompt.ForeColor = [System.Drawing.Color]::FromArgb(160, 230, 100)
$groupPrompt.Location = New-Object System.Drawing.Point(20, 225)
$groupPrompt.Size = New-Object System.Drawing.Size(800, 120)
$groupPrompt.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 40)
$form.Controls.Add($groupPrompt)
$labelPrompt = New-Object System.Windows.Forms.Label
$labelPrompt.Text = "Опишите изображение, которое хотите сгенерировать:"
$labelPrompt.ForeColor = [System.Drawing.Color]::FromArgb(200, 220, 180)
$labelPrompt.Location = New-Object System.Drawing.Point(15, 25)
$labelPrompt.Size = New-Object System.Drawing.Size(400, 20)
$labelPrompt.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$groupPrompt.Controls.Add($labelPrompt)
$textPrompt = New-Object System.Windows.Forms.TextBox
$textPrompt.Multiline = $true
$textPrompt.Location = New-Object System.Drawing.Point(15, 50)
$textPrompt.Size = New-Object System.Drawing.Size(770, 60)
$textPrompt.BackColor = [System.Drawing.Color]::FromArgb(60, 65, 55)
$textPrompt.ForeColor = [System.Drawing.Color]::White
$textPrompt.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$textPrompt.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$groupPrompt.Controls.Add($textPrompt)
# --- Секция стилей ---
$groupStyles = New-Object System.Windows.Forms.GroupBox
$groupStyles.Text = "Стили изображения (15 стилей)"
$groupStyles.ForeColor = [System.Drawing.Color]::FromArgb(255, 140, 200)
$groupStyles.Location = New-Object System.Drawing.Point(20, 360)
$groupStyles.Size = New-Object System.Drawing.Size(800, 200)
$groupStyles.BackColor = [System.Drawing.Color]::FromArgb(55, 40, 55)
$form.Controls.Add($groupStyles)
# Создаем список стилей
$styles = @(
    "Реализм",
    "Импрессионизм",
    "Сюрреализм",
    "Абстракционизм",
    "Поп-арт",
    "Киберпанк",
    "Стимпанк",
    "Фэнтези",
    "Аниме",
    "Пиксель-арт",
    "Масляная живопись",
    "Акварель",
    "Черно-белое",
    "Винтаж",
    "Мультяшный стиль"
)
# Создаем ListBox для стилей
$listStyles = New-Object System.Windows.Forms.ListBox
$listStyles.Location = New-Object System.Drawing.Point(15, 25)
$listStyles.Size = New-Object System.Drawing.Size(770, 165)
$listStyles.BackColor = [System.Drawing.Color]::FromArgb(70, 55, 70)
$listStyles.ForeColor = [System.Drawing.Color]::White
$listStyles.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$listStyles.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiSimple
$listStyles.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
# Добавляем стили в ListBox
foreach ($style in $styles) {
    [void]$listStyles.Items.Add($style)
}
# Выбираем первый стиль по умолчанию
if ($listStyles.Items.Count -gt 0) {
    $listStyles.SetSelected(0, $true)
}
$groupStyles.Controls.Add($listStyles)
# --- Кнопки управления ---
$panelControls = New-Object System.Windows.Forms.Panel
$panelControls.Location = New-Object System.Drawing.Point(20, 575)
$panelControls.Size = New-Object System.Drawing.Size(800, 100)
$panelControls.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($panelControls)
# Кнопка генерации
$btnGenerate = New-Object System.Windows.Forms.Button
$btnGenerate.Text = "Генерровать изображение"
$btnGenerate.Location = New-Object System.Drawing.Point(15, 10)
$btnGenerate.Size = New-Object System.Drawing.Size(380, 50)
$btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(46, 213, 115)
$btnGenerate.ForeColor = [System.Drawing.Color]::White
$btnGenerate.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnGenerate.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$panelControls.Controls.Add($btnGenerate)
# Кнопка скачивания
$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text = "Скачать изображение"
$btnDownload.Location = New-Object System.Drawing.Point(405, 10)
$btnDownload.Size = New-Object System.Drawing.Size(380, 50)
$btnDownload.BackColor = [System.Drawing.Color]::FromArgb(100, 150, 255)
$btnDownload.ForeColor = [System.Drawing.Color]::White
$btnDownload.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnDownload.Enabled = $false
$panelControls.Controls.Add($btnDownload)
# --- Функции работы с конфигурацией ---
function Update-GenerateButtonState {
    $hasOpenAI = $textOpenAI.Text.Trim() -ne ""
    $hasUnsplash = $textUnsplash.Text.Trim() -ne ""
    if (-not $hasOpenAI -and -not $hasUnsplash) {
        $btnGenerate.Text = "🎲 Демо-генерация"
        $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(155, 89, 182) # Фиолетовый
    } elseif ($hasOpenAI) {
        $btnGenerate.Text = "🎨 Генерация DALL-E 3"
        $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(46, 213, 115) # Зеленый
    } else {
        $btnGenerate.Text = "🔍 Поиск в Unsplash"
        $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(0, 173, 181) # Бирюзовый
    }
}
function Save-Key($keyType, $keyValue) {
    # Сохранение в память
    if ($keyType -eq "OpenAIKey") {
        $global:openAIKey = $keyValue
        # Визуальная обратная связь
        $btnSaveOpenAI.Text = "✓"
        $btnSaveOpenAI.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 150)
        Start-Sleep -Milliseconds 500
        $btnSaveOpenAI.Text = "Сохранить"
        $btnSaveOpenAI.BackColor = [System.Drawing.Color]::FromArgb(255, 165, 2)
    } else {
        $global:unsplashKey = $keyValue
        # Визуальная обратная связь
        $btnSaveUnsplash.Text = "✓"
        $btnSaveUnsplash.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 150)
        Start-Sleep -Milliseconds 500
        $btnSaveUnsplash.Text = "Сохранить"
        $btnSaveUnsplash.BackColor = [System.Drawing.Color]::FromArgb(0, 173, 181)
    }
    # Сохранение в файл
    $config = @{}
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
    }
    if ($keyValue -eq "") {
        $config.Remove($keyType)
    } else {
        $config[$keyType] = $keyValue
    }
    try {
        $config | ConvertTo-Json | Set-Content $configPath -Force
        Write-Host "Ключ $keyType сохранен в файл." -ForegroundColor Green
    } catch {
        Write-Host "Ошибка сохранения конфига: $_" -ForegroundColor Red
    }
    Update-GenerateButtonState
}
function Remove-Key($keyType) {
    if ($keyType -eq "OpenAIKey") {
        $textOpenAI.Text = ""
        $global:openAIKey = ""
        # Визуальная обратная связь
        $btnDeleteOpenAI.Text = "✓"
        $btnDeleteOpenAI.BackColor = [System.Drawing.Color]::FromArgb(180, 40, 56)
        Start-Sleep -Milliseconds 500
        $btnDeleteOpenAI.Text = "Удалить"
        $btnDeleteOpenAI.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    } else {
        $textUnsplash.Text = ""
        $global:unsplashKey = ""
        # Визуальная обратная связь
        $btnDeleteUnsplash.Text = "✓"
        $btnDeleteUnsplash.BackColor = [System.Drawing.Color]::FromArgb(180, 40, 56)
        Start-Sleep -Milliseconds 500
        $btnDeleteUnsplash.Text = "Удалить"
        $btnDeleteUnsplash.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    }
    # Удаление из файла
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
            $config.Remove($keyType)
            $config | ConvertTo-Json | Set-Content $configPath -Force
            Write-Host "Ключ $keyType удален из файла." -ForegroundColor Yellow
        } catch {
            Write-Host "Ошибка обновления конфига: $_" -ForegroundColor Red
        }
    }
    Update-GenerateButtonState
}
function Load-Config {
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $textOpenAI.Text = if ($config.OpenAIKey) { $config.OpenAIKey } else { "" }
            $textUnsplash.Text = if ($config.UnsplashKey) { $config.UnsplashKey } else { "" }
            # Загружаем в память
            $global:openAIKey = $textOpenAI.Text
            $global:unsplashKey = $textUnsplash.Text
            Write-Host "Конфигурация загружена." -ForegroundColor Green
        } catch {
            Write-Host "Ошибка загрузки конфигурации: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Файл конфигурации не найден. Будет создан при сохранении." -ForegroundColor Yellow
    }
    Update-GenerateButtonState
}
# --- Логика работы кнопок 👁️ ---
$unsplashVisible = $false
$openAIVisible = $false
$btnShowUnsplash.Add_Click({
    $script:unsplashVisible = -not $script:unsplashVisible
    if ($script:unsplashVisible) {
        $textUnsplash.PasswordChar = $null
        $btnShowUnsplash.Text = "🔒"
        $btnShowUnsplash.BackColor = [System.Drawing.Color]::FromArgb(0, 173, 181)
    } else {
        $textUnsplash.PasswordChar = '•'
        $btnShowUnsplash.Text = "👁️"
        $btnShowUnsplash.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 90)
    }
})
$btnShowOpenAI.Add_Click({
    $script:openAIVisible = -not $script:openAIVisible
    if ($script:openAIVisible) {
        $textOpenAI.PasswordChar = $null
        $btnShowOpenAI.Text = "🔒"
        $btnShowOpenAI.BackColor = [System.Drawing.Color]::FromArgb(255, 165, 2)
    } else {
        $textOpenAI.PasswordChar = '•'
        $btnShowOpenAI.Text = "👁️"
        $btnShowOpenAI.BackColor = [System.Drawing.Color]::FromArgb(90, 70, 60)
    }
})
# --- Логика кнопок управления ключами ---
$btnSaveUnsplash.Add_Click({
    $unsplashKey = $textUnsplash.Text.Trim()
    Save-Key "UnsplashKey" $unsplashKey
})
$btnDeleteUnsplash.Add_Click({
    Remove-Key "UnsplashKey"
})
$btnSaveOpenAI.Add_Click({
    $openAIKey = $textOpenAI.Text.Trim()
    Save-Key "OpenAIKey" $openAIKey
})
$btnDeleteOpenAI.Add_Click({
    Remove-Key "OpenAIKey"
})
# --- Логика генерации с демо-режимом ---
$btnGenerate.Add_Click({
    # Проверка промпта
    if ($textPrompt.Text.Trim() -eq "") {
        return
    }
    # Проверка ключей для определения режима
    $hasOpenAI = $textOpenAI.Text.Trim() -ne ""
    $hasUnsplash = $textUnsplash.Text.Trim() -ne ""
    if (-not $hasOpenAI -and -not $hasUnsplash) {
        # ДЕМО-РЕЖИМ (нет ключей)
        $btnGenerate.Text = "🎲 Демо-генерация..."
        $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(155, 89, 182) # Фиолетовый
        $btnGenerate.Enabled = $false
        Start-Sleep -Seconds 2
        # Случайное демо-изображение
        $randomImage = $demoImages | Get-Random
        $global:lastImageUrl = $randomImage
        $global:lastImageSource = "demo"
        $btnGenerate.Text = "🎲 Демо готово!"
        $btnDownload.Enabled = $true
        Start-Sleep -Seconds 1
        $btnGenerate.Text = "Генерровать изображение"
        $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(46, 213, 115)
        $btnGenerate.Enabled = $true
    } else {
        # Обычная генерация (есть ключи) - ПОДКЛЮЧЕНИЕ К БЭКЕНДУ
        if ($hasOpenAI) {
            # Проверка стилей для DALL-E
            $selectedStyles = $listStyles.SelectedItems
            if ($selectedStyles.Count -eq 0) {
                Write-Host "Выберите хотя бы один стиль для DALL-E 3" -ForegroundColor Yellow
                return
            }
            $btnGenerate.Text = "🎨 Генерация DALL-E 3..."
            $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(36, 163, 95) # Темно-зеленый
        } else {
            $btnGenerate.Text = "🔍 Поиск в Unsplash..."
            $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(0, 143, 161) # Темно-бирюзовый
        }
        $btnGenerate.Enabled = $false
        try {
            # Подготовка данных для запроса к бэкенду
            $body = @{
                prompt = $textPrompt.Text.Trim()
                api_type = if ($hasOpenAI) { "openai" } else { "unsplash" }
            }
            # Добавляем стили только для OpenAI
            if ($hasOpenAI) {
                $selectedStyles = @($listStyles.SelectedItems)
                if ($selectedStyles.Count -gt 0) {
                    $body.styles = $selectedStyles
                }
            }
            # Отправка запроса к бэкенду
            $apiUrl = "http://localhost:8000/generate"
            $jsonBody = $body | ConvertTo-Json
            Write-Host "Отправка запроса к API..." -ForegroundColor Cyan
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonBody -ContentType "application/json" -TimeoutSec 30
            if ($response.status -eq "success") {
                $global:lastImageUrl = $response.url
                $global:lastImageSource = $response.source
                $btnDownload.Enabled = $true
                $btnGenerate.Text = if ($hasOpenAI) { "✅ Готово (DALL-E)" } else { "✅ Найдено (Unsplash)" }
                Write-Host "Изображение успешно сгенерировано!" -ForegroundColor Green
                Write-Host "URL: $($response.url)" -ForegroundColor Cyan
            } else {
                $btnGenerate.Text = "❌ Ошибка"
                $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
                Write-Host "Ошибка генерации: $($response.message)" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        } catch {
            $btnGenerate.Text = "❌ Ошибка сети"
            $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
            Write-Host "Ошибка сети: $_" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
        # Возвращаем нормальное состояние кнопки
        $btnGenerate.Text = "Генерровать изображение"
        $btnGenerate.BackColor = [System.Drawing.Color]::FromArgb(46, 213, 115)
        $btnGenerate.Enabled = $true
    }
})
# --- Логика скачивания ---
$btnDownload.Add_Click({
    # Проверка наличия URL
    if (-not $global:lastImageUrl) {
        Write-Host "Нет изображения для скачивания" -ForegroundColor Red
        return
    }
    # Пробуем скачать реальное изображение с Unsplash
    try {
        Write-Host "Скачивание изображения с: $global:lastImageUrl" -ForegroundColor Cyan
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "PNG изображения (*.png)|*.png|JPEG изображения (*.jpg)|*.jpg|Все файлы (*.*)|*.*"
        if ($global:lastImageSource -eq "demo") {
            $saveDialog.FileName = "demo_$(Get-Date -Format 'yyyyMMdd_HHmmss').jpg"
        } else {
            $saveDialog.FileName = "generated_$(Get-Date -Format 'yyyyMMdd_HHmmss').jpg"
        }
        $saveDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            # Скачиваем изображение
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($global:lastImageUrl, $saveDialog.FileName)
            $webClient.Dispose()
            Write-Host "Изображение сохранено: $($saveDialog.FileName)" -ForegroundColor Green
        }
    } catch {
        Write-Host "Не удалось скачать изображение: $_" -ForegroundColor Yellow
        # Резервный вариант - создаем цветной фон
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "PNG изображения (*.png)|*.png|JPEG изображения (*.jpg)|*.jpg|Все файлы (*.*)|*.*"
        if ($global:lastImageSource -eq "demo") {
            $saveDialog.FileName = "demo_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
        } else {
            $saveDialog.FileName = "generated_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
        }
        $saveDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $bitmap = New-Object System.Drawing.Bitmap(400, 400)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            # Разный фон в зависимости от источника
            if ($global:lastImageSource -eq "demo") {
                $graphics.Clear([System.Drawing.Color]::FromArgb(155, 89, 182)) # Фиолетовый
                $sourceText = "Демо-режим"
            } elseif ($global:lastImageSource -eq "dalle") {
                $graphics.Clear([System.Drawing.Color]::FromArgb(46, 213, 115)) # Зеленый
                $sourceText = "DALL-E 3"
            } else {
                $graphics.Clear([System.Drawing.Color]::FromArgb(0, 173, 181)) # Бирюзовый
                $sourceText = "Unsplash"
            }
            $font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $promptText = $textPrompt.Text.Substring(0, [Math]::Min(30, $textPrompt.Text.Length))
            if ($textPrompt.Text.Length -gt 30) { $promptText += "..." }
            $graphics.DrawString("Изображение: $promptText", $font, $brush, 20, 180)
            $fontSmall = New-Object System.Drawing.Font("Arial", 12)
            $graphics.DrawString("Источник: $sourceText", $fontSmall, $brush, 20, 220)
            if ($global:lastImageSource -eq "demo") {
                $fontSmallest = New-Object System.Drawing.Font("Arial", 10)
                $graphics.DrawString("Для реальной генерации введите API ключи", $fontSmallest, $brush, 20, 250)
            }
            $graphics.Dispose()
            $bitmap.Save($saveDialog.FileName)
            $bitmap.Dispose()
            Write-Host "Создано резервное изображение" -ForegroundColor Yellow
        }
    }
})
# Загрузка сохраненных ключей при запуске
Load-Config
# Показываем форму
[void]$form.ShowDialog()
