#
# Cookbook Name:: rsss
# Recipe:: setup_rsss_aio
#
# Copyright 2013, Ryan J. Geyer
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

rightscale_marker :begin

include_recipe "apache2::mod_ssl"

# Preset some things that are in external cookbooks
# TODO: Should have the storage mountpoint be a variable or input somewhere
mountpoint = "/mnt/storage"

DATA_DIR = node[:db][:data_dir]
datadir = ::File.join(DATA_DIR, "mysql")

unless node["rsss"]["restore_lineage"]
  include_recipe "block_device::setup_block_device"
  db_init_status :set

  db_state_set "Set master state" do
    master_uuid node["rightscale"]["instance_uuid"]
    master_ip node["cloud"]["private_ips"][0]
    is_master true
  end
end

apache_site "000-default" do
  enable false
end

directory DATA_DIR do
  action :create
end

directory datadir do
  action :create
end

log "  Stopping database..."
db DATA_DIR do
  action :stop
end

log "  Moving database to block device..."
db datadir do
  provider node[:db][:provider]
  db_version node[:db][:version]
  action :move_data_dir
end

log "  Starting database..."
db DATA_DIR do
  action [ :start ]
end

# TODO: Bump up the PHP Memory Limit based on available memory and reboot apache
file "/etc/php.d/memory.ini" do
  backup false
  content "memory_limit = 512M"
  action :create
end

directory ::File.join(mountpoint, "rsss")

sys_dns "default" do
  id node["rsss"]["dns"]["id"]
  address node.cloud.public_ips[0]
  region node["rsss"]["dns"]["region"]
  action :set
end

if node["rsss"]["restore_lineage"]
  node["db"]["backup"]["lineage"] = node.rsss.restore_lineage
  include_recipe "db::do_primary_restore"
  db_init_status :set

  db_state_set "Set master state" do
    master_uuid node["rightscale"]["instance_uuid"]
    master_ip node["cloud"]["private_ips"][0]
    is_master true
  end
end

rightscale_marker :end