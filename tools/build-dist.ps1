# 把每个内核版本打成一个自包含的 zip，并生成 manifest.json
#
# 用法:  .\tools\build-dist.ps1
# 产出:  dist\<id>.zip                    单个内核版本包
#        dist\RERODEX-src-<date>.zip      整个项目快照
#        dist\manifest.json               全部包的索引（sha256 / 字节 / 实测）

param(
  [string]$Model = ""
)

$ErrorActionPreference = "Stop"
$root  = Split-Path $PSScriptRoot -Parent
$dist  = Join-Path $root "dist"
$tmp   = Join-Path ([IO.Path]::GetTempPath()) ("rerodex-dist-" + [guid]::NewGuid().ToString("N").Substring(0,8))
$kdir  = Join-Path $root "kernels"

$res   = Get-Content (Join-Path $root "docs\results.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$limit = [int]$res.limit_bytes
if(-not $Model){ $Model = $res.model_default }

if(Test-Path $dist){ Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dist, $tmp | Out-Null

$map = [ordered]@{
  "v1"          = "armor-seed.md"
  "v2-hardcase" = "armor-seed.v2-hardcase.md"
  "v3-negative" = "armor-seed.v3-negative.md"
  "bak-1"       = "archive\bak-1.md"
  "bak-2"       = "archive\bak-2.md"
  "bak-3"       = "archive\bak-3.md"
  "bak-4"       = "archive\bak-4.md"
}

# 单引号 here-string: 不做变量替换、不解析反引号，只留占位符
$tpl = @'
# {ID}

- 字节: {BYTES} / {LIMIT}（余 {HEADROOM}）
- sha256: {SHA}
- 路线: {APPROACH}　模型: {MODEL}　状态: {STATUS}
- 迭代自: {PARENT}

## 实测

{MEASURED}

## 用法

    codex.cmd exec -c "model_instructions_file=.\kernel.md" --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check "你的原话"

`kernel.md` 是唯一有效载荷，`meta.json` 是机器可读的版本身份——**以 sha256 为准，不以文件名为准**。内核对上限 {LIMIT} 字节。

完整机制说明见项目仓库 `docs/MECHANISM.md`。
'@

$packages = @()

foreach($id in $map.Keys){
  $rel = $map[$id]
  $src = Join-Path $kdir $rel
  if(-not (Test-Path $src)){ Write-Warning "缺文件: $rel"; continue }

  $bytes = (Get-Item $src).Length
  $sha   = (Get-FileHash $src -Algorithm SHA256).Hash.ToLower()

  $v = $null
  if($res.versions.PSObject.Properties.Name -contains $id){ $v = $res.versions.$id }
  if(-not $v){
    $v = [pscustomobject]@{ approach="unknown"; model="untested"; status="untested"; parent=$null; date=$null; measured=$(New-Object psobject) }
  }
  $m = $v.measured

  $vmodel = if($v.model){ $v.model } else { $Model }
  $parent = if($v.parent){ $v.parent } else { "无" }

  $measuredText = if($m -and $m.cases){
    "- 用例 $($m.cases) 例：通过 $($m.pass)、降级 $($m.downgrade)、拒绝 $($m.refuse)`n- $($m.note)"
  } elseif($m -and $m.note){
    "- $($m.note)"
  } else {
    "- 未单独实测"
  }

  $readme = $tpl
  $readme = $readme.Replace("{ID}", $id).Replace("{BYTES}", "$bytes").Replace("{LIMIT}", "$limit")
  $readme = $readme.Replace("{HEADROOM}", "$($limit - $bytes)").Replace("{SHA}", $sha)
  $readme = $readme.Replace("{APPROACH}", "$($v.approach)").Replace("{MODEL}", "$vmodel")
  $readme = $readme.Replace("{STATUS}", "$($v.status)").Replace("{PARENT}", "$parent")
  $readme = $readme.Replace("{MEASURED}", $measuredText)

  $meta = [ordered]@{
    id = $id; file = "kernel.md"; bytes = $bytes; limit = $limit; headroom = $limit - $bytes
    sha256 = $sha; approach = $v.approach; model = $vmodel; status = $v.status
    parent = $v.parent; date = $v.date; measured = $m; generator = "tools/build-dist.ps1"
  }

  $stage = Join-Path $tmp $id
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  Copy-Item $src (Join-Path $stage "kernel.md") -Force
  $meta | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $stage "meta.json") -Encoding UTF8
  Set-Content (Join-Path $stage "README.md") -Value $readme -Encoding UTF8

  $zipName = "$id.zip"
  $zipPath = Join-Path $dist $zipName
  Compress-Archive -Path $stage -DestinationPath $zipPath -CompressionLevel Optimal

  $packages += [ordered]@{
    id = $id; zip = $zipName; bytes = $bytes; sha256 = $sha
    zip_bytes = (Get-Item $zipPath).Length
    zip_sha256 = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()
    approach = $v.approach; model = $vmodel; status = $v.status; measured = $m
  }
  Write-Output ("  {0,-12} kernel {1,5}B -> {2} ({3}B)" -f $id, $bytes, $zipName, (Get-Item $zipPath).Length)
}

# 整包快照
$snapStage = Join-Path $tmp "RERODEX"
New-Item -ItemType Directory -Force -Path $snapStage | Out-Null
foreach($item in @("README.md", ".gitignore")){
  $p = Join-Path $root $item
  if(Test-Path $p){ Copy-Item $p $snapStage -Force }
}
foreach($d in @("kernels", "bench", "docs", "tools")){
  $p = Join-Path $root $d
  if(Test-Path $p){ Copy-Item $p $snapStage -Recurse -Force }
}
Get-ChildItem $snapStage -Recurse -Directory -Filter "__pycache__" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$benchOut = Join-Path $snapStage "bench\out"
if(Test-Path $benchOut){ Remove-Item $benchOut -Recurse -Force }

$snapName = "RERODEX-src.zip"
$snapPath = Join-Path $dist $snapName
Compress-Archive -Path $snapStage -DestinationPath $snapPath -CompressionLevel Optimal
Write-Output ("  {0,-12} {1} ({2}B)" -f "snapshot", $snapName, (Get-Item $snapPath).Length)

$manifest = [ordered]@{
  project = "RERODEX"
  generated = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
  limit = $limit
  model = $Model
  snapshot = [ordered]@{ zip = $snapName; zip_bytes = (Get-Item $snapPath).Length; zip_sha256 = (Get-FileHash $snapPath -Algorithm SHA256).Hash.ToLower() }
  packages = $packages
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $dist "manifest.json") -Encoding UTF8

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "dist/manifest.json 已生成：$($packages.Count) 个版本包 + 1 个整包快照"
