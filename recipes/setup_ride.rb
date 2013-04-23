#
# Cookbook Name:: rsss
# Recipe:: setup_ride
#
# Copyright 2013, Ryan J. Geyer <me@ryangeyer.com>
#
# All rights reserved - Do Not Redistribute
#

repo "repo_git" do
  provider "repo_git"
  repository "git@github.com:euge/ride.git"
  revision "file_export"
  destination "/opt/ride"
  credential <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAxctQAutVui4q3HJsP65nGIrg+0DrO+iYu3yV/ewNkbsg4y86
XSq1DoLE3vQZOlxG4x98pDeHjRh1AcWt6fifU/dxqAgFrBQJhh+XPGPpNtOVkfb/
dcJIoAKtduD0+6EJ69q34r301ZnRrlF6Q4MXUQV9yjyNUrvOVcGDFpeOcjuk6yAm
oyP7nWTaPv0runPDKyan7ljXbb89azGSbqYTRlNqiAU90RdLp/w+PaafD9H7Gugs
2BY47VJpjEqZMEL7nZNkDYsrW7YQ0nIF5u2I0yrvCvTVafIMDLnQZ0MkZdSnygZp
Q3nTb5DOJdetkSNqYnr7+hFXgYBI84aIk8E4cQIBIwKCAQEAgfqiSw+tXRcGORf9
/fZDv6u4aphgEWz2pxdbQHaMkvdQIEObYcubjTFczQbOv/N/CkfkMWZRwx6zSk60
HWjdutXOWHpM3stWtzlUwUj4VzqVfS1IybovuZtcDEqvngq9YHnJS9vqCLWJylLM
sAWwPI6UfZWBcOHQvALSfI963Vk8SA/93LPi0wN9zxN0v+Q+1NCFek1s7HJffRJY
RGWpt75gy0OhE1KV+k19m/WZ3Y058Am5tzIpT3w3oPKR9tItmiADhT2ZXA3E4ou3
ELCtdzkGhqPQRjnZAGTaY+X93b3W0Gi+U6EFdF91123i4nMEogWs423Kd5/flP08
4XBuuwKBgQD0ppf/KAno2eF59f6dTe+/2FOYjpLEIIu2b/W0x84+coOX3zE0wvV+
PL+llEpT2WHyPzIcq4MtHaOnZkeGsQ+KiUU/VhVDn4edqHQxBMYN6UzFcPUGJ/qY
43t+Xz+ZuZG7IPS8C6EGzVvVCCzydfgt6weYvFsbAJiyALIU4Swv5QKBgQDO+ENM
IB6YNH4QJCO7XsSCUcJEQXzGl3pZ2LvGou82vDOuqypWuRNuwdHOYvzQX7qEK6dD
efjM8o2O4y3FErv0CGA1nspBJPgbCOZwZJUOxSM17oD2fg65oxQnFvN3qL3da+y4
HMJgKMUZRSTnaYdWzs7s2H53tJtCtxBOtJDlnQKBgQCgxT9P5xx0cevxD14s23Gp
9I60tXZjoFvPqKjHQXjnNU8pSYa8RZoCf7Ejqpc+aket0cHYU3N1az+ohQpudFqr
fsca/g35PPK4D5zPwU7zMulOjA665xJkeDs1yZAx0beJmVBeUMjnNn4s6B2JY3c0
HhrvVzSOFlW2zUHTNOKF3wKBgQDJDm1CotvkUD/ybD/32Gcfgp91gXHlfTUG0oqG
cmS41BTy0ikhC484ZIKrO5aBRwz1bDwVqa/dCOFI+fHypHwRobyL3BTu03SsjE2R
wMtQLTglwx4xR0GBIhOTr+UyaWf7qqtxBf6mjgFLv4LvbdPt7XiOTqa9bZ4jjUMK
oMdFcwKBgQDKqbsfplHTAw7ffyo5cWY9rG3MU2VA6YcIy/rlND2DFprk7O7RWmtq
kYLJ5bD2O4T2YObbAN0V8Qh/mogYYhnFTzG6G2+P3EkWXFO/G27fYl4vh3xrebQs
wleqdB9SvQcIbOlISNGXGr4DTDF+RnMROwwt28vuwqldIrD+/edSYw==
-----END RSA PRIVATE KEY-----
EOF
  action :pull
end

gem_package "rdoc" do
  gem_binary "/usr/bin/gem"
end

gem_package "bundler" do
  gem_binary "/usr/bin/gem"
end

bash "Bundle install RIDE" do
  cwd "/opt/ride"
  code <<EOC
bundle install
rackup -p 8000
EOC
end

bash "Update the export HREF" do
  code <<EOC
sed -i 's,"/export","http://#{node["rsss"]["fqdn"]}/product/rideimport",g' /opt/ride/public/js/lib/exporter.js
EOC
end

package "mod_proxy_html"

apache_module "proxy"
apache_module "proxy_http"

bash "Add ProxyPass rules for ride" do
  code <<-EOC
if [ -z "`grep ProxyPass /etc/httpd/sites-enabled/rsss.conf`" ]
then
  sed -i "s,</VirtualHost>,  ProxyPass /ride http://localhost:8000\n  ProxyPassReverse /ride http://localhost:8000\n</VirtualHost>,g" /etc/httpd/sites-enabled/rsss.conf
fi
  EOC
end

service "httpd" do
  action :restart
end