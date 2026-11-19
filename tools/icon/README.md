# アプリアイコンの作り方

Android 版のアイコン（`app/src/main/res/drawable/ic_launcher_foreground.xml` と `ic_launcher_monochrome.xml`）と同じ絵を、
SVG に書き直して PNG に描いている。絵を直すときは `make_svgs.py` の図形を直して、下の手順で作り直す。

```bash
cd tools/icon
python3 make_svgs.py                      # light.svg / dark.svg / tinted.svg / launch.svg を作る
A=../../IrodoriNotes/Resources/Assets.xcassets
swift render.swift light.svg  $A/AppIcon.appiconset/AppIcon.png 1024 noalpha   # 通常（背景あり・アルファなし）
swift render.swift dark.svg   $A/AppIcon.appiconset/AppIcon-Dark.png 1024      # ダーク（背景は透明。iOS が暗い背景を敷く）
swift render.swift tinted.svg $A/AppIcon.appiconset/AppIcon-Tinted.png 1024    # 色付き（白い形だけ。iOS が色を付ける）
swift render.swift launch.svg $A/LaunchLogo.imageset/LaunchLogo@2x.png 400     # 起動画面のロゴ（200pt）
swift render.swift launch.svg $A/LaunchLogo.imageset/LaunchLogo@3x.png 600
```

- iOS はアイコンの角を丸めるだけで、Android のように丸く切り抜かないので、Android より絵を大きく描いている（`make_svgs.py` の `VIEW`）
- App Store のアイコンは透明の情報（アルファ）を持てないので、通常のアイコンは `noalpha` で書き出す
- 生成した `.svg` はコミットしない（`make_svgs.py` から作れるため）
