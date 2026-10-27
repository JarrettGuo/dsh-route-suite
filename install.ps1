# dsh-routing-suite 一键安装（Windows PowerShell）
# 步骤：1) 装配注入器  2) 安装 router-standard / router-spec / router-react 预设  3) 安装 graded（分级模式）  4) 提示重启
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# DSH_HOME 优先（#139 文档级修复 / G6）：部署环境 homedir 可能与 DSH_HOME 不一致，
# 写死 $env:USERPROFILE\.dsh 会在显式设置 DSH_HOME 时装到错误位置——与 dsh-home-paths
# 的解析（显式配置 > $DSH_HOME > ~/.dsh）同口径。
$envDshHome = $env:DSH_HOME
if (-not $envDshHome) { $envDshHome = Join-Path $env:USERPROFILE '.dsh' }
# FORCE=1：graded 已安装时也重新装配（拿到仓库内新版 tgz）
$force = ($env:FORCE -eq '1')

Write-Host '=== [1/4] 装配注入器 ===' -ForegroundColor Cyan
$injector = Join-Path $root 'injector'
if (-not (Test-Path (Join-Path $injector 'lib\index.js'))) {
  # 全新 clone 没有 lib/（构建产物不入库）。github: 装配（方式 B）会在安装时由
  # prepare 钩子自动构建；本地目录装配若构建不可行，请改用 Release tgz（方式 A）。
  Write-Host 'injector/lib 缺失——尝试 npm install 触发 prepare 钩子构建（若私有 peer 拉取失败会自动跳过）...' -ForegroundColor Yellow
  Push-Location $injector
  try {
    & npm install --no-audit --no-fund 2>&1 | Out-Host
  } catch {
    Write-Host 'npm install 失败（可忽略）' -ForegroundColor DarkGray
  } finally {
    Pop-Location
  }
  if (-not (Test-Path (Join-Path $injector 'lib\index.js'))) {
    Write-Host '自动构建不可行——注入器请改用以下方式装配：' -ForegroundColor Yellow
    Write-Host '  A. Release tgz（预构建，推荐）：https://github.com/yjh051108/dsh-super-injector/releases' -ForegroundColor Yellow
    Write-Host '  B. github: 装配（prepare 钩子自动构建）：dsh plugin --profile web add github:yjh051108/dsh-super-injector' -ForegroundColor Yellow
  } else {
    Write-Host 'injector/lib 构建完成' -ForegroundColor Green
  }
}
# dsh CLI 可能不在 PATH（用 npx @deepseek-ai/dsh web 启动的场景）；优先 dsh，fallback 到 npx
$dshCmd = Get-Command dsh -ErrorAction SilentlyContinue
if (Test-Path (Join-Path $injector 'lib\index.js')) {
  if ($dshCmd) {
    & dsh plugin --profile web add $injector 2>&1 | Out-Host
  } else {
    & npx '@deepseek-ai/dsh' plugin --profile web add $injector 2>&1 | Out-Host
  }
  Write-Host '注入器已装配（重启后由 bundles 接管）' -ForegroundColor Green
}

Write-Host '=== [2/4] 安装 router presets ===' -ForegroundColor Cyan
# DSH >=0.2：agent-preset-registry 不再扫描 $DSH_HOME\.agent-presets\，预设由
# preset\ 这个 bundle 包的 patch（preset\bundle\*.patch.yml）声明——装配 bundle 即可。
$presetRoot = Join-Path $root 'preset'
$presets = @('router-standard', 'router-spec', 'router-react')
if ($dshCmd) {
  & dsh plugin --profile web add $presetRoot 2>&1 | Out-Host
} else {
  & npx '@deepseek-ai/dsh' plugin --profile web add $presetRoot 2>&1 | Out-Host
}

# 自检：bundle patch 就位 + profile 已登记 dsh-router-standard bundle
Write-Host '=== 自检预设 bundle ===' -ForegroundColor Cyan
foreach ($name in $presets) {
  $check = Join-Path $presetRoot (Join-Path 'bundle' "$name.patch.yml")
  if (Test-Path $check) {
    Write-Host "OK: $name -> bundle\$name.patch.yml 就位" -ForegroundColor Green
  } else {
    Write-Host "FAIL: $name 缺少 bundle patch（$check）——请在 preset\ 下运行 npm run gen:bundle" -ForegroundColor Red
  }
}
$profilePkg = Join-Path $envDshHome 'profiles\web\package.json'
if (-not ((Test-Path $profilePkg) -and (Select-String -Path $profilePkg -Pattern '"dsh-router-standard"' -Quiet))) {
  Write-Host 'FAIL: profile web 的 package.json 未登记 dsh-router-standard bundle——预设不会被 DSH 发现' -ForegroundColor Red
}

Write-Host '=== [3/4] 安装 graded（分级模式，实验组件）===' -ForegroundColor Cyan
$gradedTgz = Join-Path $root 'graded\dsh-external-dsh-graded-mode-0.0.1-rc1.tgz'
$gradedLink = Join-Path $envDshHome 'profiles\web\node_modules\@dsh-external\dsh-graded-mode'
if ((Test-Path (Join-Path $gradedLink 'package.json')) -and -not $force) {
  Write-Host "graded 已安装：$gradedLink（跳过；`$env:FORCE='1' 重新装配）" -ForegroundColor Yellow
} elseif (Test-Path $gradedTgz) {
  # 仓库内预构建发布物（lib/ 已入库），直接 tgz 装配；重启后由 bundles 接管
  if ($dshCmd) {
    & dsh plugin --profile web add $gradedTgz 2>&1 | Out-Host
  } else {
    & npx '@deepseek-ai/dsh' plugin --profile web add $gradedTgz 2>&1 | Out-Host
  }
  Write-Host 'graded 已装配（/分级 on 激活；不激活零痕迹）' -ForegroundColor Green
} else {
  Write-Host "graded tgz 缺失（graded\dsh-external-dsh-graded-mode-0.0.1-rc1.tgz）——跳过（也可从 Release 附件获取后手动 dsh plugin add）" -ForegroundColor Yellow
}

Write-Host '=== [4/4] 完成 ===' -ForegroundColor Cyan
Write-Host '1. 重启 DSH（web 服务）' -ForegroundColor Yellow
Write-Host '2. GUI 新建会话 → 选择 Router Standard / Router Spec (experimental) / Router React' -ForegroundColor Yellow
Write-Host '3. 发任务：生成任务自动 react，维护任务自动 spec，模糊任务进 weak 内路由' -ForegroundColor Yellow
Write-Host '4. 分级模式（可选）：会话内 /分级 on 激活，不激活零痕迹' -ForegroundColor Yellow
Write-Host '5. AI 自优化工具：dev_router_status / dev_router_mode / dev_mode_subagent' -ForegroundColor Yellow
