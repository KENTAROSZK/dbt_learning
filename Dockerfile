# Dockerfile
FROM python:3.11-slim

# 作業ディレクトリ
WORKDIR /usr/app

# gitのインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# dbtのインストール(PostgreSQL用)
RUN pip install --no-cache-dir \
    dbt-core \
    dbt-postgres

# dbtプロジェクトファイルをコピー
COPY . /usr/app

# デフォルトコマンド
CMD ["dbt", "debug"]