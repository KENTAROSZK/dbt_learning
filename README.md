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


---

# dbt (data build tool) 学習リポジトリ

dbtをDockerで動かしながら学べる最小構成の学習用リポジトリです。

## 📚 目次

- [dbtとは](#dbtとは)
- [dbtを使うメリット・デメリット](#dbtを使うメリットデメリット)
- [環境構築](#環境構築)
- [プロジェクト構成](#プロジェクト構成)
- [セットアップ手順](#セットアップ手順)
- [dbtの実行](#dbtの実行)
- [実行結果の確認方法](#実行結果の確認方法)
- [サンプルの解説](#サンプルの解説)
- [よく使うコマンド](#よく使うコマンド)

---

## dbtとは

**dbt (data build tool)** は、データウェアハウス内のデータ変換を管理するためのオープンソースツールです。

### 特徴

- SQLでデータ変換を記述
- モデル間の依存関係を自動管理
- テストによるデータ品質の保証
- ドキュメントの自動生成
- バージョン管理(Git)との統合

### dbtが解決する課題

従来のSQLによるデータ変換では以下の問題がありました：

- SQLファイルが散在して管理が困難
- 実行順序を手動で管理する必要がある
- テストやドキュメントが不足しがち
- 変更履歴が残らない

dbtはこれらを「ソフトウェア開発のベストプラクティス」をデータ変換に適用することで解決します。

---

## dbtを使うメリット・デメリット

### ✅ メリット

| 項目 | 説明 |
|------|------|
| **バージョン管理** | GitでSQLを管理し、変更履歴を追跡可能 |
| **依存関係の自動管理** | `ref()`関数でテーブル間の依存を自動解決 |
| **データ品質保証** | テスト機能でデータの整合性をチェック |
| **ドキュメント自動生成** | コードから自動でドキュメントサイトを生成 |
| **再利用性** | マクロで共通ロジックを部品化 |
| **環境分離** | dev/prod環境を簡単に切り替え |

### ⚠️ デメリット

| 項目 | 説明 |
|------|------|
| **学習コスト** | dbt独自の概念（モデル、マクロ等）の習得が必要 |
| **SQLのみ** | Python/Scalaなど他言語でのデータ処理には不向き |
| **DWH必須** | BigQuery、Snowflake、PostgreSQL等が必要 |
| **実行環境** | dbtを動かす環境（ローカル/CI/CD/dbt Cloud）が必要 |
| **小規模に過剰** | SQLが5-10個程度の小規模プロジェクトには大げさ |
| **バッチ処理** | リアルタイム/ストリーミング処理には不向き |

### 使うべきケース vs 使わなくてもいいケース

**✅ dbtを使うべき**
- データ変換のSQLが10個以上
- 複数人で開発
- データ品質保証が必要
- ドキュメント化が必要
- 環境分離が必要

**❌ dbtを使わなくてもいい**
- SQLが5個以下の小規模
- 一度だけの分析（アドホック）
- リアルタイム処理
- SQL以外の言語を使いたい

---

## 環境構築

### 必要なもの

- Docker
- Docker Compose

### プロジェクト構成
```
my_dbt_project/
├── Dockerfile                  # dbt実行環境
├── docker-compose.yaml         # dbt + PostgreSQL
├── dbt_project.yml             # dbtプロジェクト設定
├── profiles.yml                # DB接続情報
├── seeds/
│   └── raw_orders.csv         # テストデータ
└── models/
    ├── sales_summary.sql      # 日次集計モデル
    ├── monthly_report.sql     # 月次レポートモデル
    └── schema.yml             # テスト・ドキュメント定義
```

---

## セットアップ手順

### 1. Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /usr/app

# PostgreSQLクライアントツールをインストール
RUN apt-get update && \
    apt-get install -y postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# dbtのインストール (PostgreSQL用)
RUN pip install --no-cache-dir \
    dbt-core \
    dbt-postgres

COPY . /usr/app

CMD ["bash"]
```

> **Note:** 他のデータウェアハウスを使う場合は以下に変更してください
> - BigQuery: `dbt-bigquery`
> - Snowflake: `dbt-snowflake`
> - Redshift: `dbt-redshift`

### 2. docker-compose.yaml
```yaml
version: '3.8'

services:
  # PostgreSQLデータベース
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: dbt_user
      POSTGRES_PASSWORD: dbt_password
      POSTGRES_DB: analytics
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # dbt実行環境
  dbt:
    build: .
    depends_on:
      - postgres
    volumes:
      - ./:/usr/app
    environment:
      DBT_PROFILES_DIR: /usr/app
    stdin_open: true
    tty: true

volumes:
  postgres_data:
```

### 3. dbt_project.yml
```yaml
name: 'my_dbt_project'
version: '1.0.0'
config-version: 2

# プロジェクトのプロファイル名
profile: 'my_profile'

# モデルの配置場所
model-paths: ["models"]
seed-paths: ["seeds"]
test-paths: ["tests"]

# モデルの設定
models:
  my_dbt_project:
    # 全てのモデルをviewとして作成
    +materialized: view
```

### 4. profiles.yml
```yaml
my_profile:
  target: dev
  outputs:
    dev:
      type: postgres
      host: postgres  # docker-composeのサービス名
      port: 5432
      user: dbt_user
      password: dbt_password
      dbname: analytics
      schema: public
      threads: 4
```

### 5. seeds/raw_orders.csv
```csv
order_id,order_date,product_name,quantity,price
1,2024-01-15,Product A,2,1000
2,2024-01-16,Product B,1,1500
3,2024-01-17,Product A,3,1000
4,2024-02-01,Product C,1,2000
5,2024-02-05,Product A,5,1000
6,2024-02-10,Product B,2,1500
7,2024-03-01,Product C,3,2000
8,2024-03-15,Product A,1,1000
```

### 6. models/sales_summary.sql
```sql
-- 日次で商品ごとの売上を集計

SELECT
    order_date,
    product_name,
    SUM(quantity) as total_quantity,
    SUM(quantity * price) as total_sales,
    COUNT(order_id) as order_count
FROM {{ ref('raw_orders') }}
GROUP BY order_date, product_name
ORDER BY order_date, product_name
```

### 7. models/monthly_report.sql
```sql
-- 月次で売上をまとめたレポート

SELECT
    DATE_TRUNC('month', order_date) as month,
    product_name,
    SUM(total_quantity) as monthly_quantity,
    SUM(total_sales) as monthly_sales,
    AVG(total_sales) as avg_daily_sales
FROM {{ ref('sales_summary') }}
GROUP BY DATE_TRUNC('month', order_date), product_name
ORDER BY month, product_name
```

### 8. models/schema.yml
```yaml
version: 2

models:
  - name: sales_summary
    description: "日次の商品別売上集計"
    columns:
      - name: order_date
        description: "注文日"
        tests:
          - not_null
      - name: product_name
        description: "商品名"
        tests:
          - not_null
      - name: total_quantity
        description: "合計数量"
        tests:
          - not_null
      - name: total_sales
        description: "合計売上金額"
        tests:
          - not_null
      - name: order_count
        description: "注文件数"

  - name: monthly_report
    description: "月次の商品別売上レポート"
    columns:
      - name: month
        description: "対象月(月初日)"
        tests:
          - not_null
      - name: product_name
        description: "商品名"
        tests:
          - not_null
      - name: monthly_quantity
        description: "月間合計数量"
      - name: monthly_sales
        description: "月間合計売上"
      - name: avg_daily_sales
        description: "日平均売上"
```

---

## dbtの実行

### 基本的な実行フロー
```bash
# 1. Dockerコンテナを起動
docker-compose up -d

# 2. dbtコンテナに入る
docker-compose exec dbt bash

# 3. 接続確認
dbt debug

# 4. CSVからテーブル作成
dbt seed

# 5. 全モデルを実行
dbt run

# 6. テストを実行
dbt test

# 7. ドキュメント生成
dbt docs generate

# 8. ドキュメントサーバー起動
dbt docs serve --port 8080
```

### 実行時の依存関係

dbtは自動的に以下の順序で実行します：
```
raw_orders (CSV from seed)
    ↓
sales_summary (日次集計)
    ↓
monthly_report (月次集計)
```

`{{ ref('テーブル名') }}` により依存関係が定義され、正しい順序で実行されます。

---

## 実行結果の確認方法

### 方法1: PostgreSQLコンテナから直接確認（推奨）
```bash
# PostgreSQLに接続
docker-compose exec postgres psql -U dbt_user -d analytics
```

### 方法2: dbtコンテナからpsqlで接続
```bash
# dbtコンテナに入る
docker-compose exec dbt bash

# PostgreSQLに接続
PGPASSWORD=dbt_password psql -h postgres -U dbt_user -d analytics
```

### psqlでよく使うコマンド
```sql
-- テーブル一覧
\dt

-- ビュー一覧
\dv

-- テーブル構造を確認
\d sales_summary

-- データを確認
SELECT * FROM raw_orders;
SELECT * FROM sales_summary;
SELECT * FROM monthly_report;

-- 件数確認
SELECT COUNT(*) FROM sales_summary;

-- 縦方向表示に切り替え（列が多い時）
\x

-- psqlを終了
\q
```

### よく使うSQLクエリ
```sql
-- 全テーブル・ビューの件数確認
SELECT 
    'raw_orders' as table_name,
    COUNT(*) as record_count 
FROM raw_orders
UNION ALL
SELECT 
    'sales_summary',
    COUNT(*) 
FROM sales_summary
UNION ALL
SELECT 
    'monthly_report',
    COUNT(*) 
FROM monthly_report;

-- 商品ごとの集計
SELECT 
    product_name,
    COUNT(*) as days_with_sales,
    SUM(total_quantity) as total_quantity,
    SUM(total_sales) as total_sales
FROM sales_summary
GROUP BY product_name
ORDER BY total_sales DESC;

-- 月次レポートの確認
SELECT 
    TO_CHAR(month, 'YYYY-MM') as year_month,
    product_name,
    monthly_sales
FROM monthly_report
ORDER BY month, product_name;
```

---

## サンプルの解説

### このサンプルで学べること

1. **`ref()`による依存関係管理**
   - `raw_orders` → `sales_summary` → `monthly_report`
   - 依存関係を宣言するだけで、実行順序は自動で解決

2. **自動的な実行順序**
   - `dbt run` 一つのコマンドで全て正しい順番で実行

3. **テストによるデータ品質保証**
   - `not_null`テストでNULLが入っていないことを確認
   - `dbt test`で一括実行

4. **ドキュメントの自動生成**
   - `schema.yml`の内容から見やすいドキュメントを生成
   - 依存関係の可視化も可能

5. **環境の分離**
   - `profiles.yml`で dev/prod を切り替え可能

### dbtなしとの比較

**dbtなし:**
```sql
-- 手動で順番に実行する必要がある
CREATE VIEW sales_summary AS SELECT ... FROM raw_orders;
CREATE VIEW monthly_report AS SELECT ... FROM sales_summary;
```

**dbtあり:**
```sql
-- models/sales_summary.sql
SELECT ... FROM {{ ref('raw_orders') }}

-- models/monthly_report.sql
SELECT ... FROM {{ ref('sales_summary') }}

-- 実行は1コマンド
-- $ dbt run
```

---

## よく使うコマンド

### dbtコマンド
```bash
# 全モデル実行
dbt run

# 特定のモデルのみ実行
dbt run --select sales_summary

# 特定のモデルとその下流を実行
dbt run --select sales_summary+

# 特定のモデルとその上流を実行
dbt run --select +monthly_report

# 全テスト実行
dbt test

# 特定のモデルのテストのみ実行
dbt test --select sales_summary

# ドキュメント生成・表示
dbt docs generate
dbt docs serve --port 8080

# 接続確認
dbt debug

# モデルをコンパイル（実行せずSQLを生成）
dbt compile
```

### Dockerコマンド
```bash
# コンテナ起動
docker-compose up -d

# コンテナ停止
docker-compose down

# コンテナ削除（データも削除）
docker-compose down -v

# dbtコンテナに入る
docker-compose exec dbt bash

# PostgreSQLコンテナに入る
docker-compose exec postgres psql -U dbt_user -d analytics

# ログ確認
docker-compose logs dbt
docker-compose logs postgres
```

---

## 次のステップ

このサンプルを理解したら、以下にチャレンジしてみてください：

1. **新しいモデルを追加**
   - `weekly_report.sql` を作って週次集計を作成
   - `{{ ref('sales_summary') }}` で依存関係を定義

2. **テストを追加**
   - `unique` テストを追加
   - `accepted_values` で商品名の値を制限

3. **マクロを作成**
   - よく使う計算をマクロ化して再利用

4. **incremental モデルを試す**
   - 大量データを想定した増分更新

5. **CI/CDに統合**
   - GitHub Actions で自動テスト

---

## 参考リンク

- [dbt公式ドキュメント](https://docs.getdbt.com/)
- [dbt公式チュートリアル](https://docs.getdbt.com/docs/get-started/getting-started/overview)
- [dbtのベストプラクティス](https://docs.getdbt.com/guides/best-practices)

---

## ライセンス

MIT License

---

## 貢献

プルリクエスト歓迎です！学習用コンテンツとして改善提案があればお気軽にどうぞ。