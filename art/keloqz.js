// Keloqz, the pixel German Shepherd. The drawing code is the approved mockup
// (brainstorm keloqz-v9.html) moved into a module: pure functions from
// (pose, frame) to an RGBA pixel buffer. The app's warm glow is not drawn here.

export const HEIGHT = 48

// fps: the mockup ticked every 160 ms; play advanced every tick, the other
// poses every third tick (480 ms).
export const POSES = {
  idle: { width: 48, frames: 154, fps: 2.08 },
  play: { width: 64, frames: 8, fps: 6.25 },
  done: { width: 48, frames: 2, fps: 2.08 },
  sleep: { width: 64, frames: 6, fps: 2.08 },
}

const N = HEIGHT
const ROLES = ['_', 'outline', 'dark', 'dark2', 'tan', 'tanL', 'tanS', 'ear', 'eye', 'white', 'nose', 'tongue', 'collar', 'tag', 'mask', 'ball', 'shadow', 'maskL', 'band', 'bandS']
const R = Object.fromEntries(ROLES.map((r, i) => [r, i]))
const PAL = {
  outline: '#140d0b', dark: '#1d1517', dark2: '#3a2a2a', tan: '#a3552a', tanL: '#c97c3a', tanS: '#73391a',
  ear: '#80504a', eye: '#1a0d07', white: '#fff3e0', nose: '#0c0809', tongue: '#e07e98', collar: '#5b5cf0', tag: '#ffffff',
  mask: '#4e3127', maskL: '#7a4122', band: '#d8342c', bandS: '#9a1f1b', ball: '#c9dc45',
}
const SHADOW_RGBA = [0, 0, 0, Math.round(0.35 * 255)]

function painter(buf, W, ox, oy) {
  const set = (x, y, c) => { x = Math.round(x + ox); y = Math.round(y + oy); if (x >= 0 && y >= 0 && x < W && y < N) buf[y * W + x] = R[c] }
  const ell = (cx, cy, rx, ry, c) => {
    for (let y = Math.floor(cy - ry - 1); y <= Math.ceil(cy + ry + 1); y++)
      for (let x = Math.floor(cx - rx - 1); x <= Math.ceil(cx + rx + 1); x++) {
        const dx = (x - cx) / (rx + .5), dy = (y - cy) / (ry + .5)
        if (dx * dx + dy * dy <= 1) set(x, y, c)
      }
  }
  return {
    px: set, ell,
    rect(x, y, w, h, c) { for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) set(x + i, y + j, c) },
    tri(ax, ay, bx, by, cx, cy, c) {
      const e = (x0, y0, x1, y1, x, y) => (x1 - x0) * (y - y0) - (y1 - y0) * (x - x0)
      for (let y = Math.floor(Math.min(ay, by, cy)); y <= Math.ceil(Math.max(ay, by, cy)); y++)
        for (let x = Math.floor(Math.min(ax, bx, cx)); x <= Math.ceil(Math.max(ax, bx, cx)); x++) {
          const w0 = e(bx, by, cx, cy, x, y), w1 = e(cx, cy, ax, ay, x, y), w2 = e(ax, ay, bx, by, x, y)
          if ((w0 >= 0 && w1 >= 0 && w2 >= 0) || (w0 <= 0 && w1 <= 0 && w2 <= 0)) set(x, y, c)
        }
    },
    stroke(x0, y0, r0, x1, y1, r1, c) {
      const n = Math.max(2, Math.ceil(Math.hypot(x1 - x0, y1 - y0) * 2))
      for (let i = 0; i <= n; i++) { const k = i / n, r = r0 + (r1 - r0) * k; ell(x0 + (x1 - x0) * k, y0 + (y1 - y0) * k, r, r, c) }
    },
  }
}

