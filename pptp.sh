#!/bin/bash

type pptpd > /dev/null 2>&1
[ $? -ne 0 ] && apt-get install pptpd

grep '^localip 192.168.' /etc/pptpd.conf > /dev/null
if [ $? -ne 0 ]; then
  cat >> /etc/pptpd.conf <<PPTPDCONF
  localip 192.168.17.1
  remoteip 192.168.17.11-60
PPTPDCONF
fi

grep '^ms-dns 8.8.8.8' /etc/ppp/options > /dev/null
if [ $? -ne 0 ]; then 
  cat >> /etc/ppp/options <<PPPOPTIONS
  ms-dns 8.8.8.8
  ms-dns 8.8.4.4
PPPOPTIONS
fi

echo -n "设置您的VPN账号的用户名: "
read username
echo -n "Set your VPN account password: "
read password
cat >> /etc/ppp/chap-secrets <<SECRETS
$username pptpd $password *
SECRETS

sed -i 's/#\(net\.ipv4\.ip_forward=1\)/\1/g' /etc/sysctl.conf
/sbin/sysctl -p

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sed -i "s/exit 0/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\nexit 0/g" /etc/rc.local

/etc/init.d/pptpd restart

echo "PPTP VPN 安装完毕，请使用以下账户登录:"
echo "用户名: $username"
echo "密码: $password"
