#!/bin/bash
# ==========================================
# 🚀 服务器下载加速优化脚本 (by ChatGPT)
# 支持: Ubuntu / Debian / CentOS
# 功能: 换源 + 启用BBR + aria2 + speedtest
# ==========================================

set -e

echo "=== 🧩 检测系统类型 ==="
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测系统类型！"
    exit 1
fi
echo "系统: $PRETTY_NAME"

echo "=== ⚙️ 更新系统 & 更换镜像源 ==="
case $OS in
    ubuntu|debian)
        cp /etc/apt/sources.list /etc/apt/sources.list.bak
        sed -i 's|archive.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
        sed -i 's|security.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
        apt update -y
        apt install -y wget curl net-tools iputils-ping speedtest-cli aria2
        ;;
    centos|rhel)
        cd /etc/yum.repos.d/
        sed -i 's|mirror.centos.org|mirrors.aliyun.com|g' *.repo 2>/dev/null || true
        yum clean all && yum makecache
        yum install -y wget curl net-tools iputils speedtest-cli aria2
        ;;
    *)
        echo "不支持的系统: $OS"
        exit 1
        ;;
esac

echo "=== 🚀 启用 Google BBR 加速 ==="
if ! lsmod | grep -q bbr; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi
sysctl net.ipv4.tcp_congestion_control

echo "=== ⚡ 测试下载速度 ==="
speedtest --secure || echo "speedtest 测试失败，可手动运行 speedtest"

echo "=== ✅ 优化完成 ==="
echo "工具安装路径:"
echo "  - aria2  : /usr/bin/aria2c"
echo "  - speedtest : /usr/bin/speedtest"
echo "  - 测速命令 : speedtest"
echo
echo "示例:"
echo "  aria2c -x 16 -s 16 https://example.com/file.iso"
echo "  speedtest"
echo
echo "BBR状态:"
sysctl net.ipv4.tcp_congestion_control
