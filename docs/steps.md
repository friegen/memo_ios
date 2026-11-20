# 作業ステップと進捗

各ステップで「やったこと・判断したこと・確認結果・ユーザーに確認してほしいこと」をここに残す。
チャットを遡らなくても、このファイルだけで状況がわかるようにする。
（仕様は [requirements.md](requirements.md)〔iOS で違うところ〕と、Android 版の `docs/requirements.md` v1.17）

## 進捗一覧
| # | ステップ | 主な内容 | 状態 | コミット |
|---|---|---|---|---|
| 0 | プロジェクト設定 | 作り直し、iOS 18・iPhone だけ・Bundle ID・アプリ名（9言語）、テストのターゲット、専用シミュレーター、CLAUDE.md・仕様・進捗 | ✅ 完了 | `eabffc3`, `e399dd7` |
| 1 | データ層 | GRDB、メモ・フォルダのテーブル（ピン留め・ロックの列も最初から）、Repository、ドメインモデル、文字数、設定（UserDefaults） | ✅ 完了 | `d2d753a` |
| 2 | アプリの骨組み | AppContainer、下タブ3つ、テーマ、起動時のゴミ箱の期限切れ削除、アプリアイコン・起動画面 | ✅ 完了 | `f28d652` |
| 3 | メモタブ | 一覧、並び替え、長押しメニュー（削除・ピン留め）、元に戻す | ✅ 完了 | `6bfedcd` |
| 4 | メモ編集（基本） | 編集画面、文字数・行数・選んだ範囲の文字数、自動保存、空のメモの確認、10万文字の上限、文字の大きさ・行間、HTML の変換（文字・改行だけ） | 🟡 確認待ち | |
| 5 | メモ編集（書式） | 書式パネル（色10色・B・I・U）、HTML で保存・読み込み、貼り付けは文字だけ | | |
| 6 | フォルダタブ | 一覧（色付き）、作成・編集のシート、削除の確認、並び替え、ピン留め | | |
| 7 | フォルダの中 | フォルダとメモの一覧、5階層、パンくず、移動 | | |
| 8 | 設定 | テーマ・表示・データ・ゴミ箱・ライセンス・プライバシーポリシー | | |
| 9 | ロック | Face ID / Touch ID・パスコード、LockSession、切り替え画面で隠す | | |
| 10 | 出力 | PDF・画像・テキスト・HTML、共有シート | | |
| 11 | 広告 | AdMob（バナー2つ・アプリ起動・リワード）、UMP、ATT、広告のプライバシー設定 | | |
| 12 | レビューのお願い | 10回目の「いかがですか？」、requestReview | | |
| 13 | 仕上げ・ストア準備 | プライバシーマニフェスト、プライバシーポリシーの iOS 分、ライト・ダーク・9言語の見た目、Release ビルド、App Store Connect・TestFlight、ストアの文章 | | |

## 未決事項・ユーザー対応待ち
- [x] 【ステップ0】CLAUDE.md・requirements.md（🟡 の項目を含む）→ おすすめどおりで OK（2026-11-19）
- [x] 作業ブランチ → `main` に直接コミットする（push はユーザーが行う）（2026-11-19）
- [x] 最低 iOS → **iOS 18 のまま**。確認は iOS 26.0・27.2 のシミュレーターで行う（iOS 26.0 のシミュレーターを入れてよいと了承済み）（2026-11-19）
- [x] 【ステップ1】内容の確認 → OK（2026-11-19。Xcode でビルドしてアプリ名が出ることも確認）
- [x] 【ステップ2】アイコン・起動画面・下タブ → OK（2026-11-19）
- [x] 【ステップ3】メモタブ → OK（2026-11-20。次のステップへ進む指示）
- [ ] 【ステップ4】下の「ステップ4」の「ユーザーに確認してほしいこと」
- [ ] **Apple Developer Program に登録する**（年 99 ドル。Google Play の開発者登録にあたる）。シミュレーターでの開発・確認は登録なしで進められるが、App Store Connect・TestFlight・ストアへの提出には必要。ステップ13 までに。登録したらチーム ID を Claude に教える
- 実機（iPhone）はない（2026-11-19）→ 下の「実機がないことによる制限」
- [ ] AdMob に iOS のアプリと広告ユニットを作る（ステップ11 までに。手順は下の「AdMob でユーザーがすること」）
- [ ] App Store Connect でアプリを作る（ステップ13 までに。そのとき「Irodori Notes」の名前が使えるか確かめる）

## 実機がないことによる制限（2026-11-19）
ユーザーは iPhone を持っていないので、確認はすべてシミュレーターで行う。
| 確かめたいこと | シミュレーターで | 補足 |
|---|---|---|
| Face ID・パスコード | できる | シミュレーターのメニュー Features ＞ Face ID で「登録済み」「顔が合う／合わない」を切り替えられる |
| 広告（テスト広告）・ATT・UMP | できる | シミュレーターは自動でテスト端末として扱われる |
| 共有シート・PDF・画像 | できる | ファイルの中身は「ファイル」アプリに保存して見る |
| iCloud バックアップからの復元・機種変更 | **できない** | iOS の標準の仕組みに任せる（アプリ側で特別なことはしない） |
| 本物の指で触ったときの操作感・速さ | **できない** | 長いメモの速さは、シミュレーターと単体テストで見る |
| iOS 18 での動き | **できない** | iOS 18 のシミュレーターがこの Xcode にないため。iOS 26.0・27.2 で確かめる |
- 公開する前に TestFlight（App Store Connect のテスト配信。Google Play の内部テストにあたる）で確かめるには実機が要る。用意できない場合は、シミュレーターでの確認と Apple の審査で公開することになる

