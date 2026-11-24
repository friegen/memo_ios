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
