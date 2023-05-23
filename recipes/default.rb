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
# Old lsb_release method does not work anymore, as this command now parses /usr/lib/os_release
# $gecos_os = `lsb_release -d`.split(':')[1].chomp.lstrip
# TODO: include GECOS strings in /usr/lib/os_release 
lsbrelease = File.read('/etc/lsb-release')
description = lsbrelease.lines.find { |l| l.include?('DISTRIB_DESCRIPTION=') }
$gecos_os = description.match(/"([^"]+)"/)[1]

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

env_hash = {
  gecos_path_ids: node.normal['gecos_path_ids'],
  gecos_path_names: node.normal['gecos_path_names']
}

Chef::Log.info('Create /etc/gecos/environment file ')
template '/etc/gecos/environment' do
  source 'environment.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables env_hash
  action :nothing
end.run_action(:create)

include_recipe 'gecos_ws_mgmt::required_packages'
include_recipe 'gecos_ws_mgmt::software_mgmt'
include_recipe 'gecos_ws_mgmt::misc_mgmt'
include_recipe 'gecos_ws_mgmt::network_mgmt'
include_recipe 'gecos_ws_mgmt::users_mgmt'
include_recipe 'gecos_ws_mgmt::printers_mgmt'
include_recipe 'gecos_ws_mgmt::single_node'

node.normal['use_node'] = {}
node.override['gcc_link'] = true

# Loading metadata (json-schema)
load_metadata