## AdMob でユーザーがすること（ステップ11 までに）
開発中はテスト用の ID を使うので、これが済まなくても作業は進められる。本物の ID は Release（ストアに出す用）のビルドだけで使う。
1. AdMob →「アプリ」→「アプリを追加」→ プラットフォームは **iOS** →「サポートされているアプリストアに登録済みですか？」は**いいえ** → アプリ名「Irodori Notes」→ 追加すると**アプリ ID**（`ca-app-pub-…~…`）ができる
2. そのアプリに**広告ユニットを4つ**作る（Android と同じ構成）
   - バナー（メイン画面）／バナー（編集画面）／アプリ起動／リワード（フォルダの作成）
3. 「プライバシーとメッセージ」で
   - GDPR（EEA・英国・スイス向け）のメッセージに iOS のアプリを加えて公開する
   - 「IDFA の説明メッセージ」（ATT の許可ダイアログの前に出す説明）を作って公開する
4. アプリ ID と広告ユニット ID 4つを Claude に教える（Android と同じく、プロジェクトの設定に書く。ID は秘密の情報ではない）
5. 公開後: AdMob でアプリを App Store にリンクする。App Store Connect の「マーケティング URL」を `https://friegen.github.io` にする（AdMob はここから app-ads.txt を探す。ファイルは Android と同じものでよい）

---

## ステップ0: プロジェクト設定（2026-11-19）

### 最初にあったプロジェクト（作り直す前）
- SwiftUI、最低 iOS 27.2、Bundle ID は仮の値、テストのターゲットなし、iPhone・iPad・Mac・Vision Pro 向け
- `memo_ios/` の中に Xcode が作った別の Git リポジトリ（`.git`）があり、外側の memo_ios リポジトリから中身を管理できなかった。個人の設定（`xcuserdata`）もコミットされていた
- 中身はテンプレートだけだったので、消して作り直した

### やったこと
| 種類 | ファイル | 内容 |
|---|---|---|
| プロジェクト | `IrodoriNotes.xcodeproj/project.xcproj` | リポジトリの一番上に作り直した。ターゲットは `IrodoriNotes`（アプリ）・`IrodoriNotesTests`（単体テスト）・`IrodoriNotesUITests`（UI テスト） |
| スキーム | `IrodoriNotes.xcodeproj/xcshareddata/xcschemes/IrodoriNotes.xcscheme` | 共有スキーム（Android の Run Configuration にあたる）。テストで単体テストと UI テストの両方を動かす |
| アプリ | `IrodoriNotes/App/IrodoriNotesApp.swift`, `RootView.swift` | 入り口と、アプリ名を出すだけの仮の画面（ステップ2で下タブに置き換える） |
| 文字列 | `IrodoriNotes/Resources/Localizable.xcstrings`, `InfoPlist.xcstrings` | String Catalog（9言語）。今はアプリ名だけ |
| 画像 | `IrodoriNotes/Resources/Assets.xcassets` | アイコンの枠（ライト・ダーク・色付き。絵はステップ2）とアクセントカラー |
| テスト | `IrodoriNotesTests/LocalizationTests.swift` | 9言語すべてに同じキーがあり、空でないか（Android の StringResourcesTest にあたる）。アプリ名が日本語だけ「いろどりメモ」か |
| | `IrodoriNotesUITests/LaunchUITests.swift` | シミュレーターで起動して、英語・日本語でアプリ名が出るか |
| その他 | `.gitignore`, `CLAUDE.md`, `docs/requirements.md`, `docs/steps.md` | `build/`・`xcuserdata/`・鍵や証明書はリポジトリに入れない |
| シミュレーター | `IrodoriNotes-iPhone17`（iPhone 17 / iOS 27.2） | このプロジェクト専用に作った |
| | `IrodoriNotes-iOS26`（iPhone 17 / iOS 26.0） | 一番古い iOS での確認用（2026-11-19 に追加） |

### 主な設定
| 項目 | 値 | Android でいうと |
|---|---|---|
| Bundle ID | `xyz.friegen.memo` | applicationId |
| 表示名 | Irodori Notes（日本語だけ いろどりメモ） | `app_name` |
| 最低 iOS | 18.0 | minSdk |
| 対応機種 | iPhone だけ（`TARGETED_DEVICE_FAMILY = 1`） | — |
| バージョン | 1.0.0（ビルド番号 1） | versionName / versionCode |
| 言語 | en（既定）・ja・es・pt・fr・de・ko・zh-Hant・id | `values-*` |
| 署名 | 自動（チームは未設定） | 署名の設定（keystore） |

