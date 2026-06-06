$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupDir = Join-Path $ProjectDir "_backup_before_blank_line_cleanup"

$IgnoredDirs = @(
    ".godot",
    ".git",
    "addons",
    "_backup_before_comment_removal",
    "_backup_before_blank_line_cleanup"
)

function Test-IsIgnoredPath {
    param (
        [string] $FullPath
    )

    $relative = $FullPath.Substring($ProjectDir.Length).TrimStart("\", "/")
    $parts = $relative -split "[\\/]"

    foreach ($part in $parts) {
        if ($IgnoredDirs -contains $part) {
            return $true
        }
    }

    return $false
}

function Normalize-GdBlankLines {
    param (
        [string[]] $Lines
    )

    $output = New-Object System.Collections.Generic.List[string]
    $previousWasBlank = $false

    foreach ($line in $Lines) {
        $cleanLine = $line.TrimEnd()

        if ([string]::IsNullOrWhiteSpace($cleanLine)) {
            if (-not $previousWasBlank -and $output.Count -gt 0) {
                $output.Add("")
            }

            $previousWasBlank = $true
            continue
        }

        $output.Add($cleanLine)
        $previousWasBlank = $false
    }

    while ($output.Count -gt 0 -and [string]::IsNullOrWhiteSpace($output[$output.Count - 1])) {
        $output.RemoveAt($output.Count - 1)
    }

    return $output.ToArray()
}

Write-Host "Iniciando limpeza de linhas em branco dos arquivos .gd..."
Write-Host "Projeto: $ProjectDir"

$gdFiles = Get-ChildItem -LiteralPath $ProjectDir -Recurse -File -Filter "*.gd" | Where-Object {
    -not (Test-IsIgnoredPath $_.FullName)
}

if ($gdFiles.Count -eq 0) {
    Write-Host "Nenhum arquivo .gd encontrado."
    exit
}

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

$changedCount = 0

foreach ($file in $gdFiles) {
    $originalText = [System.IO.File]::ReadAllText($file.FullName)
    $originalLines = [System.IO.File]::ReadAllLines($file.FullName)

    $cleanedLines = Normalize-GdBlankLines $originalLines
    $cleanedText = $cleanedLines -join [Environment]::NewLine
    $cleanedText += [Environment]::NewLine

    if ($cleanedText -ne $originalText) {
        $relative = $file.FullName.Substring($ProjectDir.Length).TrimStart("\", "/")
        $backupPath = Join-Path $BackupDir $relative
        $backupFolder = Split-Path $backupPath -Parent

        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $backupPath -Force

        [System.IO.File]::WriteAllText($file.FullName, $cleanedText)

        $changedCount++
        Write-Host "Linhas em branco normalizadas: $relative"
    }
}

Write-Host ""
Write-Host "Finalizado."
Write-Host "Arquivos alterados: $changedCount"
Write-Host "Backup criado em: $BackupDir"