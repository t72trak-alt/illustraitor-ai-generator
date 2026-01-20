Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# ============================================
# ILLUSTRAITOR AI - ФИНАЛЬНАЯ ВЕРСИЯ
# Двойная генерация: DALL-E 3 + Unsplash
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
# --- СОЗДАНИЕ ИНТЕРФЕЙСА ---
function Create-GUI {
    # Основная форма
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "🎨 Illustraitor AI - Двойная генерация"
    $form.Size = New-Object System.Drawing.Size(850, 800)  # Увеличили высоту для стилей
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 46)
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    # Заголовок
    $labelTitle = New-Object System.Windows.Forms.Label
    $labelTitle.Text = "Illustraitor AI - Генерация изображений"
    $labelTitle.ForeColor = [System.Drawing.Color]::FromArgb(94, 234, 212)
    $labelTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $labelTitle.Location = New-Object System.Drawing.Point(20, 15)
    $labelTitle.Size = New-Object System.Drawing.Size(810, 40)
    $labelTitle.TextAlign = "MiddleCenter"
    $form.Controls.Add($labelTitle)
    # --- Секция API ключей ---
    $groupAPI = New-Object System.Windows.Forms.GroupBox
    $groupAPI.Text = "API Ключи (оба источника независимы)"
    $groupAPI.ForeColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
    $groupAPI.Location = New-Object System.Drawing.Point(20, 70)
    $groupAPI.Size = New-Object System.Drawing.Size(810, 160)
    $groupAPI.BackColor = [System.Drawing.Color]::FromArgb(49, 51, 68)
    $form.Controls.Add($groupAPI)
    # ===== OPENAI API KEY =====
    $labelOpenAI = New-Object System.Windows.Forms.Label
    $labelOpenAI.Text = "OpenAI API Key (DALL-E 3):"
    $labelOpenAI.ForeColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
    $labelOpenAI.Location = New-Object System.Drawing.Point(15, 25)
    $labelOpenAI.Size = New-Object System.Drawing.Size(380, 20)
    $labelOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $groupAPI.Controls.Add($labelOpenAI)
    $textOpenAI = New-Object System.Windows.Forms.TextBox
    $textOpenAI.Location = New-Object System.Drawing.Point(15, 50)
    $textOpenAI.Size = New-Object System.Drawing.Size(345, 30)
    $textOpenAI.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $textOpenAI.ForeColor = [System.Drawing.Color]::White
    $textOpenAI.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textOpenAI.PasswordChar = '•'
    $groupAPI.Controls.Add($textOpenAI)
    $btnShowOpenAI = New-Object System.Windows.Forms.Button
    $btnShowOpenAI.Text = "👁"
    $btnShowOpenAI.Location = New-Object System.Drawing.Point(365, 50)
    $btnShowOpenAI.Size = New-Object System.Drawing.Size(30, 30)
    $btnShowOpenAI.BackColor = [System.Drawing.Color]::FromArgb(89, 91, 110)
    $btnShowOpenAI.ForeColor = [System.Drawing.Color]::White
    $btnShowOpenAI.FlatStyle = "Flat"
    $groupAPI.Controls.Add($btnShowOpenAI)
    $btnSaveOpenAI = New-Object System.Windows.Forms.Button
    $btnSaveOpenAI.Text = "💾 Сохранить"
    $btnSaveOpenAI.Location = New-Object System.Drawing.Point(15, 85)
    $btnSaveOpenAI.Size = New-Object System.Drawing.Size(90, 25)
    $btnSaveOpenAI.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $btnSaveOpenAI.ForeColor = [System.Drawing.Color]::Black
    $btnSaveOpenAI.FlatStyle = "Flat"
    $groupAPI.Controls.Add($btnSaveOpenAI)
    $btnDeleteOpenAI = New-Object System.Windows.Forms.Button
    $btnDeleteOpenAI.Text = "🗑 Удалить"
    $btnDeleteOpenAI.Location = New-Object System.Drawing.Point(110, 85)
    $btnDeleteOpenAI.Size = New-Object System.Drawing.Size(90, 25)
    $btnDeleteOpenAI.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
    $btnDeleteOpenAI.ForeColor = [System.Drawing.Color]::White
    $btnDeleteOpenAI.FlatStyle = "Flat"
    $groupAPI.Controls.Add($btnDeleteOpenAI)
    $btnTestOpenAI = New-Object System.Windows.Forms.Button
    $btnTestOpenAI.Text = "🔍 Проверить"
    $btnTestOpenAI.Location = New-Object System.Drawing.Point(205, 85)
    $btnTestOpenAI.Size = New-Object System.Drawing.Size(90, 25)
    $btnTestOpenAI.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
    $btnTestOpenAI.ForeColor = [System.Drawing.Color]::Black
    $btnTestOpenAI.FlatStyle = "Flat"
    $groupAPI.Controls.Add($btnTestOpenAI)
    # ===== UNSPLASH API KEY =====
    $labelUnsplash = New-Object System.Windows.Forms.Label
    $labelUnsplash.Text = "Unsplash Access Key:"
    $labelUnsplash.ForeColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
    $labelUnsplash.Location = New-Object System.Drawing.Point(415, 25)
    $labelUnsplash.Size = New-Object System.Drawing.Size(380, 20)
    $labelUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $groupAPI.Controls.Add($labelUnsplash)
    $textUnsplash = New-Object System.Windows.Forms.TextBox
    $textUnsplash.Location = New-Object System.Drawing.Point(415, 50)
    $textUnsplash.Size = New-Object System.Drawing.Size(345, 30)
    $textUnsplash.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $textUnsplash.ForeColor = [System.Drawing.Color]::White
    $textUnsplash.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textUnsplash.PasswordChar = '•'
    $groupAPI.Controls.Add($textUnsplash)
    $btnShowUnsplash = New-Object System.Windows.Forms.Button
    $btnShowUnsplash.Text = "👁"
    $btnShowUnsplash.Location = New-Object System.Drawing.Point(765, 50)
    $btnShowUnsplash.Size = New-Object System.Drawing.Size(30, 30)
    $btnShowUnsplash.BackColor = [System.Drawing.Color]::FromArgb(89, 91, 110)
    $btnShowUnsplash.ForeColor = [System.Drawing.Color]::White
    $btnShowUnsplash.FlatStyle = "Flat"
    $groupAPI.Controls.Add($btnShowUnsplash)
    $btnSaveUnsplash = New-Object System.Windows.Forms.Button
    $btnSaveUnsplash.Text = "💾 Сохранить"
    $btnSaveUnsplash.Location = New-Object System.Drawing.Point(415, 85)
    $btnSaveUnsplash.Size = New-Object System.Drawing.Size(90, 25)
    $btnSaveUnsplash.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $btnSaveUnsplash.ForeColor = [System.Drawing.Color]::Black
    $btnSaveUnsplash.FlatStyle = "Flat"
    $groupAPI.Controls.Add($btnSaveUnsplash)
    $btnDeleteUnsplash = New-Object System.Windows.Forms.Button
    $btnDeleteUnsplash.Text = "🗑 Удалить"
    $btnDeleteUnsplash.Location = New-Object System.Drawing.Point(510, 85)
    $btnDeleteUnsplash.Size = New-Object System.Drawing.Size(90, 25)
    $btnDeleteUnsplash.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
    $btnDeleteUnsplash.ForeColor = [System.Drawing.Color]::White
    $btnDeleteUnsplash.FlatStyle = "Flat"
    $groupAPI.Controls.Add($btnDeleteUnsplash)
    $btnTestUnsplash = New-Object System.Windows.Forms.Button
    $btnTestUnsplash.Text = "🔍 Проверить"
    $btnTestUnsplash.Location = New-Object System.Drawing.Point(605, 85)
    $btnTestUnsplash.Size = New-Object System.Drawing.Size(90, 25)
    $btnTestUnsplash.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
    $btnTestUnsplash.ForeColor = [System.Drawing.Color]::Black
    $btnTestUnsplash.FlatStyle = "Flat"
    $groupAPI.Controls.Add($btnTestUnsplash)
    # --- Секция промпта ---
    $groupPrompt = New-Object System.Windows.Forms.GroupBox
    $groupPrompt.Text = "Запрос / промпт"
    $groupPrompt.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
    $groupPrompt.Location = New-Object System.Drawing.Point(20, 245)
    $groupPrompt.Size = New-Object System.Drawing.Size(810, 120)
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
    $textPrompt.Size = New-Object System.Drawing.Size(780, 60)
    $textPrompt.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $textPrompt.ForeColor = [System.Drawing.Color]::White
    $textPrompt.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $textPrompt.ScrollBars = "Vertical"
    $groupPrompt.Controls.Add($textPrompt)
    # --- СЕКЦИЯ СТИЛЕЙ (ДОБАВЛЯЕМ) ---
    $groupStyles = New-Object System.Windows.Forms.GroupBox
    $groupStyles.Text = "Стили изображения (для DALL-E 3)"
    $groupStyles.ForeColor = [System.Drawing.Color]::FromArgb(137, 220, 235)
    $groupStyles.Location = New-Object System.Drawing.Point(20, 380)
    $groupStyles.Size = New-Object System.Drawing.Size(810, 150)
    $groupStyles.BackColor = [System.Drawing.Color]::FromArgb(49, 51, 68)
    $form.Controls.Add($groupStyles)
    $listStyles = New-Object System.Windows.Forms.CheckedListBox
    $listStyles.Location = New-Object System.Drawing.Point(15, 25)
    $listStyles.Size = New-Object System.Drawing.Size(780, 115)
    $listStyles.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $listStyles.ForeColor = [System.Drawing.Color]::White
    $listStyles.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $listStyles.BorderStyle = "FixedSingle"
    $listStyles.CheckOnClick = $true
    $groupStyles.Controls.Add($listStyles)
    # Заполняем стили
    $styles = @(
        "🔮 Реализм", "🎨 Импрессионизм", "🌌 Сюрреализм", "🌀 Абстракционизм",
        "🟡 Поп-арт", "🤖 Киберпанк", "⚙️ Стимпанк", "🐉 Фэнтези",
        "🌸 Аниме", "🎮 Пиксель-арт", "🖌️ Масляная живопись",
        "💧 Акварель", "⚫ Черно-белое", "📜 Винтаж", "📺 Мультяшный"
    )
    foreach ($style in $styles) {
        [void]$listStyles.Items.Add($style, $false)
    }
    # --- Кнопки управления ---
    $btnGenerateDALLE = New-Object System.Windows.Forms.Button
    $btnGenerateDALLE.Text = "🎨 ГЕНЕРИРОВАТЬ (DALL-E 3)"
    $btnGenerateDALLE.Location = New-Object System.Drawing.Point(20, 545)
    $btnGenerateDALLE.Size = New-Object System.Drawing.Size(400, 50)
    $btnGenerateDALLE.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
    $btnGenerateDALLE.ForeColor = [System.Drawing.Color]::White
    $btnGenerateDALLE.FlatStyle = "Flat"
    $btnGenerateDALLE.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($btnGenerateDALLE)
    $btnSearchUnsplash = New-Object System.Windows.Forms.Button
    $btnSearchUnsplash.Text = "🔎 ПОИСК (Unsplash)"
    $btnSearchUnsplash.Location = New-Object System.Drawing.Point(430, 545)
    $btnSearchUnsplash.Size = New-Object System.Drawing.Size(400, 50)
    $btnSearchUnsplash.BackColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
    $btnSearchUnsplash.ForeColor = [System.Drawing.Color]::White
    $btnSearchUnsplash.FlatStyle = "Flat"
    $btnSearchUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($btnSearchUnsplash)
    $btnDownload = New-Object System.Windows.Forms.Button
    $btnDownload.Text = "💾 СКАЧАТЬ ИЗОБРАЖЕНИЕ"
    $btnDownload.Location = New-Object System.Drawing.Point(20, 605)
    $btnDownload.Size = New-Object System.Drawing.Size(810, 35)
    $btnDownload.BackColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
    $btnDownload.ForeColor = [System.Drawing.Color]::White
    $btnDownload.FlatStyle = "Flat"
    $btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnDownload.Enabled = $false
    $form.Controls.Add($btnDownload)
    # Статусная строка
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "Готов к работе. Выберите источник: DALL-E 3 или Unsplash"
    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $statusLabel.Location = New-Object System.Drawing.Point(20, 650)
    $statusLabel.Size = New-Object System.Drawing.Size(810, 30)
    $statusLabel.TextAlign = "MiddleCenter"
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.Controls.Add($statusLabel)
    # Сохраняем ссылку на статусную строку
    $global:statusLabel = $statusLabel
    # ========== ФИКСАЦИЯ ПЕРЕМЕННЫХ ДЛЯ ОБРАБОТЧИКОВ ==========
    $script:textOpenAI = $textOpenAI
    $script:textUnsplash = $textUnsplash
    $script:textPrompt = $textPrompt
    $script:listStyles = $listStyles
    $script:btnSaveOpenAI = $btnSaveOpenAI
    $script:btnDeleteOpenAI = $btnDeleteOpenAI
    $script:btnTestOpenAI = $btnTestOpenAI
    $script:btnShowOpenAI = $btnShowOpenAI
    $script:btnSaveUnsplash = $btnSaveUnsplash
    $script:btnDeleteUnsplash = $btnDeleteUnsplash
    $script:btnTestUnsplash = $btnTestUnsplash
    $script:btnShowUnsplash = $btnShowUnsplash
        $script:btnGenerateDALLE = $btnGenerateDALLE
    $script:btnSearchUnsplash = $btnSearchUnsplash
    $script:btnDownload = $btnDownload
    $script:btnTestOpenAI = $btnTestOpenAI
    $script:btnTestUnsplash = $btnTestUnsplash
    $script:btnSaveOpenAI = $btnSaveOpenAI
    $script:btnSaveUnsplash = $btnSaveUnsplash
    $script:btnDeleteOpenAI = $btnDeleteOpenAI
    $script:btnDeleteUnsplash = $btnDeleteUnsplash
    $script:btnShowOpenAI = $btnShowOpenAI
    $script:btnShowUnsplash = $btnShowUnsplash
    # --- ОБРАБОТЧИКИ СОБЫТИЙ ---
    # Кнопки показа/скрытия паролей
    $btnShowOpenAI.Add_Click({
        if ($script:textOpenAI.PasswordChar -eq '•') {
            $script:textOpenAI.PasswordChar = $null
            $script:btnShowOpenAI.Text = "🔒"
        } else {
            $script:textOpenAI.PasswordChar = '•'
            $script:btnShowOpenAI.Text = "👁"
        }
    })
    $btnShowUnsplash.Add_Click({
        if ($script:textUnsplash.PasswordChar -eq '•') {
            $script:textUnsplash.PasswordChar = $null
            $script:btnShowUnsplash.Text = "🔒"
        } else {
            $script:textUnsplash.PasswordChar = '•'
            $script:btnShowUnsplash.Text = "👁"
        }
    })
    # Сохранение OpenAI
    $btnSaveOpenAI.Add_Click({
        $key = $script:textOpenAI.Text.Trim()
        if (-not $key) {
            Show-Message "Ошибка: ключ OpenAI не может быть пустым" "Error"
            return
        }
        $savedConfig = Load-Config
        $unsplashKey = if ($savedConfig -and $savedConfig.UnsplashKey) { $savedConfig.UnsplashKey } else { "" }
        if (Save-Config -OpenAIKey $key -UnsplashKey $unsplashKey) {
            Show-Message "Ключ OpenAI сохранен" "Success"
            $script:btnSaveOpenAI.Text = "✓ Сохранено"
            $script:btnSaveOpenAI.BackColor = [System.Drawing.Color]::LightGreen
            Start-Job -ScriptBlock {
                Start-Sleep -Seconds 2
                $script:btnSaveOpenAI.Text = "💾 Сохранить"
                $script:btnSaveOpenAI.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
            }
        }
    })
    # Сохранение Unsplash
    $btnSaveUnsplash.Add_Click({
        $key = $script:textUnsplash.Text.Trim()
        if (-not $key) {
            Show-Message "Ошибка: ключ Unsplash не может быть пустым" "Error"
            return
        }
        $savedConfig = Load-Config
        $openAIKey = if ($savedConfig -and $savedConfig.OpenAIKey) { $savedConfig.OpenAIKey } else { "" }
        if (Save-Config -OpenAIKey $openAIKey -UnsplashKey $key) {
            Show-Message "Ключ Unsplash сохранен" "Success"
            $script:btnSaveUnsplash.Text = "✓ Сохранено"
            $script:btnSaveUnsplash.BackColor = [System.Drawing.Color]::LightGreen
            Start-Job -ScriptBlock {
                Start-Sleep -Seconds 2
                $script:btnSaveUnsplash.Text = "💾 Сохранить"
                $script:btnSaveUnsplash.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
            }
        }
    })
    # Удаление OpenAI
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
            $script:textOpenAI.Text = ""
            Show-Message "Ключ OpenAI удален" "Success"
        }
    })
    # Удаление Unsplash
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
            $script:textUnsplash.Text = ""
            Show-Message "Ключ Unsplash удален" "Success"
        }
    # Проверка ключа OpenAI
    $btnTestOpenAI.Add_Click({
        $key = $script:textOpenAI.Text.Trim()
        if (-not $key) {
            Show-Message "Введите ключ OpenAI для проверки" "Error"
            return
        }
        if (-not $key.StartsWith("sk-")) {
            Show-Message "Ключ OpenAI должен начинаться с 'sk-'" "Error"
            return
        }
        $script:btnTestOpenAI.Enabled = $false
        $script:btnTestOpenAI.Text = "⏳ Проверка..."
        Show-Message "Проверяем ключ OpenAI..." "Info"
        try {
            $body = @{
                api_key = $key
            } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "$API_URL/validate/openai?api_key=$($key)"
                -Method Post
                -Body "{}"
                -ContentType "application/json"
                -TimeoutSec 30
            if ($response.valid -eq $true) {
                Show-Message "✅ Ключ OpenAI валиден!" "Success"
            } else {
                Show-Message "❌ Ключ OpenAI невалиден" "Error"
            }
        }
        catch {
            Show-Message "Ошибка проверки: $($_.Exception.Message)" "Error"
        }
        finally {
            $script:btnTestOpenAI.Enabled = $true
            $script:btnTestOpenAI.Text = "🔍 Проверить"
        }
    })
    # Проверка ключа Unsplash
    $btnTestUnsplash.Add_Click({
        $key = $script:textUnsplash.Text.Trim()
        if (-not $key) {
            Show-Message "Введите ключ Unsplash для проверки" "Error"
            return
        }
        if ($key.Length -lt 10) {
            Show-Message "Ключ Unsplash слишком короткий" "Error"
            return
        }
        $script:btnTestUnsplash.Enabled = $false
        $script:btnTestUnsplash.Text = "⏳ Проверка..."
        Show-Message "Проверяем ключ Unsplash..." "Info"
        try {
            $body = @{
                api_key = $key
            } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "$API_URL/validate/unsplash?api_key=$($key)"
                -Method Post
                -Body "{}"
                -ContentType "application/json"
                -TimeoutSec 30
            if ($response.valid -eq $true) {
                Show-Message "✅ Ключ Unsplash валиден!" "Success"
            } else {
                Show-Message "❌ Ключ Unsplash невалиден" "Error"
            }
        }
        catch {
            Show-Message "Ошибка проверки: $($_.Exception.Message)" "Error"
        }
        finally {
            $script:btnTestUnsplash.Enabled = $true
            $script:btnTestUnsplash.Text = "🔍 Проверить"
        }
    })
    # Поиск изображений в Unsplash
    $btnSearchUnsplash.Add_Click({
        $key = $script:textUnsplash.Text.Trim()
        if (-not $key) {
            Show-Message "Введите ключ Unsplash для поиска" "Error"
            return
        }
        $prompt = $script:textPrompt.Text.Trim()
        if (-not $prompt) {
            Show-Message "Введите описание для поиска" "Error"
            return
        }
        # Получаем выбранный цвет и ориентацию
        $color = if ($script:comboColor.SelectedItem) { $script:comboColor.SelectedItem } else { "any" }
        $orientation = if ($script:comboOrientation.SelectedItem) { 
            switch ($script:comboOrientation.SelectedItem) {
                "Пейзаж" { "landscape" }
                "Портрет" { "portrait" }
                "Квадрат" { "squarish" }
                default { "any" }
            }
        } else { "any" }
        $script:btnSearchUnsplash.Enabled = $false
        $script:btnSearchUnsplash.Text = "⏳ Поиск..."
        Show-Message "Ищем изображения в Unsplash..." "Info"
        try {
                        $body = "{"
            $body += """prompt"": """ + $prompt + ""","
            $body += """source"": ""unsplash"","
            $body += """api_key"": """ + $key + ""","
            $body += """color"": """ + $color + ""","
            $body += """orientation"": """ + $orientation + """"
            $body += "}"
            $response = Invoke-RestMethod -Uri "$API_URL/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30


            if ($response.image_url) {
                $global:generatedImageUrl = $response.image_url
                $global:currentSource = "unsplash"
                Show-Message "✅ Найдено изображение!" "Success"
                $script:btnDownload.Enabled = $true
                # Показываем изображение
                if ($script:pictureBox.Image) {
                    $script:pictureBox.Image.Dispose()
                }
                $imageStream = [System.Net.WebRequest]::Create($response.image_url).GetResponse().GetResponseStream()
                $script:pictureBox.Image = [System.Drawing.Image]::FromStream($imageStream)
                $imageStream.Close()
            } else {
                Show-Message "❌ Изображения не найдены" "Warning"
            }
        }
        catch {
            Show-Message "Ошибка поиска: $($_.Exception.Message)" "Error"
        }
        finally {
            $script:btnSearchUnsplash.Enabled = $true
            $script:btnSearchUnsplash.Text = "🔎 ПОИСК (Unsplash)"
        }
    })
    })
    # Загрузка сохраненных ключей при старте
    $savedConfig = Load-Config
    if ($savedConfig) {
        if ($savedConfig.OpenAIKey) {
            $script:textOpenAI.Text = $savedConfig.OpenAIKey
        }
        if ($savedConfig.UnsplashKey) {
            $script:textUnsplash.Text = $savedConfig.UnsplashKey
        }
    }
    return $form
}
# --- ЗАПУСК ПРИЛОЖЕНИЯ ---
try {
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "ILLUSTRAITOR AI - ФИНАЛЬНАЯ ВЕРСИЯ" -ForegroundColor Yellow
    Write-Host "API сервер: $API_URL" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Cyan
    $form = Create-GUI
    $form.Text = "🎨 Illustraitor AI - DALL-E 3 + Unsplash"
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [void]$form.ShowDialog()
}
catch {
    Write-Host "Ошибка: $_" -ForegroundColor Red
}









# ========== ДОБАВЛЕННЫЕ ОБРАБОТЧИКИ ==========

# Обработчик для генерации DALL-E
$btnGenerateDALLE.Add_Click({
    $key = $script:textOpenAI.Text.Trim()
    if (-not $key) {
        Show-Message "Введите ключ OpenAI для генерации" "Error"
        return
    }
    $prompt = $script:textPrompt.Text.Trim()
    if (-not $prompt) {
        Show-Message "Введите описание для генерации" "Error"
        return
    }
    $script:btnGenerateDALLE.Enabled = $false
    $script:btnGenerateDALLE.Text = "⏳ Генерация..."
    Show-Message "Генерируем изображение DALL-E..." "Info"
    try {
        $body = @{
            prompt = $prompt
            source = "dalle"
            api_key = $key
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$API_URL/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
        
        if ($response.image_url) {
            $global:generatedImageUrl = $response.image_url
            $global:currentSource = "dalle"
            Show-Message "✅ Изображение сгенерировано!" "Success"
            $script:btnDownload.Enabled = $true
            # Показываем изображение
            if ($script:pictureBox.Image) {
                $script:pictureBox.Image.Dispose()
            }
            $imageStream = [System.Net.WebRequest]::Create($response.image_url).GetResponse().GetResponseStream()
            $script:pictureBox.Image = [System.Drawing.Image]::FromStream($imageStream)
            $imageStream.Close()
        } else {
            Show-Message "❌ Ошибка генерации" "Error"
        }
    }
    catch {
        Show-Message "Ошибка генерации: $($_.Exception.Message)" "Error"
    }
    finally {
        $script:btnGenerateDALLE.Enabled = $true
        $script:btnGenerateDALLE.Text = "🎨 ГЕНЕРИРОВАТЬ (DALL-E 3)"
    }
})

# Обработчик для скачивания изображения
$btnDownload.Add_Click({
    if (-not $global:generatedImageUrl) {
        Show-Message "Нет изображения для скачивания" "Warning"
        return
    }
    
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "PNG Image|*.png|JPEG Image|*.jpg|All Files|*.*"
    $saveDialog.FileName = "generated_image.$(if ($global:currentSource -eq "dalle") {"png"} else {"jpg"})"
    
    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $script:btnDownload.Enabled = $false
            $script:btnDownload.Text = "⏳ Скачивание..."
            
            Invoke-WebRequest -Uri $global:generatedImageUrl -OutFile $saveDialog.FileName
            
            Show-Message "✅ Изображение сохранено: $($saveDialog.FileName)" "Success"
        }
        catch {
            Show-Message "Ошибка скачивания: $($_.Exception.Message)" "Error"
        }
        finally {
            $script:btnDownload.Enabled = $true
            $script:btnDownload.Text = "💾 СКАЧАТЬ ИЗОБРАЖЕНИЕ"
        }
    }
})
