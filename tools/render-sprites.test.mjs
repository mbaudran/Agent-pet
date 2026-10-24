import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdtemp, readFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { inflateSync } from 'node:zlib'

import { POSES, renderFrame } from '../art/keloqz.js'
import { renderAll } from './render-sprites.mjs'

/** Minimal decoder for the PNGs we write: 8-bit RGBA, filter 0 on every row. */
function decodePng(png) {
  let at = 8, width = 0, height = 0
  const idat = []
  while (at < png.length) {
    const len = png.readUInt32BE(at)
    const type = png.toString('ascii', at + 4, at + 8)
    const data = png.subarray(at + 8, at + 8 + len)
    if (type === 'IHDR') { width = data.readUInt32BE(0); height = data.readUInt32BE(4) }
    if (type === 'IDAT') idat.push(data)
    at += 12 + len
  }
  const raw = inflateSync(Buffer.concat(idat))
  const rgba = new Uint8ClampedArray(width * height * 4)
  for (let y = 0; y < height; y++) {
    assert.equal(raw[y * (width * 4 + 1)], 0, 'filter byte')
    rgba.set(raw.subarray(y * (width * 4 + 1) + 1, (y + 1) * (width * 4 + 1)), y * width * 4)
  }
  return { width, height, rgba }
}

function cropFrame(strip, frame, width) {
  const out = new Uint8ClampedArray(width * strip.height * 4)
  for (let y = 0; y < strip.height; y++) {
    const from = (y * strip.width + frame * width) * 4
    out.set(strip.rgba.subarray(from, from + width * 4), y * width * 4)
  }
  return out
}

test('every strip decodes to the frames keloqz.js draws', async () => {
  const out = await mkdtemp(join(tmpdir(), 'sprites-'))
  await renderAll(out)
  const info = JSON.parse(await readFile(join(out, 'sprites.json'), 'utf8'))
  for (const [pose, p] of Object.entries(POSES)) {
    assert.deepEqual(info[pose], { frames: p.frames, width: p.width, height: 48, fps: p.fps })
    const strip = decodePng(await readFile(join(out, `${pose}.png`)))
    assert.equal(strip.width, p.width * p.frames)
    assert.equal(strip.height, 48)
    for (const f of [0, p.frames - 1]) assert.deepEqual(cropFrame(strip, f, p.width), renderFrame(pose, f).rgba)
  }
})

test('idle blinks on frame 6 and folds the ear back up on frame 10', () => {
  assert.notDeepEqual(renderFrame('idle', 6).rgba, renderFrame('idle', 0).rgba)
  assert.notDeepEqual(renderFrame('idle', 10).rgba, renderFrame('idle', 0).rgba)
})
