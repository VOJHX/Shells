#!/usr/bin/env bash
set -e

WG_CONF="/etc/wireguard/WARP.conf"
BACKUP="/etc/wireguard/WARP.conf.bak"
IFACE="WARP"

if [[ ! -f "$WG_CONF" ]]; then
  echo "❌ 找不到 WireGuard 配置文件：$WG_CONF"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "⚙️  请使用 sudo 运行此脚本。"
  exit 1
fi

# 读取当前模式
MODE=$(grep -E '^AllowedIPs' "$WG_CONF" | head -n1)

if echo "$MODE" | grep -q "0.0.0.0/0"; then
  echo "==> 当前是『全局代理模式』，将切换为『非全局模式』..."
  cp "$WG_CONF" "$BACKUP"
  sed -i 's/^AllowedIPs.*/AllowedIPs = 172.16.0.0\/12, 2606:4700:110::\/48/' "$WG_CONF"
  NEW_MODE="非全局模式"
else
  echo "==> 当前是『非全局模式』，将切换为『全局代理模式』..."
  cp "$WG_CONF" "$BACKUP"
  sed -i 's/^AllowedIPs.*/AllowedIPs = 0.0.0.0\/0, ::\/0/' "$WG_CONF"
  NEW_MODE="全局代理模式"
fi

# 自动重启接口
echo
echo "🔄 正在重启 WARP 接口..."
wg-quick down "$IFACE" 2>/dev/null || true
wg-quick up "$IFACE"

echo
echo "✅ 已切换为【$NEW_MODE】并成功重启接口。"
echo "配置文件已备份到：$BACKUP"
echo
echo "当前出口 IP 检查："
curl -s --max-time 8 --interface "$IFACE" https://www.cloudflare.com/cdn-cgi/trace/ || echo "(无法连接，请检查网络)"
