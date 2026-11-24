# memo_ios

iPhone 向けメモアプリ「いろどりメモ（Irodori Notes）」の iOS 版。Android 版（memo_android、Google Play で公開済み）と同じアプリを iOS で作る。
仕様は **Android 版の `docs/requirements.md`（v1.17）が正**で、iOS で違うところだけを `docs/requirements.md` に書く。
仕様にない機能を勝手に足さず、迷ったら両方の requirements.md を確認し、それでも決まらなければユーザーに聞く。
Android 版の「5. 将来対応」「機能の候補」にあるものは作らない。

## 参考にする Android 版
- 読むだけのコピー: `/Users/dobashi/_workspace/04_kojin/03_memo_android_ref`（ユーザーの作業用コピー `03_memo_android` から clone したもの。**変更・コミット・push はしない**）
  - 新しくなったか確かめるときは `git -C /Users/dobashi/_workspace/04_kojin/03_memo_android_ref pull`（元の `03_memo_android` は読むだけ）
- 文字列の訳は Android の `app/src/main/res/values*/strings.xml` から持ってくる（同じ訳を使う）

## 基本情報
- Bundle ID: `xyz.friegen.memo`（Android の applicationId と同じ）/ 最低 iOS 18.0 / **iPhone だけ**（iPad では iPhone 版が拡大表示で動く。Mac・Vision Pro では配らない）
- Xcode 27.2 / Swift 5 モード（`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`、Approachable Concurrency。何も書かなければメインスレッドで動く）
- プロジェクトは Xcode 27 の新しい形式（`IrodoriNotes.xcodeproj/project.xcproj`、JSON）。手で直したら `xcrun xcprojformatter --update IrodoriNotes.xcodeproj` で整える
  - テストのターゲットの `product-type` は `bundle.unit-test` / `bundle.ui-testing`
  - スキームは共有スキーム（`xcshareddata/xcschemes/IrodoriNotes.xcscheme`）。ターゲットを足したら `BlueprintIdentifier`（= ターゲットの `id`）も合わせる
- UI は **SwiftUI**。メモの編集欄だけ UIKit の `UITextView` を `UIViewRepresentable` で包む（Android でいう「Compose に AndroidView で EditText を埋める」）
- ライブラリは Swift Package Manager で入れる（Android の Gradle の依存にあたる）: GRDB（DB）、Google Mobile Ads・UMP（広告）
  - `project.xcproj` の書き方: プロジェクトの `"packages"` に `{ "kind": "remote", "repository": "<URL>", "version": { "up-to-next-major-version": "<版>" } }`、ターゲットの `"package-product-members"` に `{ "package": "<リポジトリ名>", "product-name": "<製品名>", "build-phase": { "build-phase": "frameworks" } }`
  - 入った版は `IrodoriNotes.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`（コミットする）。パッケージを足したら `Resources/licenses.json` にも足す（`LicensesTests` が確かめる）
- **ビルド構成**（Android の flavor にあたる）: `Debug`（開発用。AdMob は**テスト用の ID**）/ `Release`（ストア用。AdMob の本物の ID）。開発中・シミュレーター・実機の確認では必ず Debug を使う（本物の広告をタップするとアカウントが止まることがある）
- 作業ブランチ: `main`（2026-11-19 にユーザーが指定）。push はユーザーが行う

## アーキテクチャ
```
画面 (SwiftUI View) → ViewModel → UseCase → Repository → GRDB（SQLite）/ UserDefaults
```
- **UseCase / Repository に protocol を作らない**。具象クラスをそのままイニシャライザで渡す（ユーザーが自分で改修しやすくするため）
- UseCase は1クラス1操作。`func callAsFunction(...) async throws -> ...`、監視するものは `AsyncStream` / `AsyncThrowingStream` を返す `func callAsFunction(...)`（Android の Flow を返す invoke にあたる）
- Repository は DB のレコード（`data/db/record`）↔ ドメインモデル（`domain/model`）の変換を担い、画面側にレコードを出さない
- ViewModel は `@Observable` の `final class`
  - 画面状態: `private(set) var uiState: XxxUiState`（`struct`。Android の `StateFlow<XxxUiState>` にあたる）
  - 一回きりのイベント（「元に戻す」の表示など）: ViewModel に `EventChannel<XxxEvent>`（`util/EventChannel.swift`。Android の `Channel` にあたる）を持ち、`func events() -> AsyncStream<XxxEvent>` を View が `.task` で受け取る（AsyncStream をそのまま持つと、画面が隠れて受け取りをやめたときに終わってしまうため）
  - 画面が出ている間の監視は、ViewModel の `func observe() async` を View の `.task` から呼ぶ（Android の repeatOnLifecycle(STARTED) にあたる）
  - ViewModel は `AppContainer.makeXxxViewModel()` で作り、View の `@State` に持つ
