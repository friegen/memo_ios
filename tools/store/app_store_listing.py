"""
App Store の掲載情報（9言語）を、Android 版の Google Play の掲載情報（store/listing/<言語>.md）から作る。

使い方:
    python3 tools/store/app_store_listing.py

- Android 版の文章をそのまま使い、Android にしかない3行（ロックの2行・自動バックアップの1行）だけを iOS の文に入れ替える
- App Store にだけある欄（サブタイトル・キーワード・プロモーションテキスト）はここに書く
- 文字数の上限（名前 30・サブタイトル 30・プロモーションテキスト 170・キーワード 100・説明文 4,000）を超えたら止める
- 出力: docs/store/app-store/<言語>.md
"""
import re
import sys
from pathlib import Path

ANDROID_LISTING = Path("/Users/dobashi/_workspace/04_kojin/03_memo_android_ref/store/listing")
OUT = Path(__file__).resolve().parents[2] / "docs/store/app-store"

# App Store Connect の言語（Android のファイル名 → App Store の言語）
LANGUAGES = {
    "en": ("en", "英語（U.S.）", "English (U.S.)"),
    "ja": ("ja", "日本語", "Japanese"),
    "es": ("es", "スペイン語（スペイン・メキシコ）", "Spanish (Spain), Spanish (Mexico)"),
    "pt": ("pt", "ポルトガル語（ブラジル・ポルトガル）", "Portuguese (Brazil), Portuguese (Portugal)"),
    "fr": ("fr", "フランス語（フランス・カナダ）", "French, French (Canada)"),
    "de": ("de", "ドイツ語", "German"),
    "ko": ("ko", "韓国語", "Korean"),
    "zh": ("zh-Hant", "繁体字中国語", "Chinese (Traditional)"),
    "id": ("id", "インドネシア語", "Indonesian"),
}

# ロックの節の2行（Android: 指紋・顔・PIN／最近使ったアプリの一覧）
LOCK = {
    "en": ["• Open locked notes and folders with Face ID, Touch ID, or your passcode",
           "• While a locked note is open, its contents are hidden from the app switcher"],
    "ja": ["・Face ID・Touch ID、または iPhone のパスコードで開くように設定できます",
           "・ロックしたメモを開いている間は、アプリの切り替え画面に中身を表示しません"],
    "es": ["• Abre las notas y carpetas bloqueadas con Face ID, Touch ID o el código",
           "• Mientras una nota bloqueada está abierta, su contenido no se muestra en el selector de apps"],
    "pt": ["• Abra notas e pastas bloqueadas com Face ID, Touch ID ou o código",
           "• Enquanto uma nota bloqueada estiver aberta, o conteúdo fica oculto no seletor de apps"],
    "fr": ["• Ouvrez les notes et dossiers verrouillés avec Face ID, Touch ID ou votre code",
           "• Lorsqu’une note verrouillée est ouverte, son contenu est masqué dans le sélecteur d’apps"],
    "de": ["• Gesperrte Notizen und Ordner mit Face ID, Touch ID oder Code öffnen",
           "• Solange eine gesperrte Notiz geöffnet ist, wird ihr Inhalt im App-Umschalter ausgeblendet"],
    "ko": ["• Face ID·Touch ID 또는 iPhone 암호로 열도록 설정",
           "• 잠긴 메모를 여는 동안에는 앱 전환기에 내용이 표시되지 않습니다"],
    "zh": ["・可設定用 Face ID、Touch ID 或 iPhone 密碼開啟",
           "・開啟已鎖定的記事時，App 切換器中不會顯示內容"],
    "id": ["• Buka catatan dan folder yang terkunci dengan Face ID, Touch ID, atau kode sandi",
           "• Saat catatan terkunci dibuka, isinya disembunyikan dari pengalih app"],
}

