此脚本运行在esxi上，通过cronb每天自动运行一次，判断ESXI的证书过期日，如果小于等于2天到期，则通过scp命令从其他服务器上自动获取新的证书（需要配合其他VPS的acme脚本；或者ESXI内跑一个Openwrt，使用acme.me插件）。

自行修改脚本中的 your_disk_name 、192.168.123.1、domain.com.crt。

使用脚本前，先期准备：

0. 上传本脚本到esxi下，比如/vmfs/volumes/your_disk_name/shell/esxisslupdate.sh

1. 通过公钥实现ESXI免密登录远端服务器，以便自动通过scp拉取证书文件。（esxi重启后，要把生成的公钥和私钥放到esxi的非系统目录下（如/vmfs/volumes/your_disk_name/bak/），并参考第4条，在local.sh中添加

mv /vmfs/volumes/your_disk_name/bak/id_rsa /.ssh/id_rsa

mv /vmfs/volumes/your_disk_name/bak/id_rsa.pub /.ssh/id_rsa.pub

chmod 600 /.ssh/id_rsa

esxi ssh中 执行 /usr/lib/vmware/openssh/bin/ssh-keygen -t rsa 生成公钥，并把/.ssh/id_rsa.pub的公钥内容添加到服务器的~/.ssh/authorized_keys中

2. 设置esxi的crontab，实现定时运行。请先参考 https://blog.csdn.net/weixin_45735058/article/details/102491062 文章
编辑esxi crontab: vi /var/spool/cron/crontabs/root

0 4 * * * /bin/sh /vmfs/volumes/your_disk_name/shell/esxisslupdate.sh

3. 重启crontab服务，使定时任务立即生效

/bin/kill $(cat /var/run/crond.pid)

/usr/lib/vmware/busybox/bin/busybox crond

4. 使crontab的更改在esxi重启后仍能保存。
vi /etc/rc.local.d/local.sh，,在exit 0之前增加

/bin/kill $(cat /var/run/crond.pid)

/bin/echo "0 4 * * * /bin/sh /vmfs/volumes/your_disk_name/shell/esxisslupdate.sh" >> /var/spool/cron/crontabs/root

/usr/lib/vmware/busybox/bin/busybox crond

5. 最后执行/sbin/auto-backup.sh 保存当前配置，以便重启后仍生效