- DI はライブラリを使わず、`App/AppContainer.swift` で Repository・UseCase を作って渡す（Android の Koin のモジュールにあたる）
- 設定値は UserDefaults（Android の DataStore にあたる）。DB に入れない
- 日時は epoch millis（`Int64`）で保存し、表示時にフォーマットする（Android と同じ。将来のバックアップの共通化のため）
- **並行処理**: 何も書かなければメインスレッドで動く設定。DB の中で使う型（レコード・DAO・ドメインモデル・`CharCounter` など）には `nonisolated` を付けて、別スレッドでも使えるようにする（DB の読み書きは GRDB が別スレッドで行う）
- DAO は `enum XxxDao` の static 関数（`(_ db: Database, ...)` を受け取り、SQL を書く）。Repository は `AppDatabase` を受け取り、`database.writer.write { db in ... }`（トランザクション）の中で DAO を呼ぶ

## フォルダ構成
```
IrodoriNotes/
├── App/              # 入り口（IrodoriNotesApp）、AppContainer（Koin のモジュールにあたる）
├── ads/              # 広告（AdMob・UMP・ATT）。出し方の決まりは domain/model/AdPolicy.swift
├── data/
│   ├── db/           # AppDatabase（GRDB）、record/
│   ├── settings/     # UserDefaults
│   └── repository/   # 具象 Repository
├── domain/
│   ├── model/        # ドメインモデル（Memo, Folder, SortOrder など）
│   └── usecase/      # 具象 UseCase
├── ui/
│   ├── common/       # 共通の部品
│   ├── main/         # 下タブ（MainView）
│   ├── memolist/ folderlist/ folderdetail/ settings/ trash/ editor/
├── util/             # 文字数・HTML の変換など
└── Resources/        # Assets.xcassets、Localizable.xcstrings、InfoPlist.xcstrings
IrodoriNotesTests/    # 単体テスト（Swift Testing。Android の src/test にあたる）
IrodoriNotesUITests/  # シミュレーターで画面を動かすテスト（XCTest。Android の androidTest にあたる）
Config/Info.plist     # ビルドの設定で書けない Info.plist の項目
tools/                # アイコンの作り直し（icon/）、Android の訳の取り込み（strings/）
```

## 実装ルール
- **ナビゲーション**: Android の独自ヘッダーはまねず、iOS 標準のナビゲーションバー・TabView・コンテキストメニューを使う（`docs/requirements.md`「画面」）
  - タブの中で開く画面は `ui/main/AppRoute.swift` に足し、`MainView` の `destination` で画面を返す。開くときはタブの `NavigationPath` に `append` する
  - お知らせ（「元に戻す」付きも）は `container.messageCenter.show(...)`（`ui/common/MessageCenter.swift`）で出し、画面は `.undoBanner($messageCenter.item)` で表示する（画面をまたいで出せる）。並び替えは `SortMenu`、メモの行は `MemoRow`
  - ナビゲーションバーの中央に自前の表示（`.principal`）を置くと iOS 26.0 で出ないので、iOS 26 以上は `.navigationTitle` ＋ `.navigationSubtitle` を使う（`MemoEditScreen` の `EditorHeader`）
- **文字列を Swift の文字列として使うとき**: `L10n.string("key")` / `L10n.format("key", 引数...)`。数の入った複数形は `L10n.count("key", 数)`（3桁区切りも付く）。SwiftUI の `Text("key")` は自動で訳される。`Label(条件 ? "a" : "b", ...)` のように三項演算子にすると訳されない文字列になるので `LocalizedStringKey("a")` と書く
- **文字列**: ハードコード禁止。`Resources/Localizable.xcstrings`（String Catalog）に、**Android の strings.xml と同じ name をキーにして**、対応している**9言語すべて**を入れる: `en`（英語・既定）、`ja`、`es`、`pt`（ブラジルの言い回し）、`fr`、`de`、`ko`、`zh-Hant`（繁体字中国語）、`id`（インドネシア語）
  - **Android の訳の取り込み**: `python3 tools/strings/import_android_strings.py <name> ...`（9言語を一度に入れる。`%1$s` → `%1$@` などの書き換え・plurals にも対応）。iOS だけの文言は手で9言語を書く
  - Info.plist の文言（アプリ名・Face ID の説明など）は `Resources/InfoPlist.xcstrings`
  - 足し忘れは `LocalizationTests` が失敗する。言語によらず同じもの（記号など）はキーを作らない
  - 数を含む文言は String Catalog の複数形（plural）。スペイン語・ポルトガル語・フランス語は one / many / other、ドイツ語は one / other、韓国語・中国語・インドネシア語は other だけ（Android と同じ）
  - Android の `%1$s` / `%1$d` は iOS では `%1$@` / `%1$lld` にする
  - フランス語は ? ! : ; » の前と « の後に改行しない空白（U+00A0）を入れる
