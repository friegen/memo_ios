# App Store Connect に入れるもの（iOS 版 1.0.0）

App Store Connect（https://appstoreconnect.apple.com/ 。Google Play Console にあたる）でアプリを登録・提出するときに入れる中身を、画面の順にまとめたもの。
片思いチェッカー iOS（b_kataomoi_ios の `docs/app-store-connect.md`。2026-11-24 に提出済み）の入れ方にそろえている。

- Google Play の欄との対応: 「アプリ名・簡単な説明・詳しい説明」→ App Store では「名前・サブタイトル・説明文」に加えて、**App Store にだけある**「プロモーション用テキスト」「キーワード」がある。「データ セーフティ」→「App のプライバシー」、「コンテンツのレーティング」→「年齢制限指定」、「アプリのアクセス権」→「App Review に関する情報」
- **Android・Google Play のことは書かない**（審査ガイドライン 2.3.10: ほかのプラットフォームの名前を出さない）。下の原稿と `app-store/<言語>.md` には入っていないことを確かめてある
- 説明文・キーワード・プライバシーの答えを変えたら、このファイルも直す

---

## 0. 申請の流れ（この順に進める）

かかる時間の目安: 準備とアップロード 30分〜1時間、App Store Connect の入力 1〜2時間（12言語の貼り付けとスクリーンショット）、審査 1〜2日。

### A. Mac での準備（ビルドを作って送る）
1. **Mac の memo_ios を最新にする**: `git pull`
2. **バンドル ID を登録する**（開発者サイト。Google Play にはない作業）: https://developer.apple.com/account/resources/identifiers/list →「＋」→「App IDs」→「App」→ Description `Irodori Notes`、Bundle ID は Explicit で `xyz.friegen.memo` → Capabilities は何も選ばない → Register
3. **配布用のプロファイルを作る**: https://developer.apple.com/account/resources/profiles/list →「＋」→ Distribution の「App Store Connect」→ App ID `xyz.friegen.memo` → 証明書は Apple Distribution（片思いチェッカーと同じもの）→ 名前を **`Irodori Notes App Store`**（1文字でも違うとプロジェクトが見つけられない）→ Generate → Download → ダウンロードしたファイルをダブルクリック
4. **アーカイブを作る**（Android の「署名付き AAB を作る」にあたる）: Xcode で `IrodoriNotes.xcodeproj` を開く → 上の実行先を「Any iOS Device (arm64)」にする → Product → Archive。終わると Organizer（作ったアーカイブの一覧）が開く
   - 「"Irodori Notes App Store" profile is missing.」と出たら「Download」を押す（ダブルクリックで取り込めていなくても、Xcode が開発者サイトから取ってくる。2026-11-25 にこれでアーカイブできた）
   - 署名のエラーで止まったら、エラーの文をターミナルの窓の Claude に渡す
5. **App Store Connect にアプリを作る**（下の「1」）。アップロードの前に作っておく（アプリが無いと送り先が無い）
6. **ビルドを送る**: Organizer で今のアーカイブを選ぶ →「Distribute App」→「App Store Connect」→ Distribute（途中で署名を聞かれたら、証明書 Apple Distribution・プロファイル `Irodori Notes App Store`）
   - 最後に「Upload Symbols Failed … GoogleMobileAds.framework / UserMessagingPlatform.framework」と出るのは問題ない（アップロードは成功している。片思いチェッカーと同じ）
   - App Store Connect で選べるようになるまで数分〜30分かかる（処理が終わると Apple からメールが来る）。その間に B を進める

### B. App Store Connect での入力（https://appstoreconnect.apple.com/ ）
7. **「App 情報」**: 右上の言語のメニューで12言語を足し、言語ごとに名前・サブタイトルを貼る（下の「2」）。カテゴリ・コンテンツ配信権・年齢制限指定（下の「3」）
8. **「価格および配信状況」**: 無料、**Mac・Vision Pro のチェックを外す**（下の「3」）
9. **「App のプライバシー」**: プライバシーポリシーの URL と、集めるデータの答え → 右上の「公開」（下の「4」）
10. **バージョンのページ「1.0 提出準備中」**（言語ごと）: スクリーンショット（中型ディスプレイは必須）・プロモーション用テキスト・説明・キーワード・サポート URL・マーケティング URL（下の「2」「6」）
11. **バージョンのページ（言語によらない欄）**:
    - 「ビルド」の「＋」で、6 で送ったビルド（1.0.0 (1)）を選ぶ
    - 著作権 `2026 friegen`
    - 「App Review に関する情報」: サインイン不要、連絡先、メモの英文（下の「5」）
    - 「このバージョンのリリース」（下の「5」）
