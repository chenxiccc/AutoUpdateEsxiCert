#!/bin/sh
#判断ESXI的证书过期日，如果小于等于2天到期，则通过scp命令从其他服务器上获取新的证书（需要配合其他VPS的acme脚本；或者ESXI内跑一个Openwrt，使用acme.me插件）

#获取证书到期日，并处理成date格式
noAfterdays=$(openssl x509 -in /etc/vmware/ssl/rui.crt -noout -dates | grep 'notAfter=' | cut -d '=' -f 2 | cut -d ' ' -f 4,1,2 | awk '{print $3,$1,$2}' | sed 's/[ ]/-/g' | sed 's/Jan/01/g' | sed 's/Feb/02/g' | sed 's/Mar/03/g' | sed 's/Apr/04/g' | sed 's/May/05/g' | sed 's/Jun/06/g' | sed 's/Jul/07/g' | sed 's/Aug/08/g' | sed 's/Sep/09/g' | sed 's/Oct/10/g' | sed 's/Nov/11/g' | sed 's/Sep/12/g')

#计算证书到期日距离1970-01-01 00:00:00 UTC有多少秒
SecondBynoAfterdays=$(date +%s -d "$noAfterdays")
#当前系统时间距离证书到期日有多少秒（注意esxi的ntp服务器是否能够获取到正确的时间）
SecondByToday=$(date +%s)

#计算证书还有几天过期
remaindays=$(expr '(' "$SecondBynoAfterdays" - "$SecondByToday" ')' / 86400)

#如果过期时间小于2天，则复制远端文件到esxi，并重启控制台使证书生效
if [ "$remaindays" -le 2 ] ; then 
    scp root@192.168.123.1:/root/.acme.sh/domain.com/fullchain.cer /etc/vmware/ssl/rui.crt
    scp root@192.168.123.1:/root/.acme.sh/domain.com/domain.com.key /etc/vmware/ssl/rui.key
    /etc/init.d/hostd restart
    /etc/init.d/vpxa restart
fi

exit 0


#单行命令版，适合直接放在Crontab中
#if [ "$(expr '(' $(date +%s -d "$(openssl x509 -in /etc/vmware/ssl/rui.crt -noout -dates | grep 'notAfter=' | cut -d '=' -f 2 | cut -d ' ' -f 4,1,2 | awk '{print $3,$1,$2}' | sed 's/[ ]/-/g' | sed 's/Jan/01/g' | sed 's/Feb/02/g' | sed 's/Mar/03/g' | sed 's/Apr/04/g' | sed 's/May/05/g' | sed 's/Jun/06/g' | sed 's/Jul/07/g' | sed 's/Aug/08/g' | sed 's/Sep/09/g' | sed 's/Oct/10/g' | sed 's/Nov/11/g' | sed 's/Sep/12/g')") - $(date +%s) ')' / 86400 )" -le 100 ] ; then scp root@192.168.123.1:/root/.acme.sh/domain.com/fullchain.cer /etc/vmware/ssl/rui.crt | scp root@192.168.123.1:/root/.acme.sh/domain.com/domain.com.key /etc/vmware/ssl/rui.key | /etc/init.d/hostd restart | /etc/init.d/vpxa restart ; fi
