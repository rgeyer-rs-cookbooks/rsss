#
# Cookbook Name:: rsss
# Recipe:: setup_rsss
#
# Copyright 2012-2013, Ryan J. Geyer <me@ryangeyer.com>
#
# All rights reserved - Do Not Redistribute
#

rightscale_marker :begin

composer_path = ::File.join(Chef::Config[:file_cache_path], "composer.phar")

package "subversion"

directory ::File.join(node.rsss.install_dir, 'logs') do
  owner 'apache'
  group 'apache'
end

file ::File.join(node.rsss.install_dir, 'logs', 'application.log') do
  owner 'apache'
  group 'apache'
  action [:create, :touch]
end

# Install and run composer.php to get dependencies
execute "Download composer.phar" do
  cwd Chef::Config[:file_cache_path]
  command "curl -s http://getcomposer.org/installer | php -d allow_url_fopen=On"
  creates composer_path
end

execute "Get rsss vendor libraries" do
  cwd node.rsss.install_dir
  command "php -d allow_url_fopen=On #{composer_path} install"
  creates ::File.join(node.rsss.install_dir, 'vendor')
end

template ::File.join(node.rsss.install_dir, 'config', 'autoload', 'local.php') do
  local true
  source ::File.join(node.rsss.install_dir, 'config', 'autoload', 'local.php.erb')
  mode 0650
  group "apache"
  variables(
    :db_host => 'localhost',
    :db_name => 'rs_selfservice',
    :db_user => 'root',
    :rs_email => node.rsss.rightscale_email,
    :rs_pass => node.rsss.rightscale_password,
    :rs_acct_num => node.rsss.rightscale_acct_num,
    :hostname => node.rsss.fqdn,
    :owners => node.rsss.owners
  )
end

# Create empty model directories
directory ::File.join(node.rsss.install_dir, 'data', 'DoctrineORMModule', 'Proxy') do
  recursive true
  mode 0774
  group "apache"
end

directory ::File.join(node.rsss.install_dir, 'data', 'SmartyModule', 'templates_c') do
  recursive true
  mode 0774
  group "apache"
end

# Create DB and zap schema
if `mysql -e 'show databases' | grep rs_selfservice`.empty?
  execute "Create Database Schema" do
    command "mysql -e 'create database rs_selfservice'"
  end

  bash "Zap Schema" do
    cwd ::File.join(node.rsss.install_dir)
    code <<-EOF
vendor/bin/doctrine-module orm:schema-tool:create
php public/index.php product add
    EOF
  end
end

# Hack up the vhost for AllowOverride and using /public
# Create or re-create virtualhost (apache) or config for nginx
# Point doc root to /root/of/app/public
# Set AllowOverride All
# SetEnv APPLICATION_ENV "production|development"

bash "Hack up the vhost" do
  code <<-EOF
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/httpd/sites-available/rsss.conf
sed -i 's,/home/webapps/rsss\\(>\\?\\)$,/home/webapps/rsss/public\\1,g' /etc/httpd/sites-available/rsss.conf
/etc/init.d/httpd restart
  EOF
end

rightscale_marker :end