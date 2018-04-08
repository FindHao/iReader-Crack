#!/bin/bash

version="r15"

home=$(cd `dirname $0`; pwd)
chmod -R 777 $home
mv $home/log $home/log.last

if [[ $1 == "-debug" ]]; then
  logging=1
fi

function pause()
{
  if [ $1 ]; then
    read -n 1 -p "$1"
  else
    read -n 1 -p "按任意键继续"
  fi
}

function log()
{
  if [ $logging ]; then
    time=`date "+%Y-%m-%d %H:%M:%S"`
    #8进制识别fix: 10#string
    time_ns=$((10#`date "+%N"`))
    time_us=$((10#$time_ns / 1000))
    time_us_formatted=" "`printf "%06d\n" $time_us`"us"
    time_formatted=${time}${time_us_formatted}
    echo "$time_formatted  $*"
  fi
  echo "$time_formatted    $*" >> $home/log
}

function stage()
{
  echo ""
  echo "第 $1 阶段: $2"
  log "========== Stage $1 =========="
}

function init_adb()
{
  WSL=$(echo `uname -a` | grep -o "Microsoft" | wc -l)
  if [ $WSL -ge "1" ]; then
    log "IS WSL Subsystem"
    echo "检测到使用 Windows 10 Linux 子系统"
    echo "请安装 Windows 的 adb 驱动，打开对应版本的 adb 程序"
    echo "所需adb版本: " `adb version | head -1`
    echo "Windows中命令行操作如下:"
    echo "adb kill-server"
    echo "adb start-server"
    pause "完成后不要关闭Windows的adb，按任意键继续"
  else
    echo "初始化adb……"
    log "Initializing adb"
    adb kill-server
  fi
  adb start-server
  sleep 1
}

function check_env()
{
  echo "正在检测环境……"
  issue=`cat /etc/issue`
  adb_exec=`which adb`
  if [[ ${issue:0:6} != "Ubuntu" ]]; then
    echo "当前使用的系统不是Ubuntu，可能不受支持"
    log "Not Ubuntu"
    pause
  fi
  if [[ ${adb_exec:0:1} != "/" ]]; then
    echo "未检测到adb程序"
    log "adb Not Found"
    if [[ ${issue:0:6} == "Ubuntu" ]]; then
      pause "按任意键执行安装，可能需要输入密码"
      log "adb Installing"
      sudo apt-get update
      sudo apt-get install adb
      check_env
    else
      echo "请安装adb后再执行本程序"
      pause "按任意键退出"
      log "Need adb, exit"
      exit
    fi
  fi
  
  echo ""
}

function adb_state()
{
  # unknown:0 device:1 recovery:2
  state=`adb get-state`
  if [[ $state == "device" ]]; then
    return 1
  elif [[ $state == "recovery" ]]; then
    return 2
  else
    return 0
  fi
}

function recovery()
{
  log "Copying Recovery Shell Files"
  adb push $home/crack/bin /system/bin/
  adb push $home/crack/lib /system/lib/
  adb shell "/system/bin/mount -t ext4 /dev/block/mmcblk0p5 /system"
  adb shell "echo 'persist.service.adb.enable=1' >> /system/build.prop"
  adb shell "echo 'persist.service.debuggable=1' >> /system/build.prop"
  adb shell "echo 'persist.sys.usb.config=mtp,adb' >> /system/build.prop"
  adb shell "echo 'ro.secure=0' >> /system/build.prop"
  adb shell "echo 'ro.adb.secure=0' >> /system/build.prop"
  adb shell "echo 'ro.debuggable=1' >> /system/build.prop"
}

function enable_adb()
{
  log "Enabling Adb During Booting"
  start=`date +%s`
  while true
  do
    adb shell "echo 'mtp,adb' > /data/property/persist.sys.usb.config"
    adb shell "echo '1' > /data/property/persist.service.adb.enable"
    dif=`expr $(date +%s) - "$start"`
    if [ "$dif" -gt "60" ]; then
      break
    fi
  done
  #主程序会关闭adb，不得不循环破解
}

function enable_adb_2()
{
  log "Enabling Adb During Booting - Alternative Approach"
  while true
  do
    adb shell "echo 'mtp,adb' > /data/property/persist.sys.usb.config" > /dev/null
    adb shell "echo '1' > /data/property/persist.service.adb.enable" > /dev/null
    adb_state
    if [[ $1 == 0 ]]; then
      break
    fi
  done
  #主程序会关闭adb，不得不循环破解
}

function update()
{
  echo ""
  echo "正在检测更新……"
  cd $home
  git pull
  sleep 3
  return
}

function main()
{
  clear
  key=
  echo "           iReader Crack 工具箱"
  echo "                    $version"
  [[ $logging == 1 ]] && echo "               debug 已开启"
  adb_state
  if [[ $? == 1 ]]; then
    echo "              USB调试已连接"
  elif [[ $? == 2 ]]; then
    echo "           已进入Recovery模式"
  fi
  echo ""
  echo "            1. 运行破解主程序"
  [[ $logging != 1 ]] && echo "            2. 开启 debug 模式"
  echo "            3. 更新工具箱"
  echo ""
  echo "            测试功能："
  echo "            4. 运行破解主程序（自动版）"
  echo "            5. 安装更新包（需修改）"
  echo "            6. 批量安装程序"
  echo ""
  echo "   A. 打开设置  B. 模拟返回键  C. 模拟主页键"
  echo ""
  echo "            0. 退出"
  echo ""

  read -n 1 -p "请键入选项: " key
}

function crack()
{
  clear
  
  log "Version: "$version
  echo "       iReader Light/Ocean 阅读器 破解"
  stage "1" "使用前须知"
  
  echo "注意事项:"
  echo "1. 请确保安装好相关组件，包括adb及adb驱动"
  echo "2. 请严格按照程序提示操作，否则有可能变砖"
  echo "3. 操作前备份好用户数据(电纸书)"
  echo ""
  sleep 1
  pause
  log "Agreed"
  
  stage "2" "环境检测与准备"
  adb_state
  if [[ $? != 0 ]]; then
    echo ""
    echo "已连接开启USB调试的Android设备，请移除后重试"
    log "Already connected adb device"
    log `adb devices`
    pause
    crack
  fi
  sleep 1
  
  stage "3" "进入Recovery"
  echo "请按如下步骤操作："
  echo "1. 将iReader用数据线连接至电脑"
  echo "2. 阅读器上 选择 设置-->关于本机-->恢复出厂设置"
  echo "3. 等待出现机器人标识"
  echo ""
  pause "出现机器人标识时按任意键继续"
  
  echo ""
  echo "正在复制破解文件……"
  recovery
  
  echo "等待重启……"
  log "Waiting for Reboot"
  
  stage "4" "执行破解"
  echo "预计需要1分钟"
  echo ""
  pause "显示进度条时按任意键继续"
  
  enable_adb
  
  echo ""
  echo "请手动重启阅读器"
  log "Waiting for Reboot Manually"
  pause "重启进阅读器界面后按任意键继续"
  
  echo ""
  adb_state
  if [[ $? == 1 ]]; then
    echo "破解成功，现可以通过adb安装程序"
    log "Done"
  else
    echo "破解失败，请尝试重新破解或进行反馈"
    log "Failed"
    log `adb devices`
  fi
  pause "按任意键返回"
  return
}

function crack_auto()
{
  clear
  
  log "Version: "$version" Auto Approach"
  echo " iReader Light/Ocean 阅读器 破解 自动版（测试）"
  stage "1" "使用前须知"
  
  echo "注意事项:"
  echo "1. 请确保安装好相关组件，包括adb及adb驱动"
  echo "2. 请严格按照程序提示操作，否则有可能变砖"
  echo "3. 操作前备份好用户数据(电纸书)"
  echo ""
  sleep 3
  
  stage "2" "环境检测与准备"
  adb_state
  if [[ $? != 0 ]]; then
    echo ""
    echo "已连接开启USB调试的Android设备，请移除后重试"
    log "Already connected adb device"
    log `adb devices`
    pause
    crack_auto
  fi
  sleep 1
  
  stage "3" "进入Recovery"
  echo "请按如下步骤操作："
  echo "1. 将iReader用数据线连接至电脑"
  echo "2. 阅读器上 选择 设置-->关于本机-->恢复出厂设置"
  echo "3. 等待出现机器人标识"
  echo ""
  echo "正在检测是否进入Recovery……"
  log "Checking Recovery"
  while true
  do
    sleep 0.1
    adb_state
    if [[ $? == 2 ]]; then
      break;
    fi
  done
  
  echo ""
  echo "正在复制破解文件……"
  recovery
  
  echo "等待重启……"
  log "Waiting for Reboot"
  
  stage "4" "执行破解"
  echo "等待出现进度条……"
  sleep 5
  while true
  do
    sleep 0.1
    adb_state
    if [[ $? == 1 ]]; then
      break;
    fi
  done
  
  enable_adb_2
  
  echo ""
  echo "请手动重启阅读器"
  log "Waiting for Reboot Manually"
  pause "重启进阅读器界面后按任意键继续"
  
  echo ""
  adb_state
  if [[ $? == 1 ]]; then
    echo "破解成功，现可以通过adb安装程序"
    log "Done"
  else
    echo "破解失败，请尝试重新破解或进行反馈"
    log "Failed"
    log `adb devices`
  fi
  pause "按任意键返回"
  return
}

function install_ota()
{
  echo ""
  stage "1" "准备阶段"
  adb_state
  if [[ $? == 0 ]]; then
    echo "未破解或未连接"
    pause "按任意键返回"
    return
  fi
  echo "请按照教程获取OTA更新包并进行修改"
  echo "将修改后的更新包放入 $home 文件夹内，重命名为update.zip"
  pause
  if [ ! -f "$home/update.zip" ]; then
    echo ""
    echo "更新包不存在"
    pause "按任意键重试"
    install_ota
  fi
  stage "2" "安装更新"
  if [[ $? == 1 ]]; then
    echo "正在进入Recovery环境"
    adb reboot recovery
    sleep 5
    while true
    do
      sleep 0.1
      adb_state
      if [[ $? == 2 ]]; then
        break;
      fi
    done
  fi
  recovery
  adb shell "/system/bin/mount -t ext4 /dev/block/mmcblk0p6 /cache"
  echo ""
  echo "正在复制OTA更新包"
  adb push $home/update.zip /cache/update.zip
  echo ""
  echo "正在安装更新"
  adb shell "/system/bin/recovery --update_package=/cache/update.zip"
  sleep 5
  adb_state
  if [[ $? != 2 ]]; then
    echo "更新成功"
  else
    echo "更新失败，请重新尝试"
  fi
  pause "按任意键返回"
  return
}

function install_apk()
{
  echo ""
  echo "请稍后……"
  adb_state
  if [[ $? != 1 ]]; then
    echo "未破解或未连接"
    pause "按任意键返回"
    return
  fi
  echo ""
  if [ ! -d "$home/apk" ]; then
    mkdir "$home/apk"
  fi
  echo "将需要安装的apk文件放入 $home/apk 中"
  echo "建议使用英文命名"
  pause
  echo ""
  echo "正在安装……"
  cd "$home/apk"
  adb install *.apk
  echo "安装完成"
  return
}

function shortcut()
{
  echo ""
  echo "请稍后……"
  adb_state
  if [[ $? != 1 ]]; then
    echo "未破解或未连接"
    pause "按任意键返回"
    return
  fi
  echo ""
  if [[ $1 == "setting" ]]; then
    adb shell am start com.android.settings/com.android.settings.Settings
  elif [[ $1 == "back" ]]; then
    adb shell input keyevent 4
  elif [[ $1 == "home" ]]; then
    adb shell input keyevent 3
  fi
  echo "完成"
  return
}

check_env
init_adb
while true
do
  main
  case $key in
    0)      clear; exit;;
    1)      crack;;
    2)      $home/crack.sh -debug; exit;;
    3)      update;;
    4)      crack_auto;;
    5)      install_ota;;
    6)      install_apk;;
    a|A)    shortcut "setting";;
    b|B)    shortcut "back";;
    c|C)    shortcut "home";;
    *)
    echo ""
    echo "输入错误，请重新尝试"
    sleep 1
    ;;
  esac
done