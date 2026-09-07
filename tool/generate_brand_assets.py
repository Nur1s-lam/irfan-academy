"""Generate platform icons from the approved IRFAN logo master."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MASTER_PATH = ROOT / "assets" / "images" / "irfan_logo.png"


def remove_checkerboard(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    cleaned = []
    for red, green, blue, alpha in image.getdata():
        neutral = max(red, green, blue) - min(red, green, blue) <= 12
        if neutral and min(red, green, blue) >= 205:
            cleaned.append((0, 0, 0, 0))
        else:
            cleaned.append((red, green, blue, alpha))
    image.putdata(cleaned)
    return image


def square_icon(logo: Image.Image, size: int, padding: float = 0.08) -> Image.Image:
    canvas = Image.new("RGB", (size, size), "white")
    available = round(size * (1 - padding * 2))
    fitted = logo.copy()
    fitted.thumbnail((available, available), Image.Resampling.LANCZOS)
    x = (size - fitted.width) // 2
    y = (size - fitted.height) // 2
    canvas.paste(fitted, (x, y), fitted)
    return canvas


def save_png(logo: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    square_icon(logo, size).save(path, "PNG", optimize=True)


def generate_ios(logo: Image.Image) -> None:
    directory = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    contents = json.loads((directory / "Contents.json").read_text(encoding="utf-8"))
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        points = float(entry["size"].split("x")[0])
        scale = float(entry["scale"].removesuffix("x"))
        save_png(logo, directory / filename, round(points * scale))


def main() -> None:
    logo = remove_checkerboard(Image.open(MASTER_PATH))
    logo.save(MASTER_PATH, "PNG", optimize=True)

    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        save_png(
            logo,
            ROOT / "android" / "app" / "src" / "main" / "res" / folder / "ic_launcher.png",
            size,
        )

    save_png(logo, ROOT / "web" / "favicon.png", 32)
    save_png(logo, ROOT / "web" / "icons" / "Icon-192.png", 192)
    save_png(logo, ROOT / "web" / "icons" / "Icon-512.png", 512)
    save_png(logo, ROOT / "web" / "icons" / "Icon-maskable-192.png", 192)
    save_png(logo, ROOT / "web" / "icons" / "Icon-maskable-512.png", 512)
    generate_ios(logo)

    windows_icon = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    windows_icon.parent.mkdir(parents=True, exist_ok=True)
    square_icon(logo, 256).save(
        windows_icon,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()
