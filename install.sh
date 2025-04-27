#!/bin/bash
set -e

# 设置环境变量
export LC_ALL=C
export USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
export HOSTNAME=$(hostname)
export CURRENT_DOMAIN="${USERNAME}.serv00.net"
export WORKDIR="${HOME}/domains/${CURRENT_DOMAIN}/public_nodejs"
export GIT_REPO="https://github.com/eooce/Merge-sub.git"

# 输出信息的函数
log_red() { echo -e "\e[1;91m$1\033[0m"; }
log_green() { echo -e "\e[1;32m$1\033[0m"; }
log_yellow() { echo -e "\e[1;33m$1\033[0m"; }

# 创建 Node.js 网站
create_website() {
    CURRENT_SITE=$(devil www list | awk -v domain="${CURRENT_DOMAIN}" '$1 == domain && $2 == "nodejs"')
    if [ -n "$CURRENT_SITE" ]; then
        log_green "已存在 ${CURRENT_DOMAIN} 的node站点, 无需修改"
    else
        EXIST_SITE=$(devil www list | awk -v domain="${CURRENT_DOMAIN}" '$1 == domain')
        if [ -n "$EXIST_SITE" ]; then
            devil www del "${CURRENT_DOMAIN}" >/dev/null 2>&1
            devil www add "${CURRENT_DOMAIN}" nodejs /usr/local/bin/node18 > /dev/null 2>&1
            log_green "已删除旧的站点并创建新的nodejs站点"
        else
            devil www add "${CURRENT_DOMAIN}" nodejs /usr/local/bin/node18 > /dev/null 2>&1
            log_green "已创建 ${CURRENT_DOMAIN} nodejs站点"
        fi
    fi
}

# 克隆并配置项目
install_project() {
    rm -rf "$WORKDIR" && mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR" >/dev/null 2>&1
    cd "$WORKDIR"
    
    log_yellow "正在克隆项目..."
    git clone $GIT_REPO >/dev/null 2>&1
    log_green "项目克隆成功, 正在配置..."

    mv "$WORKDIR"/Merge-sub/* "$WORKDIR" >/dev/null 2>&1
    rm -rf "$WORKDIR/workers" "$WORKDIR/Merge-sub" "$WORKDIR/Dockerfile" "$WORKDIR/README.md" "$WORKDIR/install.sh" >/dev/null 2>&1
}

# 配置 SSL
setup_ssl() {
    ip_address=$(devil vhost list | awk '$2 ~ /web/ {print $1}')
    devil ssl www add $ip_address le le ${CURRENT_DOMAIN} > /dev/null 2>&1
}

# 配置 npm 和 Node.js 环境
setup_node_env() {
    ln -fs /usr/local/bin/node18 ~/bin/node > /dev/null 2>&1
    ln -fs /usr/local/bin/npm18 ~/bin/npm > /dev/null 2>&1
    mkdir -p ~/.npm-global
    npm config set prefix '~/.npm-global'
    echo 'export PATH=~/.npm-global/bin:~/bin:$PATH' >> $HOME/.bash_profile && source $HOME/.bash_profile
    rm -rf $HOME/.npmrc > /dev/null 2>&1
}

# 安装项目依赖并配置网站
install_dependencies() {
    npm install -r package.json --silent > /dev/null 2>&1
    devil www options ${CURRENT_DOMAIN} sslonly on > /dev/null 2>&1
}

# 重启网站
restart_website() {
    if devil www restart ${CURRENT_DOMAIN} 2>&1 | grep -q "Ok"; then
        log_green "\n汇聚订阅已部署\n\n用户名：admin \n登录密码：admin  请及时修改\n管理页面: https://${CURRENT_DOMAIN}\n\n"
    else
        log_red "汇聚订阅安装失败\n${yellow}devil www del ${CURRENT_DOMAIN} \nrm -rf $HOME/domains/*\n${red}请依次执行上述命令后重新安装!"
        exit 1
    fi
}

# 主安装流程
log_yellow "开始安装 Merge-sub 汇聚订阅器..."

create_website
install_project
setup_ssl
setup_node_env
install_dependencies
restart_website
