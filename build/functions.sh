function func_setenv()
{
if [ "${rom_type}" == "lineage" ]; then myrom="lineage based rom"; MY_BUILD="$LINEAGE_BUILD";
elif [ "${rom_type}" == "du" ]; then myrom="du based rom"; MY_BUILD="$DU_BUILD";
elif [ "${rom_type}" == "omni" ]; then myrom="omni based rom"; MY_BUILD="$CUSTOM_BUILD";
else echo -e "${CL_RED} * Error: rom_type not set [vendor/extra/config.sh]${CL_RST}\n"; fi
unset rom_type
if [ "${with_su}" == "1" ]; then myrom="$myrom+SU"; export WITH_SU="true"; else unset WITH_SU; fi
unset with_su
unset CCACHE_DIR
}

function patchcommontree()
{
for f in `test -d vendor && find -L vendor/extra/patch/*/ -maxdepth 1 -name 'apply.sh' 2> /dev/null`
do
echo -e "${CL_YLW}\nPatching $f${CL_RST}"
. $f
done
unset f
}

function patchdevicetree()
{
for f in `test -d device && find -L device/*/$MY_BUILD/patch -maxdepth 4 -name 'apply.sh' 2> /dev/null | sort` \
 `test -d vendor && find -L vendor/extra/patch/device/$MY_BUILD -maxdepth 1 -name 'apply.sh' 2> /dev/null | sort`
do
echo -e "${CL_YLW}\nPatching $f${CL_RST}"
. $f
done
unset f
}

