详细部署步骤请查看部署指南[DEPLOY_GUIDE.md](DEPLOY_GUIDE.md)

# 一、指南核心内容速览

## 编译环境（服务端在容器里编译，宿主机不需要 Go）
| 组件 | 版本 | 用途 |
| --- | --- | --- |
| Docker + Compose | 29.9.3 / v5.7.1 | 服务端与网关 |
| Go | 1.26.5（镜像内） | DNF90Server/DNF90Assets |
| Python | 3.10+ | prepare/索引脚本 |
| Flutter / .NET / VS Build Tools | 3.47.9 / 8.0.427 / 17.14 | Windows 登录器 |

## 手动部署四段

```bash
# 1) 服务端镜像
cd /srv/dnf/ServerS5A3
docker build -t servers5a3-local:dev -f deploy/docker/Dockerfile .

# 2) 生成配置（显式 120 频道外部 ETC）
sh deploy/docker/manage.sh prepare --pvf /srv/dnf/assets/Script.pvf \
  --channel-info go-server/internal/services/dnfbridge/testdata/channel_info.etc \
  --host-ip 192.168.200.130
#    改 instance.json：joust_event_enabled=false、dungeon_tournament=vendor、
#    channel_advertise_server=1、channel_directory_owner_range=u8、
#    public_bootstrap=true、restart=unless-stopped、player_admin_secret
sh deploy/docker/manage.sh up

# 3) PurpleMagic（证书/profile/settings → 构建 → 索引 → 起服务）
python3 scripts/prepare_launcher_profile.py --connection runtime/launcher-input/server.json \
  --client runtime/client-input --certificate runtime/launcher-input/local-tls.pem \
  --public-key runtime/launcher-input/update-public.pem --output runtime/launcher-input/profile.json
python3 deploy/selfhost/prepare.py --settings runtime/selfhost-settings.json --output runtime/selfhost
docker compose --env-file runtime/selfhost/compose.env -f deploy/selfhost/compose.yaml build
# index-pvf → index-items（约 24 分钟）→ index-quests → index-professions → schema
docker compose ... up -d gateway gm edge

# 4) Windows 登录器
build-launcher.bat D:\SDKs\flutter D:\SDKs\dotnet8\dotnet.exe dist\PurpleMagic-1.0.12
```

##  一键部署
```bash
bash deploy-oneclick.sh --host-ip 192.168.200.130 \
  --pvf /srv/dnf/assets/Script.pvf --client-dir /srv/dnf/client
```
全新机器实测约 33 分钟（含 Docker 安装、镜像构建、索引、建表、自检）。

## 公网迁移只改这 6 处

| # | 位置 | 本地 → 公网
| --- | --- | --- |
| 1 | instance.json 的 host_ip | 频道通告地址（必须重跑 prepare --host-ip） |
| 2 | 登录器 server.json 的 ApiUrl | https://<玩家域名>:8443 |
| 3 | 同上的 GameHost | 公网 IP |
| 4 | selfhost-settings.json 的 gmOrigin | https://<GM域名> |
| 5 | 证书/私钥/CA | 换成真实证书链 |
| 6 | 登录器 | 换证书后必须重编（profile 内嵌） |

防火墙放行 7001、10006-10508/tcp、30000-30063/udp、8443、443；17002/18111/18444 保持 127.0.0.1。

# 二、日常运维（服务器 /srv/dnf/ops/）

```bash
bash ops-status.sh      # 状态 + 健康检查 + 端口
bash ops-logs.sh server # 日志：server|db|gateway|gm|edge|all
bash ops-start.sh       # 启动
bash ops-stop.sh        # 停止（保留数据卷）
bash ops-backup.sh      # 备份（另有每日 04:10 自动备份，保留 14 天）
bash ops-verify.sh      # 一键自检，应 11 PASS
```

指南第 10 节还写了更新/回退与"已实测"的数据库恢复步骤（停服 → 起 db → 重建库 → 导入 → 起服务 → 自检）。
