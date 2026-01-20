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
$global:unsplashResults = @()
$global:selectedImages = @()
$global:previewPanel = $null
$global:lastSearchTime = $null
$global:searchCount = 0

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

function Clear-PreviewPanel {
    if ($global:previewPanel -ne $null) {
        $global:previewPanel.Controls.Clear()
    }
    $global:selectedImages = @()
}

function Create-ImagePreview {
    param([System.Drawing.Image]$Image, [int]$Index, [int]$X, [int]$Y)
    
    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $pictureBox.Size = New-Object System.Drawing.Size(100, 100)
    $pictureBox.Location = New-Object System.Drawing.Point($X, $Y)
    $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $pictureBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pictureBox.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $pictureBox.Cursor = [System.Windows.Forms.Cursors]::Hand
    $pictureBox.Tag = $Index
    
    $scaledImage = New-Object System.Drawing.Bitmap(100, 100)
    $graphics = [System.Drawing.Graphics]::FromImage($scaledImage)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($Image, 0, 0, 100, 100)
    $graphics.Dispose()
    
    $pictureBox.Image = $scaledImage
    
    $pictureBox.Add_Click({
        $clickedIndex = $this.Tag
        if ($global:selectedImages -contains $clickedIndex) {
            $global:selectedImages = $global:selectedImages | Where-Object { $_ -ne $clickedIndex }
            $this.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
            $this.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
        } else {
            $global:selectedImages += $clickedIndex
            $this.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
            $this.BackColor = [System.Drawing.Color]::FromArgb(94, 234, 212)
        }
        
        Show-Message "Выбрано изображений: $($global:selectedImages.Count)" "Success"
        $script:btnDownload.Enabled = ($global:selectedImages.Count -gt 0) -or ($global:currentSource -eq "dalle")
    })
    
    return $pictureBox
}

function Download-SelectedImages {
    if ($global:currentSource -eq "dalle") {
        if (-not $global:generatedImageUrl) {
            Show-Message "Нет изображения для скачивания" "Warning"
            return
        }
        
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "PNG Image|*.png|JPEG Image|*.jpg|All Files|*.*"
        $saveDialog.FileName = "dalle_generated_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
        
        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($global:generatedImageUrl, $saveDialog.FileName)
                Show-Message "Изображение сохранено: $($saveDialog.FileName)" "Success"
            }
            catch {
                Show-Message "Ошибка скачивания: $($_.Exception.Message)" "Error"
            }
        }
    }
    elseif ($global:currentSource -eq "unsplash") {
        if ($global:selectedImages.Count -eq 0) {
            Show-Message "Выберите хотя бы одно изображение для скачивания" "Warning"
            return
        }
        
        if ($global:selectedImages.Count -eq 1) {
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "JPEG Image|*.jpg|PNG Image|*.png|All Files|*.*"
            $saveDialog.FileName = "unsplash_$(Get-Date -Format 'yyyyMMdd_HHmmss').jpg"
            
            if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                try {
                    $photo = $global:unsplashResults[$global:selectedImages[0]]
                    $webClient = New-Object System.Net.WebClient
                    $webClient.DownloadFile($photo.urls.regular, $saveDialog.FileName)
                    Show-Message "Изображение сохранено: $($saveDialog.FileName)" "Success"
                }
                catch {
                    Show-Message "Ошибка скачивания: $($_.Exception.Message)" "Error"
                }
            }
        } else {
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderDialog.Description = "Выберите папку для сохранения $($global:selectedImages.Count) изображений"
            $folderDialog.ShowNewFolderButton = $true
            
            if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $savedCount = 0
                foreach ($imgIndex in $global:selectedImages) {
                    try {
                        $photo = $global:unsplashResults[$imgIndex]
                        $fileName = "unsplash_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$savedCount.jpg"
                        $filePath = Join-Path $folderDialog.SelectedPath $fileName
                        
                        $webClient = New-Object System.Net.WebClient
                        $webClient.DownloadFile($photo.urls.regular, $filePath)
                        $savedCount++
                    }
                    catch {
                        Show-Message "Ошибка скачивания изображения ${imgIndex}: $($_.Exception.Message)" "Error"
                    }
                }
                
                if ($savedCount -gt 0) {
                    Show-Message "Сохранено $savedCount изображений в: $($folderDialog.SelectedPath)" "Success"
                }
            }
        }
    }
    else {
        Show-Message "Сначала сгенерируйте или найдите изображения" "Warning"
    }
}

