function func_setenv()
{
if [ "${rom_type}" == "cm" ]; then myrom="cm based rom"; MY_BUILD="$CM_BUILD";
elif [ "${rom_type}" == "du" ]; then myrom="du based rom"; MY_BUILD="$DU_BUILD";
elif [ "${rom_type}" == "omni" ]; then myrom="omni based rom"; MY_BUILD="$CUSTOM_BUILD";
else echo -e "${CL_RED} * Error: rom_type not set [vendor/extra/config.sh]${CL_RST}\n"; fi
unset rom_type
if [ "${with_su}" == "1" ]; then myrom="$myrom+SU"; export WITH_SU="true"; else unset WITH_SU; fi
unset with_su
unset CCACHE_DIR
}

#function patchcommontree()
#{
#for f in `test -d vendor && find -L vendor/extra/patch/*/ -maxdepth 1 -name 'apply.sh' 2> /dev/null`
#do
#echo -e "${CL_YLW}\nPatching $f${CL_RST}"
#. $f
#done
#unset f
#}

#function patchdevicetree()
#{
#for f in `test -d device && find -L device/*/$MY_BUILD/patch -maxdepth 4 -name 'apply.sh' 2> /dev/null | sort` \
# `test -d vendor && find -L vendor/extra/patch/device/$MY_BUILD -maxdepth 1 -name 'apply.sh' 2> /dev/null | sort`
#do
#echo -e "${CL_YLW}\nPatching $f${CL_RST}"
#. $f
#done
#unset f
#}

function set_stuff_for_environment()
{
settitle
set_java_home
setpaths
set_sequence_number
#patchcommontree
#patchdevicetree

# With this environment variable new GCC can apply colors to warnings/errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
export ASAN_OPTIONS=detect_leaks=0
}

function func_ccache()
{
rom_dir_full=`pwd`
rom_dir=`basename $rom_dir_full`
export CCACHE_DIR=$ccache_dir/$rom_dir
c_dir=`ccache -s|grep directory|cut -d '/' -f1-10`
c_size=`ccache -s|grep 'cache size'`
c_current=`echo $c_size|cut -d ' ' -f3-4`
c_max=`echo $c_size|cut -d ' ' -f8-9`
ccache -M $ccache_size >/dev/null

if [[ "${ccache_use}" == "" || "${ccache_use}" == "0" || "${ccache_use}" == "false" ]]; then echo -e "${CL_MAG} * Disabled ccache${CL_RST}"; export USE_CCACHE=0;
elif [ "${ccache_dir}" == "" ]; then echo -e "${CL_RED} * Error: ccache_dir not set [vendor/extra/config.sh]${CL_RST}\n"; else export USE_CCACHE=1; echo -e "${CL_GRN} * Setup ccache : ${CL_LBL}$c_current${CL_RST} of ${CL_LBL}$c_max${CL_RST} used in ${CL_LBL}$CCACHE_DIR${CL_RST}"; fi
}

function func_java()
{
MYPYT=`python --version 2&>/tmp/mypyt|cat /tmp/mypyt`
export mypyt=`sed q /tmp/mypyt`
MYJDK=`java -version 2&>/tmp/myjdk|cat /tmp/myjdk`
export myjdk=`sed q /tmp/myjdk`
export MY_ROM=$rom_dir
export PATH="$jdk_dir:$PATH"

echo -e "${CL_GRN} * Checking env : ${CL_LBL}$mypyt${CL_RST} | ${CL_LBL}$myjdk${CL_RST} | ${CL_LBL}$myrom${CL_RST}"
}

