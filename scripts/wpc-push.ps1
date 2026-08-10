# wpc-push — post-feature build and push workflow
#
# Run this after manually committing source changes. Steps:
#   1. Abort if any dirty/untracked files exist outside build/ (uncommitted source work)
#   2. Reset tracked build/ files to HEAD; delete untracked build/ files (e.g. source maps)
#   3. Fetch remote; abort if fetch fails; pull --rebase if remote has new commits (aborts on conflict)
#   4. Rebuild — auto-detects whether source maps are tracked and sets WP_DEVTOOL accordingly
#   5. Commit build output (skipped if nothing changed)
#   6. Push

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- 1. Safety check: only build/ files should be dirty/untracked ---
$trackedDirty   = @(git diff --name-only --relative HEAD)
$untrackedFiles = @(git ls-files --others --exclude-standard)
$allDirty       = $trackedDirty + $untrackedFiles

$nonBuild = @($allDirty | Where-Object { $_ -notmatch '(?:^|/)build/[^/]+$' })
if ($nonBuild.Count -gt 0) {
    Write-Warning "Aborting: uncommitted files found outside build/:"
    $nonBuild | ForEach-Object { Write-Host "  $_" }
    exit 1
}

# --- 2. Reset tracked build/ files; delete untracked build/ files (e.g. source maps) ---
$trackedBuild   = @($trackedDirty   | Where-Object { $_ -match '(?:^|/)build/[^/]+$' })
$untrackedBuild = @($untrackedFiles | Where-Object { $_ -match '(?:^|/)build/[^/]+$' })

if ($trackedBuild.Count -gt 0) {
    git checkout HEAD -- @($trackedBuild)
}
$untrackedBuild | ForEach-Object { Remove-Item $_ -Force -ErrorAction SilentlyContinue }

# --- 3. Fetch, check divergence, rebase only if safe ---
Write-Host "Running: git fetch"
git fetch
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Aborting: git fetch failed — check SSH key / network."
    exit 1
}

$localRev  = git rev-parse HEAD
$remoteRev = git rev-parse '@{u}' 2>$null

if ($remoteRev -and ($localRev -ne $remoteRev)) {
    git rebase '@{u}'
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Aborting: rebase hit conflicts — resolve manually then re-run."
        exit 1
    }
} else {
    Write-Host "Already up to date."
}

# --- 4. Build (with maps if tracked, without if not) ---
$mapsTracked = @(git ls-files -- "*.map").Count -gt 0
if ($mapsTracked) {
    $env:WP_DEVTOOL = 'source-map'
    npm run build
    Remove-Item Env:\WP_DEVTOOL -ErrorAction SilentlyContinue
} else {
    npm run build
}
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Aborting: npm run build failed — are you in the theme directory?"
    exit 1
}

# --- 5. Commit build (skip if nothing changed) ---
$buildDirty = @(git status --porcelain)
if ($buildDirty.Count -gt 0) {
    git commit -am 'build'
} else {
    Write-Host "Nothing to commit for build."
}

# --- 6. Push ---
Write-Host "Running: git push"
git push