function set_stuff_for_environment()
{
settitle
set_java_home
setpaths
set_sequence_number
patchcommontree
patchdevicetree

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
function func_make_debug_dir()
{
	# Make Folder With Current Date
	echo "Making Folder Debug"
	mkdir -p $home_dir"
}

function func_alias()
{
	alias cn="echo $(sed "s/lineage_//" <<< "${TARGET_PRODUCT}")"
	# Run Onces
	alias init="func_make_debug_dir
	# Update Tools
	alias udt="repo sync -c -d --force-sync -j10 BAProductions/vendor_extra && . build/envsetup.sh && show_alias"
	# Repo Sync Command
	alias rs="repo sync -c -d --force-sync -j10 && . build/envsetup.sh && show_alias"
	# Basic Build Command
	alias mb="mka bacon -j10 && rbir"
	alias msi="mka systemimage -j10 && mop "
	alias mbi="mka bootimage -j10 && rbir && adb wait-for-recovery shell rm -f sdcard/boot.img && sleep 20 && adb wait-for-recovery push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/boot.img sdcard/boot.img"
	alias mbic="mka bootimage -j10 && rbir && sleep 20 && adb wait-for-recovery push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/boot.img sdcard/boot.img && adb wait-for-device shell reboot -p"
	alias mk="mka kernel -j10 && rbir"
	alias mri="mka recoveryimage -j10 && rbir && adb wait-for-recovery push out/target/product/$(sed 's/lineage_//' <<< "${TARGET_PRODUCT}")/boot.img sdcard"
	alias mop="mka otapackage -j10 && rbir"
	# Logcat Command
	alias tlc="adb wait-for-device logcat"
	alias tlcf=". build/envsetup.sh && show_alias && adb reboot && adb wait-for-device logcat|tee >> $home_dir/logcat-$(date +"%m-%d-%Y\ %T").log"
	alias tlcfe=". build/envsetup.sh && show_alias && adb reboot && adb wait-for-device logcat *:E|tee >> $home_dir/logcat-e-$(date +"%m-%d-%Y\ %T").log"
	# Kmesg Command
	alias rkm="adb wait-for-device shell cat /proc/kmsg"
	alias rkmf=". build/envsetup.sh && show_alias && adb wait-for-device shell cat /proc/kmsg | tee >> $home_dir/kmesg-$(date +"%m-%d-%Y\ %T").log"
	alias rfkmf=". build/envsetup.sh && show_alias && adb reboot && adb wait-for-device shell cat /proc/kmsg |tee >> $home_dir/kmesg-$(date +"%m-%d-%Y\ %T").log"
	# Dmesg Command
	alias rdm="adb wait-for-device shell dmesg"
	alias rdmf=". build/envsetup.sh && show_alias && adb wait-for-device shell dmesg | tee >> $home_dir/dmsg-$(date +"%m-%d-%Y\ %T").log"
	alias rfdmf=". build/envsetup.sh && show_alias && adb reboot && adb wait-for-device shell dmesg | tee >> $home_dir/dmsg-$(date +"%m-%d-%Y\ %T").log"
	# Radio Log Command
	alias trlc="adb wait-for-device logcat -b radio|tee >> $home_dir/r1-$(date +"%m-%d-%Y\ %T").log"
	# WiFi Command
	alias dw="adb shell 'su -c \"svc wifi disable\"' && echo 'WiFi Disable'"
	alias ew="adb shell 'su -c \"svc wifi enable\"' && echo 'WiFi Enable'"
	# Other Command
	alias tss=". build/envsetup.sh && show_alias && adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png $home_dir/&& mv $home_dir/screen.png $home_dir/screen-$(date +"%m-%d-%Y\ %T").png &&  adb shell rm -f /sdcard/.screen.png"
	alias fsep="adb pull /sys/fs/selinux/policy $home_dir && adb logcat -b all -d | audit2allow -p $home_dir/policy"
	alias sabao="croot && for otaupdate in out/dist/*-target_files-*.zip; do ./build/tools/releasetools/sign_target_files_apks -o -d ~/.android-certs $otaupdate $(echo "signed-$(echo "$otaupdate" | sed -e 's/out\/dist\///')"); done && for signedotaupdate in $(ls *-target_files-*.zip); do ./build/tools/releasetools/ota_from_target_files -k ~/.android-certs/releasekey --block --backup=true $signedotaupdate $(sed 's/signed-//' <<< "$signedotaupdate"); done;"
	# ADB Flags
	alias rb="adb wait-for-device reboot"
	alias rbir="adb wait-for-device reboot recovery"
}

function show_alias()
{
	# Run Once
	echo -e "\nRun Once"
	echo -e "${CL_LBL}\ninit${CL_RST}\tfunc_make_debug_dir"
	# Update Tools
	echo -e "\nUpdate Tools"
	echo -e "${CL_LBL}\nudt${CL_RST}\trepo sync -c -d --force-sync BAProductions/vendor_extra && . build/envsetup.sh && show_alias"
	# Repo Sync Command
	echo -e "\nRepo Sync Commend"
	echo -e "${CL_LBL}\nrs${CL_RST}\trepo sync -f -d -j10 && . build/envsetup.sh && show_alias"
	# Build Commands
	echo -e "\nBuild Commands"
	echo -e "${CL_LBL}\nmb${CL_RST}\tmka bacon -j10 && rbir"
	echo -e "${CL_LBL}\nmsi${CL_RST}\tmka systemimage -j10 && mop && rbir"
	echo -e "${CL_LBL}\nmbi${CL_RST}\tmka bootimage -j10 && rbir && adb wait-for-recovery shell rm -f sdcard/boot.img && sleep 20 && adb wait-for-recovery push out/target/product/boot.img sdcard"
	echo -e "${CL_LBL}\nmbic${CL_RST}\tmka bootimage -j10 && rbir && sleep 20 && adb wait-for-recovery push out/target/product//boot.img sdcard && adb wait-for-device shell reboot -p"
	echo -e "${CL_LBL}\nmk${CL_RST}\tmka kernel -j10 && rbir"
	echo -e "${CL_LBL}\nmri${CL_RST}\tmka recoveryimage -j10 && rbir && adb wait-for-recovery push out/target/product//recovery.img sdcard"
	echo -e "${CL_LBL}\nmop${CL_RST}\tmka otapackage -j10 && mop && rbir"
	# Logcat Commands
	echo -e "\nLogcat Commands"
	echo -e "${CL_LBL}\ntlc${CL_RST}\tadb wait-for-device logcat"
	echo -e "${CL_LBL}\ntlcf${CL_RST}\t. build/envsetup.sh && show_alias && adb reboot && adb wait-for-device logcat | tee >> $home_dir/logcat-$(date +"%m-%d-%Y\ %T").log"
	echo -e "${CL_LBL}\ntlcfe${CL_RST}\t. build/envsetup.sh && show_alias && adb reboot && adb wait-for-device logcat *:E | tee >> $home_dir/logcat-e-$(date +"%m-%d-%Y\ %T").log"
	# Kmesg Commands
	echo -e "\nKmsg Commands"
	echo -e "${CL_LBL}\nrkm${CL_RST}\tadb wait-for-device shell cat /proc/kmsg"
	echo -e "${CL_LBL}\nrkmf${CL_RST}\t. build/envsetup.sh && show_alias && adb wait-for-device shell cat /proc/kmsg | tee >> $home_dir/kmesg-$(date +"%m-%d-%Y\ %T").log"
	echo -e "${CL_LBL}\nrfkmf${CL_RST}\t. build/envsetup.sh && show_alias && adb reboot && adb wait-for-device shell cat /proc/kmsg |tee >> $home_dir/kmesg-$(date +"%m-%d-%Y\ %T").log"
	# Dmesg Command
   	echo -e "\nDmesg Commands"
   	echo -e "${CL_LBL}\nrdm${CL_RST}\tadb wait-for-device shell dmesg"
	echo -e "${CL_LBL}\nrdmf${CL_RST}\t. build/envsetup.sh && show_alias && adb wait-for-device shell dmesg | tee >> $home_dir/dmesg-$(date +"%m-%d-%Y\ %T").log"
	echo -e "${CL_LBL}\nrfdmf${CL_RST}\t. build/envsetup.sh && show_alias && adb reboot && adb wait-for-device shell dmesg | tee >> $home_dir/dmesg-$(date +"%m-%d-%Y\ %T").log"
	echo -e "\nRadio Log  Commands"
	# Radio Log Command
	echo -e "${CL_LBL}\ntrlc${CL_RST}\tadb wait-for-device logcat -b radio|tee >> $home_dir/r1-$(date +"%m-%d-%Y\ %T").log"
	# WiFi Commands
	echo -e "\nWiFi Commands"
	echo -e "${CL_LBL}\ndw${CL_RST}\tadb shell 'su -c "\"svc wifi disable"\"' && echo 'WiFi Disabled'"
	echo -e "${CL_LBL}\new${CL_RST}\tadb shell 'su -c "\"svc wifi enable"\"' && echo 'WiFi Enabled'"
	# Other Commands
	echo -e "\nOther Commands"
	echo -e "${CL_LBL}\ntss${CL_RST}\t. build/envsetup.sh && show_alias && adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png && mv screen.png ~/$rom_dir/screen-$(date +"%m-%d-%Y\ %T").png &&  adb shell rm -f /sdcard/.screen.png"
	echo -e "${CL_LBL}\nfsep${CL_RST}\tadb pull /sys/fs/selinux/policy $home_dir && adb logcat -b all -d | audit2allow -p $home_dir/policy"
	echo -e "${CL_LBL}\nsabao${CL_RST}\tcroot && for otaupdate in out/dist/*-target_files-*.zip; do ./build/tools/releasetools/sign_target_files_apks -o -d ~/.android-certs $otaupdate $(echo "signed-$(echo "$otaupdate" | sed -e 's/out\/dist\///')"); done && for signedotaupdate in $\e(((ls *-target_files-*.zip); do ./build/tools/releasetools/ota_from_target_files -k ~/.android-certs/releasekey --block --backup=true $signedotaupdate $(sed 's/signed-//' <<<"$signedotaupdate"); done;"
	# ADB Flags
	echo -e "${CL_LBL}\nrbir${CL_RST}\tadb wait-for-device reboot recovery"
   	echo -e "${CL_LBL}\n${CL_RST}"
}