### 判断したこと
- **ターゲット名は `IrodoriNotes`**: Swift ではターゲット名がモジュール名になる。`Memo` にすると、ドメインモデルの `Memo` 型と名前がぶつかるため
- **Xcode 27 の新しいプロジェクトの形式（`project.xcproj`）のまま**: JSON で読みやすく、差分も見やすい。説明書がないため、項目名は Xcode のツールから調べた（テストの種類は `bundle.unit-test` / `bundle.ui-testing`）
- **Mac・Vision Pro で「iPhone 版をそのまま動かす」設定も切った**（`SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD` などを NO）: 確認していない環境で配られないように
- **ポルトガル語は `pt`**（`pt-BR` にしない）: ブラジルとポルトガルの両方の端末でこの訳が使われるように（Android の `values-pt` と同じ考え方）
- **文字列のキーは Android の strings.xml の name**（例: `app_name`）: 訳を持ってくるとき・見比べるときに対応が分かるように
- **Swift の設定はテンプレートのまま**（Swift 5 モード・何も書かなければメインスレッドで動く設定）: 重い処理（DB・HTML の変換など）だけを明示的に別スレッドにする
- **iOS 18 のシミュレーターは使えなかった**: Xcode 27.2 でダウンロードできる一番古いものは iOS 26.0（約 8GB）だった。iOS 18 では使えない書き方をすると、コンパイラがエラーにして `#available`（Android の `Build.VERSION.SDK_INT` の判定にあたる）を求めるので、使えない機能で落ちることは防げる。ただし iOS 18 での見た目・動きは確かめられない

### 確認結果
- `xcodebuild test`（専用シミュレーター、ビルドの出力は `./build`）: ビルド成功、単体テスト 2件（言語の表ごとに分けて3通り）・UI テスト 2件すべて成功
- iOS 26.0 のシミュレーター（`IrodoriNotes-iOS26`）でも同じテストがすべて成功（2026-11-19）
- できたアプリの Info.plist: Bundle ID `xyz.friegen.memo`、表示名 Irodori Notes、最低 iOS 18.0、iPhone だけ、9言語のフォルダ（`*.lproj`）が入っている

### ユーザーに確認してほしいこと
1. **`CLAUDE.md` と `docs/requirements.md` の内容**。特に requirements.md の 🟡 の項目（iOS に合わせて Android と変えたところ）
   - タブバーに文字も出す／並び替えはメニュー／フォルダの作成・編集はシート／「データ」画面の説明／レビューのお願い／スクリーンショットは止められない／パスコードがないときは案内の文言だけ
2. **Xcode で開けるか**（手で作った形式なので念のため）→ 開けて、ファイルの一覧も正しく出ることを確認（2026-11-19）
   1. Finder で `03_memo_ios/IrodoriNotes.xcodeproj` をダブルクリックして Xcode 27.2 で開く
   2. 上のツールバーで、スキーム `IrodoriNotes` と、実行先のシミュレーター `IrodoriNotes-iPhone17` を選ぶ（ほかのシミュレーターは別の作業で使っているので選ばない）
   3. ▶（Run）を押す → シミュレーターに「Irodori Notes」（日本語の設定なら「いろどりメモ」）と出る
   4. ⌘U（Test）でテストが通る
3. **最低 iOS のバージョン**（上の「判断したこと」）→ A（iOS 18 のまま）に決定。iOS 26.0 のシミュレーターも入れる（2026-11-19）
   - A. iOS 18 のまま（おすすめ）: 使える人が一番多い。iOS 18 での見た目・動きは確かめられないので、確認は iOS 26・27 のシミュレーターで行い、iOS 18 はコンパイラの確認に任せる。iOS 18 の iPhone が手元にあれば、それで確かめてもらう
   - B. iOS 26 にする: 一番古い iOS でもシミュレーターで確かめられる。そのぶん iPhone XS・XR（iOS 26 に上げられない機種）の人は使えない
   - どちらの場合も、iOS 26.0 のシミュレーター（約 8GB）を入れてよければ、一番古い iOS での確認に使う

---

## ステップ1: データ層（2026-11-19）

### やったこと
| 種類 | ファイル | 内容 |
|---|---|---|
| ライブラリ | `IrodoriNotes.xcodeproj/project.xcproj` | GRDB 7.12.0 を Swift Package Manager で追加（7.x の範囲で更新する）。入っている版は `project.xcworkspace/xcshareddata/swiftpm/Package.resolved`（Android の依存の版を固定するファイルにあたる。コミットする） |
| DB | `data/db/AppDatabase.swift` | GRDB（SQLite）。ファイルは `Library/Application Support/memo.sqlite`。最初のマイグレーション "v1" で memos・folders を作る。DB の変化を流す `observe`（Room の Flow にあたる） |
| レコード | `data/db/record/MemoRecord.swift`, `FolderRecord.swift` | テーブルの1行（Room の Entity にあたる）。一覧用の `MemoSummaryRow`（本文を読まない）、件数付きのフォルダ |
| DAO | `data/db/dao/MemoDao.swift`, `FolderDao.swift` | SQL（Android の DAO と同じ SQL）。一覧・作成・更新・移動・ゴミ箱・完全削除 |
| Repository | `data/repository/MemoRepository.swift` | 有効なメモの取得・作成・更新・元に戻す・移動・ゴミ箱へ・ロック・ピン留め |
| | `FolderRepository.swift` | 有効なフォルダの取得・作成（5階層まで）・名前と色の変更・中身の件数・中身ごとゴミ箱へ・移動先の一覧・ロック・ピン留め |
| | `TrashRepository.swift` | ゴミ箱の一覧・復元（上の階層ごと）・完全削除・空にする・30日たったものの削除 |
| | `SettingsRepository.swift`, `data/settings/SettingsKeys.swift` | テーマ・文字の大きさ・行間・並び順3つ（UserDefaults。Android の DataStore にあたる） |
| | `FolderTree.swift`, `Mappers.swift` | 階層をたどる補助、レコード → ドメインモデルの変換 |
| ドメインモデル | `domain/model/` | `Memo`・`MemoSummary`・`Folder`・`FolderColor`・`MemoSort`・`FolderSort`・`TrashItem`・`ThemeMode`・`FontSizeLevel`・`LineSpacingLevel`・`EditorSettings` と、決まりごと（`MemoPolicy`・`FolderPolicy`・`TrashPolicy`） |
| ユーティリティ | `util/CharCounter.swift`, `util/AppClock.swift` | 文字数・行数・1行目、現在時刻 |
| ライセンス | `Resources/licenses.json` | オープンソースライセンスの一覧（今は GRDB だけ）。画面はステップ8 |

