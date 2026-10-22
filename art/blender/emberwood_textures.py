#!/usr/bin/env python3
"""Deterministic, seamless Emberwood PBR surfaces (original procedural artwork).

RGB normal maps use the OpenGL tangent convention expected by Godot / glTF.
At runtime use roughly 1.5 m per stone tile, 1 m around / 3 m up for bark,
and 2 m per soil tile. Geometric paver joints are deliberately not painted in.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'godot-native/assets/environment'
SIZE = 1024
rng = np.random.default_rng(41179)
Y, X = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32)
U, V = X / SIZE, Y / SIZE


def smooth_periodic(a, sigma):
    fy = np.fft.fftfreq(a.shape[0])[:, None]
    fx = np.fft.fftfreq(a.shape[1])[None, :]
    kernel = np.exp(-2 * np.pi**2 * sigma**2 * (fx * fx + fy * fy))
    return np.fft.ifft2(np.fft.fft2(a) * kernel).real.astype(np.float32)


def noise(sigma):
    n = smooth_periodic(rng.standard_normal((SIZE, SIZE)).astype(np.float32), sigma)
    return (n - n.mean()) / max(float(n.std()), 1e-6)


def normalized(a):
    lo, hi = np.percentile(a, [1, 99])
    return np.clip((a - lo) / max(float(hi - lo), 1e-6), 0, 1)


def save_surface(name, color, height, roughness, normal_strength=8):
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.uint8(np.clip(color, 0, 255)), 'RGB').save(OUT / f'{name}_albedo.png', optimize=True)
    Image.fromarray(np.uint8(np.clip(roughness, 0, 1) * 255), 'L').save(OUT / f'{name}_roughness.png', optimize=True)
    # Centered wrapped derivatives guarantee the normal map tiles as well.
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * normal_strength
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * normal_strength
    normals = np.stack((-dx, dy, np.ones_like(height)), axis=-1)
    normals /= np.linalg.norm(normals, axis=-1, keepdims=True)
    Image.fromarray(np.uint8(np.clip(normals * .5 + .5, 0, 1) * 255), 'RGB').save(OUT / f'{name}_normal.png', optimize=True)


def wrapped_marks(kind):
    im = Image.new('L', (SIZE, SIZE)); d = ImageDraw.Draw(im)
    if kind == 'pits':
        for _ in range(4200):
            x, y = rng.uniform(0, SIZE, 2); r = rng.uniform(.4, 2.3)
            value = int(rng.uniform(35, 170))
            for ox in (-SIZE, 0, SIZE):
                for oy in (-SIZE, 0, SIZE):
                    d.ellipse((x + ox - r, y + oy - r, x + ox + r, y + oy + r), fill=value)
    else:
        for _ in range(14):
            point = rng.uniform(0, SIZE, 2); angle = rng.uniform(0, np.pi * 2)
            points = [tuple(point)]
            for __ in range(int(rng.integers(7, 16))):
                angle += rng.uniform(-.8, .8)
                point += np.array([np.cos(angle), np.sin(angle)]) * rng.uniform(6, 18)
                points.append(tuple(point))
            for ox in (-SIZE, 0, SIZE):
                for oy in (-SIZE, 0, SIZE):
                    d.line([(x + ox, y + oy) for x, y in points], fill=int(rng.uniform(80, 160)), width=1)
    return np.asarray(im).astype(np.float32) / 255


def stone():
    broad = noise(66); medium = noise(13); grain = noise(1.2)
    strata = noise(4)
    pits = smooth_periodic(wrapped_marks('pits'), .7)
    cracks = smooth_periodic(wrapped_marks('cracks'), .6)
    lichen = np.clip((noise(24) - .95) * .22, 0, .30)
    height = .24 * medium + .075 * strata + .018 * grain - .55 * pits - .28 * cracks
    tone = broad * 7 + medium * 3.5 + grain * 1.4 - pits * 34 - cracks * 37
    color = np.array([110, 119, 116], dtype=np.float32) + tone[..., None]
    color = color * (1 - lichen[..., None]) + np.array([145, 151, 111]) * lichen[..., None]
    # A slight dry/damp variation makes broad highlights break up naturally.
    damp = np.clip((-broad - .45) * .12, 0, .24)
    color *= (1 - damp[..., None] * .35)
    rough = np.clip(.74 + medium * .025 + grain * .015 + pits * .13 - damp * .65, .48, .92)
    save_surface('stone', color, height, rough, 6)


def bark():
    warp = noise(42) * .19 + noise(12) * .035
    phase = (U * 18 + warp) * 2 * np.pi
    ridge = (.5 + .5 * np.sin(phase)) ** 8
    small = (.5 + .5 * np.sin((U * 47 + noise(20) * .2) * 2 * np.pi)) ** 18
    grain = noise(1.2); body = noise(16)
    broken = normalized(noise(27))
    grooves = ridge * (.55 + broken * .45)
    height = .30 * body - .72 * grooves - .12 * small + .024 * grain
    tone = body * 7 + grain * 1.8 - grooves * 28 - small * 8
    color = np.array([88, 66, 52], dtype=np.float32) + tone[..., None]
    lichen = np.clip((noise(30) - 1.0) * .16, 0, .28)
    color = color * (1 - lichen[..., None]) + np.array([108, 119, 88]) * lichen[..., None]
    rough = np.clip(.83 + grooves * .12 + body * .02, .67, .98)
    save_surface('bark', color, height, rough, 6)


def soil():
    broad = noise(43); lumps = noise(6); grit = noise(.7)
    flecks = np.clip((grit - 1.45) * .7, 0, 1)
    moss = np.clip((broad + .4) * .45, 0, 1)
    tone = broad * 4 + lumps * 4 + grit * 1.1
    base = np.array([61, 50, 38]) + tone[..., None]
    green = np.array([56, 73, 43]) + tone[..., None] * .7
    color = base * (1 - moss[..., None] * .65) + green * moss[..., None] * .65
    color += flecks[..., None] * np.array([13, 12, 8])
    height = .21 * lumps + .035 * grit + flecks * .05
    rough = np.clip(.89 + lumps * .018 + moss * .025, .78, .98)
    save_surface('soil', color, height, rough, 7)


if __name__ == '__main__':
    stone(); bark(); soil()
    for path in sorted(OUT.glob('*.png')):
        print(path.relative_to(ROOT), f'{path.stat().st_size / 1024:.0f} KiB')
