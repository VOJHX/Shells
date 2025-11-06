## 下载
```
cd ~
mkdir warp
cd warp

wget https://raw.githubusercontent.com/VOJHX/Shells/refs/heads/main/WARP/update-wgcf.sh
wget https://raw.githubusercontent.com/VOJHX/Shells/refs/heads/main/WARP/init-warp.sh
```

## 使用
```
# 下载 wgcf
bash update-wgcf.sh

# 初始化 WG 环境，并尝试部署 WARP
bash init-warp.sh

# 启动 WARP
sudo wg-quick up WARP

# 设置自启动
sudo systemctl enable wg-quick@WARP

# 测试
curl --interface WARP https://www.cloudflare.com/cdn-cgi/trace/
```

## Xray
在你的 Xray 配置中添加下面的出站配置：

[Xray-example-outbound.jsonc](./Xray-example-outbound.jsonc)

并配置路由
