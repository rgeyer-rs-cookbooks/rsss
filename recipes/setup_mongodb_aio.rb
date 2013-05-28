#
# Cookbook Name:: rsss
# Recipe:: setup_mongodb_aio
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

# Install & Configure MongoDB
yum_repository "10gen" do
  name "10gen"
  url "http://downloads-distro.mongodb.org/repo/redhat/os/x86_64"
  action :add
end

package "mongo-10gen" do
  version "#{node["rsss"]["mongodb"]["version"]}-mongodb_1"
  action :install
end

package "mongo-10gen-server" do
  version "#{node["rsss"]["mongodb"]["version"]}-mongodb_1"
  action :install
end

directory "/mnt/storage/mongodb" do
  owner "mongod"
  group "mongod"
  mode 0755
  recursive true
end

template "/etc/mongod.conf" do
  source "mongod.conf.erb"
  owner "mongod"
  group "mongod"
  backup false
end

service "mongod" do
  action :start
end

rightscale_marker :end