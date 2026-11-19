# 要件定義 iOS 版（i1.0 / 2026-11-19）

**Android 版の要件定義（memo_android の `docs/requirements.md` v1.17）が正**。iOS 版も同じアプリとして作る。
このファイルには **iOS で違うところだけ**を書く。ここに書いていないことは、Android 版のとおりに作る。
Android 版の「5. 将来対応」「機能の候補」にあるものは作らない。

- Android 版の参照用のコピー: `/Users/dobashi/_workspace/04_kojin/03_memo_android_ref`
- 版の書き方: iOS 版の変更は `i1.0`、`i1.1` …… のように書く（Android 版の v1.x と区別するため）
- 🟡 の項目は、iOS の決まりや仕組みに合わせて Android と変えたところ。**ユーザーに確認してほしい**

## 1. 前提（Android 版 1章にあたる）
- 開発環境: Xcode 27.2（iOS 27.2 SDK）
- **最低 iOS 18.0**（iPhone XS・XR〔2018年〕以降。Android の minSdk 28〔Android 9、2018年〕と同じ時期の機種）
- **iPhone だけ**に対応する。iPad では iPhone 版が拡大表示で動く（iPad 用の画面は作らない）。Mac（Apple シリコン）・Apple Vision Pro では配らない
- 画面の向き: 縦と横（Android と同じく回転できる）
- 広告: AdMob と UMP（同意）に加えて、iOS の ATT（トラッキングの許可）を扱う（下の「広告」）
- プライバシーポリシー: Android 版のものに iOS の分（IDFA・ATT・iCloud バックアップ）を書き足す（下の「プライバシー」）

## 2. アーキテクチャ（Android 版 2章にあたる）
| Android 版 | iOS 版 |
|---|---|
| MVVM + XML レイアウト（ViewBinding） | MVVM + **SwiftUI**。メモの編集欄だけ UIKit の `UITextView` を包んで使う |
| UI(Activity/Fragment) → ViewModel → UseCase → Repository → Room DAO / DataStore | 画面(View) → ViewModel → UseCase → Repository → **GRDB（SQLite）/ UserDefaults** |
| UseCase / Repository は interface を作らない | 同じ（**protocol を作らない**） |
| Koin | ライブラリなし。`AppContainer` で作って渡す |
| StateFlow（画面状態）/ Channel（一回きりのイベント） | `@Observable` の ViewModel の `uiState` / `AsyncStream` |
| Room（スキーマ JSON） | GRDB の `DatabaseMigrator`（マイグレーションを番号順に書く） |
| DataStore（Preferences） | UserDefaults |
| BottomNavigationView + Navigation Component | `TabView` + タブごとの `NavigationStack` |
| Splash Screen API | 起動画面（Launch Screen。止まった絵だけ）＋アプリの最初の画面で同じ見た目を出して待つ（下の「広告」） |
| EdgeToEdge / R8 | なし（iOS は標準で画面の端まで描く。難読化の仕組みはない） |
| strings.xml（9言語） | String Catalog（`Localizable.xcstrings`、9言語。キーは Android の name と同じ） |

## 3. データ仕様（Android 版 3章にあたる）
- DB は **SQLite（GRDB）**。テーブル・列は Android の Room と同じにする（memos / folders、`html`・`plainText`・`firstLine`・`charCount`・`createdAt`・`updatedAt`・`deletedAt`・`deletedWithFolder`・`deletedWithParent`・`parentId`・`isLocked`・`isPinned` など）
  - **本文は Android と同じ HTML**（`<br>` `<b>` `<i>` `<u>` `<font color="red">`、色は名前で保存）。将来バックアップを Android と共通にしやすくするため
  - 日時は epoch millis
- DB のファイルは `Library/Application Support/memo.sqlite`
- 文字数の数え方（改行を含めない・絵文字は1文字）・1メモの上限（100,000 文字）・1行目（50文字）・ゴミ箱・階層・並び替えのルールは Android と同じ
  - Swift の `String.count` は書記素（見た目の1文字）で数えるので、Android の数え方と同じ結果になる

## 4. 画面（Android 版 4章にあたる）