# --- СОЗДАНИЕ ИНТЕРФЕЙСА ---
function Create-GUI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "🎨 Illustraitor AI - Двойная генерация"
    $form.Size = New-Object System.Drawing.Size(850, 850)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 46)
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    
    $labelTitle = New-Object System.Windows.Forms.Label
    $labelTitle.Text = "Illustraitor AI - Генерация изображений"
    $labelTitle.ForeColor = [System.Drawing.Color]::FromArgb(94, 234, 212)
    $labelTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $labelTitle.Location = New-Object System.Drawing.Point(20, 15)
    $labelTitle.Size = New-Object System.Drawing.Size(810, 30)
    $labelTitle.TextAlign = "MiddleCenter"
    $form.Controls.Add($labelTitle)

    $groupAPI = New-Object System.Windows.Forms.GroupBox
    $groupAPI.Text = "API Ключи (оба источника независимы)"
    $groupAPI.ForeColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
    $groupAPI.Location = New-Object System.Drawing.Point(20, 55)
    $groupAPI.Size = New-Object System.Drawing.Size(810, 140)
    $groupAPI.BackColor = [System.Drawing.Color]::FromArgb(49, 51, 68)
    $form.Controls.Add($groupAPI)

    $labelOpenAI = New-Object System.Windows.Forms.Label
    $labelOpenAI.Text = "OpenAI API Key (DALL-E 3):"
    $labelOpenAI.ForeColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
    $labelOpenAI.Location = New-Object System.Drawing.Point(15, 25)
    $labelOpenAI.Size = New-Object System.Drawing.Size(380, 20)
    $labelOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $groupAPI.Controls.Add($labelOpenAI)

    $textOpenAI = New-Object System.Windows.Forms.TextBox
    $textOpenAI.Location = New-Object System.Drawing.Point(15, 45)
    $textOpenAI.Size = New-Object System.Drawing.Size(300, 25)
    $textOpenAI.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $textOpenAI.ForeColor = [System.Drawing.Color]::White
    $textOpenAI.Font = New-Object System.Drawing.Font("Consolas", 9)
    $textOpenAI.PasswordChar = '•'
    $groupAPI.Controls.Add($textOpenAI)

    $btnShowOpenAI = New-Object System.Windows.Forms.Button
    $btnShowOpenAI.Text = "👁"
    $btnShowOpenAI.Location = New-Object System.Drawing.Point(320, 45)
    $btnShowOpenAI.Size = New-Object System.Drawing.Size(25, 25)
    $btnShowOpenAI.BackColor = [System.Drawing.Color]::FromArgb(89, 91, 110)
    $btnShowOpenAI.ForeColor = [System.Drawing.Color]::White
    $btnShowOpenAI.FlatStyle = "Flat"
    $btnShowOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $groupAPI.Controls.Add($btnShowOpenAI)

    $btnSaveOpenAI = New-Object System.Windows.Forms.Button
    $btnSaveOpenAI.Text = "💾 Сохранить"
    $btnSaveOpenAI.Location = New-Object System.Drawing.Point(15, 75)
    $btnSaveOpenAI.Size = New-Object System.Drawing.Size(80, 25)
    $btnSaveOpenAI.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $btnSaveOpenAI.ForeColor = [System.Drawing.Color]::Black
    $btnSaveOpenAI.FlatStyle = "Flat"
    $btnSaveOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $groupAPI.Controls.Add($btnSaveOpenAI)

    $btnDeleteOpenAI = New-Object System.Windows.Forms.Button
    $btnDeleteOpenAI.Text = "🗑 Удалить"
    $btnDeleteOpenAI.Location = New-Object System.Drawing.Point(100, 75)
    $btnDeleteOpenAI.Size = New-Object System.Drawing.Size(80, 25)
    $btnDeleteOpenAI.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
    $btnDeleteOpenAI.ForeColor = [System.Drawing.Color]::White
    $btnDeleteOpenAI.FlatStyle = "Flat"
    $btnDeleteOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $groupAPI.Controls.Add($btnDeleteOpenAI)

    $btnTestOpenAI = New-Object System.Windows.Forms.Button
    $btnTestOpenAI.Text = "🔍 Проверить"
    $btnTestOpenAI.Location = New-Object System.Drawing.Point(185, 75)
    $btnTestOpenAI.Size = New-Object System.Drawing.Size(80, 25)
    $btnTestOpenAI.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
    $btnTestOpenAI.ForeColor = [System.Drawing.Color]::Black
    $btnTestOpenAI.FlatStyle = "Flat"
    $btnTestOpenAI.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $groupAPI.Controls.Add($btnTestOpenAI)

    $labelUnsplash = New-Object System.Windows.Forms.Label
    $labelUnsplash.Text = "Unsplash Access Key:"
    $labelUnsplash.ForeColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
    $labelUnsplash.Location = New-Object System.Drawing.Point(415, 25)
    $labelUnsplash.Size = New-Object System.Drawing.Size(380, 20)
    $labelUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $groupAPI.Controls.Add($labelUnsplash)

    $textUnsplash = New-Object System.Windows.Forms.TextBox
    $textUnsplash.Location = New-Object System.Drawing.Point(415, 45)
    $textUnsplash.Size = New-Object System.Drawing.Size(300, 25)
    $textUnsplash.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $textUnsplash.ForeColor = [System.Drawing.Color]::White
    $textUnsplash.Font = New-Object System.Drawing.Font("Consolas", 9)
    $textUnsplash.PasswordChar = '•'
    $groupAPI.Controls.Add($textUnsplash)

    $btnShowUnsplash = New-Object System.Windows.Forms.Button
    $btnShowUnsplash.Text = "👁"
    $btnShowUnsplash.Location = New-Object System.Drawing.Point(720, 45)
    $btnShowUnsplash.Size = New-Object System.Drawing.Size(25, 25)
    $btnShowUnsplash.BackColor = [System.Drawing.Color]::FromArgb(89, 91, 110)
    $btnShowUnsplash.ForeColor = [System.Drawing.Color]::White
    $btnShowUnsplash.FlatStyle = "Flat"
    $btnShowUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $groupAPI.Controls.Add($btnShowUnsplash)

    $btnSaveUnsplash = New-Object System.Windows.Forms.Button
    $btnSaveUnsplash.Text = "💾 Сохранить"
    $btnSaveUnsplash.Location = New-Object System.Drawing.Point(415, 75)
    $btnSaveUnsplash.Size = New-Object System.Drawing.Size(80, 25)
    $btnSaveUnsplash.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $btnSaveUnsplash.ForeColor = [System.Drawing.Color]::Black
    $btnSaveUnsplash.FlatStyle = "Flat"
    $btnSaveUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $groupAPI.Controls.Add($btnSaveUnsplash)

    $btnDeleteUnsplash = New-Object System.Windows.Forms.Button
    $btnDeleteUnsplash.Text = "🗑 Удалить"
    $btnDeleteUnsplash.Location = New-Object System.Drawing.Point(500, 75)
    $btnDeleteUnsplash.Size = New-Object System.Drawing.Size(80, 25)
    $btnDeleteUnsplash.BackColor = [System.Drawing.Color]::FromArgb(237, 135, 150)
    $btnDeleteUnsplash.ForeColor = [System.Drawing.Color]::White
    $btnDeleteUnsplash.FlatStyle = "Flat"
    $btnDeleteUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $groupAPI.Controls.Add($btnDeleteUnsplash)

    $btnTestUnsplash = New-Object System.Windows.Forms.Button
    $btnTestUnsplash.Text = "🔍 Проверить"
    $btnTestUnsplash.Location = New-Object System.Drawing.Point(585, 75)
    $btnTestUnsplash.Size = New-Object System.Drawing.Size(80, 25)
    $btnTestUnsplash.BackColor = [System.Drawing.Color]::FromArgb(245, 194, 231)
    $btnTestUnsplash.ForeColor = [System.Drawing.Color]::Black
    $btnTestUnsplash.FlatStyle = "Flat"
    $btnTestUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $groupAPI.Controls.Add($btnTestUnsplash)

    $groupPrompt = New-Object System.Windows.Forms.GroupBox
    $groupPrompt.Text = "Запрос / промпт"
    $groupPrompt.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
    $groupPrompt.Location = New-Object System.Drawing.Point(20, 205)
    $groupPrompt.Size = New-Object System.Drawing.Size(810, 100)
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
    $textPrompt.Location = New-Object System.Drawing.Point(15, 45)
    $textPrompt.Size = New-Object System.Drawing.Size(780, 45)
    $textPrompt.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $textPrompt.ForeColor = [System.Drawing.Color]::White
    $textPrompt.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $textPrompt.ScrollBars = "Vertical"
    $groupPrompt.Controls.Add($textPrompt)

    $groupStyles = New-Object System.Windows.Forms.GroupBox
    $groupStyles.Text = "Стили изображения (для DALL-E 3)"
    $groupStyles.ForeColor = [System.Drawing.Color]::FromArgb(137, 220, 235)
    $groupStyles.Location = New-Object System.Drawing.Point(20, 315)
    $groupStyles.Size = New-Object System.Drawing.Size(810, 120)
    $groupStyles.BackColor = [System.Drawing.Color]::FromArgb(49, 51, 68)
    $form.Controls.Add($groupStyles)

    $listStyles = New-Object System.Windows.Forms.CheckedListBox
    $listStyles.Location = New-Object System.Drawing.Point(15, 25)
    $listStyles.Size = New-Object System.Drawing.Size(780, 85)
    $listStyles.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $listStyles.ForeColor = [System.Drawing.Color]::White
    $listStyles.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $listStyles.BorderStyle = "FixedSingle"
    $listStyles.CheckOnClick = $true
    $groupStyles.Controls.Add($listStyles)

    $styles = @(
        "🔮 Реализм", "🎨 Импрессионизм", "🌌 Сюрреализм", "🌀 Абстракционизм",
        "🟡 Поп-арт", "🤖 Киберпанк", "⚙️ Стимпанк", "🐉 Фэнтези",
        "🌸 Аниме", "🎮 Пиксель-арт", "🖌️ Масляная живопись",
        "💧 Акварель", "⚫ Черно-белое", "📜 Винтаж", "📺 Мультяшный"
    )
    foreach ($style in $styles) {
        [void]$listStyles.Items.Add($style, $false)
    }

    $groupPreview = New-Object System.Windows.Forms.GroupBox
    $groupPreview.Text = "Результаты поиска Unsplash (кликните для выбора)"
    $groupPreview.ForeColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
    $groupPreview.Location = New-Object System.Drawing.Point(20, 445)
    $groupPreview.Size = New-Object System.Drawing.Size(810, 150)
    $groupPreview.BackColor = [System.Drawing.Color]::FromArgb(49, 51, 68)
    $form.Controls.Add($groupPreview)

    $previewPanel = New-Object System.Windows.Forms.Panel
    $previewPanel.Location = New-Object System.Drawing.Point(15, 25)
    $previewPanel.Size = New-Object System.Drawing.Size(780, 115)
    $previewPanel.BackColor = [System.Drawing.Color]::FromArgb(39, 41, 58)
    $previewPanel.AutoScroll = $true
    $groupPreview.Controls.Add($previewPanel)

    $global:previewPanel = $previewPanel

    $btnGenerateDALLE = New-Object System.Windows.Forms.Button
    $btnGenerateDALLE.Text = "🎨 ГЕНЕРИРОВАТЬ (DALL-E 3)"
    $btnGenerateDALLE.Location = New-Object System.Drawing.Point(20, 605)
    $btnGenerateDALLE.Size = New-Object System.Drawing.Size(400, 40)
    $btnGenerateDALLE.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
    $btnGenerateDALLE.ForeColor = [System.Drawing.Color]::White
    $btnGenerateDALLE.FlatStyle = "Flat"
    $btnGenerateDALLE.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($btnGenerateDALLE)

    $btnSearchUnsplash = New-Object System.Windows.Forms.Button
    $btnSearchUnsplash.Text = "🔎 ПОИСК (Unsplash - до 5 изображений)"
    $btnSearchUnsplash.Location = New-Object System.Drawing.Point(430, 605)
    $btnSearchUnsplash.Size = New-Object System.Drawing.Size(400, 40)
    $btnSearchUnsplash.BackColor = [System.Drawing.Color]::FromArgb(203, 166, 247)
    $btnSearchUnsplash.ForeColor = [System.Drawing.Color]::White
    $btnSearchUnsplash.FlatStyle = "Flat"
    $btnSearchUnsplash.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($btnSearchUnsplash)

    $btnDownload = New-Object System.Windows.Forms.Button
    $btnDownload.Text = "💾 СКАЧАТЬ ВЫБРАННОЕ ИЗОБРАЖЕНИЕ"
    $btnDownload.Location = New-Object System.Drawing.Point(20, 655)
    $btnDownload.Size = New-Object System.Drawing.Size(810, 35)
    $btnDownload.BackColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
    $btnDownload.ForeColor = [System.Drawing.Color]::White
    $btnDownload.FlatStyle = "Flat"
    $btnDownload.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnDownload.Enabled = $false
    $form.Controls.Add($btnDownload)

    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "Готов к работе. Выберите источник: DALL-E 3 или Unsplash"
    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $statusLabel.Location = New-Object System.Drawing.Point(20, 700)
    $statusLabel.Size = New-Object System.Drawing.Size(810, 30)
    $statusLabel.TextAlign = "MiddleCenter"
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.Controls.Add($statusLabel)

    $global:statusLabel = $statusLabel

    # ========== ФИКСАЦИЯ ПЕРЕМЕННЫХ ==========
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

    # --- ОБРАБОТЧИКИ СОБЫТИЙ ---
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
    })

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
        Show-Message "Проверяем ключ OpenAI через API..." "Info"
        
        try {
            # Прямая проверка через OpenAI API
            $headers = @{
                "Authorization" = "Bearer $key"
                "Content-Type" = "application/json"
            }
            
            $body = @{
                model = "gpt-3.5-turbo"
                messages = @(@{ role = "user"; content = "test" })
                max_tokens = 1
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                -Method Post `
                -Headers $headers `
                -Body $body `
                -TimeoutSec 30 `
                -ErrorAction SilentlyContinue
            
            if ($response.id) {
                Show-Message "✅ Ключ OpenAI валиден!" "Success"
            } else {
                Show-Message "❌ Ключ OpenAI невалиден" "Error"
            }
        }
        catch [System.Net.WebException] {
            if ($_.Exception.Response.StatusCode -eq 401) {
                Show-Message "❌ Ключ OpenAI невалиден (ошибка 401)" "Error"
            }
            else {
                Show-Message "Ошибка проверки: $($_.Exception.Message)" "Error"
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
        Show-Message "Проверяем ключ Unsplash напрямую через API..." "Info"
        
        try {
            # Прямая проверка через Unsplash API
            $url = "https://api.unsplash.com/photos/random?count=1"
            $headers = @{
                "Authorization" = "Client-ID $key"
                "Accept-Version" = "v1"
            }
            
            $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -TimeoutSec 30
            
            if ($response -and $response[0].id) {
                Show-Message "✅ Ключ Unsplash валиден! API работает." "Success"
            } else {
                Show-Message "❌ Не удалось получить данные через API" "Error"
            }
        }
        catch [System.Net.WebException] {
            if ($_.Exception.Response.StatusCode -eq 401) {
                Show-Message "❌ Ключ Unsplash невалиден (ошибка 401)" "Error"
            }
            elseif ($_.Exception.Response.StatusCode -eq 403) {
                Show-Message "❌ Доступ запрещен. Проверьте ключ" "Error"
            }
            else {
                Show-Message "Ошибка проверки: $($_.Exception.Message)" "Error"
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

    $btnSearchUnsplash.Add_Click({
        $currentTime = Get-Date
        if ($global:lastSearchTime -ne $null) {
            $timeDiff = $currentTime - $global:lastSearchTime
            if ($global:searchCount -ge 50 -and $timeDiff.TotalHours -lt 1) {
                Show-Message "Лимит поиска: 50 запросов в час. Подождите." "Error"
                return
            }
        }
        
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
        
        $script:btnSearchUnsplash.Enabled = $false
        $script:btnSearchUnsplash.Text = "⏳ Поиск..."
        Clear-PreviewPanel
        Show-Message "Ищем изображения в Unsplash (макс. 5)..." "Info"
        
        try {
            $query = [System.Web.HttpUtility]::UrlEncode($prompt)
            $url = "https://api.unsplash.com/search/photos?query=$query&per_page=5&orientation=landscape"
            
            $headers = @{
                "Authorization" = "Client-ID $key"
                "Accept-Version" = "v1"
            }
            
            $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -TimeoutSec 30
            
            if ($response.results -and $response.results.Count -gt 0) {
                $global:unsplashResults = $response.results
                $global:currentSource = "unsplash"
                $global:searchCount++
                $global:lastSearchTime = $currentTime
                
                Show-Message "Найдено $($response.results.Count) изображений! (Запросов в час: $global:searchCount/50)" "Success"
                
                $x = 10
                $y = 10
                $count = 0
                
                foreach ($photo in $global:unsplashResults) {
                    try {
                        $tempFile = [System.IO.Path]::GetTempFileName() + ".jpg"
                        $thumbnailUrl = $photo.urls.thumb
                        
                        $webClient = New-Object System.Net.WebClient
                        $webClient.DownloadFile($thumbnailUrl, $tempFile)
                        
                        $image = [System.Drawing.Image]::FromFile($tempFile)
                        
                        $pictureBox = Create-ImagePreview -Image $image -Index $count -X $x -Y $y
                        $global:previewPanel.Controls.Add($pictureBox)
                        
                        $image.Dispose()
                        
                        $x += 110
                        $count++
                        
                        if ($x + 110 -gt $global:previewPanel.Width) {
                            $x = 10
                            $y += 110
                        }
                        
                    } catch {
                        Write-Host "Ошибка загрузки превью: $_" -ForegroundColor Yellow
                    }
                }
                
            } else {
                Show-Message "Изображения не найдены по запросу: $prompt" "Warning"
            }
        }
        catch {
            Show-Message "Ошибка поиска: $($_.Exception.Message)" "Error"
        }
        finally {
            $script:btnSearchUnsplash.Enabled = $true
            $script:btnSearchUnsplash.Text = "🔎 ПОИСК (Unsplash - до 5 изображений)"
        }
    })

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
        
        Clear-PreviewPanel
        
        $script:btnGenerateDALLE.Enabled = $false
        $script:btnGenerateDALLE.Text = "⏳ Генерация..."
        Show-Message "Генерируем изображение DALL-E..." "Info"
        
        try {
            $body = @{
                prompt = $prompt
                source = "openai"
                api_key = $key
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$API_URL/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
            
            if ($response.image_url) {
                $global:generatedImageUrl = $response.image_url
                $global:currentSource = "dalle"
                Show-Message "Изображение сгенерировано!" "Success"
                $script:btnDownload.Enabled = $true
            } else {
                Show-Message "Ошибка генерации" "Error"
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

    $btnDownload.Add_Click({
        Download-SelectedImages
    })

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
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [void]$form.ShowDialog()
}
catch {
    Write-Host "Ошибка: $_" -ForegroundColor Red
}