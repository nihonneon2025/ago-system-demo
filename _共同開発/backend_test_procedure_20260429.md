# AGO SYSTEM MANAGER バックエンド動作確認手順書

作成日: 2026-04-29
作成者: system-qa（日本ネオン株式会社 品質保証）
対象: api.php / subscribe.php / sw.js / manifest.json
目的: AGO訪問時に即実行できる「コピペで動く」テストレシピ集
機密レベル: 社内資料（出資者特例下・他案件流用禁止）

---

## 目次

1. PHP環境セットアップ手順（XAMPP / PHP内蔵サーバー）
2. データベース初期確認
3. 各エンドポイントの動作確認テスト（curlコマンド集）
4. subscribe.php（プッシュ通知登録）の動作確認
5. PWA（manifest.json / sw.js）の動作確認手順
6. 想定エラーとトラブルシューティング
7. 動作確認チェックリスト


---

## 1. PHP環境セットアップ手順

### 選択肢A: XAMPP（推奨）

XAMPPはPHP+Webサーバーをまとめてインストールできる無料ソフトです。

**インストール手順**

1. 公式サイトからダウンロード: https://www.apachefriends.org/jp/index.html
   - 「XAMPP for Windows」を選択 / PHP 8.2 以上を選択

2. インストーラー（xampp-installer.exe）を実行
   - インストール先: C:\xampp（変更不要）
   - コンポーネント: Apache と PHP だけでOK（MySQLは不要）

3. AGO_SYSTEM_MANAGER をドキュメントルートに配置
   - C:\xampp\htdocs\ に「ago」フォルダを新規作成
   - 以下のファイルを全て C:\xampp\htdocs\ago\ にコピー:
     index.html / config.js / api.php / subscribe.php / sw.js / manifest.json

4. XAMPP コントロールパネル起動
   - スタートメニュー → XAMPP → XAMPP Control Panel
   - 「Apache」の「Start」をクリック → 緑になればOK

5. ブラウザで確認: http://localhost/ago/index.html

**SQLite拡張の有効化（XAMPP）**

C:\xampp\php\php.ini をメモ帳で開き、以下の行の先頭「;」を外す:

  変更前: ;extension=pdo_sqlite
  変更後: extension=pdo_sqlite

  変更前: ;extension=sqlite3
  変更後: extension=sqlite3

変更後、Apache を再起動（Stop → Start）。

---

### 選択肢B: PHP内蔵Webサーバー（インストール最小限）

**PHPのインストール**

1. 公式サイト: https://windows.php.net/download/
   - PHP 8.2 または 8.3 の「VS17 x64 Non Thread Safe」をZIPでダウンロード
   - 解凍先: C:\php\ に展開

2. php.ini の設定
   - C:\php\php.ini-development を C:\php\php.ini にコピー
   - php.ini を開いて以下の「;」を外す:
       extension=pdo_sqlite
       extension=sqlite3
       extension_dir = ext

3. 環境変数設定
   - Windowsの設定 → システム → 詳細設定 → 環境変数 → PATH に C:\php を追加
   - コマンドプロンプト再起動後: php -v で確認

**内蔵サーバーの起動コマンド（コピペで実行）**

コマンドプロンプトで:

    cd C:\Users\[ユーザー名]\Desktop\ネオン物販\AGO_SYSTEM_MANAGER
    php -S localhost:8080

起動後、ブラウザで http://localhost:8080/index.html を開く。


---

## 2. データベース初期確認

AGO SYSTEM MANAGER は SQLite を使用します。DBファイルは初回アクセス時に自動作成されます。

**DBファイルの場所**

AGO_SYSTEM_MANAGER フォルダの直下に ago_data.db が自動生成されます。
（事前に手動でファイルを作る必要はありません）

**初回アクセス確認（ブラウザで開く）**

    http://localhost:8080/api.php?action=list

正常なら以下が返る:

    {success:true,orders:[]}

DBファイル生成の確認（コマンドプロンプトで）:

    dir C:\Users\[ユーザー名]\Desktop\ネオン物販\AGO_SYSTEM_MANAGER\ago_data.db

ago_data.db が存在すれば初期化成功。

**SQLite拡張が有効かどうかの確認（事前確認用）**

コマンドプロンプトで:

    php -m

出力に「pdo_sqlite」と「sqlite3」が含まれていればOK。


### 3-2. 現場管理

#### 現場一覧の取得
    curl http://localhost:8080/api.php?action=projects_list

#### 現場の登録（Git Bash）
    curl -X POST http://localhost:8080/api.php?action=project_create -H Content-Type:application/json -d '{name:テスト現場A,location:東京都新宿区,client_name:テスト会社,start_date:2026-04-29,end_date:2026-05-10,status:active}'

