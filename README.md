# 概要
dbtの勉強用のリポジトリ


## 実行方法


### 1. Dockerコンテナを起動
```bash
docker-compose up -d
```

### 2. dbtコンテナに入る
```bash
docker exec -it dbt_test-dbt-1 /bin/bash
```

**ここから下は、コンテナの中で実行する。**

### 3. 接続確認（コンテナの中で実行）
```bash
dbt debug
```

### 4. CSVからテーブル作成
```bash
dbt seed
```
すると、PostgreSQLに`raw_orders`テーブルが作成されます。

### 5. 全モデルを実行
```bash
dbt run
```
すると、
```css
1. sales_summary ビューが作成される
   ↓ (このビューを使って)
2. monthly_report ビューが作成される
```
### 6. テストを実行
```bash
dbt test
```
すると、全てのnot_nullテストが実行され、データに問題がないか確認されます。

### 7. 依存関係を可視化(任意)
```bash
dbt docs generate
dbt docs serve --host 0.0.0.0 --port 8080
```

### 8. 実行結果をPostgreSQLクライアント経由で確認する（dbt Dockerコンテナ内部で実行する）
```bash
# PostgreSQLに接続
psql -h postgres -U dbt_user -d analytics
# パスワードを聞かれたら: dbt_password
```

すると、`analytics=# `という表示になる。
### 9. 作成したテーブルやVIEWを確認する

```bash
-- テーブル一覧を表示
\dt

-- ビュー一覧を表示
\dv
```


実際のデータを見る場合は、通常のSQLを直で打ってenterすればOK。

```SQL
-- raw_ordersテーブルの全データを見る
SELECT * FROM raw_orders;

-- sales_summaryビューのデータを見る
SELECT * FROM sales_summary;

-- monthly_reportビューのデータを見る
SELECT * FROM monthly_report;

-- 件数を確認
SELECT COUNT(*) FROM sales_summary;

-- 特定の条件でフィルタ
SELECT * FROM monthly_report WHERE product_name = 'Product A';
```