# VERIFIABILITY — 文档可复核性总表

> 原则（research 验收）：每条断言给出**来源**（文档/代码/会话）、**证据**（数值/位置）、**复现路径**（可执行）。
> 抽查由独立红队执行（见 README 的 redteam 记录）。

## README.md（4 断言）

| # | 断言 | 来源 | 证据 | 复现路径 |
|---|---|---|---|---|
| R1 | 6 工具清单与实测一致 | README「工具（6）」 | 6 行工具表 | `gh api repos/yjh051108/dsh-routing-suite/git/trees/main?recursive=1`（graded/src/tools.js 内 6 个 `export function*Definition`） |
| R2 | 全链 7 步 | README「全链」 | 7 行流程 | 走一遍：`/graded` 触发 → commit_star → edit_plan(L1/L2) → lock ×2 → mark_task（见 docs/DATA.md f0855822 链） |
| R3 | 测试 64 项 | README「开发与测试」 | 64/64（离线装入缓存的 schemastery 3.18.2 后） | `cd graded && npm install && npm test`（dependencies 声明 schemastery ^3.18.2；mode-state/tools/inject-text/measure 四测试文件） |
| R4 | 装配命令占位符 | README「装配」 | `<NPM_GLOBAL>/<DSH_HOME>/<PLUGIN_DIR>` | 换真实路径执行 `dsh plugin --profile web add <PLUGIN_DIR>` |

## ARCHITECTURE.md（4 断言）

| # | 断言 | 来源 | 证据 | 复现路径 |
|---|---|---|---|---|
| A1 | 状态机 7 态 | ARCHITECTURE §1 | off→brainstorm→l1-edit→l2-edit→review→develop→final | `src/mode-state.js`：`STAGES` 枚举+`onLockL1/onLockL2/onReviewApproved` 转换（`node --test tests/mode-state.test.mjs`） |
| A2 | 三通道时序 | ARCHITECTURE §3 | steer/followup/splice 表 | `src/index.js`：`agent.steer`（tools.js lock 分支）/`agent.followup`（mark 分支）/`spliceInjection`（pre-step）；测试 `tests/tools.test.mjs`「锁 L2 → 进入 review」 |
| A3 | 幂等键先注后键 | ARCHITECTURE §3 | registerInjected 后 splice 跳过 | `src/tools.js`（steer 成功→注册键）；`src/index.js`（`injected.has` 检查）；审计 `uniqueRate=1`（f0855822） |
| A4 | 状态磁盘单轨 | ARCHITECTURE §1 | loadState/saveState 唯一权威 | `src/mode-state.js` stateDirFor（`join(os.homedir(),'.dsh','graded-state')`）+ `git grep -n "loadState" grad-ed/src` — 无内存副本 |

## THEORY.md（4 断言）

| # | 断言 | 来源 | 证据 | 复现路径 |
|---|---|---|---|---|
| T1 | 线性注意力四条文献真实 | THEORY §文献 | Katharopoulos ICML2020 等 4 篇 | 公开核对：arXiv（2006.16236 / 2106.09685 / 1706.03762 / 1810.04805） |
| T2 | 映射表 3 条有命中证据 | THEORY §机制映射表 | 3 行映射（线性/双边/懈怠） | 复现：`f0855822` 审计端点（`/graded-mode/api/audit` 的 uniqueRate=1）；`npm test` 红队门用例 |
| T3 | jspace 未映射（占位） | THEORY §3 | 「无映射——占位」行 | 全库 `grep -n jspace` 仅 THEORY/DATA 出现（无虚假映射） |
| T4 | 引用-证据对 6 条 | THEORY §引用 | 6 行表格 | 对照 THEORY 表逐一下载/执行（test 用例名→`npm test` 单跑） |

## DATA.md（4 断言）

| # | 断言 | 来源 | 证据 | 复现路径 |
|---|---|---|---|---|
| D1 | 三会话指标数值（作者报告，尚不可独立复核） | DATA §1 | 637/639 工具、36/31 标定、75 `read_image` 调用 | 缺原始会话包；公开脚本只支持对持有的 JSONL 复核事件级计数，不计截图产出 |
| D2 | 懈怠强度表（作者报告，尚不可独立复核） | DATA §2 | 781d16c5 后段 1 工具/0 读图 | 公开脚本按全事件三等分而非焦点注入→打卡小类分段；需原始事件与独立逐项统计实现 |
| D3 | 审计口径数值 | DATA §4 | focus=22/check=7/uniqueRate=1 | 会话运行期 `GET /graded-mode/api/audit`（f0855822） |
| D4 | 零敏感原文 | DATA 合规声明 | 两轮红队 0 命中 | 红队审计记录（本仓库审计声明）；黑名单扫描脚本可复用 |

