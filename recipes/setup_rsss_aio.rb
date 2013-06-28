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

# TODO: This is a hack that actually belongs in rs_vagrant_shim
# and/or my images need to be cleaned up better.
unless node["rsss"]["cleaned_yum"]
  execute "yum clean" do
    command "yum clean all"
    action :run
  end

  ruby_block "set yum cleaned in node" do
    block do
      node["rsss"]["cleaned_yum"] = true
    end
  end
end

include_recipe "apache2::mod_ssl"

apache_site "000-default" do
  enable false
end

file "/etc/php.d/memory.ini" do
  backup false
  content "memory_limit = 512M"
  action :create
end

sys_dns "default" do
  id node["rsss"]["dns"]["id"]
  address node.cloud.public_ips[0]
  region node["rsss"]["dns"]["region"]
  action :set
end

include_recipe "rsss::setup_mongodb_aio"

rightscale_marker :end