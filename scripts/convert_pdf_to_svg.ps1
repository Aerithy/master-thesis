[CmdletBinding()]
param(
	[string]$Root = ".",
	[string]$MuToolExe = "C:\Program Files\mupdf-1.27.0-windows\mutool.exe"
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

$muToolPath = Resolve-ExePath -Preferred $MuToolExe -CommandName "mutool"
if (-not $muToolPath) {
	throw "Cannot find mutool executable. Set -MuToolExe explicitly."
}

$rootPath = (Resolve-Path $Root).Path
$pdfFiles = Get-ChildItem -Path $rootPath -Recurse -File -Filter "*.pdf"

if (-not $pdfFiles) {
	Write-Output "No .pdf files found under $rootPath"
	exit 0
}

Write-Output "mutool : $muToolPath"
Write-Output "root   : $rootPath"
Write-Output "files  : $($pdfFiles.Count)"

$ok = 0
$failed = 0

foreach ($f in $pdfFiles) {
	$svgPath = [System.IO.Path]::ChangeExtension($f.FullName, ".svg")

	try {
		& $muToolPath draw -o $svgPath $f.FullName | Out-Null
		if ($LASTEXITCODE -ne 0 -or -not (Test-Path $svgPath)) {
			throw "mutool PDF->SVG failed"
		}

		$ok += 1
		Write-Output "[OK] $($f.FullName)"
	}
	catch {
		$failed += 1
		Write-Output "[FAIL] $($f.FullName) :: $($_.Exception.Message)"
	}
}

Write-Output "Completed. success=$ok failed=$failed total=$($pdfFiles.Count)"

if ($failed -gt 0) {
	exit 1
}