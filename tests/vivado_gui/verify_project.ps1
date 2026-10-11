param([string]$Vivado = 'C:\Xilinx\Vivado\2023.1\bin\vivado.bat')
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    & $Vivado -mode batch -source (Join-Path $PSScriptRoot 'verify_project.tcl') -log (Join-Path $PSScriptRoot 'verify.log') -journal (Join-Path $PSScriptRoot 'verify.jou')
    if ($LASTEXITCODE -ne 0) { throw "Vivado verification failed: $LASTEXITCODE" }
} finally { Pop-Location }
