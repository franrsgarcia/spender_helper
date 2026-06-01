# Initialize git, commit, and push Spender Helper to GitHub.
# Prerequisites: Git and GitHub CLI (gh) installed and authenticated.
#   winget install Git.Git
#   winget install GitHub.cli
#   gh auth login

param(
    [string]$RemoteUrl = "",
    [string]$RepoName = "spender_helper",
    [switch]$CreateGitHubRepo
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed or not on PATH. Install from https://git-scm.com/download/win"
}

if (-not (Test-Path ".git")) {
    git init
    git branch -M main
}

git add -A
$status = git status --porcelain
if ($status) {
    git commit -m @"
Add Spender Helper iOS app.

SwiftUI spending logger with Wallet Shortcuts automation, SwiftData storage, and CSV export for Excel and Google Sheets.
"@
} else {
    Write-Host "Nothing to commit."
}

if ($CreateGitHubRepo) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Error "GitHub CLI (gh) is required for -CreateGitHubRepo. Install: winget install GitHub.cli"
    }
    gh repo create $RepoName --source=. --public --push
    exit 0
}

if ($RemoteUrl) {
    $existing = git remote get-url origin 2>$null
    if (-not $existing) {
        git remote add origin $RemoteUrl
    } else {
        git remote set-url origin $RemoteUrl
    }
    git push -u origin main
    Write-Host "Pushed to $RemoteUrl"
} else {
    Write-Host @"

Committed locally. To push, either:

1. Create repo on GitHub and run:
   .\scripts\init-and-push.ps1 -RemoteUrl "https://github.com/YOUR_USER/spender_helper.git"

2. Or use GitHub CLI (creates repo and pushes):
   .\scripts\init-and-push.ps1 -CreateGitHubRepo

"@
}
