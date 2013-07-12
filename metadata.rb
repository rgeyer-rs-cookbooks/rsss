maintainer       "Ryan J. Geyer"
maintainer_email "me@ryangeyer.com"
license          "All rights reserved"
description      "Installs/Configures rsss"
long_description "Installs/Configures rsss"
version          "0.0.4"

supports "centos"

%w{rightscale repo apache2 web_apache db_mysql db block_device sys_dns logrotate}.each do |dep|
  depends dep
end

depends "yum", "~> 2.2"

recipe "rsss::setup_rsss_aio", "Sets up the filesystem and some defaults for running RSSS on an AIO instance"
recipe "rsss::setup_rsss", "Clones the specified revision of the RSSS, and sets up an HTTPS only vhost"
recipe "rsss::setup_ride", "Adds RIDE.. If you don't know what this is, don't use it. ;)"

attribute "rsss/rightscale_email",
  :display_name => "RSSS RightScale Email",
  :required => "required",
  :recipes => ["rsss::setup_rsss"]

attribute "rsss/rightscale_password",
  :display_name => "RSSS RightScale Password",
  :required => "required",
  :recipes => ["rsss::setup_rsss"]

attribute "rsss/rightscale_acct_num",
  :display_name => "RSSS RightScale Account Number",
  :required => "required",
  :recipes => ["rsss::setup_rsss"]

attribute "rsss/fqdn",
  :display_name => "RSSS Fully Qualified Domainname",
  :required => "required",
  :recipes => ["rsss::setup_rsss", "rsss::setup_ride"]

attribute "rsss/dbpass",
  :display_name => "RSSS Database Password",
  :required => "required",
  :recipes => ["rsss::setup_rsss"]

attribute "rsss/owners",
  :display_name => "RSSS Cloud Owners",
  :description => "An array of key:value pairs where the key is the RightScale Cloud ID, and the value is the owner ID for the supplied cloud credentials.  I.E. 1:1234-45678-910,1:1234-45678-910",
  :required => "required",
  :type => "array",
  :recipes => ["rsss::setup_rsss"]

attribute "rsss/memcached_servers",
  :display_name => "RSSS Memcached Servers",
  :description => "An array of key:value pairs where the key is a memcached hostname and the value is a listen port",
  :required => "recommended",
  :type => "array",
  :default => ["localhost:11211"],
  :recipes => ["rsss::setup_rsss"]

attribute "rsss/products",
  :display_name => "RSSS Products",
  :description => "An array of products which should be setup on the initial run.  Available options are (baselinux,php3tier)",
  :required => "recommended",
  :type => "array",
  :default => ["baselinux","php3tier"],
  :recipes => ["rsss::setup_rsss"]

attribute "rsss/users",
  :display_name => "RSSS Authorized Users",
  :description => "An array of email addresses of users who are allowed to use the RSSS Vending Machine.  They will be authenticated by Google OpenID",
  :required => "required",
  :type => "array",
  :recipes => ["rsss::setup_rsss"]

attribute "rsss/revision",
  :display_name => "RSSS Revision",
  :description => "The Git Revision of the RSSS to checkout and deploy",
  :required => "required",
  :type => "string",
  :recipes => ["rsss::setup_rsss"]

attribute "rsss/dns/choice",
  :display_name => "RSSS DNS Service Provider",
  :description => "See sys_dns/choice for more details",
  :required => "optional",
  :choice => ["DNSMadeEasy", "DynDNS", "Route53", "CloudDNS"],
  :recipes => ["rsss::setup_rsss_aio"]

attribute "rsss/dns/id",
  :display_name => "RSSS DNS Record ID",
  :description => "See sys_dns/id for more details",
  :required => "optional",
  :type => "string",
  :recipes => ["rsss::setup_rsss_aio"]

attribute "rsss/dns/user",
  :display_name => "RSSS DNS User",
  :description =>
      "See sys_dns/user for more details",
  :required => "optional",
  :recipes => ["rsss::setup_rsss_aio"]

attribute "rsss/dns/password",
  :display_name => "RSSS DNS Password",
  :description =>
      "See sys_dns/user for more details",
  :required => "optional",
  :recipes => ["rsss::setup_rsss_aio"]

attribute "rsss/dns/region",
  :display_name => "RSSS Cloud DNS Region",
  :description =>
    "You must specify the region when using CloudDNS." +
    " Example: Chicago",
  :required => "optional",
  :choice => ["Chicago", "Dallas", "London"],
  :recipes => ["rsss::setup_rsss_aio"]

attribute "rsss/restore_lineage",
  :display_name => "RSSS Restore Lineage",
  :description => "When set, a db::do_primary_restore will be performed.  When not set, a new blank block_device will be created",
  :required => "optional",
  :recipes => ["rsss::setup_rsss_aio"]

attribute "rsss/mongodb/version",
  :display_name => "RSSS Mongo Version",
  :description => "The version of MongoDB to install",
  :required => "optional",
  :default => "2.4.3",
  :recipes => ["rsss::setup_rsss_aio"]