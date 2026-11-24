# App Store の掲載情報（下書き）

App Store Connect の「App 情報」「（バージョンの）App Store」に、言語ごとに貼り付ける。
作り方: `python3 tools/store/app_store_listing.py`（Android 版の Google Play の掲載情報から作る。Android にしかない3行だけを iOS の文に入れ替える）

| 言語 | App Store Connect の言語 | ファイル | 名前 | サブタイトル | キーワード | 説明文 |
|---|---|---|---|---|---|---|
| 英語（U.S.） | English (U.S.) | [en.md](en.md) | 29 | 28 | 99 | 1506 |
| 日本語 | Japanese | [ja.md](ja.md) | 19 | 15 | 54 | 686 |
| スペイン語（スペイン・メキシコ） | Spanish (Spain), Spanish (Mexico) | [es.md](es.md) | 29 | 26 | 92 | 1641 |
| ポルトガル語（ブラジル・ポルトガル） | Portuguese (Brazil), Portuguese (Portugal) | [pt.md](pt.md) | 30 | 26 | 92 | 1597 |
| フランス語（フランス・カナダ） | French, French (Canada) | [fr.md](fr.md) | 26 | 26 | 94 | 1840 |
| ドイツ語 | German | [de.md](de.md) | 26 | 29 | 93 | 1643 |
| 韓国語 | Korean | [ko.md](ko.md) | 22 | 17 | 45 | 793 |
| 繁体字中国語 | Chinese (Traditional) | [zh-Hant.md](zh-Hant.md) | 21 | 15 | 43 | 593 |
| インドネシア語 | Indonesian | [id.md](id.md) | 29 | 29 | 96 | 1593 |

- 上限: 名前 30・サブタイトル 30・プロモーションテキスト 170・キーワード 100・説明文 4,000 文字（作るときに確かめている）
- 「名前」は App Store 全体で同じ名前のアプリがあると使えない。そのときは App Store Connect で教えてもらえるので、少し変える
- 名前・サブタイトルにある言葉はキーワードに入れなくても検索に使われるので、キーワードは別の言葉にしている
- 「No.1」「最高」などの言葉や、ほかのアプリの名前は使っていない（Apple の審査ガイドライン 2.3.7）
- 日本語・英語以外は Claude が作った。公開前にネイティブの人に見てもらえるとより安心

## スクリーンショット（6.9 インチ・1320×2868。2026-11-24）
`screenshots/<言語>/01.jpg 〜 07.jpg`（9言語 × 7枚）。App Store Connect のバージョンのページの「iPhone 6.9 インチディスプレイ」に、言語ごとに番号の順で入れる（6.5 インチなどほかの大きさは、6.9 インチの画像から App Store が自動で作る）。
Android 版のストアの画像（`store/<言語>/phone_*.png`）と同じ見出し・背景・サンプルのメモで作った。

| # | 画面 | 日本語の見出し |
|---|---|---|
| 1 | 編集画面（文字色・書式パネル） | 文字に色をつけて 見やすいメモに ／ 太字・斜体・下線も |
| 2 | フォルダ一覧 | 色分けフォルダで すっきり整理 |
| 3 | 編集画面（選んだ範囲の文字数） | 文字数が ひと目でわかる ／ 選んだ範囲の文字数も表示 |
| 4 | メモ一覧（ピン留め・ロック） | 大事なメモは ロック＆ピン留め |
| 5 | フォルダの中 | フォルダの中に フォルダを作れる ／ 最大5階層まで |
| 6 | 出力の形式 | PDF・画像・テキストで 出力して共有 |
| 7 | メモ一覧（ダーク） | ダークモード にも対応 |

- 画面には広告を出していない（UI テストでは広告を使わないため）
- 「No.1」「最高」などの言葉・評価・「今すぐダウンロード」のような呼びかけは入れていない
- JPEG（画質 0.92）にしている（PNG だと 63 枚で 76MB になるため。App Store は JPEG も受け付ける。透明な部分は無い）

### 作り直すとき（画面を変えたあと）
1. こちら専用の 6.9 インチのシミュレーター `IrodoriNotes-ProMax`（iPhone 17 Pro Max・iOS 27.2）の上の帯を整える: `xcrun simctl status_bar IrodoriNotes-ProMax override --time 9:41 --batteryState discharging --batteryLevel 100`（起動しておく）
2. サンプルデータを Android 版から作り直す（Android 版の文章を変えたときだけ）: `python3 tools/store/make_sample_data.py` → `IrodoriNotes/App/StoreSampleData.swift`
3. `tools/store/StoreScreenshotTests.swift.txt` を `IrodoriNotesUITests/StoreScreenshotTests.swift` にコピーして撮る（10分ほど）:
   `xcodebuild test -project IrodoriNotes.xcodeproj -scheme IrodoriNotes -destination 'platform=iOS Simulator,name=IrodoriNotes-ProMax,OS=27.2' -derivedDataPath ./build -only-testing:IrodoriNotesUITests/StoreScreenshotTests` → `build/store-screens/`。終わったらコピーしたファイルは消す
4. `swift tools/store/compose_app_store.swift` → `screenshots/`（見出しはこのファイルの `captions`）
