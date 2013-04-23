maintainer       "Ryan J. Geyer"
maintainer_email "me@ryangeyer.com"
license          "All rights reserved"
description      "Installs/Configures rsss"
long_description "Installs/Configures rsss"
version          "0.0.3"

supports "centos"

depends "rightscale"
depends "repo"
depends "apache2"

recipe "rsss::setup_rsss", "Assuming that the code has already been downloaded and that an apache vhost is setup, this installs and configures dependencies for the RSSS"
recipe "rsss::setup_ride", "Adds RIDE.. If you don't know what this is, don't use it. ;)"

attribute "rsss/install_dir",
  :display_name => "RSSS Install Directory",
  :required => "required",
  :recipes => ["rsss::setup_rsss"]

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