# 「そのほか」の節の最後の行（Android: 自動バックアップ）
BACKUP = {
    "en": "• Included in iCloud Backup, so your notes move with you to a new iPhone",
    "ja": "・iCloud バックアップに対応（機種変更のときもメモを引き継げます）",
    "es": "• Incluido en la copia de seguridad de iCloud, para llevar tus notas a un iPhone nuevo",
    "pt": "• Incluído no Backup do iCloud, para levar suas notas para um iPhone novo",
    "fr": "• Inclus dans la sauvegarde iCloud, pour retrouver vos notes sur un nouvel iPhone",
    "de": "• In der iCloud-Sicherung enthalten – so ziehen deine Notizen mit auf ein neues iPhone um",
    "ko": "• iCloud 백업 지원 (새 iPhone으로 바꿀 때도 메모를 옮길 수 있습니다)",
    "zh": "・支援 iCloud 備份（換新 iPhone 時也能帶走記事）",
    "id": "• Termasuk dalam Cadangan iCloud, jadi catatan bisa dipindahkan ke iPhone baru",
}

SUBTITLE = {
    "en": "Color text & character count",
    "ja": "色で整理、文字数もわかるメモ帳",
    "es": "Notas con color y contador",
    "pt": "Notas coloridas e contador",
    "fr": "Notes en couleur, compteur",
    "de": "Farbige Notizen & Zeichenzahl",
    "ko": "색으로 정리하고 글자 수도 확인",
    "zh": "彩色整理、字數一目了然的記事本",
    "id": "Catatan berwarna & penghitung",
}

# App Store の名前（Google Play の名前のままでは、App Store のほかのアプリで使われていて保存できなかった言語だけ。2026-11-25）
# 名前は App Store 全体で1つしか使えない。ここにない言語は Google Play の名前（store/listing の題名）をそのまま使う
NAME = {
    "ja": "いろどりメモ - 文字数がわかる色分けメモ帳",
    "es": "Irodori Notes - Notas de color",
}

# 名前・サブタイトルにある言葉は、キーワードに入れなくても検索に使われる（Apple の決まり）。カンマの後に空白を入れない
KEYWORDS = {
    "en": "memo,notepad,character counter,word count,folder,text color,lock,pdf,export,draft,highlight,journal",
    "ja": "メモ帳,文字数,カウント,ノート,フォルダ,色分け,文字色,ロック,PDF,下書き,日記,テキスト,シンプル",
    "es": "bloc de notas,caracteres,carpetas,colores,texto,bloqueo,pdf,exportar,borrador,apuntes,diario",
    "pt": "bloco de notas,caracteres,pastas,cores,texto,bloqueio,pdf,exportar,rascunho,anotações,diário",
    "fr": "bloc-notes,caractères,dossiers,couleurs,texte,verrouillage,pdf,exporter,brouillon,mémo,journal",
    "de": "notizblock,zeichenzähler,ordner,farben,text,sperre,pdf,export,entwurf,memo,schreiben,tagebuch",
    "ko": "메모장,글자수,글자 수 세기,노트,폴더,색깔,글자색,잠금,PDF,초안,일기,텍스트",
    "zh": "記事本,字數,字數統計,筆記,資料夾,顏色,文字顏色,鎖定,PDF,草稿,日記,備忘錄",
    "id": "notepad,penghitung karakter,karakter,folder,warna,teks,kunci,pdf,ekspor,draf,catatan harian,memo",
}

LIMITS = {"name": 30, "subtitle": 30, "promo": 170, "keywords": 100, "description": 4000}


def code_block(md: str, heading_prefix: str) -> str:
    match = re.search(r"## " + re.escape(heading_prefix) + r"[^\n]*\n```\n(.*?)\n```", md, re.S)
    if not match:
        sys.exit(f"見出し「{heading_prefix}」が見つからない")
    return match.group(1)


def sections(md: str):
    """Android の md から（タイトル・簡単な説明・詳しい説明）を取り出す。見出しの言葉は言語によらず日本語。"""
    return code_block(md, "タイトル"), code_block(md, "簡単な説明"), code_block(md, "詳しい説明")


