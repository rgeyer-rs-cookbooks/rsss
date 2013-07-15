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

apache_site "000-default" do
  enable false
end

file "/etc/php.d/memory.ini" do
  backup false
  content "memory_limit = 512M"
  action :create
end

if node["rsss"]["dns"]["id"] && node["rsss"]["dns"]["user"] && node["rsss"]["dns"]["password"]

  node["sys_dns"] = {}
  node["sys_dns"]["choice"] = node["rsss"]["dns"]["choice"]
  node["sys_dns"]["user"] = node["rsss"]["dns"]["user"]
  node["sys_dns"]["password"] = node["rsss"]["dns"]["password"]

  include_recipe "sys_dns::default"

  sys_dns "default" do
    id node["rsss"]["dns"]["id"]
    address node.cloud.public_ips[0]
    region node["rsss"]["dns"]["region"]
    action :set
  end
end

include_recipe "rsss::setup_mongodb_aio"

rightscale_marker :end