### 全体: iOS の部品に置き換えるもの
| Android 版 | iOS 版 |
|---|---|
| 独自の共通ヘッダー（戻る・タイトル・ボタン2つ） | iOS 標準の**ナビゲーションバー**（左に戻る、中央にタイトル、右にボタン）。戻るは画面の左端からのスワイプでもできる（iOS の標準） |
| 下タブ（アイコンだけ） | 🟡 iOS 標準のタブバー（**アイコンと文字**。iOS ではタブ名を出すのが標準のため） |
| 下タブを押すと、いつもそのタブのトップを開く（v1.8） | 同じ（iOS の標準は「前に見ていた画面に戻る」だが、Android の仕様に合わせる） |
| 長押しのポップアップメニュー（右寄せ） | iOS 標準の**コンテキストメニュー**（長押しで行が浮き上がり、メニューが出る） |
| 並び替えのダイアログ（6択・8択） | 🟡 ナビゲーションバーのボタンから出る**メニュー**（選んでいるものにチェック）。フォルダの中は「メモの並び順」「フォルダの並び順」の2つのサブメニュー |
| ＋の「メモ／フォルダ」のメニュー | 同じくメニュー |
| Snackbar「ゴミ箱に移動しました［元に戻す］」 | iOS には Snackbar がないので、同じ見た目・同じ動きの部品を作る（タブバー・バナーの上に数秒出る） |
| 確認ダイアログ | iOS 標準のアラート（`alert`）。3択以上や削除の確認は、iOS の決まりに合わせて削除のボタンを赤にする |
| フォルダの作成・編集のダイアログ（名前＋色10個） | 🟡 画面の下から出るシート（iOS のアラートには色の丸を置けないため）。開いたらキーボードを出す |
| 端末の戻るボタン | なし（iPhone には戻るボタンがない）。ナビゲーションバーの戻る・左端からのスワイプ |

### メモ編集画面
- ナビゲーションバー: 左に戻る、中央に文字数（タイトル）と行数（サブタイトル。文字を選んでいる間は「12文字を選択中」）、右に「出力」（キーボードが出ている間は「キーボードを閉じる」）と「書式」
- 書式パネル: 画面の下（キーボードが出ているときはキーボードのすぐ上）に出す。キーボードを閉じても出したまま（Android と同じ）
- 他のアプリからの貼り付けは文字だけ（Android と同じ）
- 自動保存: 入力が止まって3秒後・画面を閉じるとき・アプリが裏に回るとき（Android の onPause にあたる）
- 開いたときからあるメモを空にして戻るときの確認ダイアログ（Android v1.2）: **左端からのスワイプで戻るときも**同じダイアログを出す（このときだけスワイプで戻れないようにして、ダイアログを出す）

### 設定タブ
- テーマ（端末に従う／ライト／ダーク）・表示（文字の大きさ・行間）・ゴミ箱は Android と同じ
  - 文字の大きさは Android の sp と同じ数字の pt（小 14 / 中 16 / 大 20 / 特大 24）
- 🟡 **「データ」画面**: Android の「上限 25MB・自動バックアップ」の説明とバーは出さない（iOS のバックアップには上限がないため）。今のデータサイズと、「メモは iCloud バックアップ（と Mac・PC へのバックアップ）に含まれ、機種変更のときに引き継がれる」という説明だけを出す
- 「オープンソースライセンス」: 使っているライブラリ（GRDB・Google Mobile Ads・UMP など）の一覧と全文。一覧は手で管理する（Android の AboutLibraries にあたる自動の仕組みがないため）
- 「プライバシーポリシー」: アプリ内のブラウザ（`SFSafariViewController`。Android の Chrome Custom Tabs にあたる）で開く
- 「広告のプライバシー設定」: Android と同じ（同意が必要な地域の利用者だけ）

## 広告（Android 版「広告」にあたる）
- 種類・場所・出し方（バナー2か所・アプリ起動広告・リワード広告、AdPolicy の値）は Android と同じ
- AdMob の ID: **Debug ではテスト用の ID、Release（ストアに出す用）では本物の ID**（Android の develop / production の flavor にあたる）
- iOS 用のアプリと広告ユニット4つ（バナー メイン画面・バナー 編集画面・アプリ起動・リワード フォルダの作成）を AdMob に作る（ユーザーの作業。`docs/steps.md`）
- **ATT（トラッキングの許可）**: 初めて起動したとき、UMP の同意（必要な地域の人だけ）のあとに、UMP の「IDFA の説明メッセージ」→ iOS の許可ダイアログの順に出す。許可されたときだけ広告 ID（IDFA）を使う（断られても広告は出る）
  - その起動ではアプリ起動広告を出さない（Android の「同意の画面を出した起動では出さない」と同じ扱い）
- アプリ起動広告の「新しく起動したとき、起動画面のまま最大3秒待つ」: iOS の起動画面は止まった絵で、待たせることができない。そこで、アプリの最初の画面で起動画面と同じ見た目を出して最大3秒待つ
- 「アプリから開いたブラウザ（SFSafariViewController）・共有シート・App Store から戻ったとき」はアプリ起動広告を出さない（Android と同じ）
- SKAdNetwork の ID（広告の効果を測る仕組み。Google が一覧を出している）を Info.plist に入れる

## レビューのお願い（Android 版「レビューのお願い」にあたる）🟡
Apple は、アプリ独自のレビュー依頼ダイアログ（「レビューを書く／今はしない」）を禁止している（App Store 審査ガイドライン 5.6.1）。
1. **10回目**に開いたときの「いろどりメモはいかがですか？（気に入った／いまひとつ）」とお礼は Android と同じ
2. 「気に入った」と答えてから**さらに20回**開いたとき、独自のダイアログは出さず、Apple の仕組み（`requestReview`）を**1回だけ**呼ぶ
   - その場で星を付けられる iOS のダイアログ。出すかどうかは iOS が決める（1年に3回まで。出ないこともある）
   - 呼んだ次の起動からアプリ起動広告を出す（Android の「レビューをお願いした後」と同じ）
