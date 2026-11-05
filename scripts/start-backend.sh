#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
if [[ ! -f .env ]]; then
  echo 'Thiếu .env. Sao chép .env.example và điền cấu hình trước.' >&2
  exit 1
fi
if systemctl --user is-active --quiet cstore-mobile-backend.service; then
  echo 'Backend đang chạy: http://127.0.0.1:8080'
  exit 0
fi
if curl --silent --max-time 2 http://127.0.0.1:8080/api/branches >/dev/null; then
  echo 'Cổng 8080 đang có server khác; không khởi động đè.' >&2
  exit 1
fi
docker compose up -d --wait mysql
java_version="$(java -version 2>&1 | head -n 1 | sed -E 's/.*version "([0-9]+).*/\1/')"
(cd backend && mvn -q "-Djava.version=$java_version" -DskipTests package)
systemctl --user reset-failed cstore-mobile-backend.service 2>/dev/null || true
systemd-run --user --unit=cstore-mobile-backend --collect \
  --property="WorkingDirectory=$project_dir/backend" \
  --property="EnvironmentFile=$project_dir/.env" \
  --setenv=LOGGING_LEVEL_ROOT=INFO \
  --setenv=DEBUG=false \
  /usr/bin/java -jar "$project_dir/backend/target/cstore-simple-api-0.1.0.jar"
for ((attempt=0; attempt<45; attempt++)); do
  if curl --silent --fail --max-time 2 http://127.0.0.1:8080/api/branches >/dev/null; then
    echo 'Backend sẵn sàng: http://127.0.0.1:8080'
    exit 0
  fi
  if ! systemctl --user is-active --quiet cstore-mobile-backend.service; then
    echo 'Backend dừng khi khởi động. Xem journalctl --user -u cstore-mobile-backend -n 60' >&2
    exit 1
  fi
  sleep 1
done
echo 'Chưa sẵn sàng. Xem journalctl --user -u cstore-mobile-backend -n 60' >&2
exit 1
