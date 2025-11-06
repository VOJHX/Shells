#!/usr/bin/env bash
set -e

WGCF_PATH="./wgcf"
VERSION_FILE="./wgcf_version.txt"

echo "==> 更新系统依赖..."
sudo apt update -qq
sudo apt install -y jq curl > /dev/null

echo "==> 获取 wgcf 最新版本信息..."
LATEST_TAG=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | jq -r '.tag_name')
ASSET_URL=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest \
  | jq -r '.assets[] | select(.name | test("linux_amd64")) | .browser_download_url')

# 去掉开头的 v，方便比较
LATEST_VERSION="${LATEST_TAG#v}"

# 检查是否有旧版本记录
if [[ -f "$VERSION_FILE" ]]; then
  CURRENT_VERSION=$(cat "$VERSION_FILE")
  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo "==> wgcf 已是最新版本 ($CURRENT_VERSION)，无需更新。"
    exit 0
  else
    echo "==> 检测到新版本：$CURRENT_VERSION → $LATEST_VERSION"
  fi
else
  echo "==> 首次安装 wgcf（版本 $LATEST_VERSION）"
fi

# 下载并替换
echo "==> 正在下载 wgcf $LATEST_VERSION ..."
wget -qO "$WGCF_PATH" "$ASSET_URL"
chmod +x "$WGCF_PATH"

# 写入版本号
echo "$LATEST_VERSION" > "$VERSION_FILE"
echo "==> 已更新 wgcf 至版本 $LATEST_VERSION"