期待レスポンス: {success:true,id:1}

---

### 3-3. スケジュール管理

#### スケジュール一覧（期間指定）
    curl http://localhost:8080/api.php?action=schedule_list&from=2026-04-29&to=2026-05-05

#### スケジュール登録（スタッフ複数紐付け・Git Bash）
    curl -X POST http://localhost:8080/api.php?action=schedule_create -H Content-Type:application/json -d '{project_id:1,title:新宿現場 足場設置,date:2026-04-30,start_time:08:00,end_time:17:00,staff:[staff01,staff03,staff05],created_by:kanno}'

期待レスポンス: {success:true,id:1}

#### 個人スケジュールの取得
    curl http://localhost:8080/api.php?action=schedule_by_user&user_id=staff01&from=2026-04-29&to=2026-05-05

---

### 3-4. 勤怠管理

#### 出勤打刻（GPS座標付き・Git Bash）
    curl -X POST http://localhost:8080/api.php?action=clock_in -H Content-Type:application/json -d '{user_id:staff01,lat:35.6895,lng:139.6917}'

期待レスポンス: {success:true,clock_in:09:00:00}

#### 退勤打刻（Git Bash）
    curl -X POST http://localhost:8080/api.php?action=clock_out -H Content-Type:application/json -d '{user_id:staff01,lat:35.6895,lng:139.6917}'

#### 本日の全員出勤状況確認（本社用）
    curl http://localhost:8080/api.php?action=attendance_all&date=2026-04-29

#### 個人の月別勤怠一覧
    curl http://localhost:8080/api.php?action=attendance_list&user_id=staff01&month=2026-04

---

### 3-5. GPS追跡

#### GPS位置情報の記録（Git Bash）
    curl -X POST http://localhost:8080/api.php?action=gps_log -H Content-Type:application/json -d '{user_id:staff01,lat:35.6895,lng:139.6917,accuracy:10.5}'

#### 全スタッフの最新位置取得（本社用）
    curl http://localhost:8080/api.php?action=gps_latest

---

### 3-6. 個別指示

#### 指示の送信（代表→スタッフ・Git Bash）
    curl -X POST http://localhost:8080/api.php?action=instruction_send -H Content-Type:application/json -d '{from_user:kanno,to_user:staff01,subject:本日の作業について,body:新宿現場の足場確認を優先してください}'

#### 未読件数の確認
    curl http://localhost:8080/api.php?action=instructions_unread&user_id=staff01

#### 既読にする（Git Bash）
    curl -X POST http://localhost:8080/api.php?action=instruction_read -H Content-Type:application/json -d '{id:1}'

---

### 3-7. 経理（masterとofficeロールのみ）

#### 請求書の作成（Git Bash）
    curl -X POST http://localhost:8080/api.php?action=invoice_create -H Content-Type:application/json -d '{doc_type:invoice,client_name:株式会社サンプル,subject:看板設置工事費,amount:300000,tax:30000,issue_date:2026-04-29,due_date:2026-05-31,status:draft,created_by:kanno,items:[{description:看板設置工事,qty:1,unit_price:300000}]}'

期待レスポンス: {success:true,id:1,doc_number:AGO-INV-20260429-001}

#### 発注書の作成（Git Bash）
    curl -X POST http://localhost:8080/api.php?action=invoice_create -H Content-Type:application/json -d '{doc_type:purchase_order,client_name:株式会社資材供給,subject:鉄骨材料購入,amount:150000,tax:15000,issue_date:2026-04-29,created_by:kanno}'

期待レスポンス: {success:true,id:1,doc_number:AGO-PO-20260429-001}

#### 収支サマリーの取得（月別）
    curl http://localhost:8080/api.php?action=finance_summary&month=2026-04

期待レスポンス: {success:true,month:2026-04,revenue:0,expenses:0,purchase_orders:0,profit:0}

#### 経費の登録（Git Bash）
    curl -X POST http://localhost:8080/api.php?action=expense_create -H Content-Type:application/json -d '{category:交通費,description:新宿現場への移動,amount:2000,expense_date:2026-04-29,paid_by:staff01,created_by:kanno}'


---

## 4. subscribe.php（プッシュ通知登録）の動作確認

### 4-1. サブスクリプション登録のテスト

実際のブラウザPush購読ではなく、ダミーデータで動作を確認します。

Git Bash:
    curl -X POST http://localhost:8080/subscribe.php -H Content-Type:application/json -d '{user_name:staff01,endpoint:https://fcm.googleapis.com/test-endpoint,keys:{p256dh:test_p256dh_key,auth:test_auth_key}}'

