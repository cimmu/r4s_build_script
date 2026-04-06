#!/bin/bash
# =========================================================
# NanoPi R76S 纯净版 OpenWrt 自动构建脚本 (集成 sbwml 核心优化)
# =========================================================
set -e

# --- 1. 环境准备 ---
WORKSPACE=$(pwd)
OPENWRT_DIR="$WORKSPACE/openwrt_src"

# 定义上游仓库和版本
export github="github.com"
export gitea="github.com" # 原来指向私服的代码，这里统一改向 Github
export code_mirror="github.com"
export mirror="https://init.cooluc.com"
export branch="v25.12.2"
export platform="rk3576" 
export model="nanopi-r76s"

echo "========================================================="
echo " [1/5] Cloning Official OpenWrt $branch ..."
echo "========================================================="
git clone --depth 1 https://github.com/openwrt/openwrt.git -b $branch $OPENWRT_DIR
cd $OPENWRT_DIR


echo "========================================================="
echo " [2/5] Injecting sbwml's Core Optimizations & Patches ..."
echo "========================================================="
# 这部分原封不动利用源仓库自带的优秀补丁文件，但本地化直接执行
# 不再通过网络 curl 互相调用，保证极度透明和可靠。
# 我们直接调用上级目录里已经经过你修复过的代码：

if [ -d "$WORKSPACE/../openwrt/scripts" ]; then
    SCRIPT_DIR="$WORKSPACE/../openwrt/scripts"
else
    # 兼容脱离主仓库独立运行的情况，从开源源拉取最新的基础脚本
    mkdir -p tmp_scripts
    curl -sLo tmp_scripts/00-prepare_base.sh "$mirror/openwrt/scripts/00-prepare_base.sh"
    curl -sLo tmp_scripts/01-prepare_base-mainline.sh "https://raw.githubusercontent.com/cimmu/r4s_build_script/master/openwrt/scripts/01-prepare_base-mainline.sh"
    curl -sLo tmp_scripts/02-prepare_package.sh "$mirror/openwrt/scripts/02-prepare_package.sh"
    curl -sLo tmp_scripts/03-convert_translation.sh "$mirror/openwrt/scripts/03-convert_translation.sh"
    curl -sLo tmp_scripts/04-fix_kmod.sh "$mirror/openwrt/scripts/04-fix_kmod.sh"
    curl -sLo tmp_scripts/05-fix-source.sh "$mirror/openwrt/scripts/05-fix-source.sh"
    SCRIPT_DIR="tmp_scripts"
fi

echo "========================================================="
echo " [3/5] Updating and Installing Feeds BEFORE patching ..."
echo "========================================================="
# sbwml 的脚本需要在打补丁前更新好所有 feeds 包源码！
./scripts/feeds update -a
./scripts/feeds install -a

echo "========================================================="
echo " [4/5] Injecting sbwml's Core Optimizations & Patches ..."
echo "========================================================="
bash $SCRIPT_DIR/00-prepare_base.sh
bash $SCRIPT_DIR/01-prepare_base-mainline.sh
bash $SCRIPT_DIR/02-prepare_package.sh
bash $SCRIPT_DIR/03-convert_translation.sh
bash $SCRIPT_DIR/04-fix_kmod.sh
bash $SCRIPT_DIR/05-fix-source.sh


echo "========================================================="
echo " [5/6] Generating .config (Pure + Optimizations) ..."
echo "========================================================="
cat $WORKSPACE/scripts/r76s.config > .config

# 追加 BPF 和 LTO 高级性能优化
echo "=> Injecting LTO and BPF configurations..."
curl -sL $mirror/openwrt/generic/config-lto >> .config
curl -sL $mirror/openwrt/generic/config-bpf >> .config

# 屏蔽导致 CI 卡死的选项
echo "" >> .config
echo "# CONFIG_KERNEL_IR_IMON_DECODER is not set" >> .config

# 让 OpenWrt 自动补全和优化配置项
make defconfig


echo "========================================================="
echo " [6/6] Compiling OpenWrt for NanoPi R76S ..."
echo "========================================================="
# 下载依赖包 (避免编译中断)
make download -j8

# 开始多线程编译
make -j$(nproc) || make -j1 V=s

echo "========================================================="
echo " Build Completed! "
echo "========================================================="
