#!/usr/bin/env python3
"""Regenerate wallpapers/neon-grid.png (needs: pip install pillow numpy)."""
import numpy as np
from PIL import Image

W, H = 2560, 1600
y, x = np.mgrid[0:H, 0:W].astype(np.float32)
img = np.zeros((H, W, 3), np.float32)
img[:] = (11, 14, 20)

def glow(cx, cy, r, color, strength):
    d = np.sqrt((x - cx * W) ** 2 + (y - cy * H) ** 2) / r
    a = np.clip(1 - d, 0, 1) ** 2 * strength
    return a[..., None] * np.array(color, np.float32)

img += glow(0.20, 0.15, 1100, (0, 229, 255), 0.30)
img += glow(0.85, 0.90, 1000, (255, 46, 151), 0.22)

grid = 80
lines = ((x % grid) < 1) | ((y % grid) < 1)
img[lines] += 6

Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save("wallpapers/neon-grid.png")