function func_colors()
{
CL_RED="\033[31m"
CL_GRN="\033[32m"
CL_YLW="\033[33m"
CL_BLU="\033[34m"
CL_MAG="\033[35m"
CL_CYN="\033[36m"
CL_RST="\033[0m"
CL_B="\e[1;38;5;33m"
CL_LBL="\e[1;38;5;81m"
CL_GY="\e[1;38;5;242m"
CL_GRN="\e[1;38;5;82m"
CL_P="\e[1;38;5;161m"
CL_PP="\e[1;38;5;93m"
CL_RED="\e[1;38;5;196m"
CL_Y="\e[1;38;5;214m"
CL_W="\e[0m"
}

function func_repos()
{
if [ ! -d ".repo/local_manifests" ]
then
rsync -a vendor/extra/local_manifests/*.xml .repo/local_manifests/;
echo -e "${CL_GRN} * Local Manifest initialised, syncing now...\n${CL_RST}";
repo sync -j100 --force-sync 2&> /dev/null;
else
rsync -avc --stats --exclude=du_manifest.xml vendor/extra/local_manifests/*.xml .repo/local_manifests/ >/tmp/rsync;
fi
if ! `sed '/xml/!d' /tmp/rsync`&> /dev/null; then repo sync -j100 --force-sync; fi

echo -e "${CL_GRN} * Setup repos${CL_RST}"
echo -e "${CL_LBL}   "`sed '/xml/!d' /tmp/rsync`"\n${CL_RST}"
}

function func_alias()
{
	alias cn="echo $(sed "s/lineage_//" <<< "${TARGET_PRODUCT}")"
	#Update Tools
	alias udt="repo sync -c -d --force-sync BAProductions/vendor_extra && . build/envsetup.sh && show_alias"
	#Repo Sync Command
	alias rs="repo sync -c -d --force-sync && . build/envsetup.sh && show_alias"
	alias arb="cd vendor/cm/ && git am --abort && cd ../.. && . build/envsetup.sh && show_alias"
	#Nexus 7 More Control Panel
	alias lgrou="lunch aosp_grouper-user -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	alias lgroud="lunch aosp_grouper-userdebug -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	alias lgroeng="lunch aosp_grouper-eng -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	#Nexus 7 More Control Extre Command
	alias mgdv="mka clobber -j$(expr $(nproc --all) \* 10) && lunch aosp_grouper-userdebug  WITH_DEXPREOPT=true -j$(expr $(nproc --all) \* 10)  && mka bacon -j$(expr $(nproc --all) \* 10) && rbir";
	#Samsung Galaxy Tab E 9.6 WiFi New Tablet
	alias lgteu="lunch lineage_gtelwifiue-user-j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	alias lgteud="lunch lineage_gtelwifiue-userdebug -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	alias lgteeng="lunch lineage_gtelwifiue-eng -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	#Samsung Galaxy Tab 4 10.1 WiFi Old Tablet
	alias lmu="lunch lineage_matissewifi-user -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	alias lmud="lunch lineage_matissewifi-userdebug -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_aliass"
	alias lmeng="lunch lineage_matissewifi-eng -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	alias mofmbeng="mka clobber -j$(expr $(nproc --all) \* 10) && breakfast lineage_matissewifi-eng -j$(expr $(nproc --all) \* 10) && mka target-files-package dist otatools"
	alias mofmbud="mka clobber -j$(expr $(nproc --all) \* 10) && breakfast lineage_matissewifi-userdebug -j$(expr $(nproc --all) \* 10) && mka target-files-package dist otatools"
	#Samsung Galaxy Tab 4 10.1 WiFi Old Tablet Extre
	alias mmwdvus="nfdj && wnga && mka clobber -j$(expr $(nproc --all) \* 10) && brunch lineage_matissewifi-eng WITH_DEXPREOPT=true WITH_GAPPS=false -j$(expr $(nproc --all) \* 10) && rbir";
	alias mmwdvs="nfdj && wga && mka clobber -j$(expr $(nproc --all) \* 10) && brunch lineage_matissewifi-eng WITH_DEXPREOPT=true WITH_GAPPS=true -j$(expr $(nproc --all) \* 10) && rbir";
	alias mmwdvsp="fdj && wga && mka clobber -j$(expr $(nproc --all) \* 10) && brunch lineage_matissewifi-eng WITH_DEXPREOPT=true WITH_GAPPS=true -j$(expr $(nproc --all) \* 10) && rbir";
	alias mmwdvb="wnga && mka clobber -j$(expr $(nproc --all) \* 10) && brunch lineage_matisselte-eng WITH_DEXPREOPT=true WITH_GAPPS=false -j$(expr $(nproc --all) \* 10) && wga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=true WITH_GAPPS=true -j$(expr $(nproc --all) \* 10) && rbir"
	alias mcl="mka camera.msm8226 -j$(expr $(nproc --all) \* 10) && adb remount && adb push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/lib/hw/camera.msm8226.so system/lib/hw/ && adb shell chmod 0644 system/lib/hw/camera.msm8226.so && adb reboot && adb wait-for-device logcat | grep --color=auto -E 'camera|preview|sr|selinux|not found|sepolicy|avc|policy|rev'";
	#Camera Wrapper For MSM8226 Devices
	alias mcs="mka libmmcamera_sr130pc20_shim -j$(expr $(nproc --all) \* 10) && adb remount && adb push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/lib/libmmcamera_sr130pc20_shim.so system/lib/ && adb shell chmod 0644 system/lib/libmmcamera_sr130pc20_shim.so && adb reboot && adb wait-for-device logcat | grep --color=auto -E 'camera|preview|sr|selinux|not found|sepolicy|avc|policy|rev'";
	#Build Command
	#Build Command Userdubug Sweetend
	alias mat4uds="export WITH_DEXPREOPT=false && nfdj && wga && mka clobber -j40 && nfdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisselte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisse3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_milletwifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true-j40 && nfdj && wga && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_millet3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && fdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 &&  fdj && wga && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";
	alias mat4wmduds="export WITH_DEXPREOPT=false && nfdj && wga && mka clobber -j40 && nfdj && wga && nfdj && wga && brunch lineage_matisselte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisse3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && nfdj && wga && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_millet3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && fdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 &&  fdj && wga && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";
	#Build Command Userdubug Unsweetend
	alias mat4udus="export WITH_DEXPREOPT=false && nfdj && wnga && mka clobber -j40 && nfdj && wnga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_matisselte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_matisse3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_milletwifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false-j40 && nfdj && wnga && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_millet3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && fdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";
	#Build Command Eng
	#Build Command Eng Sweetend
	alias mat4engs="nfdj && wga && mka clobber -j40 && nfdj && wga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisselte-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisse3g-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_milletwifi-eng WITH_DEXPREOPT=false WITH_GAPPS=true-j40 && nfdj && wga && brunch lineage_milletlte-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_millet3g-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && fdj && wga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";
	#Build Command Eng Unsweetend
	alias mat4engus="export nfdj && wnga && mka clobber -j40 && nfdj && wnga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_matisselte-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_matisse3g-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_milletwifi-eng WITH_DEXPREOPT=false WITH_GAPPS=false-j40 && nfdj && wnga && brunch lineage_milletlte-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_millet3g-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && fdj && wga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";
	alias mampd="export WITH_DEXPREOPT=false && mka clobber -j40 && fdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir"

	alias mb="mka bacon -j$(expr $(nproc --all) \* 10) && rbir"
	alias msi="mka systemimage -j$(expr $(nproc --all) \* 10) && mop "
	alias mbi="mka bootimage -j$(expr $(nproc --all) \* 10) && rbir && adb wait-for-recovery shell rm -f sdcard/boot.img && sleep 20 && adb wait-for-recovery push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/boot.img sdcard/boot.img"
	alias mbic="mka bootimage -j$(expr $(nproc --all) \* 10) && rbir && sleep 20 && adb wait-for-recovery push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/boot.img sdcard/boot.img && adb wait-for-device shell reboot -p"
	alias mk="mka kernel -j$(expr $(nproc --all) \* 10) && rbir"
	alias mri="mka recoveryimage -j$(expr $(nproc --all) \* 10) && rbir && adb wait-for-recovery push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/boot.img sdcard"
	alias mop="mka otapackage -j$(expr $(nproc --all) \* 10) && rbir"
	alias mop2="repo sync -c -d --force-sync && mka systemimage -j$(expr $(nproc --all) \* 10) && mka otapackage -j$(expr $(nproc --all) \* 10) && rbir"
	#Logcat Command
	alias tlc="adb wait-for-device logcat"
	alias tlcf=". build/envsetup.sh && show_alias && adb reboot && adb wait-for-device logcat|tee >> $home_dir/logcat-$(date +"%m-%d-%Y\ %T").log"
	alias tlcfe=". build/envsetup.sh && show_alias && adb reboot && adb wait-for-device logcat *:E|tee >> $home_dir/logcat-e-$(date +"%m-%d-%Y\ %T").log"
	#Kmesg Command
	alias rkm="adb wait-for-device shell cat /proc/kmsg"
	alias rkmf=". build/envsetup.sh && show_alias && adb wait-for-device shell cat /proc/kmsg | tee >> $home_dir/kmesg-$(date +"%m-%d-%Y\ %T").log"
	alias rfkmf=". build/envsetup.sh && show_alias && adb reboot && adb wait-for-device shell cat /proc/kmsg |tee >> $home_dir/kmesg-$(date +"%m-%d-%Y\ %T").log"
	#Dmesg Command
	alias rdm="adb wait-for-device shell dmesg"
	alias rdmf=". build/envsetup.sh && show_alias && adb wait-for-device shell dmesg | tee >> $home_dir/dmsg-$(date +"%m-%d-%Y\ %T").log"
	alias rfdmf=". build/envsetup.sh && show_alias && adb reboot && adb wait-for-device shell dmesg | tee >> $home_dir/dmsg-$(date +"%m-%d-%Y\ %T").log"
	#Radio Log Command
	alias trlc="adb wait-for-device logcat -b radio|tee >> $home_dir/r1-$(date +"%m-%d-%Y\ %T").log"
	#WiFi Command
	alias dw="adb shell 'su -c \"svc wifi disable\"' && echo 'WiFi Disable'"
	alias ew="adb shell 'su -c \"svc wifi enable\"' && echo 'WiFi Enable'"
	#Other Command
	alias msuiapk="mka SystemUI -j$(expr $(nproc --all) \* 10) && adb remount && adb push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/priv-app/SystemUI/SystemUI.apk system/priv-app/SystemUI/ && adb reboot"
	alias mssapk="mka Settings -j$(expr $(nproc --all) \* 10) && adb remount && adb push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/priv-app/Settings/Settings.apk system/priv-app/Settings/ && adb reboot"
	alias ml3apk="mka Pixelated -j$(expr $(nproc --all) \* 10) && adb remount && adb shell input keyevent KEYCODE_POWER && adb install -r out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/app/Pixelated/Pixelated.apk"
	alias tss=". build/envsetup.sh && show_alias && adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png $home_dir/&& mv $home_dir/screen.png $home_dir/screen-$(date +"%m-%d-%Y\ %T").png &&  adb shell rm -f /sdcard/.screen.png"
	alias fsep="adb pull /sys/fs/selinux/policy $home_dir && adb logcat -b all -d | audit2allow -p $home_dir/policy"
	alias sabao="croot && for otaupdate in out/dist/*-target_files-*.zip; do ./build/tools/releasetools/sign_target_files_apks -o -d ~/.android-certs $otaupdate $(echo "signed-$(echo "$otaupdate" | sed -e 's/out\/dist\///')"); done && for signedotaupdate in $(ls *-target_files-*.zip); do ./build/tools/releasetools/ota_from_target_files -k ~/.android-certs/releasekey --block --backup=true $signedotaupdate $(sed 's/signed-//' <<< "$signedotaupdate"); done;"
	#Lightning Fast Roms Flags
	alias wga="export WITH_GAPPS=true"
	alias wnga="export WITH_GAPPS=false"
	alias fdj="export DEVICE_SUPPORT_DJ=true"
	alias nfdj="export DEVICE_SUPPORT_DJ=false"
	alias rbir="adb wait-for-device reboot recovery"
}

function show_alias()
{
	#Update Tools
	echo -e "\nUpdate Tools"
	echo -e "${CL_LBL}\nudt${CL_RST}\trepo sync -c -d --force-sync BAProductions/vendor_extra && . build/envsetup.sh && show_alias"
	#Repo Sync Command
	echo -e "\nRepo Sync Commend"
	echo -e "${CL_LBL}\nrs${CL_RST}\trepo sync -c -d --force-sync && . build/envsetup.sh && show_alias"
	echo -e "${CL_LBL}\narb${CL_RST}\tcd vendor/cm/ && git am --abort && cd ../.. && . build/envsetup.sh && show_alias"
	#Nexus 7 More Control Panel
	echo -e "\nNexus 7 Forever More Control Panel"
	echo -e "${CL_LBL}\nlgrou${CL_RST}\tlunch aosp_grouper-user -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	echo -e "${CL_LBL}\nlgroud${CL_RST}\tlunchg aosp_grouper-userdebug -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	echo -e "${CL_LBL}\nlgroeng${CL_RST}\tlunch aosp_grouper-eng -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	echo -e "\nNexus 7 Forever More Control Panel Extra Command"
	echo -e "${CL_LBL}\nmgdv${CL_RST}\tmka clobber -j$(expr $(nproc --all) \* 10) && lunch aosp_grouper-userdebug -j$(expr $(nproc --all) \* 10)  &&  mka bacon -j$(expr $(nproc --all) \* 10) && rbir";
	#Samsung Galaxy Tab E 9.6 WiFi New Tablet
	echo -e "\nSamsung Galaxy Tab E 9.6 WiFi New Tablet"
	echo -e "${CL_LBL}\nlgteu${CL_RST}\tlunch lineage_gtelwifiue-user -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	echo -e "${CL_LBL}\nlgteud${CL_RST}\tlunch lineage_gtelwifiue-userdebug -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	echo -e "${CL_LBL}\nlgteeng${CL_RST}\tlunch lineage_gtelwifiue-eng -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	#Samsung Galaxy Tab 4 10.1 WiFi Old Tablet
	echo -e "\nSamsung Galaxy Tab 4 10.1 WiFi Old Tablet"
	echo -e "${CL_LBL}\nlmu${CL_RST}\tlunch lineage_matissewifi-user -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	echo -e "${CL_LBL}\nlmud${CL_RST}\tlunch lineage_matissewifi-userdebug -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	echo -e "${CL_LBL}\nlmeng${CL_RST}\tlunch lineage_matissewifi-eng -j$(expr $(nproc --all) \* 10) && . build/envsetup.sh && show_alias"
	echo -e "${CL_LBL}\nmofmbeng${CL_RST}\tmka clobber -j$(expr $(nproc --all) \* 10) && breakfast lineage_matissewifi-eng -j$(expr $(nproc --all) \* 10) && mka target-files-package dist otatools"
	echo -e "${CL_LBL}\nmofmbud${CL_RST}\tmka clobber -j$(expr $(nproc --all) \* 10) && breakfast lineage_matissewifi-userdebug -j$(expr $(nproc --all) \* 10) && mka target-files-package dist otatools"
	#Samsung Galaxy Tab 4 10.1 WiFi Old Tablet Extre
	echo -e "${CL_LBL}\nmmwdvus${CL_RST}\tnfdj && wnga && mka clobber -j$(expr $(nproc --all) \* 10) && brunch lineage_matissewifi-eng WITH_DEXPREOPT=true WITH_GAPPS=false -j$(expr $(nproc --all) \* 10) && rbir";
	echo -e "${CL_LBL}\nmmwdvs${CL_RST}\tnfdj && wga && mka clobber -j$(expr $(nproc --all) \* 10) && brunch lineage_matissewifi-eng WITH_DEXPREOPT=true WITH_GAPPS=true -j$(expr $(nproc --all) \* 10) && rbir";
	echo -e "${CL_LBL}\nmmwdvsp${CL_RST}\tfdj && wga && mka clobber -j$(expr $(nproc --all) \* 10) && brunch lineage_matissewifi-eng WITH_DEXPREOPT=true WITH_GAPPS=true -j$(expr $(nproc --all) \* 10) && rbir";
	echo -e "${CL_LBL}\nmmwdvb${CL_RST}\twnga && mka clobber -j$(expr $(nproc --all) \* 10) && brunch lineage_matisselte-eng WITH_DEXPREOPT=true WITH_GAPPS=false -j$(expr $(nproc --all) \* 10) && wga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=true WITH_GAPPS=true -j$(expr $(nproc --all) \* 10) && rbir"
	echo -e "${CL_LBL}\nmcl${CL_RST}\tmka camera.msm8226 -j$(expr $(nproc --all) \* 10) && adb remount && adb push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/lib/hw/camera.msm8226.so system/lib/hw/ && adb shell chmod 0644 system/lib/hw/camera.msm8226.so && adb reboot && adb wait-for-device logcat | grep --color=auto -E 'camera|preview|sr|selinux|not found|sepolicy|avc|policy|rev'";
	#Camera Wrapper For MSM8226 Devices
	echo -e "${CL_LBL}\nmcs${CL_RST}\tmka libmmcamera_sr130pc20_shim -j$(expr $(nproc --all) \* 10) && adb remount && adb push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/lib/libmmcamera_sr130pc20_shim.so system/lib/ && adb shell chmod 0644 system/lib/libmmcamera_sr130pc20_shim.so && adb reboot && adb wait-for-device logcat | grep --color=auto -E 'camera|preview|sr|selinux|not found|sepolicy|avc|policy|rev'";
	#Build Commands
	echo -e "\nBuild Commands Samsung Galaxy Tab4 10.1 & Samsung Galaxy Tab4 8.0"
	#Build Command Userdubug
	#Build Command Userdubug Sweetend
	echo -e "${CL_LBL}\nmat4uds${CL_RST}\texport WITH_DEXPREOPT=false && nfdj && wga && mka clobber -j40 && nfdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisselte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisse3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_milletwifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true-j40 && nfdj && wga && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_millet3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && fdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";
	echo -e "${CL_LBL}\nmat4wmduds${CL_RST}\texport WITH_DEXPREOPT=false && nfdj && wga && mka clobber -j40 && nfdj && wga && nfdj && wga && brunch lineage_matisselte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisse3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && nfdj && wga && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_millet3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && fdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 &&  fdj && wga && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";

	#Build Command Userdubug Unsweetend
	echo -e "${CL_LBL}\nmat4udus${CL_RST}\texport WITH_DEXPREOPT=false && nfdj && wnga && mka clobber -j40 && nfdj && wnga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_matisselte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_matisse3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_milletwifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false-j40 && nfdj && wnga && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_millet3g-userdebug WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && fdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";
	#Build Command Eng
	#Build Command Eng Sweetend
	echo -e "${CL_LBL}\nmat4engs${CL_RST}\tnfdj && wga && mka clobber -j40 && nfdj && wga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisselte-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_matisse3g-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_milletwifi-eng WITH_DEXPREOPT=false WITH_GAPPS=true-j40 && nfdj && wga && brunch lineage_milletlte-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && nfdj && wga && brunch lineage_millet3g-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && fdj && wga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";
	#Build Command Eng Unsweetend
	echo -e "${CL_LBL}\nmat4engus${CL_RST}\ nfdj && wnga && mka clobber -j40 && nfdj && wnga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_matisselte-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_matisse3g-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_milletwifi-eng WITH_DEXPREOPT=false WITH_GAPPS=false-j40 && nfdj && wnga && brunch lineage_milletlte-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && nfdj && wnga && brunch lineage_millet3g-eng WITH_DEXPREOPT=false WITH_GAPPS=false -j40 && fdj && wga && brunch lineage_matissewifi-eng WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";
	echo -e "${CL_LBL}\nmampd${CL_RST}\ export WITH_DEXPREOPT=false && mka clobber -j40 && fdj && wga && brunch lineage_matissewifi-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && brunch lineage_milletlte-userdebug WITH_DEXPREOPT=false WITH_GAPPS=true -j40 && rbir";

	#Build Commands
	echo -e "\nBuild Commands"
	echo -e "${CL_LBL}\nmb${CL_RST}\tmka bacon -j$(expr $(nproc --all) \* 10) && rbir"
	echo -e "${CL_LBL}\nmsi${CL_RST}\tmka systemimage -j$(expr $(nproc --all) \* 10) && mop && rbir"
	echo -e "${CL_LBL}\nmbi${CL_RST}\tmka bootimage -j$(expr $(nproc --all) \* 10) && rbir && adb wait-for-recovery shell rm -f sdcard/boot.img && sleep 20 && adb wait-for-recovery push out/target/product/boot.img sdcard"
	echo -e "${CL_LBL}\nmbic${CL_RST}\tmka bootimage -j$(expr $(nproc --all) \* 10) && rbir && sleep 20 && adb wait-for-recovery push out/target/product//boot.img sdcard && adb wait-for-device shell reboot -p"
	echo -e "${CL_LBL}\nmk${CL_RST}\tmka kernel -j$(expr $(nproc --all) \* 10) && rbir"
	echo -e "${CL_LBL}\nmri${CL_RST}\tmka recoveryimage -j$(expr $(nproc --all) \* 10) && rbir && adb wait-for-recovery push out/target/product//recovery.img sdcard"
	echo -e "${CL_LBL}\nmop${CL_RST}\tmka otapackage -j$(expr $(nproc --all) \* 10) && mop && rbir"
	#Logcat Commands
	echo -e "\nLogcat Commands"
	echo -e "${CL_LBL}\ntlc${CL_RST}\tadb wait-for-device logcat"
	echo -e "${CL_LBL}\ntlcf${CL_RST}\t. build/envsetup.sh && show_alias && adb reboot && adb wait-for-device logcat | tee >> $home_dir/logcat-$(date +"%m-%d-%Y\ %T").log"
	echo -e "${CL_LBL}\ntlcfe${CL_RST}\t. build/envsetup.sh && show_alias && adb reboot && adb wait-for-device logcat *:E | tee >> $home_dir/logcat-e-$(date +"%m-%d-%Y\ %T").log"
	#Kmesg Commands
	echo -e "\nKmsg Commands"
	echo -e "${CL_LBL}\nrkm${CL_RST}\tadb wait-for-device shell cat /proc/kmsg"
	echo -e "${CL_LBL}\nrkmf${CL_RST}\t. build/envsetup.sh && show_alias && adb wait-for-device shell cat /proc/kmsg | tee >> $home_dir/kmesg-$(date +"%m-%d-%Y\ %T").log"
	echo -e "${CL_LBL}\nrfkmf${CL_RST}\t. build/envsetup.sh && show_alias && adb reboot && adb wait-for-device shell cat /proc/kmsg |tee >> $home_dir/kmesg-$(date +"%m-%d-%Y\ %T").log"
	#Dmesg Command
   	echo -e "\nDmesg Commands"
   	echo -e "${CL_LBL}\nrdm${CL_RST}\tadb wait-for-device shell dmesg"
	echo -e "${CL_LBL}\nrdmf${CL_RST}\t. build/envsetup.sh && show_alias && adb wait-for-device shell dmesg | tee >> $home_dir/dmesg-$(date +"%m-%d-%Y\ %T").log"
	echo -e "${CL_LBL}\nrfdmf${CL_RST}\t. build/envsetup.sh && show_alias && adb reboot && adb wait-for-device shell dmesg | tee >> $home_dir/dmesg-$(date +"%m-%d-%Y\ %T").log"
	echo -e "\nRadio Log  Commands"
	#Radio Log Command
	echo -e "${CL_LBL}\ntrlc${CL_RST}\tadb wait-for-device logcat -b radio|tee >> $home_dir/r1-$(date +"%m-%d-%Y\ %T").log"
	#WiFi Commands
	echo -e "\nWiFi Commands"
	echo -e "${CL_LBL}\ndw${CL_RST}\tadb shell 'su -c "\"svc wifi disable"\"' && echo 'WiFi Disabled'"
	echo -e "${CL_LBL}\new${CL_RST}\tadb shell 'su -c "\"svc wifi enable"\"' && echo 'WiFi Enabled'"
	#Other Commands
	echo -e "\nOther Commands"
	echo -e "${CL_LBL}\nmsuiapk${CL_RST}\tmka SystemUI -j$(expr $(nproc --all) \* 10) && adb remount && adb push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/priv-app/SystemUI/SystemUI.apk system/priv-app/SystemUI/ && adb reboot"
	echo -e "${CL_LBL}\nmssapk${CL_RST}\tmka Settings -j$(expr $(nproc --all) \* 10) && adb remount && adb push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/priv-app/Settings/Settings.apk system/priv-app/Settings/ && adb reboot"
	echo -e "${CL_LBL}\nml3apk${CL_RST}\tmka Pixelated -j$(expr $(nproc --all) \* 10) && adb remount && adb shell input keyevent KEYCODE_POWER &&  adb install -r out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/system/app/Pixelated/Pixelated.apk"
	echo -e "${CL_LBL}\ntss${CL_RST}\t. build/envsetup.sh && show_alias && adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png && mv screen.png ~/$rom_dir/screen-$(date +"%m-%d-%Y\ %T").png &&  adb shell rm -f /sdcard/.screen.png"
	echo -e "${CL_LBL}\nfsep${CL_RST}\tadb pull /sys/fs/selinux/policy $home_dir && adb logcat -b all -d | audit2allow -p $home_dir/policy"
	echo -e "${CL_LBL}\nsabao${CL_RST}\tcroot && for otaupdate in out/dist/*-target_files-*.zip; do ./build/tools/releasetools/sign_target_files_apks -o -d ~/.android-certs $otaupdate $(echo "signed-$(echo "$otaupdate" | sed -e 's/out\/dist\///')"); done && for signedotaupdate in $\e(((ls *-target_files-*.zip); do ./build/tools/releasetools/ota_from_target_files -k ~/.android-certs/releasekey --block --backup=true $signedotaupdate $(sed 's/signed-//' <<<"$signedotaupdate"); done;"
	#Lightning Fast Roms Flags
	echo -e "${CL_LBL}\nwga${CL_RST}\texport WITH_GAPPS=true"
	echo -e "${CL_LBL}\nwnga${CL_RST}\texport WITH_GAPPS=false"
	echo -e "${CL_LBL}\nfdj${CL_RST}\texport DEVICE_SUPPORT_DJ=true"
	echo -e "${CL_LBL}\nnfdj${CL_RST}\texport DEVICE_SUPPORT_DJ=false"
	echo -e "${CL_LBL}\nrbir${CL_RST}\tadb wait-for-device reboot recovery"
   	echo -e "${CL_LBL}\n${CL_RST}"
}
