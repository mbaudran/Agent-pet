"""Animated GIFs of Keloqz for the README, made from the app's own sprite strips.

    python3 tools/readme-gifs.py      (needs Pillow; run tools/render-sprites.mjs first)

Writes docs/images/{idle,play,done,sleep,eat,pee,run}.gif and docs/images/poses.gif.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SPRITES = ROOT / "Sources/Keloqz/Resources/sprites"
OUT = ROOT / "docs/images"
SCALE = 4
BACKGROUND = (22, 24, 29)
GLOW = (255, 170, 100)
TICK_MS = 160  # the mockup's tick: play advances every tick, the rest every third
LABELS = {"idle": "esperando", "play": "trabajando", "done": "¡saltado!", "sleep": "durmiendo"}


def frames(pose, info):
    strip = Image.open(SPRITES / f"{pose}.png").convert("RGBA")
    w, h = info["width"], info["height"]
    return [strip.crop((i * w, 0, (i + 1) * w, h)) for i in range(info["frames"])]


def lit(sprite, pad):
    """The sprite at SCALE× on the dark background, with the app's warm glow."""
    big = sprite.resize((sprite.width * SCALE, sprite.height * SCALE), Image.NEAREST)
    canvas = Image.new("RGBA", (big.width + pad * 2, big.height + pad * 2), BACKGROUND + (255,))
    glow = Image.new("RGBA", canvas.size, GLOW + (0,))
    alpha = Image.new("L", canvas.size, 0)
    alpha.paste(big.getchannel("A"), (pad, pad))
    glow.putalpha(alpha.filter(ImageFilter.GaussianBlur(10)).point(lambda a: int(a * 0.32)))
    canvas = Image.alpha_composite(canvas, glow)
    canvas.alpha_composite(big, (pad, pad))
    return canvas.convert("RGB")


def save(path, images, duration):
    images[0].save(path, save_all=True, append_images=images[1:], duration=duration, loop=0, optimize=True, disposal=2)


def main():
    info = json.loads((SPRITES / "sprites.json").read_text())
    poses = {pose: frames(pose, spec) for pose, spec in info.items()}
    pad = 12

    for pose, spec in info.items():
        save(OUT / f"{pose}.gif", [lit(f, pad) for f in poses[pose]], round(1000 / spec["fps"]))

    # All four side by side, ticking together like the app: 48 ticks ≈ 7.7 s.
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 22)
    cell_w = 64 * SCALE + pad * 2
    cell_h = 48 * SCALE + pad * 2
    order = ["idle", "play", "done", "sleep"]
    strip = []
    for tick in range(48):
        sheet = Image.new("RGB", (cell_w * len(order), cell_h + 40), BACKGROUND)
        draw = ImageDraw.Draw(sheet)
        for col, pose in enumerate(order):
            step = tick if pose == "play" else tick // 3
            cell = lit(poses[pose][step % len(poses[pose])], pad)
            sheet.paste(cell, (col * cell_w + (cell_w - cell.width) // 2, 0))
            label = LABELS[pose]
            width = draw.textlength(label, font=font)
            draw.text((col * cell_w + (cell_w - width) / 2, cell_h + 6), label, fill=(170, 172, 180), font=font)
        strip.append(sheet)
    save(OUT / "poses.gif", strip, TICK_MS)


if __name__ == "__main__":
    main()
