param([string]$Target = 'D:\SAFE\temp1\RERODEX\stytch-blog-review.md')
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $Target) { Remove-Item -LiteralPath $Target }
Write-Output "Restored absent baseline: $(-not (Test-Path -LiteralPath $Target))"