期待レスポンス: {success:true}

### 4-2. 登録済みサブスクリプション一覧の確認
    curl http://localhost:8080/subscribe.php?action=list

期待レスポンス: {success:true,subscriptions:[{id:1,user_name:staff01,created_at:...}]}

### 4-3. 通知ログの記録テスト（Git Bash）
    curl -X POST http://localhost:8080/subscribe.php?action=send -H Content-Type:application/json -d '{target_user:staff01,title:テスト通知,body:これはテスト送信です}'

期待レスポンス: {success:true,message:通知をログに記録しました,targets:1}

### 4-4. VAPID鍵の設定（本番運用前に必要）

現在 config.js の vapidPublicKey は REPLACE_WITH_AGO_VAPID_PUBLIC_KEY のままです。
本番前にAGO専用VAPID鍵を生成します。

Node.js が使える環境で:
    npm install -g web-push
    web-push generate-vapid-keys

出力例:
  Public Key:  BxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxACk
  Private Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

設定:
- 公開鍵 → config.js の vapidPublicKey に設定
- 秘密鍵 → サーバー側で保管（Gitにコミットしない・ago_data.db と同じ扱い）

重要: VAPID鍵が変わると既存の購読が全て無効になります。一度設定したら変更しないこと。


---

## 5. PWA（manifest.json / sw.js）の動作確認手順

### 5-1. manifest.json の確認（ブラウザの開発者ツール）

1. ブラウザで http://localhost:8080/index.html を開く
2. F12キーを押して開発者ツールを開く
3. 「Application」タブをクリック
4. 左のメニューから「Manifest」を選択
5. 以下の項目が正しく表示されることを確認:
   - Name: AGO SYSTEM MANAGER
   - Short name: AGO
   - Start URL: index.html
   - Display: standalone
   - Theme color: #0f172a

---

### 5-2. sw.js（サービスワーカー）の動作確認

1. F12 → 「Application」タブ → 「Service Workers」を選択
2. status が「activated and is running」になっていることを確認

サービスワーカーが登録されていない場合:
- index.html 内で navigator.serviceWorker.register(''sw.js'') が呼ばれているか確認
- http://localhost 上で動いているか確認
  （HTTPはlocalhostのみSW動作可。本番はHTTPS必須）

---

### 5-3. オフライン動作の確認

1. http://localhost:8080/index.html を開いてキャッシュをためる
2. F12 → Network タブ → 「Offline」にチェックを入れる
3. ページを再読み込み（F5）
4. index.html / config.js / manifest.json はキャッシュから表示されることを確認
5. api.php へのリクエストは「オフラインです」エラーになることを確認

キャッシュの確認: F12 → Application → Cache Storage → 「ago-system-v1」

---

### 5-4. スマートフォンからの確認（ホーム画面追加）

PCのIPアドレス確認（コマンドプロンプトで ipconfig を実行）。
スマートフォンのブラウザで: http://[PCのIPアドレス]:8080/index.html を開く。

ホーム画面への追加:
- Chrome（Android）: メニュー → 「ホーム画面に追加」
- Safari（iOS）: 共有ボタン → 「ホーム画面に追加」

ホーム画面から起動したとき、アドレスバーが消えてアプリのような表示になればPWA設定は正常。

注意: スマートフォンからのアクセスはHTTPのためService Workerが動作しません。
      本番運用では HTTPS が必要です。


---

## 6. 想定エラーとトラブルシューティング

### エラー: DB接続エラー: unable to open database file

原因: SQLite拡張が無効、またはフォルダへの書き込み権限がない

対処:
1. php.ini で extension=pdo_sqlite の「;」が外れているか確認
2. AGO_SYSTEM_MANAGER フォルダを右クリック → プロパティ → セキュリティ
   「Users」に「書き込み」権限があるか確認

---

### エラー: Access to XMLHttpRequest ... has been blocked by CORS policy

原因: ファイルを file:// で直接開いている（サーバー経由でないとCORSエラー）

対処: 必ず http://localhost:8080/index.html でアクセスする
      ファイルをダブルクリックして開かないこと

---

### エラー: {success:false,message:不明なアクション: }

原因: action パラメーターが渡っていない

対処: URLに ?action=list のように action パラメーターを付ける

---

### エラー: Service Worker が起動しない

原因: HTTP環境での制限（localhost は例外として動作可）

対処:
- http://localhost:8080 での動作はOK
- LAN内の別端末（192.168.x.x:8080）からはSWが動作しない
  テスト時: F12 → Application → Service Workers → 「Bypass for network」を使う
  本番: HTTPS（SSL証明書）が必要

