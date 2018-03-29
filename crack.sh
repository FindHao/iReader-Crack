#!/bin/bash

version="r2"

function pause()
{
  if [ $1 ];then
    read -n 1 -p "$1"
  else
    read -n 1 -p "按任意键继续"
  fi
}

function header()
{
  echo ""
  echo "第 $1 阶段: $2"
}

function init_adb()
{
  adb kill-server >> log
  adb start-server >> log
}

function check_env()
{
  echo "正在检测环境……"
  issue=`cat /etc/issue`
  adb_exec=`which adb`
  if [[ ${issue:0:6} != "Ubuntu" ]]; then
    echo "当前使用的系统不是Ubuntu，可能不受支持"
    pause
  elif [[ ${adb_exec:0:1} != "/" ]]; then
    echo "未检测到adb程序"
    pause "按任意键执行安装"
    sudo apt-get update
    sudo apt-get install adb
    check_env
  fi
  
  echo ""
  
  WSL=$(echo `uname -a` | grep -o "Microsoft" | wc -l)
  if [[ $WSL != "" ]]; then
    echo "检测到使用 Windows 10 Linux 子系统"
    echo "请安装 Windows 的 adb 驱动，打开 adb 程序"
    echo "Windows中命令行操作如下:"
    echo "adb kill-server"
    echo "adb start-server"
    pause "完成后不要关闭Windows的adb，按任意键继续"
  else
    echo "初始化adb……"
    init_adb
  fi
}

function recovery()
{
  adb push crack/bin /system/bin/ >> log
  adb push crack/lib /system/lib/ >> log
  adb shell "/system/bin/mount -t ext4 /dev/block/mmcblk0p5 /system" >> log
  adb shell "echo 'persist.service.adb.enable=1' >> /system/build.prop" >> log
  adb shell "echo 'persist.service.debuggable=1' >> /system/build.prop" >> log
  adb shell "echo 'persist.sys.usb.config=mtp,adb' >> /system/build.prop" >> log
  adb shell "echo 'ro.secure=0' >> /system/build.prop" >> log
  adb shell "echo 'ro.adb.secure=0' >> /system/build.prop" >> log
  adb shell "echo 'ro.debuggable=1' >> /system/build.prop" >> log
}

function enable_adb()
{
  echo ""
  echo "正在尝试开启adb……"
  echo "预计需要1分钟"
  start=`date +%s`
  while true
  do
    adb shell "echo 'mtp,adb' > /data/property/persist.sys.usb.config" >> log
    adb shell "echo '1' > /data/property/persist.service.adb.enable" >> log
    if [[ `expr $(date +%s) - "$start"` > "60" ]]; then
      break
    fi
  done
  #主程序会关闭adb，不得不循环破解
}

function main()
{
  mv log log.last
  clear
  
  echo "       iReader Light/Ocean 阅读器 破解"
  echo "             for Linux(Ubuntu)"
  echo "                     $version"
  header "1" "使用前须知"
  
  echo "注意事项:"
  echo "1. 请确保安装好相关组件，包括adb及adb驱动"
  echo "2. 请严格按照程序提示操作，否则有可能变砖"
  echo "3. 本程序仅在Ubuntu测试通过，其他系统未测试"
  echo "4. 操作前备份好用户数据(电纸书)"
  echo "5. 破解前移除其他所有Android设备"
  echo "6. 如破解过程中已进入阅读器主界面但程序未响应，请强制关闭后再次尝试或进行反馈"
  echo ""
  sleep 3
  pause
  
  header "2" "环境检测"
  check_env
  sleep 1
  
  header "3" "进入Recovery"
  echo "请按如下步骤操作："
  echo "1. 将iReader用数据线连接至电脑"
  echo "2. 阅读器上 选择 设置-->关于本机-->恢复出厂设置"
  echo "3. 等待出现机器人标识，程序识别"
  echo ""
  
  echo "正在检测是否进入Recovery……"
  while true
  do
    sleep 0.1
    check_rec=$(echo `adb devices` | grep "recovery")
    if [[ "$check_rec" != "" ]]; then
      break
    fi
  done
  
  echo ""
  echo "正在复制破解文件……"
  recovery
  
  echo "完成，等待重启……"
  
  while true
  do
    sleep 0.1
    check_rec=$(echo `adb devices` | grep "recovery")
    if [[ "$check_rec" == "" ]]; then
      break
    fi
  done
  
  header "4" "启动破解"
  echo "正在检测破解前准备是否生效……"
  while true
  do
    sleep 0.1
    check_unauth=$(echo `adb devices` | grep "unauthorized")
    check_dev=$(echo `adb devices` | grep -o "device" | wc -l)
    if [[ "$check_unauth" != "" ]]; then
      echo "出现错误，10秒后请重新尝试"
      echo "Error: unauthorized device"
      sleep 10
      main
    elif [[ "$check_dev" == "2" ]]; then
      break
    fi
  done
  
  enable_adb
  
  check_dev=$(echo `adb devices` | grep -o "device" | wc -l)
  if [[ "$check_dev" == "2" ]]; then
    echo "破解成功，现可以通过adb安装程序"
  else
    echo "破解失败，请尝试重新破解或进行反馈"
  fi
  pause "按任意键退出"
}

main
