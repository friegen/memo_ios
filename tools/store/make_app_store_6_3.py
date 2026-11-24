"""
App Store のスクリーンショットの「中型ディスプレイ」（6.1・6.3 インチ。1206×2622。App Store Connect で必須）の分を、
6.9 インチの画像（1320×2868）から作る。

使い方（リポジトリの一番上で）:
    python3 tools/store/make_app_store_6_3.py

- 入力: docs/store/app-store/screenshots/<言語>/NN.jpg（`swift tools/store/compose_app_store.swift` で作ったもの）
- 出力: docs/store/app-store/screenshots_6.3/<言語>/NN.jpg
- 縦横の比率の差は 1px 未満なので、高さを 2622 に合わせて縮め、左右をわずかに（合わせて 1px ほど）切る
- 6.9 インチの画像を作り直したら、これも流す。Pillow が要る（`pip3 install Pillow`）
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2] / "docs/store/app-store"
SRC = ROOT / "screenshots"
OUT = ROOT / "screenshots_6.3"
W, H = 1206, 2622


def main() -> None:
    count = 0
    for src in sorted(SRC.glob("*/*.jpg")):
        im = Image.open(src).convert("RGB")
        scaled_w = round(im.width * H / im.height)
        im = im.resize((scaled_w, H), Image.LANCZOS)
        left = (scaled_w - W) // 2
        im = im.crop((left, 0, left + W, H))
        dst = OUT / src.parent.name / src.name
        dst.parent.mkdir(parents=True, exist_ok=True)
        im.save(dst, "JPEG", quality=92)
        count += 1
    print(f"{count} 枚を作りました → {OUT}")


if __name__ == "__main__":
    main()
