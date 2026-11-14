#!/bin/bash
# 一键自检：容器、账号 API、频道端口、活动开关、网关与频道握手
set -uo pipefail
PASS=0; FAIL=0
ok()   { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad()  { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

echo "== 1. 容器 =="
cd /srv/dnf/ServerS5A3
for c in servers5a3-local-db-1 servers5a3-local-server-1; do
  s=$(docker inspect -f '{{.State.Health.Status}}' "$c" 2>/dev/null)
  [ "$s" = "healthy" ] && ok "$c healthy" || bad "$c = ${s:-missing}"
done
cd /srv/dnf/PurpleMagic
for c in purplemagic-gateway-1 purplemagic-gm-1 purplemagic-edge-1; do
  st=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
  [ "$st" = "running" ] && ok "$c running" || bad "$c = ${st:-missing}"
done

echo "== 2. 账号 API =="
curl -s --max-time 5 http://127.0.0.1:17002/api/status | grep -q '"ok":true' && ok "17002 /api/status" || bad "17002 /api/status"

echo "== 3. 频道端口 =="
HOST_IP=$(python3 -c "import json;print(json.load(open('/srv/dnf/ServerS5A3/runtime/docker/instance.json'))['host_ip'])")
n=$(ss -lnt | grep -c "$HOST_IP:10")
[ "$n" -eq 120 ] && ok "120 个频道端口监听（$HOST_IP）" || bad "频道端口数=$n（$HOST_IP）"
ss -lnt | grep -q "$HOST_IP:7001" && ok "7001 引导端口（$HOST_IP）" || bad "7001 未监听（$HOST_IP）"

echo "== 4. 活动 2365 =="
SECRET=$(python3 -c "import json;print(json.load(open('/srv/dnf/ServerS5A3/runtime/docker/instance.json'))['player_admin_secret'])")
curl -s --max-time 8 -X POST http://127.0.0.1:17002/api/game/admin \
  -H "Authorization: Bearer $SECRET" -H 'Content-Type: application/json' \
  -d '{"version":1,"action":"activities"}' > /tmp/verify-act.json
python3 - <<'PY'
import json
d = json.load(open('/tmp/verify-act.json'))
a = {x['id']: x for x in d['activities']['activities']}
x = a.get(2365, {})
print('  [%s] 2365 enabled=%s effective=%s pendingRestart=%s' % (
    'PASS' if x.get('enabled') is False and x.get('effectiveEnabled') is False else 'FAIL',
    x.get('enabled'), x.get('effectiveEnabled'), x.get('pendingRestart')))
PY

echo "== 5. 玩家网关 =="
CA=/srv/dnf/PurpleMagic/runtime/selfhost/tls-player/ca.pem
curl -s --max-time 8 --cacert "$CA" https://players.purplemagic.test:8443/api/status | grep -q '"ok":true' \
  && ok "8443 /api/status（证书固定链）" || bad "8443 /api/status"
code=$(curl -s --max-time 8 --cacert "$CA" -o /dev/null -w '%{http_code}' https://players.purplemagic.test:8443/launcher/v2/bootstrap.json)
[ "$code" = "200" ] && ok "bootstrap.json 200" || bad "bootstrap.json=$code"

echo "== 6. 频道握手（探测器） =="
if [ -x /usr/bin/dotnet ] && [ -f /srv/dnf/probe/Launcher.Probe.dll ]; then
  if dotnet /srv/dnf/probe/Launcher.Probe.dll /srv/dnf/probe/profile.json --channel-only 2>&1 | tee /tmp/verify-probe.log | grep -q 'PASS native channel bootstrap'; then
    ok "$(grep 'PASS native' /tmp/verify-probe.log)"
  else
    bad "频道握手失败：$(tail -2 /tmp/verify-probe.log | tr '\n' ' ')"
  fi
else
  echo "  [SKIP] 无 dotnet 或探测器"
fi

echo
echo "结果：PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && echo "VERIFY_OK" || echo "VERIFY_FAILED"
