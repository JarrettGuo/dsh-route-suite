# VERIFIABILITY — dsh-router-standard 效果宣称可验证性

> 本次复测（t15）对仓库宣称的效果数字逐条定级。三类定义：
> **可复现**=本仓库内可用命令/静态检查独立确认；**口径已校准**=原表述与实现不一致，已改代码或改文档使其自洽
> （数字本身仍可能不可复现）；**不可验证**=缺原始材料或付费/实机条件，本仓库无法独立确认——**不默认采信**。

## 1. 可复现（源码/测试层）

| 宣称（来源） | 证据 |
|---|---|
| 分类/档位/persona 选择逻辑 | `cd preset && node --test router.test.mjs` → 27/27 |
| 首轮只给 `phase_begin` + RL persona；promoted 后恢复完整 sections/contexts；plan-mode 段保留 | `node --test router.integration.test.mjs` → 40/40（Cordis mock 重放 claim→assemble→pre-step；含 shadow 保留/水位/fork 继承/snapshotEvents-muted） |
| 三份 `agent.cordis.yml` 的 persona 使用 `prefix` 且通过当前 DSH schema | 实装 `@deepseek-ai/dsh-persona` 0.1.5-rc.3 `Config` 校验（集成测试内，无 DSH 时优雅 skip） |
| promoted 只替换 `deployment:persona-prefix`，`deployment:persona-suffix` 保留 | `router.integration.test.mjs`「DSH persona prefix replaces only prefix and preserves suffix after promotion」 |
| `update_goal` shim 的 `deferContext` 消息带 `id`/`summary`（当前 DSH 要求 identified message） | `router.integration.test.mjs`「goal shim deferred notice carries identified DSH user message」 |
| 源码自检（结构断言） | `node router-standard/router-bootstrap-v34.selftest.mjs` → `SELFTEST PASS` |
| 两个测试文件的项数 | `cd preset && npm test` → 67/67（27 + 40） |

## 2. 口径已校准

| 原表述 | 现状 |
|---|---|
| README「`node --test router.test.mjs  # 11 tests`」 | 实际 27 项；README 已改为 27/40/67 三行命令（F3 同步本文件口径） |
| persona/`text` 键的历史文档与 0.1.5-rc.3 实现不一致 | 三份 YAML 改 `prefix`；README 增「DSH 0.1.5-rc.3 兼容性修复」小节 |

## 3. 不可验证（缺原始材料 / 付费条件）

| 宣称（来源） | 原因 |
|---|---|
| Flash + w7+锚 → **96% 路由、100% 单任务完成**（P23；README） | probe 原始结果未入库：`preset/probe/` 仅 `README.md` + `cot-lexicon.md`，无脚本/JSON；样本 n=2-5；未提供模型 build/凭据/成本与授权，本次未调用付费 API |
| Pro w6c → **24/24 = 100% 路由**（P24；README） | 同上 |
| P13/P14「远距离加速衰减 / 近距离零衰减」（`docs/blog.md`、`docs/experiments.md`） | 同上；且 `docs/experiments.md` 自述 n=2-3，作者也提示"96% 与 88% 可能是同一次采样波动" |
| P30「depth **+12%**、收敛 8.0 vs 8.3 步、3/3 完成」 | 同上（n 极小，无原始 JSON） |
| 反跑题锚「reasoning tokens 0.0-0.3%」 | 同上 |
| P21 相关链 46-63%（guidance 在相关任务为负） | 同上；作者已披露 probe 工具结果是信息空洞的 fixture，可能放大跳过读取率 |
| 「3D 场景防衰退对比」 | 跨仓库引用 graded `docs/COMPARE.md`：原始会话 JSONL 未发布、A（分段）与 C（未分段）口径不同——该文件已标注不可复算 |
| README 的性能/缓存类数字（如 92-94% 命中） | 属 injector 侧历史 CHANGELOG 表述，本任务范围内无原始测量材料 |

## 4. 复现命令（本仓库内可执行的）

```sh
cd preset && npm test                              # 67/67
node router-standard/router-bootstrap-v34.selftest.mjs   # SELFTEST PASS
cd ../graded && npm test                           # 64/64（需 @deepseek-ai/schemastery）
node scripts/measure.mjs --selftest                # SELFTEST OK
node scripts/e2e-3.1.mjs                           # 全链 dogfood：exit 0、隔离 TMP DSH_HOME、离线
```

> 均不触网、不部署、不调用模型 API；`graded/scripts/e2e-develop.mjs`、`e2e-v4.mjs` 会请求现用
> `127.0.0.1:3080` 实例，**不得运行**（见 `graded/docs/VERIFIABILITY.md`）。
