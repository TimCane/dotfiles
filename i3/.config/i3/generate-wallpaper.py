#!/usr/bin/env python3
"""Generate a Gruvbox-themed wallpaper as SVG then convert to PNG."""
import subprocess, os

svg = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
  <defs>
    <radialGradient id="g1" cx="50%" cy="50%" r="70%">
      <stop offset="0%" stop-color="#3c3836"/>
      <stop offset="100%" stop-color="#282828"/>
    </radialGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#g1)"/>
  <!-- Subtle geometric pattern -->
  <g opacity="0.07">
    <circle cx="960" cy="540" r="300" fill="none" stroke="#fe8019" stroke-width="1"/>
    <circle cx="960" cy="540" r="250" fill="none" stroke="#fabd2f" stroke-width="1"/>
    <circle cx="960" cy="540" r="200" fill="none" stroke="#b8bb26" stroke-width="1"/>
    <circle cx="960" cy="540" r="150" fill="none" stroke="#83a598" stroke-width="1"/>
    <circle cx="960" cy="540" r="100" fill="none" stroke="#d3869b" stroke-width="1"/>
    <circle cx="960" cy="540" r="350" fill="none" stroke="#8ec07c" stroke-width="0.5"/>
    <circle cx="960" cy="540" r="400" fill="none" stroke="#928374" stroke-width="0.5"/>
  </g>
  <!-- Corner accents -->
  <g opacity="0.04">
    <rect x="0" y="0" width="400" height="2" fill="#fe8019"/>
    <rect x="0" y="0" width="2" height="300" fill="#fe8019"/>
    <rect x="1520" y="0" width="400" height="2" fill="#fe8019"/>
    <rect x="1918" y="0" width="2" height="300" fill="#fe8019"/>
    <rect x="0" y="1078" width="400" height="2" fill="#fe8019"/>
    <rect x="0" y="780" width="2" height="300" fill="#fe8019"/>
    <rect x="1520" y="1078" width="400" height="2" fill="#fe8019"/>
    <rect x="1918" y="780" width="2" height="300" fill="#fe8019"/>
  </g>
</svg>'''

svg_path = os.path.expanduser('~/.config/i3/wallpaper.svg')
png_path = os.path.expanduser('~/.config/i3/wallpaper.png')

with open(svg_path, 'w') as f:
    f.write(svg)

# Try rsvg-convert first, fall back to convert (ImageMagick)
try:
    subprocess.run(['rsvg-convert', svg_path, '-o', png_path], check=True)
except FileNotFoundError:
    try:
        subprocess.run(['convert', svg_path, png_path], check=True)
    except FileNotFoundError:
        # Just keep SVG, feh can handle it
        import shutil
        shutil.copy(svg_path, png_path.replace('.png', '.svg'))
        print("No converter found, keeping SVG")

print(f"Wallpaper saved to {png_path}")
