# 把一个版本打成一个 zip：内核 + 该版本自己的 bench 用例与实测 + 版本文档
#
# 用法:  .\tools\build-dist.ps1
# 产出:  dist\<id>.zip       一个版本 = 一个自包含板块
#        dist\manifest.json 全部包的索引（本脚本只重建 $map 里的包，其它包与 manifest 条目保留）

param(
  [string]$Model = ""
)

$ErrorActionPreference = "Stop"
$root  = Split-Path $PSScriptRoot -Parent
$dist  = Join-Path $root "dist"
$tmp   = Join-Path ([IO.Path]::GetTempPath()) ("rerodex-dist-" + [guid]::NewGuid().ToString("N").Substring(0,8))
$kdir  = Join-Path $root "kernels"
$bench = Join-Path $root "bench"

$res   = Get-Content (Join-Path $root "docs\results.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$limit = [int]$res.limit_bytes
if(-not $Model){ $Model = $res.model_default }

New-Item -ItemType Directory -Force -Path $dist, $tmp | Out-Null

$map = [ordered]@{
  "v1"          = "armor-seed.md"
  "v2-hardcase" = "armor-seed.v2-hardcase.md"
  "v3-negative" = "armor-seed.v3-negative.md"
  "iter2"       = "iter2.md"
  "bak-1"       = "archive\bak-1.md"
  "bak-2"       = "archive\bak-2.md"
  "bak-3"       = "archive\bak-3.md"
  "bak-4"       = "archive\bak-4.md"
}

$tpl = @'
# {ID}

一个版本板块：内核 + 这一版自己的 bench + 实测结果。

- 内核字节: {BYTES} / {LIMIT}（余 {HEADROOM}）
- kernel.md sha256: `{SHA}`
- 路线: {APPROACH}　模型: {MODEL}　状态: {STATUS}
- 迭代自: {PARENT}

## 这一版的 bench

{BENCH_DESC}

{BENCH_TABLE}

## 实测结论

{SUMMARY}

## 包内结构

{PKG_STRUCT}

判据跟着版本走：不同版本用例集与阈值不同，所以 bench 必须随包分发，不能共用全局那一份。

## 复跑这一版

    .\bench\run-bench.ps1 -Kernel <解压目录>\kernel.md -CasesFile <解压目录>\bench\cases.json

`run-bench.ps1` 在仓库 `bench/` 下，不随包分发。

## 用法

    codex.cmd exec -c "model_instructions_file=<解压目录>\kernel.md" --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check "你的原话"

`kernel.md` 是唯一有效载荷。版本身份以 sha256 为准，不以文件名为准——改名不影响，内容一改哈希就变。
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
    $v = [pscustomobject]@{ approach="unknown"; model="untested"; status="untested"; parent=$null; date=$null; bench=$null; measured=$(New-Object psobject) }
  }

  $vmodel = if($v.model){ $v.model } else { $Model }
  $parent = if($v.parent){ $v.parent } else { "无（初版）" }

  # ---- bench：把这一版的用例与结果读进来 ----
  $benchDesc  = "本版无对应 bench（早期迭代，未单独实测）。"
  $benchTable = ""
  $summary    = "- 未单独实测"
  $benchMeta  = $null
  $casesDst   = $null
  $resultsDst = $null

  if($v.bench -and $v.bench.cases){
    $casesSrc   = Join-Path $bench $v.bench.cases
    $resultsSrc = Join-Path $bench $v.bench.results

    if(Test-Path $casesSrc){
      $cases = Get-Content $casesSrc -Raw -Encoding UTF8 | ConvertFrom-Json
      $benchDesc = "$($cases.meta.name)。$($cases.meta.philosophy)"

      $lookup = @{}
      if(Test-Path $resultsSrc){
        $rr = Get-Content $resultsSrc -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach($r in $rr.cases){ $lookup[$r.id] = $r }
      }

      $lines = @("| 用例 | 原话 | 结果 | exec | 文件 |", "|---|---|---|---|---|")
      foreach($cc in $cases.cases){
        $task = $cc.task
        if($task.Length -gt 34){ $task = $task.Substring(0, 34) + "…" }
        $task = $task.Replace("|", "\|")
        $r = $lookup[$cc.id]
        $st = if($r){ $r.status } else { "未记录" }
        $ex = if($r){ $r.exec } else { "-" }
        $fl = if($r){ $r.files } else { "-" }
        $lines += "| $($cc.id) | $task | **$st** | $ex | $fl |"
      }
      $benchTable = $lines -join "`n"

      if(Test-Path $resultsSrc){
        $rr2 = Get-Content $resultsSrc -Raw -Encoding UTF8 | ConvertFrom-Json
        $summary = "- 用例 $($rr2.summary.cases) 例：通过 $($rr2.summary.pass)、降级 $($rr2.summary.downgrade)、拒绝 $($rr2.summary.refuse)"
        if($v.measured -and $v.measured.note){ $summary += "`n- $($v.measured.note)" }
        $resultsDst = $resultsSrc
      }
      $casesDst = $casesSrc
      $benchMeta = [ordered]@{
        cases = $v.bench.cases; results = $v.bench.results
        count = @($cases.cases).Count
        ids   = @($cases.cases | ForEach-Object { $_.id })
      }
    }
  } elseif($v.measured -and $v.measured.note){
    $summary = "- $($v.measured.note)"
  }

  # 包内结构按实际装进 zip 的内容生成，不写死
  $struct = @(
    "    kernel.md              唯一有效载荷",
    "    meta.json              机器可读身份（sha256 / 字节 / 路线 / 模型 / 实测）"
  )
  if($casesDst){
    $struct += "    bench\cases.json       这一版实际用的用例与判据"
    if($resultsDst){ $struct += "    bench\results.json     这一版的实测结果" }
  }
  if($v.extras){
    foreach($k in $v.extras.PSObject.Properties.Name){
      if(Test-Path (Join-Path $root $v.extras.$k)){ $struct += ("    " + $k.Replace("/","\") + "       随包附加") }
    }
  }
  $pkgStruct = $struct -join "`n"

  $readme = $tpl
  $readme = $readme.Replace("{ID}", $id).Replace("{BYTES}", "$bytes").Replace("{LIMIT}", "$limit")
  $readme = $readme.Replace("{HEADROOM}", "$($limit - $bytes)").Replace("{SHA}", $sha)
  $readme = $readme.Replace("{APPROACH}", "$($v.approach)").Replace("{MODEL}", "$vmodel")
  $readme = $readme.Replace("{STATUS}", "$($v.status)").Replace("{PARENT}", "$parent")
  $readme = $readme.Replace("{BENCH_DESC}", $benchDesc).Replace("{BENCH_TABLE}", $benchTable).Replace("{SUMMARY}", $summary)
  $readme = $readme.Replace("{PKG_STRUCT}", $pkgStruct)

  # ---- 组装板块 ----
  $stage = Join-Path $tmp $id
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  Copy-Item $src (Join-Path $stage "kernel.md") -Force
  Set-Content (Join-Path $stage "README.md") -Value $readme -Encoding UTF8

  $meta = [ordered]@{
    id = $id; file = "kernel.md"; bytes = $bytes; limit = $limit; headroom = $limit - $bytes
    sha256 = $sha; approach = $v.approach; model = $vmodel; status = $v.status
    parent = $v.parent; date = $v.date; bench = $benchMeta; measured = $v.measured
    generator = "tools/build-dist.ps1"
  }
  $meta | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $stage "meta.json") -Encoding UTF8

  if($casesDst){
    $bd = Join-Path $stage "bench"
    New-Item -ItemType Directory -Force -Path $bd | Out-Null
    Copy-Item $casesDst (Join-Path $bd "cases.json") -Force
    if($resultsDst){ Copy-Item $resultsDst (Join-Path $bd "results.json") -Force }
  }

  # 同版本附加文件（如 iter2 的同轮备选内核），在 results.json 里按 包内路径 -> 仓库路径 声明
  if($v.extras){
    foreach($k in $v.extras.PSObject.Properties.Name){
      $dstRel = $k; $srcRel = $v.extras.$k
      $srcP = Join-Path $root $srcRel
      if(Test-Path $srcP){
        $dstP = Join-Path $stage $dstRel
        New-Item -ItemType Directory -Force -Path (Split-Path $dstP -Parent) | Out-Null
        Copy-Item $srcP $dstP -Force
      } else { Write-Warning "$id extras 缺文件: $srcRel" }
    }
  }

  $zipName = "$id.zip"
  $zipPath = Join-Path $dist $zipName
  Compress-Archive -Path $stage -DestinationPath $zipPath -CompressionLevel Optimal -Force

  $packages += [ordered]@{
    id = $id; zip = $zipName; bytes = $bytes; sha256 = $sha
    zip_bytes = (Get-Item $zipPath).Length
    zip_sha256 = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()
    approach = $v.approach; model = $vmodel; status = $v.status
    bench = $benchMeta; measured = $v.measured
  }

  $benchTag = if($benchMeta){ "bench=$($benchMeta.count)例" } else { "bench=无" }
  Write-Output ("  {0,-12} kernel {1,5}B  {2,-12} -> {3} ({4}B)" -f $id, $bytes, $benchTag, $zipName, (Get-Item $zipPath).Length)
}

# 合并旧 manifest：$map 里重建的包用新数据，其余条目原样保留（如手工打的版本）
$oldPackages = @()
$mfPath = Join-Path $dist "manifest.json"
if(Test-Path $mfPath){
  try {
    $old = Get-Content $mfPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($p in @($old.packages)){ if(-not $map.Contains($p.id)){ $oldPackages += $p } }
  } catch { Write-Warning "旧 manifest 解析失败，全部重建" }
}

$manifest = [ordered]@{
  project = "RERODEX"
  generated = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
  unit = "一个版本 = 一个 zip（内核 + 该版本自己的 bench 用例与实测 + 版本文档）"
  limit = $limit
  model = $Model
  packages = @($packages + $oldPackages)
}
$manifest | ConvertTo-Json -Depth 10 | Set-Content $mfPath -Encoding UTF8

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "dist/manifest.json 已生成：$($packages.Count) 个重建包 + $($oldPackages.Count) 个保留包"