### 判断したこと
- **テーブル・列・保存する値は Android と同じ**: 列の名前・型、色の名前（red など）、並び順やテーマの保存名（`UPDATED_AT`・`DARK` など）、設定のキー（`theme_mode` など）をそろえた。将来バックアップを Android と共通にしやすくするため（テストで確かめている）
- **DAO は `enum` の中の関数（SQL を書く）**: Android の DAO の SQL をそのまま移せて、見比べやすいため。Repository は DB（`AppDatabase`）だけを受け取る。UseCase・Repository に protocol は作っていない
- **一覧で本文を読まない決まりも同じ**: iOS の SQLite には Android の「1行 約2MB」の上限はないが、一覧が重くならないように同じ作りにした
- **データの型はメインスレッドに縛らない**（`nonisolated`）: このプロジェクトは「何も書かなければメインスレッドで動く」設定なので、DB の中で使う型（レコード・ドメインモデルなど）にだけ印を付けて、DB の処理を別スレッドで動かせるようにした（Android の Dispatchers.IO にあたる）
- **設定の変化の監視**: UserDefaults が変わったときの知らせ（`UserDefaults.didChangeNotification`）を受けて、値が変わったときだけ流す（Android の DataStore の Flow ＋ distinctUntilChanged と同じ動き）
- **名前の並び順**: 端末の言語に合わせた比べ方（Android の Collator にあたる `String.compare(_:locale:)`）
- **時刻**: `AppClock` は、テストで継承して時刻を固定できるようにした（protocol は使わない）
- **HTML の変換はステップ4・5に回した**: 画面（UITextView の装飾）とつながる部分が多いため。Android もステップ4・5で作っている
- **ライセンスの一覧は手で管理し、テストで足し忘れを見つける**: `Package.resolved` に載っているパッケージが `licenses.json` にすべてあるかを `LicensesTests` が確かめる

### 確認結果
- 単体テスト 70件すべて成功（iOS 27.2・iOS 26.0 の両方のシミュレーター）、UI テスト 2件も成功。ビルドの警告なし
| テスト | 件数 | 主な内容 |
|---|---|---|
| `CharCounterTests` | 10 | 改行を数えない（\r\n・\r・\n）、絵文字（ZWJ・国旗・肌の色・異体字セレクタ）、結合文字、行数、1行目、上限の位置（UTF-16） |
| `SortTests` | 9 | 各並び順・昇順降順、同じ値の順、日本語の名前順、ピン留めが上、色の名前が Android と同じ |
| `MemoRepositoryTests` | 13 | 作成・更新・同じ内容なら何もしない・元に戻す・移動・ゴミ箱へ・ロック・ピン留め・フォルダの更新日・約120万文字のメモがあっても一覧が出る・DB が変わると一覧に流れる |
| `FolderRepositoryTests` | 10 | フォルダタブ直下と中のフォルダ、件数、階層のパス、5階層の上限、上の階層の更新日、名前と色の変更、中身ごとゴミ箱へ、移動先の一覧 |
| `TrashRepositoryTests` | 15 | Android の TrashRepositoryTest と同じ各パターン（フォルダごとの復元・先に単体で削除したものは残る・上の階層ごとの復元・完全削除・空にする・30日） |
| `SettingsRepositoryTests` | 6 | 既定値、保存、並び順3つが別々、不正な値は既定値、保存する名前が Android と同じ、変わったときだけ流れる |
| `AppDatabaseTests` | 3 | 列が Android と同じ、フォルダの完全削除で中身も消える、ファイルの DB を作れる |
| `LicensesTests` | 2 | 使っているパッケージがライセンスの一覧にすべてあり、全文がある |

### ユーザーに確認してほしいこと
- このステップは画面がないので、シミュレーターで触って確かめるところはない
- 内容（上の「判断したこと」）に問題がなければ、ステップ2（アプリの骨組み: 下タブ3つ・テーマ・起動時のゴミ箱の期限切れ削除・アプリアイコン）に進む

