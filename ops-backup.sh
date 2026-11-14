#!/bin/bash
# DNF90 本地部署备份：游戏库 + 服务端/网关配置 + 频道表与清单
set -euo pipefail
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=/srv/dnf/backups
mkdir -p "$OUT"

cd /srv/dnf/ServerS5A3
PW=$(grep '^MARIADB_PASSWORD=' runtime/docker/database.env | cut -d= -f2)

echo "== 1. 数据库一致性备份 =="
docker exec servers5a3-local-db-1 mariadb-dump -udnf -p"$PW" \
  --single-transaction --routines --events --default-character-set=utf8mb4 dnf_local \
  | gzip -9 > "$OUT/dnf_local-$STAMP.sql.gz"

echo "== 2. 服务端配置与频道表 =="
tar czf "$OUT/server-config-$STAMP.tar.gz" \
  runtime/docker/instance.json \
  runtime/docker/server.env \
  runtime/docker/database.env \
  runtime/docker/compose.json \
  runtime/docker/data/manifest.json \
  runtime/docker/data/channel.override.etc

echo "== 3. PurpleMagic 私有配置与运行数据 =="
cd /srv/dnf/PurpleMagic
tar czf "$OUT/purplemagic-$STAMP.tar.gz" \
  runtime/selfhost-settings.json \
  runtime/selfhost/gateway.json \
  runtime/selfhost/service.json \
  runtime/selfhost/indexer.json \
  runtime/selfhost/admin-token.txt \
  runtime/selfhost/compose.env \
  runtime/launcher-input/profile.json \
  runtime/launcher-input/server.json \
  runtime/selfhost/gm runtime/selfhost/hub runtime/selfhost/releases \
  runtime/selfhost/private runtime/selfhost/tls-player runtime/selfhost/tls-web

echo "== 4. 校验与清单 =="
cd "$OUT"
sha256sum "dnf_local-$STAMP.sql.gz" "server-config-$STAMP.tar.gz" "purplemagic-$STAMP.tar.gz" > "SHA256-$STAMP.txt"
cat "SHA256-$STAMP.txt"

echo "== 5. 清理 14 天前的旧备份 =="
find "$OUT" -maxdepth 1 -type f \( -name 'dnf_local-*.sql.gz' -o -name 'server-config-*.tar.gz' \
  -o -name 'purplemagic-*.tar.gz' -o -name 'SHA256-*.txt' \) -mtime +14 -print -delete
echo "剩余备份组：$(ls "$OUT"/SHA256-*.txt 2>/dev/null | wc -l)"
echo "备份完成：$OUT"
