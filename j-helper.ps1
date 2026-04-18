param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('find', 'record', 'recent', 'clean')]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$HistoryPath,

    [string]$Query,

    [string]$Dir
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding

function Get-HistoryList {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    Get-Content -LiteralPath $Path | Where-Object {
        $_ -and (Test-Path -LiteralPath $_ -PathType Container)
    }
}

function Save-HistoryList {
    param(
        [string]$Path,
        [string[]]$Items
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    Set-Content -LiteralPath $Path -Value $Items -Encoding ASCII
}

function Resolve-FullPath {
    param([string]$Path)

    try {
        return [System.IO.DirectoryInfo]::new($Path).FullName
    } catch {
        return $null
    }
}

switch ($Action) {
    'find' {
        $needle = $Query
        if ([string]::IsNullOrWhiteSpace($needle)) {
            exit 0
        }

        foreach ($item in Get-HistoryList -Path $HistoryPath) {
            $leaf = Split-Path -Leaf $item
            if ($leaf.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                Write-Output ("TARGET|{0}" -f $item)
                break
            }
        }
    }

    'record' {
        if ([string]::IsNullOrWhiteSpace($Dir)) {
            exit 0
        }

        $resolved = Resolve-FullPath -Path $Dir
        if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
            exit 0
        }

        $history = @($resolved)
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        [void]$seen.Add($resolved)

        foreach ($item in Get-HistoryList -Path $HistoryPath) {
            if ($seen.Add($item)) {
                $history += $item
            }
        }

        Save-HistoryList -Path $HistoryPath -Items $history
    }

    'recent' {
        Get-HistoryList -Path $HistoryPath | Select-Object -First 15 | ForEach-Object {
            $leaf = Split-Path -Leaf $_
            "RECENT|[{0}] {1}" -f $leaf, $_
        }
    }

    'clean' {
        $history = @(Get-HistoryList -Path $HistoryPath)
        Save-HistoryList -Path $HistoryPath -Items $history
        foreach ($item in $history | Select-Object -First 15) {
            $leaf = Split-Path -Leaf $item
            "RECENT|[{0}] {1}" -f $leaf, $item
        }
    }
}
