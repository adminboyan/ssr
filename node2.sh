#!/bin/bash
#个人使用的对接脚本
#check root
[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }
rm -rf node*
#常规变量设置
#fonts color
Green="\033[32m" 
Red="\033[31m" 
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
Info="${Green}[Info]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[Error]${Font}"
Notification="${Yellow}[Notification]${Font}"

#IP and config
#IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
config="/root/shadowsocks/userapiconfig.py"
get_ip(){
	ip=$(curl -s https://ipinfo.io/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ip.sb/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ipify.org)
	[[ -z $ip ]] && ip=$(curl -s https://ip.seeip.org)
	[[ -z $ip ]] && ip=$(curl -s https://ifconfig.co/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && ip=$(curl -s icanhazip.com)
	[[ -z $ip ]] && ip=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && echo -e "\n 这小鸡鸡还是割了吧！\n" && exit
}
check_system(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
	#res = $(cat /etc/redhat-release | awk '{print $4}')
	#if [[ ${release} == "centos" ]] && [[ ${bit} == "x86_64" ]] && [[ ${res} -ge 7 ]]; then
	if [[ ${release} == "centos" ]] && [[ ${bit} == "x86_64" ]]; then
	echo -e "你的系统为[${release} ${bit}],检测${Green} 可以 ${Font}搭建。"
	else 
	echo -e "你的系统为[${release} ${bit}],检测${Red} 可以 ${Font}搭建。"
	fi
}
node_install_start(){
	apt-get update -y
	apt-get install supervisor -y
	apt-get install git -y
	apt-get install build-essential -y
	#wget --no-check-certificate https://raw.githubusercontent.com/iboyan/ssr/main/libsodium-1.0.18.tar.gz
	wget --no-check-certificate https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz
	tar xf libsodium-1.0.18.tar.gz && cd libsodium-1.0.18
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	cd /root
	apt-get install python-pip -y
	git clone https://github.com/iboyan/ssr.git "/root/shadowsocks"
	cd shadowsocks
	pip install -r requirements.txt
	pip install cymysql
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}
api(){
    clear
	# 取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	echo -e "如果以下手动配置错误，请在${config}手动编辑修改"
	read -p "请输入你的对接域名或IP(例如:http://www.baidu.com 默认为本机对接): " WEBAPI_URL
	read -p "请输入muKey(在你的配置文件中 默认marisn):" WEBAPI_TOKEN
	read -p "请输入测速周期(回车默认为每6小时测速):" SPEEDTEST
	read -p "请输入你的节点编号(回车默认为节点ID 3):  " NODE_ID
	node_install_start
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	get_ip
	WEBAPI_URL=${WEBAPI_URL:-"http://${ip}"}
	sed -i '/WEBAPI_URL/c \WEBAPI_URL = '\'${WEBAPI_URL}\''' ${config}
	#sed -i "s#https://zhaoj.in#${WEBAPI_URL}#" /root/shadowsocks/userapiconfig.py
	WEBAPI_TOKEN=${WEBAPI_TOKEN:-"marisn"}
	sed -i '/WEBAPI_TOKEN/c \WEBAPI_TOKEN = '\'${WEBAPI_TOKEN}\''' ${config}
	#sed -i "s#glzjin#${WEBAPI_TOKEN}#" /root/shadowsocks/userapiconfig.py
	SPEEDTEST=${SPEEDTEST:-"6"}
	sed -i '/SPEED/c \SPEEDTEST = '${SPEEDTEST}'' ${config}
	NODE_ID=${NODE_ID:-"3"}
	sed -i '/NODE_ID/c \NODE_ID = '${NODE_ID}'' ${config}
}
db(){
    clear
	# 取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	echo -e "如果以下手动配置错误，请在${config}手动编辑修改"
	echo
	read -p "请输入你的对接数据库IP(例如:127.0.0.1): " MYSQL_HOST
	if [ -z "$MYSQL_HOST" ];then
	MYSQL_HOST=127.0.0.1
	fi
	echo -e "已设置数据库IP为:\033[32m "$MYSQL_HOST"\033[0m"
	
	echo
	read -p "请输入你的数据库名称(默认sspanel):" MYSQL_DB
	if [ -z "$MYSQL_DB" ];then
	MYSQL_DB=sspanel
	fi
	echo -e "已设置数据库名称为:\033[32m "$MYSQL_DB"\033[0m"
	
	echo
	read -p "请输入你的数据库端口(默认3306):" MYSQL_PORT
	if [ -z "$MYSQL_PORT" ];then
	MYSQL_PORT=3306
	fi
	echo -e "已设置数据库端口为:\033[32m "$MYSQL_PORT"\033[0m"
	
	echo
	read -p "请输入你的数据库用户名(默认root):" MYSQL_USER
	if [ -z "$MYSQL_USER" ];then
	MYSQL_USER=sspanel
	fi
	echo -e "已设置数据库用户名为:\033[32m "$MYSQL_USER"\033[0m"
	
	echo
	read -p "请输入你的数据库密码(默认root):" MYSQL_PASS
	if [ -z "$MYSQL_PASS" ];then
	MYSQL_PASS=root
	fi
	echo -e "已设置数据库密码为:\033[32m "$MYSQL_PASS"\033[0m"
	
	
	read -p "请输入你的节点编号(回车默认为节点ID 3):  " NODE_ID
	node_install_start
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	get_ip
	sed -i '/API_INTERFACE/c \API_INTERFACE = '\'glzjinmod\''' ${config}
	MYSQL_HOST=${MYSQL_HOST:-"${ip}"}
	sed -i '/MYSQL_HOST/c \MYSQL_HOST = '\'${MYSQL_HOST}\''' ${config}
	MYSQL_DB=${MYSQL_DB:-"sspanel"}
	sed -i '/MYSQL_DB/c \MYSQL_DB = '\'${MYSQL_DB}\''' ${config}
	MYSQL_USER=${MYSQL_USER:-"root"}
	sed -i '/MYSQL_USER/c \MYSQL_USER = '\'${MYSQL_USER}\''' ${config}
	MYSQL_PASS=${MYSQL_PASS:-"root"}
	sed -i '/MYSQL_PASS/c \MYSQL_PASS = '\'${MYSQL_PASS}\''' ${config}
	MYSQL_PORT=${MYSQL_PORT:-"3306"}
	sed -i '/MYSQL_PORT/c \MYSQL_PORT = '${MYSQL_PORT}'' ${config}
	NODE_ID=${NODE_ID:-"3"}
	sed -i '/NODE_ID/c \NODE_ID = '${NODE_ID}'' ${config}
}
clear
check_system
echo -e "\033[1;5;31m请选择对接模式：\033[0m"
echo -e "1.API对接模式(不支持)"
echo -e "2.数据库对接模式"
read -t 30 -p "选择：" NODE_MS
case $NODE_MS in
		1)
			echo -e "世界加钱可及"
			exit 1
			;;
		2)
			db
			;;
		*)
		    echo -e "请选择正确对接模式"
			exit 1
			;;
