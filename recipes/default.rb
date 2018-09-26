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
$gecos_os = `lsb_release -d`.split(':')[1].chomp.lstrip

$arch = case node[:kernel][:machine]
        when 'x86_64'
          'amd64'
        when 'i686'
          'i386'
        else
          ''
        end

$gem_path = if ::File.exist?('/opt/chef/embedded/bin/gem')
              '/opt/chef/embedded/bin/gem'
            else
              $gem_path = '/usr/bin/gem'
            end

# Snitch, the chef notifier has been renamed
# TODO: move this to chef-client-wrapper
$snitch_binary = if ::File.exist?('/usr/bin/gecos-snitch-client')
                   '/usr/bin/gecos-snitch-client'
                 else
                   '/usr/bin/gecosws-chef-snitch-client'
                 end

execute 'gecos-snitch-client' do
  command "#{$snitch_binary} --set-active true"
  action :nothing
end.run_action(:run)

# Prepare the environment variables
Chef::Log.info('Prepare the environment variables for '\
    "#{node['ohai_gecos']['pclabel']} computer")
$gecos_environ = ENV.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = v }
$gecos_environ['STATION'.to_sym] = node['ohai_gecos']['pclabel']
$node = node

# Get locale
$locale = ENV['LANG'].downcase
$locale = $locale.split('.')[0] if $locale.include? '.'
Chef::Log.info("Locale is #{$locale}")

Chef::Log.info('Enabling GECOS Agent in cron')

cron 'GECOS Agent' do
  minute '30'
  command '/usr/bin/gecos-chef-client-wrapper'
  action :create
end

Chef::Log.info('Chef client version check')

current_client_version = node['chef_packages']['chef']['version']
power = 1_000_000
cclient_version = current_client_version.split('.')
integer_current_client_version = cclient_version.inject(0) do |sum, val|
  power /= 100
  sum + val.to_i * power
end



if integer_current_client_version < 122_000
  Chef::Log.info('Chef client upgrade required')
  execute "apt-get-update" do
    command "apt-get update"
    ignore_failure true
  end
  package 'chef' do
    action :upgrade
  end
end

include_recipe 'gecos_ws_mgmt::required_packages'
include_recipe 'gecos_ws_mgmt::software_mgmt'
include_recipe 'gecos_ws_mgmt::misc_mgmt'
include_recipe 'gecos_ws_mgmt::network_mgmt'
include_recipe 'gecos_ws_mgmt::users_mgmt'
include_recipe 'gecos_ws_mgmt::printers_mgmt'
include_recipe 'gecos_ws_mgmt::single_node'

node.normal['use_node'] = {}
node.override['gcc_link'] = true
