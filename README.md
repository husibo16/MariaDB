# MariaDB 一键安装与初始化脚本（兼容 MySQL 8.0）

> 适配系统：Debian / Ubuntu（含 Debian 13 Trixie）  
> 功能：自动安装 MariaDB、启用日志、创建全局管理员用户  
> 作者：胡博涵 实践版（2025）  
> 版本：v1.0

---

## 📖 功能简介

本脚本可在 **全新系统环境** 下自动完成以下工作：

1. 自动检测系统版本（支持 Debian / Ubuntu）  
2. 自动安装 `MariaDB Server` 与 `Client`  
3. 初始化 `root` 密码（安全配置）  
4. 创建业务数据库与具备全局权限的管理员账号  
5. 启用 **通用日志** 与 **慢查询日志**  
6. 自动备份原始配置文件并输出日志至 `/var/log/mysql_install.log`

---

## ⚙️ 默认配置

| 项目 | 默认值 | 说明 |
|------|---------|------|
| MariaDB 版本 | 兼容 MySQL 8.0 | 通过官方 `mariadb-server` 软件包安装 |
| root 密码 | `Root@123456` | 可在脚本顶部修改 |
| 新数据库名 | `xboard` | 可在脚本顶部修改 |
| 新用户名 | `xboard` | 拥有全局管理权限 |
| 新用户密码 | `3uA3iPqOwzNyUlMB` | 随机默认，可自定义 |
| 日志目录 | `/var/log/mysql/` | 含通用日志与慢查询日志 |

---

## 🚀 使用方法

### 1️⃣ 下载脚本

```bash
wget -O install_mariadb.sh https://raw.githubusercontent.com/husibo16/MariaDB/main/install_mariadb.sh
chmod +x install_mariadb.sh
 ./install_mariadb.sh

