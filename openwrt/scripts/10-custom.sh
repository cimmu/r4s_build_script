#!/bin/bash
# Brand customization script for R76S Custom Firmware

GREEN_COLOR='\e[1;32m'
RES='\e[0m'

echo -e "\n${GREEN_COLOR}Applying R76S brand customization...${RES}\n"

# 0. Add Passwall2 package source (Official)
echo -e "${GREEN_COLOR}Removing bundled Passwall2 and adding official repository...${RES}"
# 清除 sbwml 捆绑包里自带的 passwall2 避免包名冲突
rm -rf package/new/helloworld/luci-app-passwall2 package/new/helloworld/passwall2
git clone https://github.com/Openwrt-Passwall/openwrt-passwall2.git package/new/passwall2 --depth=1

# 1. Modify version source
sed -i 's/VERSION_DIST:=OpenWrt/VERSION_DIST:=R76S/g' include/version.mk

# 2. Modify system description
sed -i "s/DISTRIB_ID='OpenWrt'/DISTRIB_ID='R76S'/g" package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_RELEASE=.*/DISTRIB_RELEASE='1.0'/g" package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_REVISION=.*/DISTRIB_REVISION='by William'/g" package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_DESCRIPTION=.*/DISTRIB_DESCRIPTION='R76S Custom Firmware (Technical Support by William)'/g" package/base-files/files/etc/openwrt_release

# 3. Modify default hostname
sed -i "s/hostname='OpenWrt'/hostname='R76S'/g" package/base-files/files/bin/config_generate

# 4. Modify SSH Banner
cat > package/base-files/files/etc/banner <<'EOF'
R76S Custom Firmware
Technical Support by William
EOF

# 5. Modify LuCI version string (if file exists)
if [ -f "feeds/luci/modules/luci-base/root/usr/lib/lua/luci/version.lua" ]; then
    sed -i 's/return ".*"/return "LuCI R76S Edition (Powered by William)"/g' feeds/luci/modules/luci-base/root/usr/lib/lua/luci/version.lua
fi

# 6. Add version configurations to .config
echo "CONFIG_VERSION_DIST=\"R76S\"" >> .config
echo "CONFIG_VERSION_NUMBER=\"1.0\"" >> .config
echo "CONFIG_VERSION_CODE=\"by William\"" >> .config
echo "CONFIG_VERSIONOPT=y" >> .config

echo -e "${GREEN_COLOR}Brand customization completed!${RES}\n"