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

## **Aさん**
実行すると何が起こるんですか?

## **Bさん**
順番に説明しますね:

### `dbt seed`実行後:
PostgreSQLに`raw_orders`テーブルが作成されます。

### `dbt run`実行後:
```
1. sales_summary ビューが作成される
   ↓ (このビューを使って)
2. monthly_report ビューが作成される