---

## ステップ2: アプリの骨組み（2026-11-19）

### やったこと
| 種類 | ファイル | 内容 |
|---|---|---|
| 入り口 | `App/IrodoriNotesApp.swift` | 起動時にゴミ箱の期限切れ（30日）を削除（Android の MemoApplication と同じ） |
| 入れ物 | `App/AppContainer.swift` | Repository を1つずつ作り、UseCase・ViewModel を `makeXxx()` で作る（Android の Koin のモジュールにあたる）。ログ（`AppLog`） |
| メイン画面 | `ui/main/MainView.swift`, `MainViewModel.swift` | 下タブ3つ（メモ / フォルダ / 設定）。タブごとに画面の積み重ね（NavigationStack）を持ち、タブを押すといつもトップに戻す（Android v1.8） |
| テーマ | `ui/common/ThemeModes.swift` | 設定のテーマ（端末に従う／ライト／ダーク）をウィンドウに反映。設定画面はステップ8 |
| UseCase | `domain/usecase/PurgeExpiredTrashUseCase.swift`, `GetThemeModeUseCase.swift`, `ObserveThemeModeUseCase.swift` | ゴミ箱の期限切れ削除、テーマの読み込み・監視 |
| タブの画面（仮） | `ui/memolist/MemoListScreen.swift`, `ui/folderlist/FolderListScreen.swift`, `ui/settings/SettingsScreen.swift` | タイトルだけの空の画面。中身は各ステップで作る |
| アイコン | `Resources/Assets.xcassets/AppIcon.appiconset` | 通常・ダーク・色付き（tinted）の 1024×1024 |
| 起動画面 | `Config/Info.plist`, `Assets.xcassets/LaunchLogo.imageset`, `LaunchBackground.colorset` | 背景（ライト 白 / ダーク 黒）の中央にロゴ（Android の起動画面と同じく薄い青の丸の上） |
| 色 | `Assets.xcassets/AccentColor.colorset` | アクセントカラー（ボタン・選択中のタブの色）を Android の brand_primary に（ライト #0A6CD6 / ダーク #3D95F5） |
| 文字列 | `Localizable.xcstrings` | タブ名（`tab_memo`・`tab_folder`・`tab_settings`）9言語 |
| ツール | `tools/icon/`（`make_svgs.py`・`render.swift`・`README.md`） | Android のアイコンのベクターを SVG に書き直し、PNG に描く。絵を直すときはここから作り直す |
| | `tools/strings/import_android_strings.py` | Android の strings.xml（9言語）から指定した name を String Catalog に取り込む（`%1$s` → `%1$@` などの書き換え、plurals にも対応） |

### 判断したこと
- **アイコンは Android のベクターから描き直した**: 512px の PNG を拡大するとぼやけるため。図形・色・グラデーションは Android と同じで、iOS は角を丸めるだけなので絵を大きめにした（`tools/icon/make_svgs.py` の `VIEW`）
  - App Store のアイコンは透明の情報（アルファ）を持てないので、通常のアイコンはアルファなしで書き出す
  - 途中で見つけた不具合: アルファなしで書き出すと絵が描かれず真っ黒になっていた（ホーム画面で黒い四角）。アルファ付きで描いてから外すように直した
- **ダークのアイコンは背景を透明に**: iOS が暗い背景を敷く。**色付き（tinted）**は Android の1色版（テーマアイコン）と同じ形を白で描き、iOS が色を付ける
- **起動画面は Info.plist に書く**: ビルドの設定（`INFOPLIST_KEY_*`）では起動画面のロゴを指定できないため、`Config/Info.plist` に書き、ほかの項目はこれまでどおりビルドの設定から作る（Xcode が合わせる）
- **テーマはウィンドウの設定で反映**: SwiftUI の `.preferredColorScheme` は「端末に従う」に戻したときに前のテーマが残ることがあるため、ウィンドウの `overrideUserInterfaceStyle` を直接変える（シート・アラート・UIKit の部品にも効く）。起動直後から保存したテーマで出る（ちらつかない）ように、最初の値はすぐに読む
- **タブの画面のタイトルは中央に小さく**（iOS の大きいタイトルにしない）: Android のヘッダーと同じ見た目にするため
- **タブのアイコン**: iOS の標準のアイコン（SF Symbols。Android の Material Icons にあたる。ライセンスの一覧に載せる必要はない）の note.text・folder・gearshape

### 確認結果
- 単体テスト 74件・UI テスト 2件すべて成功（iOS 27.2・iOS 26.0）、ビルドの警告なし
  - 追加: `PurgeExpiredTrashUseCaseTests`（30日を過ぎたものだけ消える）、`MainViewModelTests`（保存したテーマで始まる・設定が変わると追従する）、`LaunchUITests`（タブが3つあり押すと切り替わる・日本語のタブ名）
- シミュレーターの画面を撮って確認: タブ（日本語・ライト）、端末がライトでもアプリの設定がダークならダーク（設定は起動の引数 `-theme_mode DARK` で指定）、ホーム画面のアイコン、起動画面（ダーク）

