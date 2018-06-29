# set-user-rgw-pools

#### 项目介绍
set user rgw pools

#### 使用说明
```
python set_user_rgw_pool.py gyc 128
参数1为rgw pool前缀，如下面命令生成的rgw pools为
.rgw.root
gyc.rgw.control
gyc.rgw.gc
gyc.rgw.log
gyc.rgw.intent-log
gyc.rgw.usage
gyc.rgw.users.keys
gyc.rgw.users.email
gyc.rgw.buckets.data1
gyc.rgw.buckets.index1
gyc.rgw.users.swift
gyc.rgw.users.uid
gyc.rgw.data.root

参数2为pg num

user_rgw_realm.txt为生成用户自定义placement target的命令集，set_user_rgw_pool.py读取所有命令并依次执行，可以根据index和data pool是否分离修改命令
相关wiki链接：
http://wiki.op.ksyun.com/pages/viewpage.action?pageId=75370241
```