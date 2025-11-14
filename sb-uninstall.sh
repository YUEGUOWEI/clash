#!/bin/bash
# =============================================
#   Sing-Box / sb.sh 通用安全卸载脚本
#   不依赖原脚本，适用于各种安装方式
# =============================================

echo "==== 停止 sing-box / sb 服务 ===="
SERVICES=("sing-box" "singbox" "sb" "sing-box.service" "singbox.service" "sb.service")

for svc in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "$svc"; then
        echo "停止服务: $svc"
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null
        rm -f "/etc/systemd/system/$svc"
    fi
done

systemctl daemon-reload

echo
echo "==== 删除程序文件（如存在） ===="
BIN_PATHS=(
    "/usr/bin/sing-box"
    "/usr/local/bin/sing-box"
    "/usr/sbin/sing-box"
)

for path in "${BIN_PATHS[@]}"; do
    if [ -f "$path" ]; then
        echo "删除文件: $path"
        rm -f "$path"
    fi
done

echo
echo "==== 删除配置目录（如存在） ===="
CONF_PATHS=(
    "/etc/sing-box"
    "/usr/local/etc/sing-box"
    "/var/lib/sing-box"
    "/var/log/sing-box"
)

for cpath in "${CONF_PATHS[@]}"; do
    if [ -d "$cpath" ]; then
        echo "删除目录: $cpath"
        rm -rf "$cpath"
    fi
done

echo
echo "==== 清理完成 ===="
echo "如果仍看到端口占用，请手动执行： ss -lntp | grep -i sing"
echo "卸载已完成！"