### ユーザーに確認してほしいこと（Xcode でシミュレーター `IrodoriNotes-iPhone17` に入れて）
1. **ホーム画面のアイコン**: 前に入れたアプリが残っていると古い（空の）アイコンのままのことがあるので、シミュレーターのアイコンを長押し →「アプリを削除」してから ▶ で入れ直す
   - ダーク・色付きのアイコン: ホーム画面の何もないところを長押し → 左上の「編集」→「カスタマイズ」→ 下の「ダーク」「色付き」を選ぶ
2. **起動画面**: アプリを起動した瞬間に、白（ダークなら黒）の背景の中央に薄い青の丸とロゴが出る（一瞬で消える）
   - シミュレーターのダークモード: メニューの Features ＞ Toggle Appearance（⇧⌘A）
3. **下タブ**: メモ・フォルダ・設定の3つ（アイコンと文字）。押すと画面のタイトルが変わる。ライト・ダークで見やすいか
4. テーマの切り替え（設定画面）はステップ8で作るので、まだ確かめられない

---

## ステップ3: メモタブ（2026-11-19）

### やったこと
| 種類 | ファイル | 内容 |
|---|---|---|
| UseCase | `domain/usecase/ObserveMemoTabMemosUseCase.swift` | メモタブのメモを並び順で並べて監視（メモか並び順が変わるたびに流れる） |
| | `SetMemoTabSortUseCase` / `MoveMemoToTrashUseCase` / `RestoreMemoUseCase` / `SetMemoPinnedUseCase` | 並び順の保存 / ゴミ箱へ / 元に戻す（ゴミ箱画面の復元でも使う） / ピン留め |
| モデル | `domain/model/SortedMemos.swift` | 並び替え済みの一覧＋そのときの並び順 |
| ViewModel | `ui/memolist/MemoListViewModel.swift` | 一覧・空表示・並び順の状態、「元に戻す」を出すイベント |
| 画面 | `ui/memolist/MemoListScreen.swift` | ナビゲーションバーに並び替え・新規作成、一覧、空表示、長押しメニュー（ピン留め・削除）、元に戻す |
| 共通部品 | `ui/common/MemoRow.swift` | メモ一覧の1行（ピン・ロックのアイコン、1行目、作成日・更新日、文字数）。フォルダの中でも使う |
| | `ui/common/SortMenu.swift` | 並び替えメニュー（見出し「並び替え」、選んでいるものにチェック）と、メモの並び順の6つの選択肢 |
| | `ui/common/UndoBanner.swift` | 「ゴミ箱に移動しました［元に戻す］」のお知らせ（Android の Snackbar にあたる。色も Android と同じ） |
| | `ui/common/DateTimeText.swift` | 日時の表示（端末の言語に合わせた順序。日付の途中では折り返さない） |
| 画面遷移 | `ui/main/AppRoute.swift`, `MainView.swift` | タブの中で開く画面の一覧（今は編集画面だけ） |
| 編集画面（受け口） | `ui/editor/MemoEditScreen.swift` | 空の画面（下タブを隠す）。中身はステップ4 |
| 共通処理 | `util/AsyncCombine.swift` | 2つの流れの最新の値をまとめる（Android の Flow の combine にあたる） |
| | `util/EventChannel.swift` | ViewModel から画面への一回きりのイベント（Android の Channel にあたる） |
| | `util/L10n.swift` | 書式付きの訳・複数形の訳を文字列で読む（Android の getString / getQuantityString にあたる） |
| UI テスト用 | `App/UITestSupport.swift` | 起動の引数 `-ui-testing` でメモリ上の DB を使い、`-ui-test-seed memos` でダミーのメモを入れる（Debug のビルドだけ） |
| 文字列 | `Localizable.xcstrings` | 一覧・並び替え・削除・元に戻す・ピン留めなど 22 項目を Android から取り込み（9言語） |

### 判断したこと
- **長押しメニューは iOS 標準のコンテキストメニュー**（行が浮き上がり、その下にメニュー）。ピン留め／削除（削除は赤）。ロックの項目はステップ9で足す
- **並び替えはナビゲーションバーのボタンから出るメニュー**（要件 i1.0 のとおり）。見出し「並び替え」と、選んでいるものにチェック
- **「元に戻す」は3秒で消える**（Android の Snackbar の LENGTH_LONG とほぼ同じ）。下タブのすぐ上に出し、出ている間は一覧がその分だけ縮む（最後の行が隠れない）
- **行をタップすると編集画面**。iOS の一覧によくある右端の「＞」は付けていない（Android と同じく、右端は文字数）
- **一回きりのイベントの受け取り方**: AsyncStream は受け取りをやめる（タブを切り替えて画面が隠れる）と終わってしまうので、画面が出るたびに受け取り直せる `EventChannel` を作った（受け取る画面がないときのイベントは取っておく。Android の Channel と同じ）。CLAUDE.md に追記
- **訳の複数形は、アプリが使っている訳の言語の決まりで選ぶ**: 端末の言語（このシミュレーターは日本語）の決まりで選ぶと、英語の訳で「1 characters」になっていた（テストで見つけた）。iOS の「アプリごとの言語」で端末と違う言語にしたときも同じことが起きるため
- **UI テストはメモリ上の DB で動かす**: シミュレーターに入っているメモを使わない・消さない。ダミーのメモ（Shopping list など。個人の情報は入れない）は起動の引数で入れる

