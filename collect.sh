#!/bin/sh

################################################################################
########### Проверки и составление описания хостов:  ###########################

# - Имя хоста:
uname -n
cat /proc/sys/kernel/hostname
cat /proc/sys/kernel/domainname

# Основной IP-адрес и метрика (тот, который висит на интерфейсе, смотрящем на default GW):
iface=$(ip route | awk '{ if ($1 =="default") print $5; }');ip -f inet addr show dev $iface |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}/[0-9]{1,3}"

# Шлюз по умолчанию:
ip route | awk '{ if ($1 =="default") print $3,"via",$5; }'

# Используемые хостом DNS-серверы для разрешения имен:
grep -v '^#' /etc/resolv.conf |grep nameserver | awk '{print $2}'

# Количество таблиц маршрутизации. Если больше 4-х, то это маршрутизатор, смотреть конфиг руками
grep -v '^#' /etc/iproute2/rt_tables | grep -v '^$' | wc -l

#Есть ли OpenVPN server\client Если значение больше 1 - смотреть конфиг руками
ps ax |grep openvpn |wc -l

#Есть ли Tinc VPN Если значение больше 1 - смотреть конфиг руками
ps ax |grep tinc |wc -l

################################################################################
########### Сбор информации в виде файлов  #####################################
#для отладки
rm -rf /tmp/collect

mkdir /tmp/collect
mkdir /tmp/collect/info
mkdir /tmp/collect/config

# Включен ли IPv4 форвардинг и тюнинг tcp:
sysctl -a |grep net.ipv[46]. > /tmp/collect/info/sysctl

# Бэкапим текущие настройки iptables
ip6tables-save > /tmp/collect/info/ip6tables.conf
iptables-save > /tmp/collect/info/iptables-save.conf

# Бэкапим текущие маршруты из таблицы main
ip route > /tmp/collect/info/route

# Какие сервисы слушают внешние соединения
netstat -46lnpn | sed '1,2d;/127.0.0.1/d;/ ::1:/d' | awk '{if ($1 == "tcp") {print $7,$1,$4} else {if ($1 == "tcp6") {print $7,$1,$4} else {print $6,$1,$4}}}' | sed 's/^[0-9]*\///'| cut -d" " -f1 |sort -u > /tmp/collect/info/listening_services.short

# Какие сервисы слушают (подробно)
netstat -46lnpn | sed '1,2d;/127.0.0.1/d;/ ::1:/d' | awk '{if ($1 == "tcp") {print $7,$1,$4} else {if ($1 == "tcp6") {print $7,$1,$4} else {print $6,$1,$4}}}' | sed 's/^[0-9]*\///'| sort > /tmp/collect/info/listening_services

################################################################################
########### Копируем конфигурационные файлы  ###################################

cd /tmp/collect/config

cp /etc/resolv.conf ./
cp /etc/hostname ./
cp /etc/hosts ./

# Конфигурационные файлы Ubuntu
cp /etc/network/interfaces ./
cp /etc/udev/rules.d/70-persistent-net.rules ./
# OpenVPN:
# директория /usr/share/doc/openvpn/examples/easy-rsa/2.0/
# или  /usr/share/doc/easy-rsa/
# может быть /etc/ssl/
# директория /etc/openvpn/

cp -r /etc/bind/ ./

# CentOS:
cp /etc/sysconfig/firewalld ./
cp /etc/sysconfig/ip6tables-config ./
cp /etc/sysconfig/iptables-config ./
cp /etc/sysconfig/network ./
cp -r /etc/sysconfig/network-scripts ./

#/usr/share/easy-rsa/2.0/

# Для CentOS 6
cp /etc/sysconfig/system-config-firewall ./
cp /etc/udev/rules.d/70-persistent-net.rules ./
cd

echo 'Done!'