function frontBody(g, wag) {
  g.stroke(32, 44, 2.4, 38.5, 39, 2.4, 'dark')
  g.stroke(38.5, 39, 2.4, 39.5 + wag, 32, 1.8, 'dark')
  g.ell(39.5 + wag, 31.5, 1.3, 1.3, 'dark2')
  g.ell(17, 35, 2.8, 5.5, 'dark'); g.ell(31, 35, 2.8, 5.5, 'dark')
  g.ell(24, 37, 8.5, 8.5, 'tan')
  g.ell(24, 34, 4.5, 5.5, 'tanL')
  for (const [x, y] of [[21, 32], [27, 33], [23, 36], [26, 30], [20, 38], [28, 38]]) g.px(x, y, 'tanS')
  g.rect(18, 39, 4, 7, 'tan'); g.rect(26, 39, 4, 7, 'tan')
  g.rect(22, 41, 1, 5, 'tanS'); g.rect(25, 41, 1, 5, 'tanS')
  g.rect(17, 44, 5, 2, 'tanL'); g.rect(26, 44, 5, 2, 'tanL')
  g.px(19, 45, 'tanS'); g.px(28, 45, 'tanS')
}

function frontHead(g, eyes, tongue, flop) {
  g.stroke(17.5, 12, 4.4, 14, 2.5, 2.2, 'dark')
  g.stroke(17, 11, 2.2, 14.6, 4.5, 1, 'ear')
  if (flop) {
    // right ear folded over at the middle, tip hanging outward
    g.stroke(30.5, 12, 4.4, 33, 7, 3, 'dark')
    g.stroke(33, 7, 3, 37.5, 10.5, 1.7, 'dark')
    g.stroke(31, 11, 2, 32.2, 8.5, 1.2, 'ear')
    g.px(34, 6, 'dark2'); g.px(35, 7, 'dark2')
  } else {
    g.stroke(30.5, 12, 4.4, 34, 2.5, 2.2, 'dark')
    g.stroke(31, 11, 2.2, 33.4, 4.5, 1, 'ear')
  }
  g.ell(24, 18, 11, 9, 'tan')
  g.ell(15.5, 21, 3, 3.5, 'tanL'); g.ell(32.5, 21, 3, 3.5, 'tanL')
  // widow's peak: dark brown fading to rust, dithered at the edges
  g.ell(24, 10.5, 5, 2.3, 'maskL')
  g.ell(24, 10, 3.6, 1.6, 'mask')
  g.stroke(24, 11, 1.6, 24, 13, 1, 'mask')
  g.stroke(24, 13, 1, 24, 15, .5, 'maskL')
  for (const [x, y] of [[19, 11], [29, 11], [21, 12], [27, 12], [23, 15], [25, 14]]) g.px(x, y, 'maskL')
  g.px(22, 13, 'tanS'); g.px(26, 13, 'tanS')
  g.ell(19, 15.6, 2.8, 1.9, 'mask'); g.ell(29, 15.6, 2.8, 1.9, 'mask')
  g.rect(18, 12, 2, 1, 'tanL'); g.rect(29, 12, 2, 1, 'tanL')
  g.ell(24, 22, 4.5, 3.4, 'mask')
  for (const x of [18, 28]) {
    if (eyes === 'open') { g.rect(x, 15, 3, 2, 'eye'); g.px(x, 15, 'white') }
    else if (eyes === 'left') { g.rect(x - 1, 15, 3, 2, 'eye'); g.px(x - 1, 15, 'white'); g.px(x + 2, 16, 'mask') }
    else if (eyes === 'up') { g.rect(x - 1, 14, 3, 2, 'eye'); g.px(x - 1, 14, 'white'); g.px(x + 1, 16, 'mask') }
    else if (eyes === 'blink') g.rect(x, 16, 3, 1, 'eye')
    else if (eyes === 'happy') { g.px(x, 16, 'eye'); g.px(x + 1, 15, 'eye'); g.px(x + 2, 16, 'eye') }
    else g.rect(x, 16, 3, 1, 'eye')
  }
  g.rect(22, 19, 5, 2, 'nose'); g.px(23, 19, 'dark2')
  g.px(24, 21, 'nose')
  if (tongue) { g.rect(23, 23, 3, 3, 'tongue'); g.px(24, 26, 'tongue') }
  else { g.px(23, 23, 'nose'); g.px(25, 23, 'nose') }
}

