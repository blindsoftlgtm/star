$ErrorActionPreference = "Stop"

$starRoot = Split-Path -Parent $PSScriptRoot
$providerRoot = Join-Path $starRoot "provider"
$python = (Get-Command python.exe -ErrorAction Stop).Source
$providerScripts = @{}

Write-Host "Finding configured STAR providers..."
Write-Host ""

# Discover every configured provider whose configuration name matches its
# Python entry point. The server addresses already stored in each .ini file are
# left unchanged.
Get-ChildItem -Path $providerRoot -Filter "*.ini" -File -Recurse | ForEach-Object {
	$scriptPath = Join-Path $_.DirectoryName ($_.BaseName + ".py")
	if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
		$providerScripts[$scriptPath.ToLowerInvariant()] = $scriptPath
	}
}

# Retain providers already running from this checkout, including providers
# whose script and configuration filenames do not match.
$pythonProcesses = Get-CimInstance Win32_Process | Where-Object {
	$_.Name -match '^python(w)?\.exe$' -and $_.CommandLine -match '\.py(?:\s|"|$)'
}
Get-ChildItem -Path $providerRoot -Filter "*.py" -File -Recurse | ForEach-Object {
	$scriptFile = $_
	foreach ($process in $pythonProcesses) {
		if ($process.CommandLine -match [regex]::Escape($scriptFile.Name)) {
			$providerScripts[$scriptFile.FullName.ToLowerInvariant()] = $scriptFile.FullName
		}
	}
}

if ($providerScripts.Count -eq 0) {
	Write-Host "No configured or running STAR providers were found."
	Read-Host "Press Enter to close"
	exit 1
}

$restarted = 0
foreach ($scriptPath in ($providerScripts.Values | Sort-Object)) {
	$script = Get-Item -LiteralPath $scriptPath
	$scriptPattern = [regex]::Escape($script.Name)
	Get-CimInstance Win32_Process | Where-Object {
		$_.Name -match '^python(w)?\.exe$' -and $_.CommandLine -match $scriptPattern
	} | ForEach-Object {
		Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
	}

	Start-Process -FilePath $python `
		-ArgumentList "-u", $script.Name `
		-WorkingDirectory $script.DirectoryName `
		-WindowStyle Hidden `
		-RedirectStandardOutput (Join-Path $script.DirectoryName "provider.log") `
		-RedirectStandardError (Join-Path $script.DirectoryName "provider-error.log")

	Write-Host "$($script.BaseName): restarted"
	$restarted++
}

Start-Sleep -Seconds 3
Write-Host ""
Write-Host "$restarted STAR provider(s) restarted and reconnecting."
Read-Host "Press Enter to close"