12. **右上の「審査用に追加」→「審査へ提出」**。足りない欄があると赤字で教えてくれるので、そこを埋める

### C. 提出のあと
- 状態は「審査待ち」→「審査中」→「配信準備完了」（自動でリリースにしていれば、そのまま App Store に出る）。結果はメールでも来る
- **リジェクト（却下）されたら**、App Store Connect の「App Review」のメッセージをブラウザの窓の Claude に貼る。直し方と返事の文案を作る
- **公開されたら**、ブラウザの窓の Claude に伝える → friegen.github.io のサポートのページを検索に出す・トップページに App Store のリンクを足す
- 実機が無いので TestFlight（Google Play の内部テストにあたる）は使わない

---

## 1. アプリを作る（「マイ App」→「＋」→「新規 App」）

| 項目 | 入れるもの | メモ |
|---|---|---|
| プラットフォーム | iOS | |
| 名前 | `Irodori Notes - Color Notepad` | プライマリ言語（英語）の名前。ほかの言語の名前は 2 で入れる。App Store 全体で同じ名前があると使えない。そのときは少し変える（例 `Irodori Notes: Color Notepad`） |
| プライマリ言語 | 英語（米国） | 入れていない言語の国の人には、プライマリ言語のページが出るので英語にする（片思いチェッカーと同じ） |
| バンドル ID | `xyz.friegen.memo` | 先に developer.apple.com の「Identifiers」に登録してあること（`docs/steps.md` の手順） |
| SKU | `irodori-notes-ios` | 自分用の管理番号。利用者には見えない。あとから変えられない |
| ユーザアクセス | アクセス制限なし | |

## 2. ストアのページ（言語ごと）

App Store Connect の右上の言語のメニューで言語を足し、言語ごとに入れる。原稿は `app-store/<言語>.md`（文字数も書いてある）。

| アプリの言語 | App Store Connect で足す言語 | 原稿 |
|---|---|---|
| 英語 | English (U.S.)（プライマリ） | [app-store/en.md](app-store/en.md) |
| 日本語 | Japanese | [app-store/ja.md](app-store/ja.md) |
| スペイン語 | Spanish (Spain)・Spanish (Mexico)（**2つとも同じ原稿**） | [app-store/es.md](app-store/es.md) |
| ポルトガル語 | Portuguese (Brazil)・Portuguese (Portugal)（**2つとも同じ原稿**） | [app-store/pt.md](app-store/pt.md) |
| フランス語 | French・French (Canada)（**2つとも同じ原稿**） | [app-store/fr.md](app-store/fr.md) |
| ドイツ語 | German | [app-store/de.md](app-store/de.md) |
| 韓国語 | Korean | [app-store/ko.md](app-store/ko.md) |
| 繁体字中国語 | Chinese (Traditional) | [app-store/zh-Hant.md](app-store/zh-Hant.md) |
| インドネシア語 | Indonesian | [app-store/id.md](app-store/id.md) |

→ 言語は全部で **12**（英語を含む）。Google Play は「es」1つで全部のスペイン語の国に出るが、App Store は国ごとの言語なので、同じ原稿を2回入れる。

### 言語ごとに入れる欄と、どこにあるか

| 欄 | 上限 | 画面 | 原稿の見出し |
|---|---|---|---|
| 名前 | 30 | 「App 情報」 | 名前 |
| サブタイトル | 30 | 「App 情報」 | サブタイトル |
| プライバシーポリシー URL | — | 「App のプライバシー」（言語ごと） | 全言語 `https://friegen.github.io/irodori-notes/privacy-policy.html` |
| スクリーンショット | — | バージョンのページ（「1.0 提出準備中」） | 下の 6 |
| プロモーション用テキスト | 170 | バージョンのページ | プロモーションテキスト（**審査なしでいつでも変えられる**） |
| 説明 | 4,000 | バージョンのページ | 説明文 |
| キーワード | 100 | バージョンのページ | キーワード（カンマ区切り。空白を入れない方が多く入る） |
| サポート URL | — | バージョンのページ | 全言語 `https://friegen.github.io/irodori-notes/support-ios.html` |
| マーケティング URL | — | バージョンのページ | 全言語 `https://friegen.github.io`（AdMob の app-ads.txt はこのサイトから探される） |
| このバージョンの最新情報 | — | バージョンのページ | **1.0.0 では欄が出ない**（2回目の版から。Google Play の「リリースノート」にあたる） |

