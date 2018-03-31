#!/bin/bash

mv log log.last
version="r8"
home=$(cd `dirname $0`; pwd)
logging=1

function pause()
{
  if [ $1 ];then
    read -n 1 -p "$1"
  else
    read -n 1 -p "按任意键继续"
  fi
}

function log()
{
  if [ $logging ]; then
    echo "$1" >> log
  fi
}

function stage()
{
  echo ""
  echo "第 $1 阶段: $2"
  log "Stage $1"
}

function init_adb()
{
  WSL=$(echo `uname -a` | grep -o "Microsoft" | wc -l)
  if [ $WSL -ge "1" ]; then
    log "WSL Subsystem"
    echo "检测到使用 Windows 10 Linux 子系统"
    echo "请安装 Windows 的 adb 驱动，打开 adb 程序"
    echo "Windows中命令行操作如下:"
    echo "adb kill-server"
    echo "adb start-server"
    pause "完成后不要关闭Windows的adb，按任意键继续"
    adb device
  else
    echo "初始化adb……"
    log "Initializing adb"
    adb kill-server
    adb start-server
  fi
}

function check_env()
{
  echo "正在检测环境……"
  issue=`cat /etc/issue`
  adb_exec=`which adb`
  if [[ ${issue:0:6} != "Ubuntu" ]];  then
    echo "当前使用的系统不是Ubuntu，可能不受支持"
    log "Not Ubuntu"
    pause
  elif [[ ${adb_exec:0:1} != "/" ]]; then
    echo "未检测到adb程序"
    log "adb Not Found"
    pause "按任意键执行安装，可能需要输入密码"
    log "adb Installing"
    sudo apt-get update
    sudo apt-get install adb
    check_env
  fi
  
  echo ""
}

function adb_state()
{
  # offline:0 device:1 recovery:2
  state=$(echo `adb get-state`)
  if [[ $state == "device" ]]: then
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

function main()
{
  clear
  
  echo "       iReader Light/Ocean 阅读器 破解"
  echo "             for Linux(Ubuntu)"
  echo "                     $version"
  stage "1" "使用前须知"
  
  echo "注意事项:"
  echo "1. 请确保安装好相关组件，包括adb及adb驱动"
  echo "2. 请严格按照程序提示操作，否则有可能变砖"
  echo "3. 本程序仅在Ubuntu测试通过，其他系统未测试"
  echo "4. 操作前备份好用户数据(电纸书)"
  echo "5. 破解前移除其他所有Android设备"
  echo ""
  sleep 1
  pause
  
  stage "2" "环境检测"
  check_env
  init_adb
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
  if [[ "$?" == "1" ]]; then
    echo "破解成功，现可以通过adb安装程序"
    log "Done"
  else
    echo "破解失败，请尝试重新破解或进行反馈"
    log "Failed"
  fi
  pause "按任意键退出"
}

main
