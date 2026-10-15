"""Puts the raw renders in a simple iPhone frame and builds an overview.

    python3 tool/screenshots/frame.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "tool/screenshots/raw"
OUT = ROOT / "docs/screenshots"
FONT = "/usr/share/fonts/opentype/inter/Inter-SemiBold.otf"

CAPTIONS = {
    "01_gorevler": "Görevler",
    "02_gorevler_koyu": "Koyu tema",
    "03_gorev_duzenle": "Görev düzenle",
    "04_gecmis": "Geçmiş",
    "05_takvim": "Takvim",
    "06_dogum_gunu": "Doğum günü",
    "07_ayarlar": "Ayarlar",
}


def is_dark(img):
    r, g, b = img.getpixel((20, 20))[:3]
    return (r + g + b) / 3 < 128


def status_bar(img):
    """Draws an iOS-like status bar (time, signal, battery) at the top."""
    d = ImageDraw.Draw(img)
    color = (255, 255, 255) if is_dark(img) else (0, 0, 0)
    font = ImageFont.truetype(FONT, 50)
    d.text((150, 85), "10:30", font=font, fill=color)
    # Dynamic Island.
    d.rounded_rectangle((410, 33, 769, 140), radius=55, fill=(0, 0, 0))
    # Signal bars.
    x = 860
    for i, h in enumerate([14, 20, 26, 32]):
        d.rounded_rectangle((x + i * 17, 120 - h, x + i * 17 + 11, 120), radius=3, fill=color)
    # Battery.
    d.rounded_rectangle((950, 90, 1030, 124), radius=9, outline=color, width=4)
    d.rounded_rectangle((957, 97, 1010, 117), radius=5, fill=color)
    d.rounded_rectangle((1034, 101, 1040, 113), radius=2, fill=color)
    # Home indicator.
    d.rounded_rectangle((440, 2510, 739, 2525), radius=8, fill=color)
    return img


def frame(img, radius=150, bezel=36):
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    W, H = w + 2 * bezel, h + 2 * bezel
    phone = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(phone).rounded_rectangle(
        (0, 0, W - 1, H - 1), radius=radius + bezel, fill=(28, 28, 30, 255)
    )
    phone.paste(img, (bezel, bezel), mask)
    shadow = Image.new("RGBA", (W + 160, H + 160), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (80, 100, W + 80, H + 100), radius=radius + bezel, fill=(0, 0, 0, 90)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    shadow.alpha_composite(phone, (80, 80))
    return shadow


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    framed = []
    for path in sorted(RAW.glob("*.png")):
        img = status_bar(Image.open(path).convert("RGB"))
        f = frame(img)
        bg = Image.new("RGB", f.size, (236, 241, 245))
        bg.paste(f, (0, 0), f)
        bg.save(OUT / path.name, optimize=True)
        framed.append((path.stem, f))

    # Overview: all screens side by side, scaled down, with captions.
    scale = 0.36
    cell_w = int(framed[0][1].width * scale)
    cell_h = int(framed[0][1].height * scale)
    cols = 4
    rows = (len(framed) + cols - 1) // cols
    pad, cap = 40, 90
    W = cols * cell_w + (cols + 1) * pad
    H = rows * (cell_h + cap) + (rows + 1) * pad + 120
    sheet = Image.new("RGB", (W, H), (236, 241, 245))
    d = ImageDraw.Draw(sheet)
    d.text((pad + 20, 40), "ineed — ekranlar", font=ImageFont.truetype(FONT, 64), fill=(30, 40, 48))
    capfont = ImageFont.truetype(FONT, 40)
    for i, (stem, f) in enumerate(framed):
        r, c = divmod(i, cols)
        x = pad + c * (cell_w + pad)
        y = 140 + pad + r * (cell_h + cap + pad)
        small = f.resize((cell_w, cell_h), Image.LANCZOS)
        sheet.paste(small, (x, y), small)
        text = CAPTIONS.get(stem, stem)
        tw = d.textlength(text, font=capfont)
        d.text((x + (cell_w - tw) / 2, y + cell_h), text, font=capfont, fill=(30, 40, 48))
    sheet.save(OUT / "00_genel_bakis.png", optimize=True)


if __name__ == "__main__":
    main()