3. 「いまひとつ」の後の動き（次の起動からアプリ起動広告）は Android と同じ

## ロック（Android 版「ロック」にあたる）
- 端末の認証は **Face ID / Touch ID**（だめなら端末のパスコード）。アプリ独自のパスワードは使わない（Android と同じ）
  - Face ID を使うために、Info.plist に使う理由の文言（`NSFaceIDUsageDescription`。9言語）を入れる
- 🟡 **スクリーンショット**: iOS には Android の FLAG_SECURE にあたるものがなく、止められない。ロックした中身を表示している間は、**アプリの切り替え画面（最近使ったアプリの一覧にあたるもの）に中身を映さない**ことだけをする
- 🟡 **端末にパスコードがないとき**: iOS ではアプリから「Face ID とパスコード」の設定画面を直接開けない（開けるのは設定アプリのこのアプリのページだけ）。案内の文言（「設定 ＞ Face ID とパスコード でパスコードを設定してください」）だけを出し、設定を開くボタンは付けない
- アプリから離れたとき（バックグラウンドへ）にすべてロックし直すのは Android と同じ。Face ID の画面が出ている間・通知センターを下ろしただけ（バックグラウンドに行かない）ではロックし直さない

## 出力（Android 版「出力」にあたる）
- 形式（PDF・画像・テキスト・HTML）、大きさ（PDF は A4 縦、画像は幅 1080px）、白い背景、ファイル名の決まりは Android と同じ
- 共有は iOS の**共有シート**（Android の共有の画面にあたる）。「ファイルに保存」「プリント」なども共有シートから選べる
- ファイルはアプリの一時フォルダの `exports/` に作り、次に出力するときに前回のものを消す

## 対応言語（Android 版 v1.17 にあたる）
- 9言語は Android と同じ: 英語（既定）・日本語・スペイン語・ポルトガル語（ブラジルの言い回し）・フランス語・ドイツ語・韓国語・繁体字中国語・インドネシア語
  - iOS の言語のコード: `en` `ja` `es` `pt` `fr` `de` `ko` `zh-Hant` `id`（ポルトガル語は `pt` にして、ブラジルとポルトガルの両方の端末で使われるようにする）
- 訳は Android の strings.xml と同じものを使う
- アプリ名はどの言語でも「Irodori Notes」（日本語だけ「いろどりメモ」）
- 端末の言語で切り替わる。iOS の設定アプリの「いろどりメモ ＞ 言語」でこのアプリだけ別の言語にもできる（iOS の標準。Android 13 以降の「アプリの言語」にあたる）
- App Store の掲載情報（名前・サブタイトル・説明文・キーワード・スクリーンショット）は App Store Connect で言語ごとに用意する。文章は Android の `store/listing/` を元にする（App Store は文字数の上限が違う: 名前 30・サブタイトル 30・キーワード 100・説明文 4,000）

## バックアップ（Android 版「データ」画面・自動バックアップにあたる）
- アプリのデータ（DB・設定）は **iCloud バックアップと Mac・PC へのバックアップに含める**（iOS の標準のまま。上限はない）。機種変更（クイックスタート）でも引き継がれる
- Android と iPhone の間でメモを移す方法は作らない（Android 版の「機能の候補」のバックアップの書き出し・読み込みにあたるため）

## プライバシー
- **プライバシーポリシー**: Android 版（`friegen.github.io` の `irodori-notes/privacy-policy.md`）に iOS の分を書き足す（IDFA と ATT、iCloud バックアップ、iPhone の広告の設定の場所）。Android と iOS のどちらの利用者にも当てはまる書き方にする
- **App Store の「App のプライバシー」**（Google Play の「データ セーフティ」にあたる）: AdMob が集める情報（ID・使用状況・診断・おおよその位置など）と、ATT で許可された場合のトラッキングを申告する
- **プライバシーマニフェスト**（`PrivacyInfo.xcprivacy`。アプリが使う「理由の申告が必要な API」とデータの扱いを書くファイル。Android にはないもの）: UserDefaults などを使う理由を書く。Google の SDK は自分のマニフェストを持っている

## アプリアイコン
- Android のアイコン（ノートにペンで書くとペン先から色が広がる絵）と同じデザイン
- 1024×1024 を Android のベクター（`ic_launcher_foreground.xml`）から描き直す。iOS は角を丸めるだけで丸く切り抜かないので、Android より絵を大きく描く
- ダーク・色付き（tinted）のアイコン（iOS 18 から）も作る。色付きは Android の1色版（テーマアイコン用）を元にする

## 5. 将来対応（今回は作らない）
- Android 版の「5. 将来対応」「機能の候補」のすべて
- iPad 用の画面、Mac 版、ウィジェット、iCloud 同期
