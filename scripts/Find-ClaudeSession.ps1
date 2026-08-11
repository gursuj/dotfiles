# Finds the working directory for a Claude Code session ID and cd's into it.
# Usage: . Find-ClaudeSession.ps1 <session-id>   (dot-source so cd persists in your shell)

function Find-ClaudeSession {
    param(
        [Parameter(Mandatory)]
        [string]$SessionId
    )

    $claudeDir = Join-Path $HOME ".claude"
    $cwd = $null
    $source = $null

    # 1. Check the live session registry (running processes)
    $liveMatch = Get-ChildItem (Join-Path $claudeDir "sessions") -Filter "*.json" -ErrorAction SilentlyContinue |
        ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json } |
        Where-Object { $_.sessionId -eq $SessionId } |
        Select-Object -First 1

    if ($liveMatch) {
        $cwd = $liveMatch.cwd
        $source = "live session (pid $($liveMatch.pid), status $($liveMatch.status))"
    }
    else {
        # 2. Fall back to scanning project transcript folders for a matching jsonl
        $transcript = Get-ChildItem (Join-Path $claudeDir "projects") -Recurse -Filter "$SessionId.jsonl" -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($transcript) {
            # Each line in the transcript embeds a "cwd" field - read it straight from there
            # rather than decoding the folder name, since folder-name decoding breaks on any
            # real path that itself contains dashes.
            # The first few lines are metadata records (mode, permission-mode,
            # file-history-snapshot) with no "cwd" field, so scan until we find one
            # rather than assuming line 1 has it.
            $matchLine = Get-Content $transcript.FullName | Select-String -Pattern '"cwd":"((?:[^"\\]|\\.)*)"' -List
            if ($matchLine) {
                $cwd = $matchLine.Matches[0].Groups[1].Value -replace '\\\\', '\'
            }
            $source = "transcript at $($transcript.FullName)"
        }
    }

    if (-not $cwd) {
        Write-Warning "No working directory found for session '$SessionId'. Checked live sessions and project transcripts."
        return
    }

    Write-Host "Session $SessionId -> $cwd" -ForegroundColor Cyan
    Write-Host "(source: $source)" -ForegroundColor DarkGray

    if (Test-Path $cwd) {
        Set-Location $cwd
        claude --resume $SessionId
    }
    else {
        Write-Warning "Path '$cwd' does not exist on disk."
    }
}
