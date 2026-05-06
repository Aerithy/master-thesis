[CmdletBinding()]
param(
	[string]$Root = ".",
	[string]$DrawIoExe = "C:\Program Files\draw.io\draw.io.exe"
)

$ErrorActionPreference = "Stop"

function Resolve-ExePath {
	param(
		[string]$Preferred,
		[string]$CommandName
	)

	if ($Preferred -and (Test-Path $Preferred)) {
		return (Resolve-Path $Preferred).Path
	}

	$cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
	if ($cmd) {
		return $cmd.Source
	}

	return $null
}

$drawIoPath = Resolve-ExePath -Preferred $DrawIoExe -CommandName "drawio"
if (-not $drawIoPath) {
	throw "Cannot find draw.io executable. Set -DrawIoExe explicitly."
}

$rootPath = (Resolve-Path $Root).Path
$drawioFiles = Get-ChildItem -Path $rootPath -Recurse -File -Filter "*.drawio"

if (-not $drawioFiles) {
	Write-Output "No .drawio files found under $rootPath"
	exit 0
}

Write-Output "draw.io: $drawIoPath"
Write-Output "root   : $rootPath"
Write-Output "files  : $($drawioFiles.Count)"

$ok = 0
$failed = 0

foreach ($f in $drawioFiles) {
	$pdfPath = [System.IO.Path]::ChangeExtension($f.FullName, ".pdf")

	try {
		& $drawIoPath --export --format pdf --output $pdfPath $f.FullName | Out-Null
		if ($LASTEXITCODE -ne 0 -or -not (Test-Path $pdfPath)) {
			throw "draw.io export failed"
		}

		$ok += 1
		Write-Output "[OK] $($f.FullName)"
	}
	catch {
		$failed += 1
		Write-Output "[FAIL] $($f.FullName) :: $($_.Exception.Message)"
	}
}

Write-Output "Completed. success=$ok failed=$failed total=$($drawioFiles.Count)"

if ($failed -gt 0) {
	exit 1
}
