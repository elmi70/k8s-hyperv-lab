#Requires -RunAsAdministrator
$root=Split-Path $PSScriptRoot -Parent
Push-Location "$root\vagrant"
try { vagrant destroy -f } finally { Pop-Location }
