#!/usr/bin/env node
/**
 * injector-known-slots.test.mjs — KNOWN_SLOTS 白名单与本机 DSH 实际 slot 集的守护测试（F2 固化）。
 *
 * 口径来源：t5 复测独立提取本机 DSH 0.1.5-rc.3 全部 @deepseek-ai/dsh-client-* 编译产物中
 * `slots.register` 的真实 slot 名（59 个）→ test/fixtures/actual-slots-rc3.txt。
 * 另有两个**声明面** slot（宿主 renderSlot 声明、运行时可被插件注册）：
 *   - settings.models.provider-card（dsh-client-ui-settings-models renderSlot）
 *   - conversation.chat.assistant-actions（dsh-client-ui-chat renderSlot）
 * t5 复测发现 KNOWN_SLOTS 缺 9 个真实 slot、含 6 个 rc.3 不存在的陈旧名，且 unknown-slot
 * 告警曾被并入 block 列表阻断合法插件注入——本测试三面守护防回归。
 */
import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const here = dirname(fileURLToPath(import.meta.url))
const repo = dirname(here)
const src = readFileSync(join(repo, 'injector', 'src', 'index.ts'), 'utf8')

function extractKnownSlots() {
  const m = src.match(/const KNOWN_SLOTS = \[([\s\S]*?)\]/)
  assert.ok(m, 'KNOWN_SLOTS declaration found in injector/src/index.ts')
  return [...m[1].matchAll(/'([^']+)'/g)].map((x) => x[1])
}

test('F2: KNOWN_SLOTS covers every register-site slot measured on rc.3', () => {
  const actual = readFileSync(join(repo, 'test', 'fixtures', 'actual-slots-rc3.txt'), 'utf8')
    .split('\n').map((l) => l.trim()).filter(Boolean)
  const known = new Set(extractKnownSlots())
  const missing = actual.filter((a) => !known.has(a))
  assert.deepEqual(missing, [], 'KNOWN_SLOTS 缺失 rc.3 真实 slot：' + missing.join(', '))
})

test('F2: KNOWN_SLOTS no longer contains the 6 stale rc.3 names', () => {
  const stale = [
    'conversation.chat.assistant', 'conversation.chat.turn', 'conversation.hero.agent',
    'conversation.hero.workspace.directory', 'settings.models.provider', 'sidebar.workspaces.directory',
  ]
  const known = new Set(extractKnownSlots())
  const kept = stale.filter((s) => known.has(s))
  assert.deepEqual(kept, [], 'rc.3 不存在的陈旧 slot 名仍在白名单：' + kept.join(', '))
})

test('F2: declaration-face slots (renderSlot-declared) stay whitelisted', () => {
  const known = new Set(extractKnownSlots())
  for (const s of ['settings.models.provider-card', 'conversation.chat.assistant-actions']) {
    assert.ok(known.has(s), `声明面 slot 缺失：${s}（宿主 renderSlot 声明，插件可注册）`)
  }
})

test('F2: unknown-slot findings are warn-only — not merged into the inject/restore block list', () => {
  // clientSkeletonProblems 的两个消费点都把 unknown slot 走独立警告通道（clientUnknownSlotProblems）
  assert.ok(!/clientSkeletonProblems\([^)]*\)[\s\S]{0,120}unknownSlotRegisters/.test(src),
    '骨架校验不得内联 unknown slot 判定')
  assert.ok(src.includes('const slotWarn = clientUnknownSlotProblems('),
    '两个消费点必须把 unknown slot 走 clientUnknownSlotProblems 警告通道')
  assert.ok(!/const block = \[\.\.\.problems, \.\.\.fresh\.block, \.\.\.slotWarn\]/.test(src) &&
    !/\.\.\.slotWarn\]\n      if \(block/.test(src),
    'slotWarn 不得并入 block 数组（阻断列）')
})