esac
#iptables
iptables -F
iptables -X  
iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
iptables-save >/etc/sysconfig/iptables
#删除libsodium
cd /root && rm -rf libsodium*
#开启SS
cd /root/shadowsocks && chmod +x *.sh
./run.sh #后台运行shadowsocks
echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
echo 'bash /root/shadowsocks/run.sh' >> /etc/rc.local
chmod +x /etc/rc.d/rc.local && chmod +x /etc/rc.local
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime -r >/dev/null 2>&1
clear
echo -e "${GreenBG} 载入后端简易守护程序中...请稍后... ${Font}"
sleep 2
echo 'if [[ `ps -ef | grep server.py |grep -v grep | wc -l` -ge 1 ]];then
echo "后端运行中...";
else
cd /root/shadowsocks;bash run.sh;
fi' > /root/shadowsocks/monitoring.sh
chmod +x /root/shadowsocks/monitoring.sh
echo '*/5 * * * * /bin/bash /root/shadowsocks/monitoring.sh' >> /var/spool/cron/root
/sbin/service crond restart
if [[ `ps -ef | grep server.py |grep -v grep | wc -l` -ge 1 ]];then
	echo -e "${OK} ${GreenBG} 后端已启动 ${Font}"
else
	echo -e "${OK} ${RedBG} 后端未启动 ${Font}"
	echo -e "检查配置文件是否正确、检查是否代码错误请反馈"
	exit 1
fi