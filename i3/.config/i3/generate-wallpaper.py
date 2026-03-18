#!/usr/bin/env python3
"""Generate a randomized Gruvbox-themed wallpaper as SVG then convert to PNG."""
import subprocess, os, random

W, H = 3840, 2160

# Gruvbox accent palette
ACCENTS = ['#fe8019', '#fb4934']

def rand_color():
    return random.choice(ACCENTS)

def concentric_circles():
    cx = random.randint(W // 4, 3 * W // 4)
    cy = random.randint(H // 4, 3 * H // 4)
    count = random.randint(4, 8)
    base_r = random.randint(150, 400)
    step = random.randint(40, 80)
    lines = []
    for i in range(count):
        r = base_r + i * step
        sw = round(random.uniform(0.5, 4.0), 1)
        lines.append(f'    <circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{rand_color()}" stroke-width="{sw}"/>')
    return '\n'.join(lines)

def scattered_circles():
    lines = []
    for _ in range(random.randint(3, 8)):
        cx = random.randint(0, W)
        cy = random.randint(0, H)
        r = random.randint(50, 500)
        sw = round(random.uniform(3, 4.0), 1)
        lines.append(f'    <circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{rand_color()}" stroke-width="{sw}"/>')
    return '\n'.join(lines)

def diagonal_lines():
    lines = []
    for _ in range(random.randint(2, 6)):
        x1 = random.randint(-200, W + 200)
        y1 = random.randint(-200, H + 200)
        x2 = random.randint(-200, W + 200)
        y2 = random.randint(-200, H + 200)
        sw = round(random.uniform(0.5, 3.0), 1)
        lines.append(f'    <line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{rand_color()}" stroke-width="{sw}"/>')
    return '\n'.join(lines)

def corner_accents():
    color = rand_color()
    length = random.randint(300, 600)
    thickness = random.randint(1, 3)
    return f'''  <g opacity="0.04">
    <rect x="0" y="0" width="{length}" height="{thickness}" fill="{color}"/>
    <rect x="0" y="0" width="{thickness}" height="{length}" fill="{color}"/>
    <rect x="{W - length}" y="0" width="{length}" height="{thickness}" fill="{color}"/>
    <rect x="{W - thickness}" y="0" width="{thickness}" height="{length}" fill="{color}"/>
    <rect x="0" y="{H - thickness}" width="{length}" height="{thickness}" fill="{color}"/>
    <rect x="0" y="{H - length}" width="{thickness}" height="{length}" fill="{color}"/>
    <rect x="{W - length}" y="{H - thickness}" width="{length}" height="{thickness}" fill="{color}"/>
    <rect x="{W - thickness}" y="{H - length}" width="{thickness}" height="{length}" fill="{color}"/>
  </g>'''

# Pick 2-3 random geometric elements
elements = random.sample([concentric_circles, scattered_circles, diagonal_lines], k=random.randint(2, 3))

shapes = '\n'.join(el() for el in elements)
opacity = round(random.uniform(0.10, 0.20), 2)

svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">
  <rect width="{W}" height="{H}" fill="#282828"/>
  <g opacity="{opacity}">
{shapes}
  </g>
{corner_accents()}
</svg>'''

svg_path = os.path.expanduser('~/.config/i3/wallpaper.svg')
png_path = os.path.expanduser('~/.config/i3/wallpaper.png')

with open(svg_path, 'w') as f:
    f.write(svg)

try:
    subprocess.run(['rsvg-convert', svg_path, '-o', png_path], check=True)
except FileNotFoundError:
    try:
        subprocess.run(['convert', svg_path, png_path], check=True)
    except FileNotFoundError:
        import shutil
        shutil.copy(svg_path, png_path.replace('.png', '.svg'))
        print("No converter found, keeping SVG")

print(f"Wallpaper saved to {png_path}")