**抽查范围**：红队抽 ≥4 条（R1/R3/A2/T2/D3 至少），复现路径可执行性判定。

## 效果数字分类（本次复测 · t15）

> 三类定义：**可复现**=本仓库内可用命令/静态检查独立确认；**口径已校准**=原表述与实现不一致，
> 已改代码或改文档使其自洽（数字本身仍可能不可复现）；**不可验证**=缺原始材料或付费/实机条件，
> 本仓库无法独立确认，**不默认采信**。

| 宣称（来源） | 类别 | 证据 / 原因 |
|---|---|---|
| 工具清单 6 个（README「工具（6）」） | **可复现** | `graded/src/tools.js` 6 个 `*Definition`（commit_star/edit_plan/lock_stage/mark_task/redteam_verdict/revise_do）；`tests/tools.test.mjs` 断言注册名与 schema |
| 全链 7 步（README「全链（7 步）」） | **可复现** | `node scripts/e2e-3.1.mjs` → exit 0、`E2E OK（隔离目录已清理）`：隔离 TMP `DSH_HOME`、纯本地（无 fetch/模型调用），覆盖 触发→脑暴→commit_star→L1→锁→L2→锁→审核→注入→组收官→finalCheck→audit；另有 `tests/mode-state.test.mjs` 状态转换断言 |
| 测试 64 项（README「开发与测试」） | **可复现** | `cd graded && npm test` → 64/64（mode-state/tools/inject-text/measure） |
| `measure.mjs` 事件级计数 + 事件索引三等分；`tools` 不含 `mark_task` | **可复现** | `node scripts/measure.mjs --selftest`；`scripts/measure.test.mjs` 断言段内工具数之和 = `tools` |
| README「测试 62 项」旧表述 | **口径已校准** | README 与 VERIFIABILITY R3 已改为 64 项（含新增 measure 测试文件） |
| C 链"75 张截图" | **口径已校准** | 实为 75 次 `read_image` **调用**（≠截图产出数）；DATA.md/STUDY.md/COMPARE.md 已改口径 |
| C 链"全程均匀/无衰减" | **不可验证** | 未分段测量（仅总量 + 24/24 打卡）；COMPARE.md §2/§3 已标注，且 A（分段）与 C（未分段）口径不同 |
| 三会话数字：637/639 工具、36/31 标定、18/75 读图、2 红队 pass、7 委派（DATA §1、COMPARE §1） | **不可验证** | 原始会话 JSONL 未随仓库发布；脚本只对持有者自己的 JSONL 复算事件级计数 |
| 懈怠强度表（DATA §2）的 A/B 前后段值（26/1 工具、15/0 读图等） | **不可验证** | 逐小类口径未在公开脚本中实现；原始事件缺失 |
| 审计端点数值 focus=22 / check=7 / uniqueRate=1（DATA §4） | **不可验证（代码路径可静态核对）** | 数值来自 f0855822 实机会话，未采录；`/graded-mode/api/audit` 代码路径存在（`src/index.js`） |
| "两轮红队 0 命中"（DATA 合规声明） | **不可验证** | 仅审计声明，无脱敏记录/可重放产物 |
| `scripts/e2e-3.1.mjs` 全链 dogfood | **可复现** | 本次已运行：exit 0、无网络/无模型调用；仅写 TMP `DSH_HOME` 并在结束时删除（`~/.dsh/graded-state` 未生成）。其 audit 输出（`l2-guidance:1`/`review-pending:1`/`uniqueRate:1`）是 dogfood 运行值，**不等于** DATA §4 的 f0855822 历史值 |
| `scripts/e2e-develop.mjs` / `e2e-v4.mjs` | **不可验证（禁止运行）** | 硬编码 `http://127.0.0.1:3080`（现用 GUI）且 `USERPROFILE` 回退路径——会向在用实例建会话/发模型请求，本任务明确不运行 |

**结论**：本仓库可本地独立确认的只有**代码/测试层**（工具数、状态机、注入逻辑、测试套件、测量脚本口径）；
所有**会话效果数字**（含 96%/100% 类收敛与衰减对比）均属作者报告，原始材料未随仓库发布，判定为**不可验证**。