// red bandana: knotted band around the neck, triangle hanging over the chest
function bandana(g) {
  g.rect(16, 27, 16, 2, 'band')
  g.tri(17, 28, 31, 28, 24, 35, 'band')
  g.rect(16, 28, 16, 1, 'bandS')
  g.px(24, 34, 'bandS'); g.px(23, 33, 'bandS'); g.px(25, 33, 'bandS')
  for (const [x, y] of [[20, 30], [27, 30], [24, 31], [22, 32], [26, 32], [18, 27], [24, 27], [30, 27]]) g.px(x, y, 'white')
  g.rect(31, 26, 2, 2, 'bandS'); g.px(33, 28, 'band')
}

function zed(g, x, y) { g.rect(x, y, 3, 1, 'white'); g.px(x + 1, y + 1, 'white'); g.rect(x, y + 2, 3, 1, 'white') }

// Playing with a ball: play-bow (chest low, rump up, tail wagging), eyes
// track the ball, near paw swats it on the way down.
const HOP = [0, 9, 15, 18, 18, 15, 9, 0]
function play(buf, W, t) {
  const i = t % 8, g = painter(buf, W, 14, 0), hop = HOP[i]
  const wag = [0, 1.5, 0, -1.5][t % 4]
  g.stroke(38, 23, 2.3, 44 + wag, 19, 2, 'dark'); g.stroke(44 + wag, 19, 2, 46 + wag * 1.5, 13, 1.4, 'dark')
  g.ell(46 + wag * 1.5, 13, 1.1, 1.1, 'dark2')
  g.stroke(37, 27, 2, 39, 44, 1.5, 'tanS'); g.ell(39.5, 44, 1.8, 1.1, 'tanS')
  g.ell(34, 25, 6, 5.5, 'tan')
  g.stroke(34, 28, 2.4, 35, 44, 1.6, 'tan'); g.ell(35.5, 44, 2, 1.2, 'tanL')
  g.stroke(23, 35, 7, 32, 26, 5.5, 'tan')
  g.stroke(23, 31, 3.5, 32, 22, 3, 'dark')
  for (const [x, y] of [[28, 30], [31, 28], [26, 34]]) g.px(x, y, 'tanS')
  g.ell(20, 38, 6, 4.5, 'tanL')
  g.stroke(25, 40, 2, 18, 44.5, 1.5, 'tanS'); g.ell(16.5, 44.5, 2, 1.2, 'tanS')
  const swat = i === 6 || i === 7 || i === 0
  if (swat) { g.stroke(17, 39, 2.4, 6, 37, 1.8, 'tan'); g.ell(5, 37, 2.1, 1.6, 'tanL') }
  else { g.stroke(18, 40, 2.4, 11, 44.5, 1.8, 'tan'); g.ell(10, 44.5, 2.2, 1.3, 'tanL') }
  const h = painter(buf, W, 10, 9)
  bandana(h)
  frontHead(h, hop > 7 ? 'up' : 'left', true)
  const by = 42 - hop, bx = 11
  const b = painter(buf, W, 0, 0)
  b.ell(bx, 46, 3 - hop / 9, .5, 'shadow')
  b.ell(bx, by, 3, 3, 'ball')
  b.px(bx - 3, by, 'white'); b.px(bx - 2, by - 1, 'white'); b.px(bx - 1, by - 1, 'white'); b.px(bx + 1, by + 1, 'white'); b.px(bx + 2, by + 1, 'white'); b.px(bx + 3, by, 'white')
}