def to_ios(lang: str, description: str) -> str:
    lines = description.split("\n")
    heads = [i for i, line in enumerate(lines) if line.startswith("■")]
    if len(heads) < 7:
        sys.exit(f"{lang}: 節の数が想定（7）とちがう")
    # 4つ目の節（ロック）の2行
    lock_start = heads[3] + 1
    lines[lock_start:lock_start + 2] = LOCK[lang]
    # 6つ目の節（そのほか）の最後の行
    heads = [i for i, line in enumerate(lines) if line.startswith("■")]
    more_last = heads[6] - 1
    while not lines[more_last].strip():
        more_last -= 1
    lines[more_last] = BACKUP[lang]
    text = "\n".join(lines)
    for word in ["Android", "PIN", "Google"]:
        if word in text:
            sys.exit(f"{lang}: 説明文に「{word}」が残っている")
    return text


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for android, (code, ja_name, en_name) in LANGUAGES.items():
        title, short, long = sections((ANDROID_LISTING / f"{android}.md").read_text(encoding="utf-8"))
        description = to_ios(android, long)
        fields = {"name": NAME.get(android, title), "subtitle": SUBTITLE[android], "promo": short, "keywords": KEYWORDS[android],
                  "description": description}
        for key, value in fields.items():
            if len(value) > LIMITS[key]:
                sys.exit(f"{android}: {key} が {len(value)} 文字（上限 {LIMITS[key]}）: {value}")
        if ", " in fields["keywords"]:
            sys.exit(f"{android}: キーワードのカンマの後に空白がある")
        counts = {k: len(v) for k, v in fields.items()}
        rows.append((ja_name, en_name, code, counts))
        (OUT / f"{code}.md").write_text(f"""# {ja_name}（App Store Connect: {en_name}）

## 名前（{counts['name']} / 30 文字）
```
{fields['name']}
```

## サブタイトル（{counts['subtitle']} / 30 文字）
```
{fields['subtitle']}
```

## プロモーションテキスト（{counts['promo']} / 170 文字。審査なしでいつでも変えられる）
```
{fields['promo']}
```

## キーワード（{counts['keywords']} / 100 文字。カンマ区切り）
```
{fields['keywords']}
```

## 説明文（{counts['description']} / 4,000 文字）
```
{fields['description']}
```
""", encoding="utf-8")
        print(f"{code}: 名前 {counts['name']} / サブタイトル {counts['subtitle']} / プロモーション {counts['promo']} / キーワード {counts['keywords']} / 説明文 {counts['description']}")
    table = "\n".join(f"| {ja} | {en} | [{code}.md]({code}.md) | {c['name']} | {c['subtitle']} | {c['keywords']} | {c['description']} |"
                      for ja, en, code, c in rows)
    (OUT / "README.md").write_text(f"""# App Store の掲載情報（下書き）

App Store Connect の「App 情報」「（バージョンの）App Store」に、言語ごとに貼り付ける。
作り方: `python3 tools/store/app_store_listing.py`（Android 版の Google Play の掲載情報から作る。Android にしかない3行だけを iOS の文に入れ替える）

| 言語 | App Store Connect の言語 | ファイル | 名前 | サブタイトル | キーワード | 説明文 |
|---|---|---|---|---|---|---|
{table}

- 上限: 名前 30・サブタイトル 30・プロモーションテキスト 170・キーワード 100・説明文 4,000 文字（作るときに確かめている）
- 「名前」は App Store 全体で同じ名前のアプリがあると使えない。そのときは App Store Connect で教えてもらえるので、少し変える
- 名前・サブタイトルにある言葉はキーワードに入れなくても検索に使われるので、キーワードは別の言葉にしている
- 「No.1」「最高」などの言葉や、ほかのアプリの名前は使っていない（Apple の審査ガイドライン 2.3.7）
- 日本語・英語以外は Claude が作った。公開前にネイティブの人に見てもらえるとより安心
""", encoding="utf-8")


if __name__ == "__main__":
    main()
