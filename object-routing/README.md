# object-routing

#### 项目介绍
ceph rgw object routing with openresty nginx

object-routing目录为当前项目使用的
object-routing-with-db目录包含db操作但是未启用

#### 安装教程
wiki链接地址：
http://wiki.op.ksyun.com/pages/viewpage.action?pageId=75374366

1\. 安装openresty
安装下列openresty rpm包
openresty-1.13.6.2-1.el7.centos.x86_64.rpm
openresty-openssl-1.1.0h-3.el7.centos.x86_64.rpm
openresty-pcre-8.42-1.el7.centos.x86_64.rpm
openresty-zlib-1.2.11-3.el7.centos.x86_64.rpm

安装路径默认为/usr/local/openresty
```
[root@cephnode1 openresty]# ls
bin conf COPYRIGHT luajit lualib nginx openssl pcre site zlib

# nginx启动和reload命令
/usr/local/openresty/nginx/sbin/nginx -c /usr/local/openresty/nginx/conf/nginx.conf
/usr/local/openresty/nginx/sbin/nginx -s reload
```

2\.添加配置文件
```
将附件中配置文件更新到openresty相关目录下：
# 1 copy /object-routing/conf下的内容到/usr/local/openresty/conf/
cp object-routing/conf /usr/local/openresty/
[root@cephnode1 conf]# pwd
/usr/local/openresty/conf
[root@cephnode1 conf]# ls
load-balancer-servers.conf  load-balancer-servers.conf.example  object-routing.conf  object-routing.conf.tmpl
 
# 2 copy /object-routing/nginx/nginx.conf和/object-routing/nginx/conf.d目录到/usr/local/openresty/nginx/conf/
cp -rf object-routing/nginx/nginx.conf /usr/local/openresty/nginx/conf/
cp -r object-routing/nginx/conf.d /usr/local/openresty/nginx/conf/
[root@cephnode1 conf]# pwd
/usr/local/openresty/nginx/conf
 
# copy /object-routing/nginx/lua目录到/usr/local/openresty/nginx/
cp -rf object-routing/nginx/lua /usr/local/openresty/nginx/
[root@cephnode1 nginx]# pwd
/usr/local/openresty/nginx
[root@cephnode1 nginx]# ls
client_body_temp  conf  fastcgi_temp  html  logs  lua  proxy_temp  sbin  scgi_temp  tapset  uwsgi_temp

rgw servers和object routing路径记录在lua/common/utils.lua文件中：
_M.or_dir = "/usr/local/openresty"
_M.config_dir = "/conf/object-routing.conf"
_M.servers_config_dir = "/conf/load-balancer-servers.conf"
```

3.更新配置文件
将load-balancer-servers.conf内的rgw server和port更新为集群配置的server
```
/conf/load-balancer-servers.conf
load-balancer-servers.conf内容如下例：
10.210.0.66:7480=1
10.210.0.66:7481=1
10.210.0.66:7482=1
10.210.0.66:7483=1
10.210.0.69:7480=1
10.210.0.69:7481=1
10.210.0.69:7482=1
10.210.0.69:7483=1
10.210.0.70:7480=1
10.210.0.70:7481=1
10.210.0.70:7482=1
10.210.0.70:7483=1
```