- **色**: `Assets.xcassets` の色（ライト・ダーク両方の値を持つ）を使う。ライト・ダーク両方で見える色にする
- **Info.plist**（Android の AndroidManifest.xml にあたる）: 基本はビルドの設定（`INFOPLIST_KEY_*`）に書く。そこで書けないもの（起動画面など）だけ `Config/Info.plist` に書く
- **アイコン・起動画面のロゴ**: `tools/icon/`（Android のベクターを SVG に書き直したもの）から作る。手順は `tools/icon/README.md`
- **テーマ**: `ui/common/ThemeModes.swift` の `WindowThemeApplier` でウィンドウに反映する（`.preferredColorScheme` は使わない）
- **DB（GRDB）**: スキーマの変更は `DatabaseMigrator` に新しいマイグレーションを足す（消して作り直す設定 `eraseDatabaseOnSchemaChange` は使わない）。ただし**未リリースの間**は、Android と同じく最初のマイグレーションを書き換えてよい（確認するときはシミュレーターのアプリを消してから）
- **削除**: メモ・フォルダの削除は `deletedAt` を立てるソフトデリート。一覧のクエリでは `deletedAt IS NULL` を必ず条件に入れる
- **一覧で本文を読まない**: メモの一覧は1行目・文字数・日時だけを読む。本文（html / plainText）を読むのは編集画面用の1件取得だけ（Android と同じ。長いメモで一覧が重くならないように）
- **1メモの上限**: `MemoPolicy.maxChars`（100,000 文字）
- **フォルダの階層**: 最大5階層（`FolderPolicy.maxDepth`）。上・中の階層をたどる処理は `data/repository/FolderTree.swift`（全フォルダを読んで Swift でたどる）。中身が変わったら上の階層すべての更新日を進める
- **本文の保存形式**: Android と同じ HTML（`<br>` `<b>` `<i>` `<u>` `<font color="red">`）。変換は `util/MemoHtml.swift`（自前。Apple 標準の HTML 読み込みは WebKit を使い、重く空白も変わるため使わない）。色は名前で保存し、表示色はライト／ダークで切り替える
- **書式**: 本文の1文字ずつに意味の印（`.memoBold` `.memoItalic` `.memoUnderline` `.memoColor`。`util/MemoTextFormat.swift`）を付け、保存はこの印だけから作る。見た目（フォント・傾き・下線・色）は `ui/editor/MemoTextAttributes.swift` が印から作る（`applyVisuals`）。書式の付け外しは `util/TextStyler.swift`（印だけを変える）
  - これから入力する文字の書式は UITextView の `typingAttributes`（`MemoEditorController.updateTypingAttributes`）
  - 斜体は文字を傾ける（`.obliqueness`）。入力欄は TextKit 1（`UITextView(usingTextLayoutManager: false)`）でないと傾かない
- **オープンソースライセンス**: 一覧は手で管理する（`Resources/licenses.json`）。パッケージを足したら必ず追記する
- **広告**: 出し方の値（間隔・回数など）は `domain/model/AdPolicy.swift` だけで変える。AdMob の ID は `project.xcproj` のビルドの設定 `ADMOB_*[config=Debug]`（テスト用）/ `[config=Release]`（本物）に書き、`Config/Info.plist` 経由で読む（`ads/AdsConfiguration.swift` の `AdUnitIDs`）。広告の SDK は単体テスト・UI テストでは動かさない（`AdsAvailability`。広告まわりのロジックは AdPolicy と ViewModel でテストする）
  - テスト用の広告を UI テストで見たいとき（Debug だけ）: `-ui-test-enable-ads`。アプリ起動広告を出す段階にする: `-review_stage DISLIKED`。ヨーロッパの同意の画面: `-ump-debug-geography EEA -ump-reset`