---

### エラー: 既に出勤済みです

原因: 同じ user_id で同日に2回 clock_in を呼んでいる

対処（テスト中のDBリセット）:
1. AGO_SYSTEM_MANAGER フォルダの ago_data.db を削除
2. api.php に再度アクセスするとDBが再作成される

---

### エラー: 通知ログ記録でtargetsが0

原因: Push購読が登録されていない

対処: セクション4-1のサブスクリプション登録を先に実行してから send を呼ぶ

---

### エラー: icon-192.png / icon-512.png が見つからない

原因: PWA用アイコン画像が未作成

対処（暫定）:
192x192px と 512x512px の PNG 画像を用意して
AGO_SYSTEM_MANAGER フォルダに icon-192.png / icon-512.png として配置。
通常動作には影響なし（ホーム画面追加時のアイコン表示にのみ必要）。


---

## 7. 動作確認チェックリスト

AGO訪問時に順番に実行してチェックする。

### 事前準備
- [ ] PHP がインストール済み（php -v で確認）
- [ ] SQLite拡張が有効（php.ini 設定済み・php -m で pdo_sqlite が含まれる）
- [ ] AGO_SYSTEM_MANAGER フォルダをドキュメントルートに配置

### PHPサーバー起動確認
- [ ] php -S localhost:8080 が通る
- [ ] ブラウザで http://localhost:8080/index.html が表示される

### DB初期化確認
- [ ] api.php?action=list で {success:true,orders:[]} が返る
- [ ] ago_data.db ファイルが生成されている

### 発注管理
- [ ] 注文作成（create）→ 注文コードが返る
- [ ] 注文一覧（list）→ 作成した注文が見える
- [ ] 注文詳細（get）→ ステータスログも確認
- [ ] ステータス更新（update_status）→ ステータスが変わる
- [ ] 引継ぎメモ追加（add_memo）→ メモが記録される

### 現場・スケジュール管理
- [ ] 現場登録（project_create）→ IDが返る
- [ ] スケジュール登録（schedule_create・staff配列付き）→ IDが返る
- [ ] 個人スケジュール取得（schedule_by_user）→ 登録したものが見える

### 勤怠・GPS
- [ ] 出勤打刻（clock_in）→ 時刻が返る
- [ ] GPS記録（gps_log）→ success が返る
- [ ] GPS最新位置取得（gps_latest）→ 位置情報が返る
- [ ] 退勤打刻（clock_out）→ 時刻が返る

### 個別指示
- [ ] 指示送信（instruction_send）→ IDが返る
- [ ] 未読件数確認（instructions_unread）→ 1以上が返る
- [ ] 既読処理（instruction_read）→ success が返る

### 経理
- [ ] 請求書作成（invoice_create・doc_type:invoice）→ 書類番号が返る
- [ ] 発注書作成（invoice_create・doc_type:purchase_order）→ 書類番号が返る
- [ ] 収支サマリー（finance_summary）→ 正常に返る
- [ ] 経費登録（expense_create）→ IDが返る

### subscribe.php
- [ ] サブスクリプション登録 → success が返る
- [ ] 一覧取得（?action=list）→ 登録済みが見える
- [ ] 通知ログ記録（?action=send）→ success が返る

### PWA確認
- [ ] manifest.json が認識されている（F12 → Application → Manifest）
- [ ] Service Worker が active 状態（F12 → Application → Service Workers）
- [ ] オフライン時に index.html が表示される
- [ ] （任意）スマートフォンからアクセスしてホーム画面に追加できる

---

## 補足: PowerShellでのAPIテスト方法

PowerShellでは curl が別コマンドの別名になっています。
PowerShellを使う場合は Invoke-RestMethod を使ってください。

GETリクエストの例:
    Invoke-RestMethod -Uri http://localhost:8080/api.php?action=list

POSTリクエストの例（新規注文作成）:
    # 変数に値をセット
    `$body = ConvertTo-Json @{ product='テスト商品'; qty=2; amount=50000; buyer_name='テスト顧客'; source='catalog' } -Depth 10
    Invoke-RestMethod -Uri 'http://localhost:8080/api.php?action=create' -Method POST -ContentType 'application/json' -Body `$body

Git Bash（Git for Windows に付属）を使う場合は、セクション3のコマンドをそのままコピペで実行できます。

---

*作成: system-qa / 日本ネオン株式会社 品質保証 / 2026-04-29*
*対象案件: AGO_SYSTEM_MANAGER（開発事業部 受託案件第1号・出資者特例下）*
*他案件への流用禁止*
