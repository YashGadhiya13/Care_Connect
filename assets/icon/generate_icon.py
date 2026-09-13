"""Generates CareConnect's app icon: a rounded teal square with a white
heart-and-pulse mark. Run once with `python generate_icon.py` — output feeds
flutter_launcher_icons (see pubspec.yaml).
"""
import math
from PIL import Image, ImageDraw

SIZE = 1024
PRIMARY = (26, 122, 116, 255)      # 0xFF1A7A74
PRIMARY_DARK = (17, 94, 89, 255)   # 0xFF115E59
WHITE = (255, 255, 255, 255)


def heart_points(cx, cy, scale, n=200):
    """Classic parametric heart curve, y-flipped for image coordinates."""
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * scale, cy - y * scale))
    return pts


def draw_heart(draw, cx, cy, scale, fill):
    draw.polygon(heart_points(cx, cy, scale), fill=fill)


def rounded_bg(size, radius):
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    gradient = Image.new("RGBA", (size, size), PRIMARY)
    gd = ImageDraw.Draw(gradient)
    for y in range(size):
        t = y / size
        r = int(PRIMARY[0] + (PRIMARY_DARK[0] - PRIMARY[0]) * t)
        g = int(PRIMARY[1] + (PRIMARY_DARK[1] - PRIMARY[1]) * t)
        b = int(PRIMARY[2] + (PRIMARY_DARK[2] - PRIMARY[2]) * t)
        gd.line([(0, y), (size, y)], fill=(r, g, b, 255))
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(gradient, (0, 0), mask)
    return out


def pulse_line(draw, cx, cy, half_width, width):
    pts = [
        (cx - half_width, cy),
        (cx - half_width * 0.35, cy),
        (cx - half_width * 0.12, cy - half_width * 0.55),
        (cx + half_width * 0.05, cy + half_width * 0.4),
        (cx + half_width * 0.22, cy),
        (cx + half_width, cy),
    ]
    draw.line(pts, fill=PRIMARY, width=width, joint="curve")


# --- Full icon (background + heart + pulse) ---
img = rounded_bg(SIZE, int(SIZE * 0.22))
draw = ImageDraw.Draw(img)
cx, cy = SIZE // 2, int(SIZE * 0.5)
draw_heart(draw, cx, cy, SIZE * 0.021, WHITE)
pulse_line(draw, cx, int(cy + SIZE * 0.03), SIZE * 0.19, int(SIZE * 0.02))
img.save("app_icon.png")

# --- Foreground-only (transparent bg) for Android adaptive icons ---
# Adaptive icons get cropped to a circle/squircle by the OS, so keep the
# heart small and centered with generous padding.
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
fg_draw = ImageDraw.Draw(fg)
draw_heart(fg_draw, cx, cy, SIZE * 0.014, WHITE)
pulse_line(fg_draw, cx, int(cy + SIZE * 0.02), SIZE * 0.125, int(SIZE * 0.014))
fg.save("app_icon_foreground.png")

print("Saved app_icon.png and app_icon_foreground.png")