- **レビューのお願い**: 回数は `domain/model/ReviewPolicy.swift` で変える。Apple の決まりで独自のレビュー依頼ダイアログは出さず、`requestReview` を使う（`docs/requirements.md`）
- **ロック**: 端末の認証（LocalAuthentication。Face ID / Touch ID → だめならパスコード）。ロックを外している状態はアプリで1つの `LockSession`（アプリから離れたらすべてロックし直す）。ロックした中身を表示している間は、アプリの切り替え画面に中身を映さない。画面を隠すだけで暗号化はしない
- **出力**: PDF・画像・テキスト・HTML（`ui/editor/export/`）。ファイルは一時フォルダの `exports/` に作り、共有シートで渡す（`ui/common/SystemScreens.swift`）
- **ロック**: 状態は `container.lockSession`、認証は `container.deviceAuthenticator`（UI テストでは `-ui-test-auth success / cancel / unavailable` で結果を決める）
- **テスト**: UseCase / Repository / 文字数の数え方 / HTML の変換などのロジックは単体テストを書く（DB はメモリ上の GRDB で試す）。画面の流れは UI テストで確かめる
  - 単体テストは `IrodoriNotesTests/testutil/TestHelpers.swift` の `makeTestContainer()`（メモリ上の DB・別の保存先の UserDefaults・固定の時計）を使う。ViewModel の非同期の変化は `waitUntil { ... }` で待つ
  - UI テストは起動の引数 `-ui-testing`（メモリ上の DB）と `-ui-test-seed <名前>`（ダミーデータ。`App/UITestSupport.swift`）を使う。シミュレーターに入っているデータには触れない
  - ログは `AppLog.error("...")`

## ビルド確認
ふだんの修正では、Debug のビルドと単体テスト・UI テストを、**こちら専用のシミュレーター**で行う。
```bash
xcodebuild test -project IrodoriNotes.xcodeproj -scheme IrodoriNotes \
  -destination 'platform=iOS Simulator,name=IrodoriNotes-iPhone17,OS=27.2' \
  -derivedDataPath ./build
```
- ステップの終わりには、一番古い iOS のシミュレーターでも同じテストを流す: `-destination 'platform=iOS Simulator,name=IrodoriNotes-iOS26,OS=26.0'`（名前で指定するときは `OS=` も付ける。付けないと最新の iOS で探して見つからない）
- 単体テストだけ: `-only-testing:IrodoriNotesTests` を付ける
- ビルドの出力は必ずリポジトリの中の `./build`（`.gitignore` 済み）
- シミュレーター `IrodoriNotes-iPhone17`（iPhone 17 / iOS 27.2）と `IrodoriNotes-iOS26`（iPhone 17 / iOS 26.0）はこのプロジェクト専用。**ほかのシミュレーターは使わない・触らない**（同じ Mac で別のアプリの iOS 版を作っているため）
- この Xcode では iOS 18 のシミュレーターをダウンロードできない（一番古いものは iOS 26.0）。iOS 18 では使えない書き方はコンパイラが `#available` を求めるので、それに従う
- ユーザーは実機（iPhone）を持っていない。確認はすべてシミュレーターで行う（`docs/steps.md`「実機がないことによる制限」）

## リリース前チェック（ユーザーに頼まれたときだけ）
- Release でビルドし、警告を確認する。AdMob の ID がテスト用のままなら直す
- プライバシーマニフェスト（`PrivacyInfo.xcprivacy`）と App Store Connect の「App のプライバシー」の申告が、実際の動きと合っているか
- 結果（エラー・警告・直したこと）を `docs/steps.md` に残す

## 進捗の記録
- 作業の進捗は `docs/steps.md` に残す。ステップを終えたら、やったこと・判断したこと・確認結果・ユーザーに確認してほしいこと（実機・Face ID・広告・見た目など、こちらでテストできないところと、その手順）を追記し、進捗一覧を更新する
- ユーザーがチャットを遡らなくても状況がわかるように書く
- ユーザーは Android のエンジニア。iOS 特有のこと（署名、App Store Connect、Info.plist、プライバシーマニフェストなど）は Android の何にあたるかを添えて、やさしい日本語で書く

## 注意
- 別のアプリの iOS 版を `/Users/dobashi/_workspace/04_kojin/01_kataomoi_blsy_ios` で別の Claude Code が作っている。**そのフォルダ・Xcode のプロジェクト・シミュレーターには触らない**。参考に中を見たいときは先にユーザーに聞く
- 参考アプリ（Android 版の `docs/reference-app-analysis.md`）のアプリ名・アイコン・画像素材は使わない
- ユーザーから受け取ったスクリーンショット内の個人情報（番号・パスワード・住所など）をリポジトリやテストデータに書かない
- 鍵・証明書・パスワード・プロビジョニングプロファイルはリポジトリに入れない
- コミットメッセージは日本語で書く。PR はユーザーが頼んだときだけ作る