- サポートのページ・プライバシーポリシーの原稿は friegen/friegen.github.io の `irodori-notes/support-ios.md` / `privacy-policy.md`（日本語と英語。2026-11-24 に公開済み）

## 3. 一般の情報

### 「App 情報」

| 項目 | 入れるもの | メモ |
|---|---|---|
| カテゴリ（プライマリ） | 仕事効率化（Productivity） | Google Play と同じ |
| カテゴリ（セカンダリ） | ユーティリティ（Utilities） | 任意。片思いチェッカーと同じ |
| コンテンツ配信権 | 「いいえ、第三者のコンテンツを含んだり、表示したり、アクセスしたりしません」 | メモは利用者が書いたもので、外のコンテンツを取ってこない |
| 年齢制限指定 | 下の表 | |

### 年齢制限指定（質問に答えると Apple が区分を決める。Google Play の「コンテンツのレーティング」にあたる）

| 質問 | 答え | 理由 |
|---|---|---|
| 暴力・性的な内容・ギャンブル・薬物・医療など、内容についての質問 | すべて「なし」 | |
| ユーザーが作ったコンテンツ | いいえ | メモは自分の端末の中だけで、ほかの人に見せる機能はない |
| メッセージ・チャット | いいえ | |
| 広告 | はい | AdMob |
| 制限のない Web アクセス | いいえ | アプリの中のブラウザは、プライバシーポリシーのページを開くだけ |
| 保護者による管理・年齢の確認 | いいえ | |

※ 質問の言い方・並びは Apple が変えることがある。わからない質問は、アプリがそれをしているかで答える

### 「価格および配信状況」

| 項目 | 入れるもの |
|---|---|
| 価格 | 無料 |
| 配信する国 | すべての国（初期のまま） |
| Apple シリコン搭載の Mac・Apple Vision Pro での配信 | **どちらもチェックを外す**（初期はチェックが入っている。iPhone だけのアプリで、Mac・Vision Pro では確かめていないため。`docs/requirements.md`） |
| アプリの配信方法 | 公開（初期のまま。承認された後は変えられない） |

### そのほか

| 項目 | 入れるもの |
|---|---|
| App 内課金 | なし |
| 著作権（バージョンのページ） | `2026 friegen` |
| 輸出コンプライアンス（暗号化） | 聞かれない（ビルドの設定 `ITSAppUsesNonExemptEncryption = NO` で申告済み。独自の暗号化を使わず、通信の HTTPS だけのため） |

## 4. App のプライバシー（Google Play の「データ セーフティ」にあたる）

### 考え方
- **このアプリのコードが集めるデータは無い**。メモ・フォルダ・設定は端末の中だけ（`Resources/PrivacyInfo.xcprivacy` と同じ）
- **広告の SDK（Google Mobile Ads）が集めるデータを答える**。Apple の決まりでは、組み込んだ SDK が集めるものも「集める」に入る
- 片思いチェッカーで提出した答え（**Google の案内より多めに答える**。ユーザーの判断。少なく答えると審査で止められるが、多めに答えて止められることはない）にそろえる
- 提出の前に Google の最新の案内で変わっていないか確かめる: https://developers.google.com/admob/ios/privacy/data-disclosure

### 答え

「データを収集していますか？」→ **はい、このアプリからデータを収集しています**

使う目的は、7つとも「サードパーティ広告」「デベロッパの広告またはマーケティング」「アナリティクス」の3つ（デバイス ID だけはアナリティクスなし）。

| データの種類 | ユーザーに関連付けられる | トラッキングに使う |
|---|---|---|
| 位置情報 ＞ おおよその場所（IP アドレスから） | いいえ | はい |
| 閲覧履歴 | はい | はい |
| ID ＞ デバイス ID（IDFA。許可した人だけ） | はい | はい |
| 使用状況データ ＞ 製品の操作 | はい | はい |
| 使用状況データ ＞ 広告データ | はい | はい |
| 診断 ＞ クラッシュデータ | いいえ | はい |
| 診断 ＞ パフォーマンスデータ | はい | はい |

