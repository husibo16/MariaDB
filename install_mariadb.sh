#!/usr/bin/env bash
# ============================================================
# MariaDB 一键安装与初始化脚本（兼容 MySQL 8.0）
# 适配系统: Debian / Ubuntu（含 Debian 13 Trixie）
# 功能: 自动安装 MariaDB、启用日志、创建全局管理员用户
# 作者: 胡博涵 实践版（2025）
# 版本: v1.1（生产级稳定版）
# ============================================================

set -euo pipefail
trap 'echo -e "\033[1;31m[错误]\033[0m 安装过程中出现异常，脚本已中断。请检查日志：${LOG_FILE}"; exit 1' ERR

# === 配置部分（可修改） ===
MYSQL_VERSION="8.0"                 # 显示用途
MYSQL_ROOT_PASSWORD="Root@123456"   # root 密码
NEW_DB_NAME="xboard"                # 自动创建的数据库名
NEW_DB_USER="xboard"                # 自动创建的用户名
NEW_DB_PASS="3uA3iPqOwzNyUlMB"      # 自动创建的用户密码
LOG_FILE="/var/log/mysql_install.log"

# === 彩色输出函数 ===
info()    { echo -e "\033[1;34m[信息]\033[0m $1"; }
success() { echo -e "\033[1;32m[成功]\033[0m $1"; }
warn()    { echo -e "\033[1;33m[警告]\033[0m $1"; }
error()   { echo -e "\033[1;31m[错误]\033[0m $1"; }

# === 日志重定向 ===
exec > >(tee -a "$LOG_FILE") 2>&1

info "检测系统环境..."
if ! command -v lsb_release &>/dev/null; then
  apt update -y && apt install -y lsb-release
fi
DISTRO=$(lsb_release -is)
CODENAME=$(lsb_release -cs)
success "系统识别为：$DISTRO ($CODENAME)"

info "更新系统与依赖..."
apt update -y && apt install -y wget gnupg ca-certificates

# === 安装 MariaDB（MySQL 兼容版本）===
info "开始安装 MariaDB（兼容 MySQL ${MYSQL_VERSION}）..."
apt install -y mariadb-server mariadb-client

info "启动 MariaDB 服务..."
systemctl enable mariadb
systemctl start mariadb

# === 初始化 root 密码 ===
info "配置 root 密码..."
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
success "root 密码设置完成。"

# === 创建数据库与业务用户 ===
info "创建数据库与全局管理员用户..."
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS ${NEW_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${NEW_DB_USER}'@'%' IDENTIFIED BY '${NEW_DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${NEW_DB_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
success "数据库 ${NEW_DB_NAME} 与用户 ${NEW_DB_USER} 已创建并授权。"

# === 启用通用日志与慢查询日志 ===
info "启用通用日志与慢查询日志..."
MYCNF="/etc/mysql/mariadb.conf.d/50-server.cnf"
cp -a "$MYCNF" "${MYCNF}.bak.$(date +%s)"

# 确保日志目录存在
mkdir -p /var/log/mysql
chown mysql:adm /var/log/mysql
chmod 750 /var/log/mysql

# 写入日志配置
cat >> "$MYCNF" <<EOF

# === MariaDB 日志设置 ===
general_log = 1
general_log_file = /var/log/mysql/mariadb_general.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mariadb_slow.log
long_query_time = 2
log_error = /var/log/mysql/mariadb_error.log
EOF

systemctl restart mariadb
success "日志系统已启用：/var/log/mysql/"

# === 验证安装状态 ===
info "验证 MariaDB 服务状态..."
mysql --version
systemctl status mariadb --no-pager | grep Active

# === 测试连接 ===
info "验证 MariaDB 连接..."
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT VERSION();" && success "MariaDB 连接成功！"

# === 完成提示 ===
success "✅ MariaDB (MySQL ${MYSQL_VERSION} 兼容版) 安装完成！"
echo "-----------------------------------------"
echo " root 密码: ${MYSQL_ROOT_PASSWORD}"
echo " 数据库名: ${NEW_DB_NAME}"
echo " 用户名:   ${NEW_DB_USER}"
echo " 用户密码: ${NEW_DB_PASS}"
echo " 日志目录: /var/log/mysql/"
echo " 日志文件: mariadb_general.log / mariadb_slow.log"
echo "-----------------------------------------"
echo ""
warn "如需远程访问，请修改 /etc/mysql/mariadb.conf.d/50-server.cnf 中："
echo "  bind-address = 0.0.0.0"
warn "并执行：systemctl restart mariadb"
echo ""
info "建议执行以下命令验证数据库登录："
echo "  mysql -u root -p"
echo "  mysql -u ${NEW_DB_USER} -p${NEW_DB_PASS} -h 127.0.0.1 -P 3306"
echo ""
success "安装日志已保存至：${LOG_FILE}"
