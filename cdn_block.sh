#!/bin/bash
# =======================================================
# 📛 GCP / Linux 服务器防火墙一键脚本
# 🔒 封禁 Akamai / Cloudflare / Fastly CDN IP
# 🔁 每日自动更新
# 📦 适用系统：Ubuntu / Debian / CentOS / Rocky / AlmaLinux
# =======================================================

set -e

TMPDIR="/tmp/cdn_block"
RULES_FILE="/etc/iptables.rules"
SCRIPT_PATH="/usr/local/bin/update_cdn_block.sh"
CRON_FILE="/etc/cron.d/cdn_block_update"

echo "🚧 [1/6] 正在安装依赖..."
if command -v apt &>/dev/null; then
  apt update -y && apt install -y curl iptables cron
elif command -v yum &>/dev/null; then
  yum install -y curl iptables cronie
else
  echo "❌ 未检测到受支持的包管理器 (apt/yum)"
  exit 1
fi

mkdir -p "$TMPDIR"

# 创建更新脚本
cat > "$SCRIPT_PATH" <<'EOF'
#!/bin/bash
TMPDIR="/tmp/cdn_block"
mkdir -p $TMPDIR

echo "⬇️ 更新 CDN IP 列表..."

# Cloudflare
curl -s https://www.cloudflare.com/ips-v4 -o $TMPDIR/cloudflare.txt

# Fastly
curl -s https://api.fastly.com/public-ip-list | grep -oE '[0-9\.]+/[0-9]+' > $TMPDIR/fastly.txt

# Akamai（第三方列表）
curl -s https://raw.githubusercontent.com/SecOps-Institute/CDN-IP-Lists/master/Akamai/Akamai.txt -o $TMPDIR/akamai.txt

# 合并并去重
cat $TMPDIR/*.txt | sort -u > $TMPDIR/all.txt
COUNT=$(wc -l < $TMPDIR/all.txt)
echo "📦 已获取 $COUNT 个 IP 段"

# 清除旧规则（仅针对标记的链）
iptables -F CDN_BLOCK 2>/dev/null || true
iptables -X CDN_BLOCK 2>/dev/null || true
iptables -N CDN_BLOCK

# 将链挂入 INPUT
iptables -C INPUT -j CDN_BLOCK 2>/dev/null || iptables -I INPUT -j CDN_BLOCK

# 添加封禁规则
while read ip; do
  [ -z "$ip" ] && continue
  iptables -A CDN_BLOCK -s "$ip" -j DROP
done < $TMPDIR/all.txt

# 保存规则
iptables-save > /etc/iptables.rules
echo "✅ 防火墙规则已更新并保存"

EOF

chmod +x "$SCRIPT_PATH"

echo "⚙️ [2/6] 正在执行首次封禁..."
bash "$SCRIPT_PATH"

# 设置开机自动恢复
echo "⚙️ [3/6] 设置开机自动加载规则..."
cat > /etc/network/if-pre-up.d/iptablesload <<EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
EOF
chmod +x /etc/network/if-pre-up.d/iptablesload

# 设置每日自动更新任务（每天凌晨 3 点）
echo "⚙️ [4/6] 添加每日自动更新任务..."
echo "0 3 * * * root /usr/local/bin/update_cdn_block.sh >/var/log/cdn_block_update.log 2>&1" > "$CRON_FILE"

# 启用 cron 服务
echo "⚙️ [5/6] 启动定时任务服务..."
if command -v systemctl &>/dev/null; then
  systemctl enable cron || systemctl enable crond
  systemctl start cron || systemctl start crond
else
  service cron start || service crond start
fi

echo "✅ [6/6] 完成所有配置"
echo "📂 规则文件: $RULES_FILE"
echo "📜 更新脚本: $SCRIPT_PATH"
echo "🕒 自动更新任务: $CRON_FILE"
echo "🚀 CDN 封禁规则已生效并将每日自动更新！"
