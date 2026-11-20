"""
Android 版の strings.xml（9言語）から、指定した name の文字列を iOS の String Catalog（.xcstrings）に取り込む。

使い方:
    python3 tools/strings/import_android_strings.py <name> [<name> ...]

- 取り込み元: Android 版の読む専用のコピー（ANDROID_RES）。取り込み先: IrodoriNotes/Resources/Localizable.xcstrings
- キーは Android の name と同じ。すでにあるキーは上書きする
- Android の書き方を iOS に合わせる: %1$s → %1$@、%1$d → %1$lld、\\n → 改行、\\' → '、前後の "..." を外す
- plurals は String Catalog の複数形（plural）にする。中の %s は数値の %lld にする（L10n.count で3桁区切りを付ける）
- translatable="false" のものは英語の値を全言語に入れる（LocalizationTests が全言語にキーがあることを確かめるため）
"""
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ANDROID_RES = Path("/Users/dobashi/_workspace/04_kojin/03_memo_android_ref/app/src/main/res")
CATALOG = Path(__file__).resolve().parents[2] / "IrodoriNotes/Resources/Localizable.xcstrings"
LANGUAGES = {  # Android のフォルダ → iOS の言語のコード
    "values": "en", "values-ja": "ja", "values-es": "es", "values-pt": "pt", "values-fr": "fr",
    "values-de": "de", "values-ko": "ko", "values-b+zh+Hant": "zh-Hant", "values-in": "id",
}


def convert(text: str) -> str:
    text = text.strip()
    if len(text) >= 2 and text.startswith('"') and text.endswith('"'):
        text = text[1:-1]
    text = re.sub(r"\s*\n\s*", " ", text)  # XML 上の改行は空白1つ（Android と同じ）
    text = (text.replace("\\n", "\n").replace("\\'", "'").replace('\\"', '"').replace("\\@", "@").replace("\\?", "?"))
    text = re.sub(r"%(\d+\$)?s", lambda m: f"%{m.group(1) or ''}@", text)
    text = re.sub(r"%(\d+\$)?d", lambda m: f"%{m.group(1) or ''}lld", text)
    return text


def element_text(element) -> str:
    return "".join(element.itertext())


def load(folder: str):
    path = ANDROID_RES / folder / "strings.xml"
    root = ET.parse(path).getroot()
    strings, plurals, untranslatable = {}, {}, set()
    for element in root:
        name = element.get("name")
        if element.tag == "string":
            strings[name] = convert(element_text(element))
            if element.get("translatable") == "false":
                untranslatable.add(name)
        elif element.tag == "plurals":
            # iOS の複数形は数そのもの（数値）で one / other を選ぶので、Android で書式済みの数を入れていた %s も数値（%lld）にする。
            # 3桁区切りは Swift 側（L10n.count）で付ける
            plurals[name] = {item.get("quantity"): convert(element_text(item)).replace("%@", "%lld").replace("$@", "$lld")
                             for item in element}
    return strings, plurals, untranslatable


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def main(names):
    data = {folder: load(folder) for folder in LANGUAGES}
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    en_strings, en_plurals, untranslatable = data["values"]
    for name in names:
        localizations = {}
        for folder, language in LANGUAGES.items():
            strings, plurals, _ = data[folder]
            if name in en_plurals:
                forms = plurals.get(name) or (en_plurals[name] if name in untranslatable else None)
                if forms is None:
                    sys.exit(f"{folder} に plurals {name} がない")
                localizations[language] = {"variations": {"plural": {q: unit(v) for q, v in forms.items()}}}
            elif name in en_strings:
                value = en_strings[name] if name in untranslatable else strings.get(name)
                if value is None:
                    sys.exit(f"{folder} に {name} がない")
                localizations[language] = unit(value)
            else:
                sys.exit(f"英語の strings.xml に {name} がない")
        catalog["strings"][name] = {"extractionState": "manual", "localizations": localizations}
        print(f"取り込み: {name}")
    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
