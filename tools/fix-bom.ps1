# 给所有 .ps1 补回 UTF-8 BOM
#
# 为什么需要：edit 工具会剥掉 BOM，PowerShell 5.1 读无 BOM 的 UTF-8 时按 ANSI 解码，
# 中文注释变乱码，字符串里的引号/括号失配，报 "Unexpected token" / "missing terminator"。
# 改完任何含非 ASCII 字符的 .ps1 都要跑一次。

param([switch]$Quiet)

$root = Split-Path $PSScriptRoot -Parent
$bom  = New-Object Text.UTF8Encoding $true
$nobom = New-Object Text.UTF8Encoding $false
$fixed = 0
$clean = 0

foreach($f in (Get-ChildItem $root -Filter *.ps1 -Recurse -File)){
  $bytes = [IO.File]::ReadAllBytes($f.FullName)
  $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)

  # 判断是否含非 ASCII
  $text = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
  $nonAscii = [bool]($text -match '[^\x00-\x7F]')

  if($nonAscii -and -not $hasBom){
    [IO.File]::WriteAllText($f.FullName, $text, $bom)
    $fixed++
    if(-not $Quiet){ Write-Output ("  补 BOM  {0}" -f $f.FullName.Substring($root.Length + 1)) }
  } else {
    $clean++
  }

  # 顺带校验语法
  try { $null = [scriptblock]::Create($text) }
  catch {
    Write-Warning ("语法错误 {0}: {1}" -f $f.Name, $_.Exception.Message)
  }
}

if(-not $Quiet){
  Write-Output ""
  Write-Output ("已补 {0} 个，正常 {1} 个" -f $fixed, $clean)
}
