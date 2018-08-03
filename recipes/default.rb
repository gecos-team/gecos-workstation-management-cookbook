#
# Cookbook Name:: gecos_ws_mgmt
# Recipe:: default
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

# Global variable $gecos_os created to reduce calls to external programs
$gecos_os = `lsb_release -d`.split(":")[1].chomp().lstrip()

case node[:kernel][:machine]
  when "x86_64"
    $arch = "amd64"
  when "i686"
    $arch = "i386"
  else  
    $arch = ""
end


$gem_path = "/opt/chef/embedded/bin/gem"
if not ::File.exist?($gem_path)
    $gem_path = "/usr/bin/gem"
end


# Snitch, the chef notifier has been renamed
# TODO: move this to chef-client-wrapper
if ::File.exists?("/usr/bin/gecos-snitch-client")
  $snitch_binary="/usr/bin/gecos-snitch-client"
else
  $snitch_binary="/usr/bin/gecosws-chef-snitch-client"
end  

execute "gecos-snitch-client" do
  command "#{$snitch_binary} --set-active true"
  action :nothing
end.run_action(:run)

# Prepare the environment variables
Chef::Log.info("Prepare the environment variables for #{node['ohai_gecos']['pclabel']} computer")
$gecos_environ = ENV.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
$gecos_environ['STATION'.to_sym] = node['ohai_gecos']['pclabel']
$node = node


# This should not be necessary, as wrapper is in new GECOS-Agent package. It is a transitional solution.
Chef::Log.info("Installing wrapper")
cookbook_file "gecos-chef-client-wrapper" do
  path "/usr/bin/gecos-chef-client-wrapper"
  owner 'root'
  mode '0700'
  group 'root'
  action :nothing
end.run_action(:create_if_missing)

Chef::Log.info("Enabling GECOS Agent in cron")
  
cron "GECOS Agent" do
    minute '30'
    command '/usr/bin/gecos-chef-client-wrapper'
    action :create
end

# This chef-client upstart service is not created anymore
#Chef::Log.info("Disabling old chef-client service")

#service 'chef-client' do
#    provider Chef::Provider::Service::Upstart
#    supports :status => true, :restart => true, :reload => true
#    action [:disable, :stop]
#end

include_recipe "gecos_ws_mgmt::required_packages"
include_recipe "gecos_ws_mgmt::software_mgmt"
include_recipe "gecos_ws_mgmt::misc_mgmt"
include_recipe "gecos_ws_mgmt::network_mgmt"
include_recipe "gecos_ws_mgmt::users_mgmt"
include_recipe "gecos_ws_mgmt::printers_mgmt"
include_recipe "gecos_ws_mgmt::single_node"                                           


node.normal['use_node']= {}
node.override['gcc_link'] = true
