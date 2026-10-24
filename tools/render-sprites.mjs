// Renders every Keloqz pose to a horizontal PNG strip (1×) plus sprites.json,
// which the Swift app plays. Node built-ins only.
//
//   node tools/render-sprites.mjs        → Sources/Keloqz/Resources/sprites/

import { mkdir, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { crc32, deflateSync } from 'node:zlib'

import { HEIGHT, POSES, renderFrame } from '../art/keloqz.js'

function chunk(type, data) {
  const head = Buffer.alloc(8)
  head.writeUInt32BE(data.length, 0)
  head.write(type, 4, 'ascii')
  const crc = Buffer.alloc(4)
  crc.writeUInt32BE(crc32(Buffer.concat([head.subarray(4), data])), 0)
  return Buffer.concat([head, data, crc])
}

function encodePng(width, height, rgba) {
  const ihdr = Buffer.alloc(13)
  ihdr.writeUInt32BE(width, 0)
  ihdr.writeUInt32BE(height, 4)
  ihdr[8] = 8 // bit depth
  ihdr[9] = 6 // RGBA
  const raw = Buffer.alloc(height * (width * 4 + 1))
  for (let y = 0; y < height; y++) {
    raw[y * (width * 4 + 1)] = 0
    raw.set(rgba.subarray(y * width * 4, (y + 1) * width * 4), y * (width * 4 + 1) + 1)
  }
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ])
}

export async function renderAll(outDir) {
  await mkdir(outDir, { recursive: true })
  const info = {}
  for (const [pose, spec] of Object.entries(POSES)) {
    const stripWidth = spec.width * spec.frames
    const strip = new Uint8ClampedArray(stripWidth * HEIGHT * 4)
    for (let f = 0; f < spec.frames; f++) {
      const { rgba } = renderFrame(pose, f)
      for (let y = 0; y < HEIGHT; y++)
        strip.set(rgba.subarray(y * spec.width * 4, (y + 1) * spec.width * 4), (y * stripWidth + f * spec.width) * 4)
    }
    await writeFile(join(outDir, `${pose}.png`), encodePng(stripWidth, HEIGHT, strip))
    info[pose] = { frames: spec.frames, width: spec.width, height: HEIGHT, fps: spec.fps }
  }
  await writeFile(join(outDir, 'sprites.json'), JSON.stringify(info, null, 2) + '\n')
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  await renderAll(fileURLToPath(new URL('../Sources/Keloqz/Resources/sprites', import.meta.url)))
}
