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
underscored_fqdn = node.rsss.fqdn.gsub(".", "_")
underscored_fqdn = underscored_fqdn.gsub("-", "_")
underscored_fqdn_16 = underscored_fqdn.slice(0..15)
rsss_dir = ::File.join(node.block_device.devices.device1.mount_point, "rsss")
vhost_dir = ::File.join(rsss_dir, node.rsss.fqdn)
docroot = ::File.join(vhost_dir, "public")
ssl_dir = ::File.join("/etc", node.web_apache.config_subdir, 'rightscale.d', "key")

directory rsss_dir do
  recursive true
end

package "subversion"

directory ssl_dir do
  mode 00700
  recursive true
end

bash "Create SSL Certificates" do
  cwd ssl_dir
  code <<-EOH
  umask 077
  openssl genrsa 2048 > #{node.rsss.fqdn}.key
  openssl req -subj '/CN=#{node.rsss.fqdn}' -new -x509 -nodes -sha1 -days 3650 -key #{node.rsss.fqdn}.key > #{node.rsss.fqdn}.crt
  cat #{node.rsss.fqdn}.key #{node.rsss.fqdn}.crt > #{node.rsss.fqdn}.pem
  EOH
  not_if { ::File.exists?(::File.join(ssl_dir, "#{node.rsss.fqdn}.pem")) }
end

web_app node.rsss.fqdn do
  docroot docroot
  vhost_port 443
  server_name node.rsss.fqdn
  ssl_certificate_file ::File.join(ssl_dir, "#{node.rsss.fqdn}.crt")
  ssl_key_file ::File.join(ssl_dir, "#{node.rsss.fqdn}.key")
  allow_override "All"
  notifies :restart, resources(:service => "apache2")
end

git vhost_dir do
  repository "git://github.com/rgeyer/rs_selfservice.git"
  reference node.rsss.revision
  action :sync
end

directory ::File.join(vhost_dir, 'logs') do
  owner 'apache'
  group 'apache'
end

file ::File.join(vhost_dir, 'logs', 'application.log') do
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
  cwd vhost_dir
  command "php -d allow_url_fopen=On #{composer_path} install"
  creates ::File.join(vhost_dir, 'vendor')
end

template ::File.join(vhost_dir, 'config', 'autoload', 'local.php') do
  local true
  source ::File.join(vhost_dir, 'config', 'autoload', 'local.php.erb')
  mode 0650
  group "apache"
  variables(
    :db_host => 'localhost',
    :db_name => underscored_fqdn,
    :rs_email => node.rsss.rightscale_email,
    :rs_pass => node.rsss.rightscale_password,
    :rs_acct_num => node.rsss.rightscale_acct_num,
    :hostname => node.rsss.fqdn,
    :owners => node.rsss.owners,
    :memcached_servers => node.rsss.memcached_servers
  )
end

directory ::File.join(vhost_dir, 'data', 'DoctrineMongoODMModule', 'Hydrator') do
  recursive true
  mode 0774
  group "apache"
end

directory ::File.join(vhost_dir, 'data', 'SmartyModule', 'templates_c') do
  recursive true
  mode 0774
  group "apache"
end

product_add_lines = ''
node.rsss.products.each do |product|
  product_add_lines += "\n  php public/index.php product add #{product}"
end

bash "Zap Schema" do
  cwd ::File.join(vhost_dir)
  code <<-EOF
vendor/bin/doctrine-module odm:schema:create#{product_add_lines}
  EOF
end

bash "Prime the caches" do
  cwd ::File.join(vhost_dir)
  code "php public/index.php cache update rightscale"
end

preauth_code = ""

node.rsss.users.each do |email|
  preauth_code += "\nphp public/index.php users authorize #{email}"
end

bash "(Pre)authorize users" do
  cwd ::File.join(vhost_dir)
  code preauth_code
end

# TODO: cron for updating cache
rightscale_logrotate_app "rsss" do
  cookbook "rightscale"
  template "logrotate.erb"
  path [::File.join(vhost_dir,"logs","*.log")]
  frequency "size 10M"
  rotate 4
end

cron "RSSS Cache Refresh" do
  minute 45
  user "root"
  command "php #{::File.join(vhost_dir,"public","index.php")} cache update rightscale"
  action :create
end

service "httpd" do
  action :restart
end

rightscale_marker :end