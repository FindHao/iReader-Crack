** 本工具箱已停止功能性更新，仅修复bug **

# iReader-Crack

iReader Plus、Light 与 Ocean 阅读器破解，支持最新系统（截至4月初）

Plus建议降级以使用蓝牙听书功能：[教程](https://www.einkfans.com/thread-60.htm)

目前支持Linux系统进行破解，推荐Ubuntu，支持Windows 10 Linux子系统。

Windows 自动方案即将上线，仅支持 Windows 10 RS3 及以上版本，详细信息请关注论坛。

## 使用方法

1. 终端:

```
git clone https://github.com/KazushiMe/iReader-Crack.git
./iReader-Crack/crack.sh
```

2. 按程序提示操作

3. 完成后可以……

安装程序、设置主屏幕

开启root后[安装Xposed框架](https://www.einkfans.com/thread-51.htm)

### 更新或恢复

1.	获取官方OTA（在系统更新下载，不要安装），解压得到update.zip

2.	对update.zip包进行修改，删除update.zip下的recovery文件夹及boot.img（防止更新封堵破解）

3.	打开META-INF>com>google>android>updater-script，修改文件：

```
删除 首行 (!less_than…… 的版本校验
删除 更新recovery 的命令
删除 更新boot.img 的命令
删除 build.prop校验 的命令
```

保存后在zip包内替换原文件

4.	按程序提示操作

[更新包资源](https://www.einkfans.com/thread-2.htm)

### 视频教程

[iReader阅读器开启adb教程](https://www.bilibili.com/video/av21532543/)  by 愿乘风归去

## 原理

iReader官方请的工程师，连Recovery的adb都忘关了……

清空数据进入Recovery➡加入adb（改build.prop）➡强制开启adb（否则会被阅读器主程序关闭）
