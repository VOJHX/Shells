#!/usr/bin/env bash
set -e

WGCF="./wgcf"
WGCF_ACCOUNT="./wgcf-account.toml"
WGCF_PROFILE="./wgcf-profile.conf"
WG_CONF="/etc/wireguard/WARP.conf"

#=== 函数区 ===#

check_wireguard() {
  echo "==> 检查 WireGuard 环境..."
  
  if command -v wg &>/dev/null && command -v wg-quick &>/dev/null; then
    echo "✅ WireGuard 已安装。"
  else
    echo "⚙️  未检测到 WireGuard，正在自动安装..."
    sudo apt update -qq
    sudo apt install -y wireguard > /dev/null
    echo "✅ WireGuard 安装完成。"
  fi

  # 检查内核模块
  if ! lsmod | grep -q wireguard; then
    echo "==> 尝试加载 WireGuard 内核模块..."
    sudo modprobe wireguard || {
      echo "❌ 无法加载 WireGuard 内核模块，请检查内核版本。"
      echo "   你可能需要安装内核模块包：linux-headers-$(uname -r)"
      exit 1
    }
  fi
}

#=== 主逻辑 ===#

echo "==> 自动化 WARP 配置脚本启动..."
check_wireguard

# 检查 wgcf 是否存在
if [[ ! -x "$WGCF" ]]; then
  echo "❌ 未找到可执行文件 $WGCF"
  echo "请先运行 update-wgcf.sh 下载最新版 wgcf。"
  exit 1
fi

# 注册账户
if [[ -f "$WGCF_ACCOUNT" ]]; then
  echo "==> 检测到已有账户文件：$WGCF_ACCOUNT"
else
  echo "==> 未检测到账户文件，开始注册新账户..."
  "$WGCF" register --accept-tos
  echo "==> 注册完成，账户文件已生成：$WGCF_ACCOUNT"
fi

# 若设置了 WARP+ License
if [[ -n "$WARP_LICENSE" ]]; then
  echo "==> 检测到 WARP+ License Key，正在更新账户..."
  "$WGCF" update --license-key "$WARP_LICENSE"
fi

# 生成配置
echo "==> 生成 WireGuard 配置..."
"$WGCF" generate

if [[ ! -f "$WGCF_PROFILE" ]]; then
  echo "❌ 生成配置失败，未找到 $WGCF_PROFILE"
  exit 1
fi

# 复制配置到系统目录
echo "==> 复制配置到 $WG_CONF ..."
sudo mkdir -p /etc/wireguard
sudo cp "$WGCF_PROFILE" "$WG_CONF"
sudo chmod 600 "$WG_CONF"

# 自动注释掉配置文件中的 DNS 行，以防止 wg-quick 调用 resolvconf 失败。
# 这样脚本就能在不安装 resolvconf 的情况下正常工作，并使用系统现有的 DNS 设置。
echo "==> 禁用 WireGuard 配置中的 DNS 管理功能以增强兼容性..."
sudo sed -i 's/^DNS =.*/#&/' "$WG_CONF"

#=== 完成提示 ===#
echo
echo "✅ WARP 配置已完成：$WG_CONF"
echo
echo "要启动 WARP 接口，请运行："
echo "  sudo wg-quick up WARP"
echo
echo "若要开机自启："
echo "  sudo systemctl enable wg-quick@WARP"
echo
echo "测试连接："
echo "  curl --interface WARP https://www.cloudflare.com/cdn-cgi/trace/"
echo
echo "（使用 WARP+ 时运行："
echo "  WARP_LICENSE=<你的key> ./init-warp.sh"
echo "）"
