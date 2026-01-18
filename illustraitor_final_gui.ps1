Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$API_URL = "https://illustraitor-ai-generator.onrender.com"
$CONFIG_PATH = "$env:APPDATA\AI_Image_Generator\config.json"
$generatedImageUrl = $null
$currentSource = $null
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
    Write-Host "$Type: $Message" -ForegroundColor $(if ($Type -eq "Error") { "Red" } else { "Cyan" })
}
# Дальше будет полный код...
