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
  eat: { width: 64, frames: 8, fps: 4 },
  pee: { width: 64, frames: 80, fps: 4 },
  run: { width: 64, frames: 6, fps: 12.5 },
}

const N = HEIGHT
const ROLES = ['_', 'outline', 'dark', 'dark2', 'tan', 'tanL', 'tanS', 'ear', 'eye', 'white', 'nose', 'tongue', 'collar', 'tag', 'mask', 'ball', 'shadow', 'maskL', 'band', 'bandS', 'bowl', 'bowlS', 'pee', 'peeL', 'dust']
const R = Object.fromEntries(ROLES.map((r, i) => [r, i]))
const PAL = {
  outline: '#140d0b', dark: '#1d1517', dark2: '#3a2a2a', tan: '#a3552a', tanL: '#c97c3a', tanS: '#73391a',
  ear: '#80504a', eye: '#1a0d07', white: '#fff3e0', nose: '#0c0809', tongue: '#e07e98', collar: '#5b5cf0', tag: '#ffffff',
  mask: '#4e3127', maskL: '#7a4122', band: '#d8342c', bandS: '#9a1f1b', ball: '#c9dc45',
  bowl: '#3f8fd8', bowlS: '#22507f', pee: '#f0c93a', peeL: '#fff09a', dust: '#b9a58f',
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
    else if (eyes === 'right') { g.rect(x + 1, 15, 3, 2, 'eye'); g.px(x + 1, 15, 'white'); g.px(x, 16, 'mask') }
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

// Standing side-on, facing left: torso from chest to rump with the dark saddle on top.
function torso(g, cx, cy, rx, ry) {
  g.stroke(cx, cy, 6, rx, ry, 5.5, 'tan')
  g.stroke(cx + 2, cy - 4, 3.5, rx, ry - 4, 3.2, 'dark')
  g.stroke(cx + 1, cy + 3, 2.6, rx - 5, ry + 3, 2, 'tanL')
  for (const [x, y] of [[cx + 6, cy + 1], [cx + 11, cy + 2], [rx - 3, ry + 1], [cx + 8, cy - 1]]) g.px(x, y, 'tanS')
}

// A leg from hip or shoulder to paw; far legs are in shade.
function leg(g, x0, y0, x1, y1, far) {
  g.stroke(x0, y0, far ? 2 : 2.4, x1, y1, far ? 1.5 : 1.7, far ? 'tanS' : 'tan')
  g.ell(x1 - .5, y1, far ? 1.8 : 2.1, far ? 1.1 : 1.3, far ? 'tanS' : 'tanL')
}

// the bandana knotted round a neck seen from the side
function neckBand(g, x0, y0, x1, y1) {
  g.stroke(x0, y0, 1.2, x1, y1, 1.2, 'band')
  g.px((x0 + x1) / 2, (y0 + y1) / 2, 'white'); g.px(x1, y1 - 1, 'white')
}

// Eating from his bowl: head down munching, crumbs on each chew, then a lick.
const DIP = [3, 1, 3, 1, 3, 1, -1, -1]
function eat(buf, W, t) {
  const i = t % 8, dip = DIP[i], g = painter(buf, W, 0, 0)
  const wag = [0, 1.5, 0, -1.5][t % 4]
  g.ell(32, 46.6, 24, .6, 'shadow')
  leg(g, 27, 34, 28, 44.5, true); leg(g, 46, 32, 48, 44.5, true)
  g.stroke(48, 27, 2.3, 54, 31, 2, 'dark'); g.stroke(54, 31, 2, 56 + wag, 37, 1.4, 'dark')
  g.ell(56 + wag, 37.5, 1.1, 1.1, 'dark2')
  torso(g, 25, 31, 44, 28)
  g.ell(43, 32, 5, 5, 'tan')
  leg(g, 22, 34, 21, 44.5); leg(g, 43, 34, 44, 44.5)
  g.stroke(17, 29, 4.5, 25, 30, 5.5, 'tan')
  neckBand(g, 26, 24, 27, 35)
  frontHead(painter(buf, W, -9, 15 + dip), dip > 0 ? 'closed' : 'happy', dip < 0, false)
  // the bowl, drawn over the muzzle so the nose dips into it
  const b = painter(buf, W, 0, 0)
  b.ell(15, 40.4, 10.5, 1.4, 'bowlS')
  for (const [x, y] of [[9, 39], [12, 39], [15, 39], [18, 39], [21, 39], [11, 40], [17, 40]]) b.px(x, y, i % 3 ? 'tanS' : 'maskL')
  for (let y = 41; y <= 45; y++) { const hw = 11.5 - (y - 41) * .6; b.rect(Math.round(15 - hw), y, Math.round(hw * 2), 1, y === 41 ? 'bowlS' : 'bowl') }
  b.rect(4, 41, 22, 1, 'bowl')
  b.rect(12, 43, 6, 1, 'white'); b.px(11, 42, 'white'); b.px(11, 44, 'white'); b.px(18, 42, 'white'); b.px(18, 44, 'white')
  if (dip === 1) { b.px(6, 36 - i % 3, 'tanS'); b.px(24, 35, 'maskL') }
}

// Lifting a leg against a fire hydrant, then a proud kick of dust. One pee
// fills the whole 20 s trick: lift, a long stream, lower, kick, kick.
const PEE_END = 72 // frame the leg starts coming down
function pee(buf, W, t) {
  const i = t % 80, g = painter(buf, W, 0, 0)
  const lift = i <= 1 || i > PEE_END ? 0 : i === 2 || i === PEE_END ? .5 : 1
  const kick = i === 76 || i === 78, streaming = i >= 3 && i < PEE_END
  const wag = [0, 1, 0, -1][t % 4]
  // hydrant
  g.ell(56.5, 46.6, 6, .6, 'shadow')
  g.rect(51, 44, 11, 2, 'bandS')
  g.rect(53, 30, 7, 14, 'band'); g.rect(58, 31, 2, 13, 'bandS')
  g.ell(56.5, 29.5, 4.5, 2.5, 'band'); g.rect(55, 25, 3, 2, 'bandS')
  g.rect(51, 34, 2, 3, 'bandS'); g.rect(60, 34, 2, 3, 'bandS')
  g.rect(53, 39, 7, 1, 'bandS')
  // the dog
  g.ell(28, 46.6, 18, .6, 'shadow')
  leg(g, 22, 34, 23, 44.5, true)
  if (kick) leg(g, 39, 33, 47, 43, true)
  else leg(g, 40, 33, 40, 44.5, true)
  const tailUp = lift ? 1 : 0
  g.stroke(42, 27, 2.2, 46, 22 + 2 * (1 - tailUp), 1.9, 'dark'); g.stroke(46, 22 + 2 * (1 - tailUp), 1.9, 47 + wag, 16 + 6 * (1 - tailUp), 1.4, 'dark')
  g.ell(47 + wag, 15.5 + 6 * (1 - tailUp), 1.1, 1.1, 'dark2')
  torso(g, 19, 31, 38, 30)
  g.ell(38, 32, 5, 5, 'tan')
  leg(g, 17, 34, 16, 44.5)
  if (lift) { leg(g, 40, 34, 40 + 9 * lift, 40 - 8 * lift); g.stroke(41, 36, .5, 40 + 9 * lift, 41.5 - 8 * lift, .5, 'tanS') }
  else if (kick) leg(g, 39, 34, 48, 41)
  else leg(g, 38, 34, 38, 44.5)
  const h = painter(buf, W, -10, 1)
  bandana(h)
  const gaze = streaming ? ['left', 'up', 'up', 'left'][Math.floor(i / 8) % 4] : i <= 1 ? 'right' : i > PEE_END ? 'happy' : 'left'
  frontHead(h, gaze, i > PEE_END, i % 6 !== 5)
  // stream and puddle
  const s = painter(buf, W, 0, 0)
  if (streaming) {
    for (let x = 44; x <= 51; x++) if ((x + i) % 3) s.px(x, Math.round(36 + (x - 44) * (x - 44) * .08), 'pee')
    if (i % 2) { s.px(52, 37, 'peeL'); s.px(51, 40, 'peeL') } else s.px(52, 39, 'peeL')
  }
  if (i >= 4) {
    const r = Math.min(7, 1 + (i - 4) * .2)
    s.ell(51 - r / 3, 46, r, .7, 'pee')
    if (r > 3) s.px(49, 46, 'peeL')
  }
  if (kick) { s.ell(54, 43, 1.5, 1.2, 'dust'); s.px(58, 41, 'dust'); s.px(50, 41, 'dust') }
}

// Head in profile looking where he runs (left): long dark muzzle, ears swept
// back, tongue flapping, bandana knotted on the neck.
function sideHead(g, i) {
  const flap = i % 2
  g.stroke(27, 28, 5, 20, 21, 4.5, 'tan')
  g.stroke(28, 24, 3, 22, 17, 2.4, 'dark')
  g.stroke(21, 12, 2.6, 27, 5 + flap, 1, 'dark')
  g.stroke(18, 12, 3, 23, 3 + flap, 1, 'dark')
  g.stroke(18.5, 11, 1.4, 22, 5 + flap, .6, 'ear')
  g.ell(17, 16, 6.5, 5.5, 'tan')
  g.ell(19, 12.5, 4.5, 2.2, 'mask')
  g.ell(18, 19.5, 3.5, 2.5, 'tanL')
  g.stroke(13, 17.5, 3.4, 6, 19, 2.4, 'mask')
  g.stroke(13, 15.5, 1, 7, 17.5, .8, 'maskL')
  g.ell(4.6, 18.6, 1.6, 1.4, 'nose')
  g.stroke(13, 21.5, 1.6, 8, 21.5, 1.2, 'mask')
  g.rect(9, 22, 3, 2 + flap, 'tongue'); g.px(10 + flap, 24 + flap, 'tongue')
  g.rect(14, 14, 3, 2, 'eye'); g.px(14, 14, 'white')
  g.rect(14, 12, 3, 1, 'tanL')
  neckBand(g, 21, 23, 25, 31)
  g.tri(21, 28, 26, 30, 17 - flap, 34, 'band')
  g.px(20, 30, 'white'); g.px(22, 31, 'white'); g.px(19, 32, 'white')
}

// Galloping on the spot: stretch, front plant, gather, rear plant.
const GALLOP = [
  // bounce, near front, far front, near rear, far rear (paw x, y)
  [1, [11, 37], [14, 39], [57, 37], [55, 40]],
  [0, [17, 44.5], [13, 42], [53, 42], [55, 40]],
  [-1, [24, 44.5], [20, 44.5], [47, 43], [51, 42]],
  [-3, [29, 40], [27, 41], [36, 41], [39, 42]],
  [-1, [21, 37], [24, 39], [40, 44.5], [36, 44.5]],
  [0, [14, 36], [17, 38], [47, 44.5], [43, 44.5]],
]
function run(buf, W, t) {
  const i = t % 6, [bob, nf, ff, nr, fr] = GALLOP[i], g = painter(buf, W, 0, bob)
  const shadow = painter(buf, W, 0, 0)
  shadow.ell(33, 46.6, 20 + bob, .6, 'shadow')
  leg(g, 27, 33, ff[0], ff[1] - bob, true); leg(g, 44, 32, fr[0], fr[1] - bob, true)
  const flick = [0, -1, -2, -1, 0, 1][i]
  g.stroke(47, 27, 2.2, 54, 25 + flick, 1.9, 'dark'); g.stroke(54, 25 + flick, 1.9, 60, 27 - flick, 1.3, 'dark')
  g.ell(60.5, 27 - flick, 1.1, 1.1, 'dark2')
  torso(g, 27, 30, 44, 29 - (bob < -1 ? 1 : 0))
  g.ell(43, 31, 5, 5, 'tan')
  leg(g, 25, 33, nf[0], nf[1] - bob); leg(g, 44, 33, nr[0], nr[1] - bob)
  sideHead(g, i)
  // dust kicked up behind, drifting away
  const d = painter(buf, W, 0, 0), k = (i + 2) % 6
  d.ell(50 + k * 2, 44 - k / 2, 2 - k / 3, 1.6 - k / 4, 'dust')
  if (k < 4) d.px(56 + k * 2, 42 - k, 'dust')
}

function draw(buf, W, pose, t) {
  const f = t % 2
  if (pose === 'play') return play(buf, W, t)
  if (pose === 'eat') return eat(buf, W, t)
  if (pose === 'pee') return pee(buf, W, t)
  if (pose === 'run') return run(buf, W, t)
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
