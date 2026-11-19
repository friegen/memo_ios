# 使い方は README.md
# Android 版の ic_launcher_foreground.xml / ic_launcher_monochrome.xml を SVG に書き直す（座標は元の 1254px 四方のまま）
import sys
VIEW = "215 115 960 960"  # 絵の中心 (695, 595) のまわり 960 四方。iOS は角を丸めるだけなので Android より大きく見せる
NOTE = "M418,381H788A60,60 0,0 1,848 441V801A60,60 0,0 1,788 861H418A60,60 0,0 1,358 801V441A60,60 0,0 1,418 381Z"
NOTE_MONO = "M418,399H788A42,42 0,0 1,830 441V801A42,42 0,0 1,788 843H418A42,42 0,0 1,376 801V441A42,42 0,0 1,418 399Z"
BAND = "M410,772C430,715 520,680 590,692C650,702 700,725 740,712C760,705 772,697 780,688L805,703C790,745 750,778 700,782C640,786 590,765 540,763C480,762 440,790 420,822Z"
LINES = ["M410,517L612,476", "M428,597L668,548"]

def color_svg(background, view=VIEW):
    bg = f'<rect x="-2000" y="-2000" width="6000" height="6000" fill="{background}"/>' if background else ""
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}" width="1024" height="1024">
<defs><linearGradient id="band" gradientUnits="userSpaceOnUse" x1="410" y1="760" x2="805" y2="720">
<stop offset="0" stop-color="#3B8BF0"/><stop offset="0.25" stop-color="#A48AD8"/><stop offset="0.45" stop-color="#F28B96"/>
<stop offset="0.72" stop-color="#FFDA6B"/><stop offset="1" stop-color="#7FCF7A"/></linearGradient></defs>
{bg}
<g transform="rotate(-12 603 621)"><path d="{NOTE}" fill="#FAFBFC"/></g>
{''.join(f'<path d="{d}" stroke="#D3D6DE" stroke-width="50" stroke-linecap="round" fill="none"/>' for d in LINES)}
<path d="{BAND}" fill="url(#band)"/>
<g transform="translate(783 705) rotate(28.5)">
<path d="M-55,-100L-55,-404A55,55 0,0 1,55 -404L55,-100Z" fill="#0A6CD6"/>
<path d="M-55,-100L55,-100L12,-8Q0,4 -12,-8Z" fill="#E8EAED"/>
<path d="M-21,-28L21,-28L12,-8Q0,4 -12,-8Z" fill="#0A6CD6"/>
</g></svg>'''

def mono_svg(view=VIEW):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}" width="1024" height="1024">
<g transform="rotate(-12 603 621)"><path d="{NOTE_MONO}" stroke="#FFFFFF" stroke-width="36" fill="none"/></g>
{''.join(f'<path d="{d}" stroke="#FFFFFF" stroke-width="44" stroke-linecap="round" fill="none"/>' for d in LINES)}
<path d="{BAND}" fill="#FFFFFF"/>
<g transform="translate(783 705) rotate(28.5)"><path d="M-55,-100L-55,-404A55,55 0,0 1,55 -404L55,-100L12,-8Q0,4 -12,-8Z" fill="#FFFFFF"/></g>
</svg>'''

open("light.svg", "w").write(color_svg("#D6E6FA"))
open("dark.svg", "w").write(color_svg(None))
open("tinted.svg", "w").write(mono_svg())
# 起動画面のロゴ。白いノートが白い背景に溶けないよう、Android の起動画面と同じく薄い青の丸を敷く
launch = color_svg(None, view="135 35 1120 1120").replace(
    "</defs>", '</defs><circle cx="695" cy="595" r="540" fill="#D6E6FA"/>', 1)
open("launch.svg", "w").write(launch)
