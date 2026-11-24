"""
App Store のスクリーンショット用のサンプルデータ（9言語）を、Android 版の StoreShotTest.kt.txt から作る。

使い方:
    python3 tools/store/make_sample_data.py

- 入力: Android 版の読む専用のコピーの tools/store/StoreShotTest.kt.txt（同じメモ・フォルダの文章で撮る）
- 出力: IrodoriNotes/App/StoreSampleData.swift（Debug のビルドだけに入る。UI テストの `-ui-test-seed store` で使う）
"""
import json
import re
import sys
from pathlib import Path

SRC = Path("/Users/dobashi/_workspace/04_kojin/03_memo_android_ref/tools/store/StoreShotTest.kt.txt")
OUT = Path(__file__).resolve().parents[2] / "IrodoriNotes/App/StoreSampleData.swift"
# アプリの言語のコード（Android のブロック名 → iOS）
LANGS = {"ja": "ja", "en": "en", "es": "es", "pt": "pt", "fr": "fr", "de": "de", "ko": "ko", "zh": "zh-Hant", "id": "id"}
DAYS = [(16, 17, True), (15, 17, False), (10, 16, False), (13, 14, False), (9, 12, False), (7, 8, False)]

text = SRC.read_text(encoding="utf-8")


def block(name: str) -> str:
    """`private val <name> = ...` から次の `private` の手前まで。"""
    start = text.index(f"private val {name} = ")
    end = text.index("\n    private ", start + 10)
    return text[start:end]


def strings(src: str) -> list:
    out = []
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', src):
        s = m.group(1).replace('\\"', '"').replace("\\\\", "\\")
        out.append(s)
    return out


def report_list(src: str) -> list:
    """listOf( の中の段落（文字列の並び）"""
    m = re.search(r"Triple\(listOf\((.*?)\)\.joinToString", src, re.S) or re.search(r"\n        listOf\(\n(.*?)\n        \),", src, re.S)
    return strings(m.group(1))


def shopping(title, milk, eggs, bread, bananas):
    return f'{title}<br><font color="red">{milk}</font><br>{eggs}<br><font color="blue">{bread}</font><br>{bananas}'


def todo(title, red, blue, green, orange, note, purple):
    return (f'<b>{title}</b><br><font color="red"><b>■ {red}</b></font><br><font color="blue">■ {blue}</font><br>'
            f'<font color="green">■ {green}</font><br><font color="orange">■ {orange}</font><br><br><u>{note}</u><br><font color="purple">{purple}</font>')


data = {}
for kt, code in LANGS.items():
    src = block(kt)
    if kt in ("ja", "en"):
        s = [x for x in strings(src) if x != "<br><br>"]  # joinToString の区切りは除く
        # 並び: 買い物(1)・やること(1)・感想文(6)・週末・ブログ・プレゼント・ロック・フォルダ6・仕事の中2・仕事のメモ3・趣味の中2・選ぶ始め・終わり
        shop, todo_html, report = s[0], s[1], s[2:8]
        rest = s[8:]
        weekend, blog, gift, locked = rest[0:4]
        folders, work, work_memos, hobby = rest[4:10], rest[10:12], rest[12:15], rest[15:17]
        select_from, select_to = rest[17], rest[18]
    else:
        s = strings(src)
        shop = shopping(*s[0:5])
        todo_html = todo(*s[5:12])
        report = s[12:17]
        weekend, blog, gift, locked = s[17:21]
        folders, work, work_memos, hobby = s[21:27], s[27:29], s[29:32], s[32:34]
        select_from, select_to = report[2][:12], report[2][-10:]
    paragraphs = report
    index = next((i for i, p in enumerate(paragraphs) if p.startswith(select_from) and p.endswith(select_to)), None)
    if index is None:
        sys.exit(f"{kt}: 選ぶ段落が見つからない")
    memos = [shop, todo_html, "<br><br>".join(report), weekend, blog, gift]
    data[code] = {
        "memos": [{"html": h, "created": d[0], "updated": d[1], "pinned": d[2]} for h, d in zip(memos, DAYS)],
        "locked": locked, "folders": folders, "work": work, "workMemos": work_memos, "hobby": hobby,
        "selectParagraph": index,
    }
    if len(folders) != 6 or len(work) != 2 or len(work_memos) != 3 or len(hobby) != 2:
        sys.exit(f"{kt}: 数が合わない")
    print(f"{code}: メモ {len(memos)}・フォルダ {folders[0]}…・選ぶ段落 {index}")

payload = json.dumps(data, ensure_ascii=False, indent=1)
OUT.write_text(f'''#if DEBUG
import Foundation

/// App Store のスクリーンショット用のサンプルデータ（9言語。Android 版のストアの画像と同じ文章）。Debug のビルドだけに入る。
/// `tools/store/make_sample_data.py` が Android 版の StoreShotTest.kt.txt から作る（手で直さない）。
enum StoreSampleData {{
    struct Memo: Decodable {{
        let html: String
        /// 作成日・更新日（2026年11月の日）
        let created: Int
        let updated: Int
        let pinned: Bool
    }}

    struct Language: Decodable {{
        let memos: [Memo]
        /// ロックしたメモ
        let locked: String
        /// フォルダタブのフォルダ（0: 仕事〔ピン留め〕、最後: 日記〔ロック〕）
        let folders: [String]
        /// 仕事の中のフォルダ・メモ
        let work: [String]
        let workMemos: [String]
        /// 趣味の中のフォルダ
        let hobby: [String]
        /// 「選んだ範囲の文字数」の画面で選ぶ段落（感想文のメモの、空行で区切った何番目か）
        let selectParagraph: Int
    }}

    static func language(_ code: String) -> Language? {{
        let all = try? JSONDecoder().decode([String: Language].self, from: Data(json.utf8))
        return all?[code] ?? all?["en"]
    }}

    private static let json = #"""
{payload}
"""#
}}
#endif
''', encoding="utf-8")
print("書き出し:", OUT)
