#!/bin/bash
export LC_ALL=C

# 定义颜色输出
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"

# 输出信息的函数
log_red() { echo -e "\e[1;91m$1\033[0m"; }
log_green() { echo -e "\e[1;32m$1\033[0m"; }
log_yellow() { echo -e "\e[1;33m$1\033[0m"; }

# 获取当前用户名和主机名
USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
HOSTNAME=$(hostname)

# 根据主机名选择域名
set_domain() {
    if [[ "$HOSTNAME" =~ ct8 ]]; then
        CURRENT_DOMAIN="${USERNAME}.ct8.pl"
    elif [[ "$HOSTNAME" =~ useruno ]]; then
        CURRENT_DOMAIN="${USERNAME}.useruno.com"
    else
        CURRENT_DOMAIN="${USERNAME}.serv00.net"
    fi
}

# 检查网站是否存在，如果存在则返回 true
check_website() {
    log_yellow "正在安装中,请稍等..."
    CURRENT_SITE=$(devil www list | awk -v domain="${CURRENT_DOMAIN}" '$1 == domain && $2 == "nodejs"')
    if [ -n "$CURRENT_SITE" ]; then
        log_green "已存在 ${CURRENT_DOMAIN} 的node站点,无需修改"
        return 0
    else
        log_yellow "站点不存在，正在创建..."
        return 1
    fi
}

# 删除并创建新的站点
create_site() {
    EXIST_SITE=$(devil www list | awk -v domain="${CURRENT_DOMAIN}" '$1 == domain')
    if [ -n "$EXIST_SITE" ]; then
        devil www del "${CURRENT_DOMAIN}" >/dev/null 2>&1
        devil www add "${CURRENT_DOMAIN}" nodejs /usr/local/bin/node18 > /dev/null 2>&1
        log_green "已删除旧的站点并创建新的nodejs站点"
    else
        devil www add "${CURRENT_DOMAIN}" nodejs /usr/local/bin/node18 > /dev/null 2>&1
        log_green "已创建 ${CURRENT_DOMAIN} nodejs站点"
    fi
}

# 安装项目和配置
install_sub() {
    set_domain
    check_website || create_site

    WORKDIR="${HOME}/domains/${CURRENT_DOMAIN}/public_nodejs"
    rm -rf "$WORKDIR" && mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR" >/dev/null 2>&1
    cd "$WORKDIR" && git clone https://github.com/eooce/Merge-sub.git >/dev/null 2>&1
    log_green "项目克隆成功,正在配置..."

    mv "$WORKDIR"/Merge-sub/* "$WORKDIR" >/dev/null 2>&1
    rm -rf workers Merge-sub Dockerfile README.md install.sh >/dev/null 2>&1

    ip_address=$(devil vhost list | awk '$2 ~ /web/ {print $1}')
    devil ssl www add $ip_address le le ${CURRENT_DOMAIN} > /dev/null 2>&1

    # 设置 Node.js 环境
    ln -fs /usr/local/bin/node18 ~/bin/node > /dev/null 2>&1
    ln -fs /usr/local/bin/npm18 ~/bin/npm > /dev/null 2>&1
    mkdir -p ~/.npm-global
    npm config set prefix '~/.npm-global'
    echo 'export PATH=~/.npm-global/bin:~/bin:$PATH' >> $HOME/.bash_profile && source $HOME/.bash_profile
    rm -rf $HOME/.npmrc > /dev/null 2>&1

    npm install -r package.json --silent > /dev/null 2>&1
    devil www options ${CURRENT_DOMAIN} sslonly on > /dev/null 2>&1

    # 重启服务并检查是否成功
    if devil www restart ${CURRENT_DOMAIN} 2>&1 | grep -q "Ok"; then
        log_green "\n汇聚订阅已部署\n\n用户名：admin \n登录密码：admin  请及时修改\n管理页面: https://${CURRENT_DOMAIN}\n\n"
        log_yellow "汇聚节点订阅登录管理页面查看\n\n"
    else
        log_red "汇聚订阅安装失败\n${yellow}devil www del ${CURRENT_DOMAIN} \nrm -rf $HOME/domains/*\n${red}请依次执行上述命令后重新安装!"
        exit 1
    fi
}  

install_sub