### 確認結果
- 単体テスト 81件・UI テスト 8件すべて成功（iOS 27.2・iOS 26.0）、ビルドの警告なし
  - 追加の単体テスト: `ObserveMemoTabMemosUseCaseTests`（並び順で並ぶ・並び順を変えると流れ直す・フォルダのメモは出ない）、`MemoListViewModelTests`（読み込み前は空表示を出さない・削除で元に戻すのイベント・元に戻す・ピン留めで一番上・並び順の保存）、`AsyncCombineTests`、`EventChannelTests`（受け取り直せる・取っておく）、`L10nTests`（複数形）、`DateTimeTextTests`（日本語・ドイツ語の順序、折り返し）
  - 追加の UI テスト（`MemoListUITests`）: メモがないときの案内、更新日の新しい順、並び替え（文字数の少ない順）、長押し → 削除 → 元に戻す、ピン留めで一番上・外すと元の位置、行と＋で編集画面（下タブが隠れる）
- 画面を撮って確認（日本語、ライト・ダーク）: 一覧（ピン・作成日・更新日・文字数）、長押しメニュー、「元に戻す」のバー、並び替えメニュー

### ユーザーに確認してほしいこと（Xcode で `IrodoriNotes-iPhone17` に入れて）
編集画面がまだ空なので、ふだんの操作ではメモを作れない。確認用のメモは、スキームの起動の引数で入れる:
1. Xcode のメニュー Product ＞ Scheme ＞ Edit Scheme…（⌘<）→ 左の Run →「Arguments」タブ →「Arguments Passed On Launch」の＋で `-ui-testing` と `-ui-test-seed memos` の2行を足す（メモリ上の DB なので、アプリを閉じると消える）
2. ▶ で起動 → メモが3つ並ぶ（更新日の新しい順: Shopping list → Ideas → Meeting notes）
3. 右上の並び替えボタン → メニューの見出し「並び替え」と6つの選択肢、選んでいるものにチェック → 選ぶと並びが変わる
4. 行を長押し → メニュー（ピン留めする／削除）
   - ピン留めする → 一番上に移り、ピンのアイコンが付く。もう一度長押し → ピン留めを外す
   - 削除 → 一覧から消え、下に「ゴミ箱に移動しました［元に戻す］」が3秒出る →「元に戻す」で戻る
5. 行または右上の＋ → 空の編集画面（下タブが消える）→ 左上の戻るで一覧へ
6. ライト・ダーク（⇧⌘A）で文字・バッジ・お知らせのバーが見やすいか
7. 確認が終わったら、Edit Scheme で足した2行のチェックを外す（消してもよい）

---

## ステップ4: メモ編集（基本）（2026-11-20）

### やったこと
| 種類 | ファイル | 内容 |
|---|---|---|
| 画面 | `ui/editor/MemoEditScreen.swift` | 入力欄、ナビゲーションバーに戻る・文字数（タイトル）・行数／選んだ範囲の文字数（サブタイトル）・キーボードを閉じる、新規ならキーボードを出す、空にしたときの確認ダイアログ、文字の大きさ・行間の反映 |
| 入力欄 | `ui/editor/MemoTextView.swift` | UIKit の UITextView を SwiftUI に埋めたもの（`MemoEditorController` で本文を入れる・キーボードを出す／閉じる）。何も書いていないときは「メモを入力」の案内 |
| ViewModel | `ui/editor/MemoEditViewModel.swift` | 読み込み、文字数・行数（別のスレッドで数える）、自動保存（入力が止まって3秒後／閉じるとき／アプリが裏に回るとき）、空のメモの確認・削除・元に戻して閉じる・破棄 |
| 入力の上限 | `ui/editor/MaxCharsLimiter.swift` | 100,000文字（改行を除く）を超える入力を止める。貼り付けは入る分だけ残し、案内を出す |
| UseCase | `SaveMemoUseCase` / `GetMemoUseCase` / `RevertMemoUseCase` / `DiscardMemoUseCase` / `ObserveEditorSettingsUseCase` | Android と同じ保存のルール（下記）、本文を含めて1件読む、開いたときの内容に戻す、ゴミ箱を通さずに消す、文字の大きさ・行間 |
| 変換 | `util/MemoHtml.swift` | 本文 ⇔ 保存用 HTML。今は文字・空白・改行のみ（装飾はステップ5）。Android で保存した HTML も読める |
| 共通処理 | `util/SerialTaskQueue.swift` | 保存を1つずつ順番に行う（Android の Mutex にあたる）。画面を閉じた後も最後まで行う（Android の AppScope にあたる） |
| | `ui/common/MessageCenter.swift` | アプリ全体のお知らせの置き場。編集画面で削除 → 一覧に「ゴミ箱に移動しました」を出すなど、画面をまたいで出せるようにした（メモタブもこれを使うように変更） |
| | `util/L10n.swift` の `count` | 数の入った複数形の訳で、数を3桁ごとに区切る（例: 12,345 characters） |
| | `util/StringBlank.swift` | 空白だけか（Kotlin の isBlank） |
| 文字列 | `Localizable.xcstrings` | 編集画面の文字列 13 項目（9言語）。取り込みツールで、複数形の中の数を数値（%lld）にするように直した |

