#!/bin/bash
# Debian/Ubuntu 一键重装 iptables + NAT 伪装脚本
# 适配：Debian 8-12 / Ubuntu 16-24

echo "======================================"
echo "   一键重装 iptables + 启用伪装(MASQUERADE)"
echo "======================================"

# 停止并禁用 nftables
echo "[1/6] 卸载 nftables..."
systemctl stop nftables 2>/dev/null
systemctl disable nftables 2>/dev/null
apt-get remove -y nftables 2>/dev/null

# 安装 iptables + 持久化
echo "[2/6] 安装 iptables..."
apt update -y
apt install -y iptables iptables-persistent netfilter-persistent

# 清空现有规则
echo "[3/6] 清空原有规则..."
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X
iptables -t nat -X
iptables -t mangle -X

# 开启 ipv4 转发
echo "[4/6] 启用 IPv4 转发..."
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# 自动添加 MASQUERADE 伪装
echo "[5/6] 添加 iptables NAT 伪装规则..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -j ACCEPT
iptables -A FORWARD -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# 保存规则
echo "[6/6] 保存规则..."
netfilter-persistent save >/dev/null 2>&1
netfilter-persistent reload >/dev/null 2>&1

echo
echo "======================================"
echo "✔ iptables 重装完成"
echo "✔ NAT 伪装 (MASQUERADE) 已启用"
echo "✔ IPv4 转发已开启"
echo "✔ 规则已保存并开机自启"
echo "======================================"
echo
echo "提示：如你的外网网卡不是 eth0，请自行修改脚本中 -o eth0 为你的网卡名"
echo
