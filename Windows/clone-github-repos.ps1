<#  Clone-Repos.ps1
    Clones every public repo from a GitHub user or org.

    Requirements:
      - git in PATH
      - PowerShell 5.1+ or PowerShell 7+
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$Account,

  [string]$Destination = (Join-Path (Get-Location) $Account),

  [string]$Token,

  [switch]$AsOrg,

  [switch]$SkipExisting = $true,

  [switch]$Mirror
)

function Assert-Git {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git not found in PATH. Install Git for Windows and restart your shell."
  }
}

function New-GitHubHeaders {
  $h = @{
    "Accept"     = "application/vnd.github+json"
    "User-Agent" = "VSCode-Terminal-Repo-Cloner"
  }
  if ($Token) {
    $h["Authorization"] = "Bearer $Token"
  }
  return $h
}

function Get-AllRepos {
  param(
    [Parameter(Mandatory)][string]$BaseUrl,
    [Parameter(Mandatory)][hashtable]$Headers
  )

  $all = @()
  $page = 1
  $perPage = 100

  while ($true) {
    $url = "${BaseUrl}?per_page=$perPage&page=$page&sort=full_name&direction=asc"
    try {
      $repos = Invoke-RestMethod -Method Get -Uri $url -Headers $Headers -ErrorAction Stop
    } catch {
      $msg = $_.Exception.Message
      throw "GitHub API call failed at page ${page}: $msg`nURL: $url"
    }

    if (-not $repos -or $repos.Count -eq 0) { break }

    $all += $repos
    if ($repos.Count -lt $perPage) { break }
    $page++
  }

  return $all
}

function Invoke-GitClone {
  param(
    [Parameter(Mandatory)][string]$CloneUrl,
    [Parameter(Mandatory)][string]$TargetPath
  )

  if ($Mirror) {
    & git clone --mirror $CloneUrl $TargetPath
  } else {
    & git clone $CloneUrl $TargetPath
  }

  if ($LASTEXITCODE -ne 0) {
    throw "git clone failed for $CloneUrl"
  }
}

# ---- main ----
$ErrorActionPreference = "Stop"
Assert-Git

try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$headers = New-GitHubHeaders

$base = if ($AsOrg) {
  "https://api.github.com/orgs/$Account/repos"
} else {
  "https://api.github.com/users/$Account/repos"
}

$kind = if ($AsOrg) { "org" } else { "user" }
Write-Host "Fetching public repos for '$Account' ($kind)..." -ForegroundColor Cyan

$repos = Get-AllRepos -BaseUrl $base -Headers $headers

if (-not $repos -or $repos.Count -eq 0) {
  Write-Host "No public repos found (or account not found)." -ForegroundColor Yellow
  exit 0
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null
Write-Host "Cloning $($repos.Count) repos into: $Destination" -ForegroundColor Cyan

foreach ($r in $repos) {
  $cloneUrl = $r.clone_url
  $folderName = if ($Mirror) { "$($r.name).git" } else { $r.name }
  $target = Join-Path $Destination $folderName

  if (Test-Path $target) {
    if ($SkipExisting) {
      Write-Host "SKIP  $($r.full_name) (already exists)" -ForegroundColor DarkYellow
      continue
    } else {
      throw "Target path already exists: $target"
    }
  }

  Write-Host "CLONE $($r.full_name)" -ForegroundColor Green
  Invoke-GitClone -CloneUrl $cloneUrl -TargetPath $target
}

Write-Host "Done." -ForegroundColor Cyan
