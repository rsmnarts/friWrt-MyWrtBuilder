#!/bin/bash

echo "Start Downloading Misc files !"
echo "Current Path: $PWD"

# setup login password
{
if [ -z "$LOGIN_PASSWORD" ]; then
  sed -i "/uci commit wireless/ i\echo -e \"$LOGIN_PASSWORD\n$LOGIN_PASSWORD\" | passwd" files/etc/uci-defaults/99-init-settings.sh
fi
if [ -z "$WIFI_PASSWORD" ]; then
  sed -i "/uci commit wireless/ i\uci set wireless.@wifi-iface[0].encryption='psk2'" files/etc/uci-defaults/99-init-settings.sh
  sed -i "/uci commit wireless/ i\uci set wireless.@wifi-iface[0].key=\"$WIFI_PASSWORD\"" files/etc/uci-defaults/99-init-settings.sh
fi
}

# custom script files urls
urls=("https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-$ARCH_2.tgz"
      "https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch"
      "https://raw.githubusercontent.com/frizkyiman/auto-sync-time/main/sbin/sync_time.sh"
      "https://raw.githubusercontent.com/frizkyiman/auto-sync-time/main/usr/bin/clock"
      "https://raw.githubusercontent.com/frizkyiman/fix-read-only/main/sbin/repair_ro"
      "https://raw.githubusercontent.com/frizkyiman/auto-mount-hdd/main/mount_hdd")

{
echo "setup 99-init-settings.sh"
if [[ -e "files/etc/uci-defaults/99-init-settings_"$BASE""$tags.sh"" ]]; then
     mv "files/etc/uci-defaults/99-init-settings_"$BASE""$tags.sh"" "files/etc/uci-defaults/99-init-settings.sh"
     rm files/etc/uci-defaults/99-init-settings_*.sh
fi

echo "setup 10_system.js"
if [[ -e "files/www/luci-static/resources/view/status/include/10_system_$BASE.js" ]]; then
     mv "files/www/luci-static/resources/view/status/include/10_system_$BASE.js" "files/www/luci-static/resources/view/status/include/10_system.js"
     rm files/www/luci-static/resources/view/status/include/10_system_*.js
fi
}
{
echo "Downloading custom script"
mkdir -p files/etc/init.d
mkdir -p files/sbin/
if wget --no-check-certificate -nv -P files "${urls[@]}"; then
    echo "sync && echo 3 > /proc/sys/vm/drop_caches && rm -rf /tmp/luci*" >> files/sbin/free.sh
    mv files/sync_time.sh files/sbin/sync_time.sh
    mv files/neofetch files/usr/bin/neofetch
    mv files/clock files/usr/bin/clock
    mv files/repair_ro files/sbin/repair_ro
    mv files/mount_hdd files/usr/bin/mount_hdd
    tar -zxf files/ookla-speedtest-1.2.0-linux-$ARCH_2.tgz -C files/usr/bin && rm files/ookla-speedtest-1.2.0-linux-$ARCH_2.tgz && rm files/usr/bin/speedtest.md
fi
}

{
cat <<'EOF' >files/etc/init.d/repair_ro
#!/bin/sh /etc/rc.common

START=99

start() {
    /sbin/repair_ro
}
EOF
}
{
cat <<'EOF' >files/usr/bin/repair_ro
#!/bin/sh
root_device="$1"
/sbin/repair_ro "$root_device"
EOF
}
{
cat <<'EOF' >files/etc/config/vnstat
config vnstat
	list interface 'br-lan'
	list interface 'wwan0'
EOF
}
{
sed -i '/reboot/ i\chmod +x /root/fix-tinyfm.sh && bash /root/fix-tinyfm.sh' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /sbin/sync_time.sh' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /sbin/free.sh' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /usr/bin/patchoc.sh' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /usr/bin/neofetch' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /usr/bin/clock' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /etc/init.d/repair_ro' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /usr/bin/repair_ro' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /sbin/repair_ro' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /usr/bin/mount_hdd' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /usr/bin/speedtest' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\chmod +x /usr/bin/adguardhome' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\bash /usr/bin/adguardhome --force-enable' files/etc/uci-defaults/99-init-settings.sh
sed -i '/reboot/ i\uci set luci.main.mediaurlbase='/luci-static/argon' && uci commit' files/etc/uci-defaults/99-init-settings.sh
}
echo "Downloading and configurating completed!"