### 保存のルール（Android と同じ）
| 状況 | 動き |
|---|---|
| 新規で、何も書かずに（空白だけで）閉じた | 保存しない |
| この画面で作ったメモを空にして閉じた | 確認なしで破棄（ゴミ箱も通さない） |
| 開いたときからあるメモを空にして戻る | 確認ダイアログ: 削除（ゴミ箱へ）／元に戻して閉じる（開いたときの本文・更新日に戻す）／編集に戻る |
| 内容が前回の保存と同じ | 何もしない（更新日を進めない） |
| アプリが裏に回った（ホームに戻るなど） | すぐ保存（確認はしない。空なら保存しないだけ） |

### 判断したこと
- **入力欄は UIKit の UITextView**（要件 i1.0 のとおり）: 入力の上限・選んだ範囲の通知・これから打つ文字の書式（ステップ5）など、SwiftUI の TextEditor ではできない制御が要るため
- **ナビゲーションバーのタイトル**: iOS 26 以上は標準のタイトル・サブタイトル（`.navigationSubtitle`）を使い、iOS 18〜25 は自前で2行に並べる。自前の中央の表示（`.principal`）が iOS 26.0 では出なかったため（iOS 26.0 のシミュレーターでテストして見つけた）
- **空にしたメモで戻るとき**: 標準の戻るボタンを確認付きの戻るボタンに差し替える。左端からのスワイプでも確認ダイアログを出す（標準のスワイプで戻ると確認を飛ばしてしまうため、そのときだけ標準のスワイプを止めている）
- **カーソルの位置**: 既存のメモを開いたときはカーソルを置かず、タップした位置に置く（iOS の標準。本文の下の空いているところをタップすると末尾）
- **「メモが見つからない」「ゴミ箱に移動しました」は前の画面（一覧）のお知らせとして出す**: Android の Toast にあたる。iOS には Toast がないので、一覧の下のお知らせのバーに出す
- **お知らせが消えてしまう不具合を直した**: 3秒で消す処理が、画面を閉じて待ちが打ち切られたときも消していた（編集画面で削除 → 一覧に出る前に消えた）。テストで見つけた
- **文字数・行数は別のスレッドで数える**（Android と同じ）: 10万文字のメモでも入力が重くならないように
- **アプリが裏で終了されたときの復元はしない**: Android は新規メモの id を画面の復元用に残していたが、iOS 版は裏に回るときに必ず保存するので、終了されても内容は残る（開き直すとメモタブから始まる）
- **文字の大きさは端末の文字の大きさの設定にも合わせる**（Android の sp と同じ考え方）

### 確認結果
- 単体テスト 119件・UI テスト 14件すべて成功（iOS 27.2・iOS 26.0）、ビルドの警告なし
  - 追加の単体テスト: `MemoEditViewModelTests`（Android の MemoEditViewModelTest と同じ11の場面＋何も書かずに閉じる・裏に回ったらすぐ保存・選んだ範囲の文字数・文字の大きさの追従）、`SaveMemoUseCaseTests`、`MaxCharsLimiterTests`（Android の MaxCharsInputFilterTest と同じ）、`MemoHtmlTests`（エスケープ・改行・往復・知らないタグ・Android の HTML を読める）、`L10nTests`（3桁区切り）
  - 追加の UI テスト（`MemoEditUITests`）: ＋で作って入力 → 文字数・行数 → 一覧に出る、何も書かずに戻ると増えない、既存のメモの編集、空にして戻る → ダイアログの3つのボタン、空にして左端からスワイプ → ダイアログ、キーボードを閉じるボタン
- 画面を撮って確認（日本語、ライト・ダーク）: 新規（案内の文・キーボード・キーボードを閉じるボタン）、入力中の文字数・行数、空にしたときのダイアログ

### ユーザーに確認してほしいこと（Xcode で `IrodoriNotes-iPhone17` に入れて）
ステップ3で Edit Scheme に足した `-ui-testing` などのチェックは外しておく（外すとシミュレーターに保存されるので、閉じてもメモが残る）。
1. ＋で新規作成 → キーボードが出て「メモを入力」の案内 → 入力するとタイトルに文字数・サブタイトルに行数（改行は数えない）→ 戻ると一覧に出る
2. 一覧のメモをタップ → 本文が出る → 編集して戻ると、一覧の1行目・文字数・更新日が変わる
3. 文字を選ぶ（長押し → 選択）→ サブタイトルが「○文字を選択中」になる。選択をやめると行数に戻る
4. 何も書かずに戻ると一覧に増えない
5. 既存のメモを全部消して戻る → 「メモが空です」→ 3つのボタンそれぞれ（削除は一覧に「ゴミ箱に移動しました」）。左端からスワイプで戻ろうとしても同じダイアログが出る
6. 書いている途中でホームに戻る（⇧⌘H）→ アプリを終了（アプリの切り替え画面で上にスワイプ）→ 開き直すと書いた内容が残っている
7. キーボードが出ている間だけ右上にキーボードのボタン → 押すとキーボードが閉じる
8. 長い文章を入力して、入力位置がキーボードに隠れないか
9. ライト・ダークで文字・案内が見やすいか