集めていないもの（選ばない）: 連絡先情報（名前・メールアドレス）、**ユーザーコンテンツ（メモの中身）**、検索の履歴、ID ＞ ユーザ ID、その他の診断データ、購入、健康、財務、連絡先、機密情報

- プライバシーポリシーの URL: `https://friegen.github.io/irodori-notes/privacy-policy.html`
- 入れたら、画面の右上の「公開」を押す（押さないと「審査用に追加」で止められる）
- 「トラッキング」に「はい」がある → アプリで ATT（トラッキングの許可）を聞いている（`NSUserTrackingUsageDescription`）ことと合っている

## 5. 審査に出すときの情報（バージョンのページの「App Review に関する情報」）

Google Play の「アプリのアクセス権」にあたる。

### サインイン情報
**「サインインが必要です」のチェックを外す**（ログインの機能が無いため）。

### 連絡先
開発者本人の名前・電話番号・メールアドレス（審査の人が問い合わせに使う。ストアには出ない）。**このリポジトリには書かない**。

### メモ（英語で書く。そのまま貼る）

```
Irodori Notes is a simple notepad. No account or sign-in is required, and all notes, folders, and settings are stored only on the device (with standard iCloud/device backups). The app has no servers of its own; it communicates only with Google AdMob / User Messaging Platform for ads.

Notes for review:
- On first launch, the Google UMP consent form is shown only in the EEA, UK, and Switzerland. It is followed by an explanation message and the App Tracking Transparency prompt. All features work without allowing tracking.
- Ads: banner ads on the main screen and the note editor, and an app open ad that is shown only after the app has been used for a while. Creating a folder inside another folder shows a rewarded ad (one ad allows two subfolders; top-level folders can be created without ads). If an ad cannot be loaded (e.g. offline), the folder is created without an ad.
- Lock: notes and folders can be locked. Unlocking uses Face ID / Touch ID or the device passcode via LocalAuthentication, so a device passcode must be set to use this feature. The app never receives biometric data. While locked content is open, it is hidden in the app switcher.
- Export: a note can be exported as PDF, image (PNG), text, or HTML and shared via the standard share sheet.
- The privacy policy opens in an in-app Safari view (SFSafariViewController).
- Rating requests use only Apple's standard requestReview API.
```

### このバージョンのリリース
- 「App 審査による承認後に、自動的にこのバージョンをリリースする」（初期のまま）でよい。公開の日を自分で決めたいときは「手動でリリースする」
- 公開されたら、friegen.github.io の `irodori-notes/support-ios.md` の `sitemap: false` を外し、トップページに App Store のボタンを足す（friegen.github.io の CLAUDE.md）

## 6. スクリーンショット（バージョンのページ。言語ごと）

App Store Connect の言語（右上のメニュー）ごとに、`01.jpg` 〜 `07.jpg` の順で入れる。スペイン語・ポルトガル語・フランス語は、2つの言語の欄の両方に同じ画像を入れる。

| 欄 | 大きさ | フォルダ |
|---|---|---|
| Dynamic Island 搭載 iPhone（中型ディスプレイ）（**必須**。6.1・6.3 インチ） | 1206 × 2622 | `app-store/screenshots_6.3/<言語>/` |
| Dynamic Island 搭載 iPhone（大型ディスプレイ）（任意。6.9 インチ。欄の右上の「メディアマネージャーですべてのサイズを表示」から開く） | 1320 × 2868 | `app-store/screenshots/<言語>/` |

- 2026-11-24 の App Store Connect では、必須なのは中型ディスプレイの方（片思いチェッカーの提出で分かった）。大型ディスプレイも入れておくと、大きい iPhone で見たときにきれい
- iPad・Apple Watch などの欄は空のまま（iPhone だけのアプリ）
- 中型ディスプレイの分は、6.9 インチの画像を縮めて作る: `python3 tools/store/make_app_store_6_3.py`（6.9 インチの画像を作り直したら、これも流す）

## 7. ビルドのアップロードと提出

1. Xcode で Product → Archive →「Distribute App」→ App Store Connect（手順は `docs/steps.md`）。最後に「Upload Symbols Failed … GoogleMobileAds.framework」と出るのは問題ない（Google が SDK を dSYM 無しで配っているため。片思いチェッカーと同じ）
2. 数分〜30分ほどで、App Store Connect のバージョンのページの「ビルド」の欄で選べるようになる
3. 上の 1〜6 がすべて入ったら、右上の「審査用に追加」→「審査へ提出」
