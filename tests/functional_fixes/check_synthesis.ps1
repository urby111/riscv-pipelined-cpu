param([string]$Vivado = 'C:\Xilinx\Vivado\2023.1\bin\vivado.bat')
$ErrorActionPreference = 'Stop'
$outputDirectory = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
Push-Location $outputDirectory
try {
    & $Vivado -mode batch -source (Join-Path $PSScriptRoot 'check_synthesis.tcl') -log (Join-Path $outputDirectory 'synthesis.log') -journal (Join-Path $outputDirectory 'synthesis.jou')
    if ($LASTEXITCODE -ne 0) { throw "Synthesis failed: $LASTEXITCODE" }
} finally { Pop-Location }
