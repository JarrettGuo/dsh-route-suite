import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'

const script = fileURLToPath(new URL('./measure.mjs', import.meta.url))

test('event thirds exclude marks consistently and tolerate malformed mark arguments', () => {
  const dir = mkdtempSync(join(tmpdir(), 'graded-measure-'))
  try {
    const file = join(dir, 'events.jsonl')
    const names = ['read_image', 'mark_task', 'pwsh', 'mark_task', 'redteam_verdict', 'read_image']
    const rows = names.map((name, index) => ({
      type: 'tool/call',
      data: { name, arguments: name === 'mark_task' && index === 3 ? '{bad' : JSON.stringify({ level: 'L2', title: 'Item' }) },
    }))
    writeFileSync(file, rows.map((row) => JSON.stringify(row)).join('\n') + '\n')
    const run = spawnSync(process.execPath, [script, file, '--json'], { encoding: 'utf8' })
    assert.equal(run.status, 0, run.stderr)
    const result = JSON.parse(run.stdout)
    assert.equal(result.tools, 4)
    assert.equal(result.marks, 2)
    assert.equal(result.readImages, 2)
    assert.equal(result.redteam, 1)
    assert.equal(result.segments.reduce((sum, segment) => sum + segment.tools, 0), result.tools)
    assert.deepEqual(result.segments.map((segment) => segment.tools), [1, 1, 2])
  } finally {
    rmSync(dir, { recursive: true, force: true })
  }
})
