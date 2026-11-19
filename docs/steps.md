# 作業ステップと進捗

各ステップで「やったこと・判断したこと・確認結果・ユーザーに確認してほしいこと」をここに残す。
チャットを遡らなくても、このファイルだけで状況がわかるようにする。
（仕様は [requirements.md](requirements.md)〔iOS で違うところ〕と、Android 版の `docs/requirements.md` v1.17）

## 進捗一覧
| # | ステップ | 主な内容 | 状態 | コミット |
|---|---|---|---|---|
| 0 | プロジェクト設定 | 作り直し、iOS 18・iPhone だけ・Bundle ID・アプリ名（9言語）、テストのターゲット、専用シミュレーター、CLAUDE.md・仕様・進捗 | ✅ 完了 | |
| 1 | データ層 | GRDB、メモ・フォルダのテーブル（ピン留め・ロックの列も最初から）、Repository、ドメインモデル、文字数、設定（UserDefaults） | 🟡 確認待ち | |
| 2 | アプリの骨組み | AppContainer、下タブ3つ、テーマ、起動時のゴミ箱の期限切れ削除、アプリアイコン | | |
| 3 | メモタブ | 一覧、並び替え、長押しメニュー（削除・ピン留め）、元に戻す | | |
| 4 | メモ編集（基本） | 編集画面、文字数・行数・選んだ範囲の文字数、自動保存、空のメモの確認、10万文字の上限、文字の大きさ・行間、HTML の変換（文字・改行だけ） | | |
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
- [ ] 【ステップ1】下の「ステップ1」の内容の確認
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