function draw(buf, W, pose, t) {
  const f = t % 2
  if (pose === 'play') return play(buf, W, t)
  if (pose === 'idle') {
    const g = painter(buf, W, 0, 0)
    frontBody(g, f ? 1.5 : -.5); bandana(g); frontHead(g, t % 7 === 6 ? 'blink' : 'open', false, t % 11 !== 10)
  } else if (pose === 'done') {
    const g = painter(buf, W, 0, f ? -3 : 0)
    frontBody(g, 2); bandana(g); frontHead(g, 'happy', true)
    const s = painter(buf, W, 0, 0)
    const spark = (x, y) => { s.px(x, y, 'tag'); s.px(x - 1, y, 'tag'); s.px(x + 1, y, 'tag'); s.px(x, y - 1, 'tag'); s.px(x, y + 1, 'tag') }
    if (f) { spark(5, 10); spark(43, 6) } else { spark(7, 4); spark(44, 16) }
  } else {
    // lying on the floor, chin on the front paws, tail curled along the ground
    const g = painter(buf, W, 0, 0), breath = f ? .6 : 0
    g.ell(34, 47, 22, .6, 'shadow')
    g.stroke(44, 44, 2.4, 52, 45, 2.1, 'dark'); g.stroke(52, 45, 2.1, 57, 42, 1.5, 'dark')
    g.ell(57, 41.5, 1.2, 1.2, 'dark2')
    g.ell(33, 39, 14, 6.5 + breath, 'tan')
    g.ell(33, 35 - breath, 12, 3.3, 'dark')
    g.ell(44, 40, 5.5, 5 + breath, 'tan'); g.ell(45, 37 - breath, 4, 2, 'dark')
    g.ell(47, 45, 3, 1.3, 'tanL')
    for (const [x, y] of [[28, 40], [36, 42], [40, 39], [31, 43]]) g.px(x, y, 'tanS')
    const h = painter(buf, W, -1, 18)
    h.rect(16, 27, 16, 2, 'band'); h.px(18, 27, 'white'); h.px(24, 27, 'white'); h.px(30, 27, 'white')
    frontHead(h, 'closed', false, true)
    g.ell(15, 45, 3.2, 1.6, 'tanL'); g.ell(31, 45, 3.2, 1.6, 'tanL')
    g.px(14, 46, 'tanS'); g.px(16, 46, 'tanS'); g.px(30, 46, 'tanS'); g.px(32, 46, 'tanS')
    const s = painter(buf, W, 0, 0)
    const z = Math.floor(t / 2) % 3
    zed(s, 40, 22 - z * 2); if (z > 0) zed(s, 45, 16 - z * 2); if (z > 1) zed(s, 50, 10)
  }
}

const rgb = hex => { const n = parseInt(hex.slice(1), 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255] }
const lift = c => Math.round(c + (255 - c) * 0.25)

/** One frame of a pose as RGBA, with the outline and the rim light applied. */
export function renderFrame(pose, frame) {
  const spec = POSES[pose]
  if (!spec) throw new Error(`unknown pose ${pose}`)
  const W = spec.width
  const buf = new Uint8Array(W * N)
  draw(buf, W, pose, ((frame % spec.frames) + spec.frames) % spec.frames)
  const filled = (x, y) => x >= 0 && y >= 0 && x < W && y < N && buf[y * W + x] !== 0 && buf[y * W + x] !== R.shadow
  const rgba = new Uint8ClampedArray(W * N * 4)
  for (let y = 0; y < N; y++) for (let x = 0; x < W; x++) {
    const i = y * W + x
    let role = buf[i], isRim = false
    if (role === 0) {
      if (filled(x - 1, y) || filled(x + 1, y) || filled(x, y - 1) || filled(x, y + 1)) role = R.outline
      else continue
    } else if (role !== R.shadow && !filled(x, y - 1)) isRim = true
    let px
    if (role === R.shadow) px = SHADOW_RGBA
    else {
      const [r, g, b] = rgb(PAL[ROLES[role]])
      px = isRim ? [lift(r), lift(g), lift(b), 255] : [r, g, b, 255]
    }
    rgba.set(px, i * 4)
  }
  return { width: W, height: N, rgba }
}
