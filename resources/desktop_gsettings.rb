#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: desktop_gsettings
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
#

resource_name :desktop_gsettings

property :schema, String, name_property: true, required: true
property :user, String, required: true
property :key, String, required: true
property :value, String
property :dbus_command, String

# dbus-1.8.0: dbus-run-session (better option than dbus-launch because
# dbus-daemon will run for as long as the program does, after which it
# will terminate.)

load_current_value do |desired|
  Chef::Log.debug("desktop_gsettings.rb: desired.schema = #{desired.schema}")
  Chef::Log.debug("desktop_gsettings.rb: desired.key = #{desired.key}")
  Chef::Log.debug("desktop_gsettings.rb: desired.user = #{desired.user}")
  if ::File.executable?('/usr/bin/dbus-run-session')
    dbus_command '/usr/bin/dbus-run-session'
  else
    dbus_command '/usr/bin/xvfb-run'
  end

  cmd_out = shell_out("sudo -u #{desired.user} HOME=/home/#{desired.user} "\
		      "#{dbus_command} gsettings get "\
		      "#{desired.schema} #{desired.key}")
  Chef::Log.debug("desktop_gsettings.rb: cmd_out = #{cmd_out.stdout}")

  unless cmd_out.exitstatus.zero? && !cmd_out.stdout.nil?
    current_value_does_not_exist!
  end

  result = if cmd_out.stdout =~ /uint/
             cmd_out.stdout.chomp.split.pop
           else
             cmd_out.stdout.chomp
           end
  value result
end

###############
## action :set
###############
action :set do
  package 'libglib2.0-bin' do
    action :nothing
  end.run_action(:install)

  package 'xvfb' do
    action :nothing
    only_if "#{dbus_command} == 'xvfb-run'"
  end.run_action(:install)

  converge_if_changed :value do
    bash "set key #{key} online" do
      code <<-SET_GSETTINGS_SCRIPT
        sudo -u #{new_resource.user} \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u #{new_resource.user})/bus" \
        gsettings set #{new_resource.schema} #{new_resource.key} #{new_resource.value}
      SET_GSETTINGS_SCRIPT
      environment 'HOME' => "/home/#{new_resource.user}"
      only_if "gsettings list-schemas | grep  #{schema}"
      only_if "test -e /run/user/$(id -u #{new_resource.user})/bus"
    end

    bash "set key #{key}" do
      code <<-SET_GSETTINGS_SCRIPT
        sudo -u #{new_resource.user} #{dbus_command} \
        gsettings set #{new_resource.schema} \
        #{new_resource.key} #{new_resource.value}
      SET_GSETTINGS_SCRIPT
      environment 'HOME' => "/home/#{new_resource.user}"
      only_if "gsettings list-schemas | grep  #{schema}"
      not_if "test -e /run/user/$(id -u #{new_resource.user})/bus"
    end
  end
end

################
## action :unset
################
action :unset do
  package 'libglib2.0-bin' do
    action :nothing
  end.run_action(:install)

  bash 'unset key by dbus' do
    code <<-RESET_GSETTINGS_SCRIPT
      sudo -u #{new_resource.user} \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u #{new_resource.user})/bus" \
      gsettings reset #{new_resource.schema} #{new_resource.key}
    RESET_GSETTINGS_SCRIPT
    environment 'HOME' => "/home/#{new_resource.user}"
    only_if "gsettings list-schemas | grep  #{schema}"
    only_if "test -e /run/user/$(id -u #{new_resource.user})/bus"
  end

  bash "set key #{key}" do
    code <<-RESET_GSETTINGS_SCRIPT
      sudo -u #{new_resource.user} #{dbus_command} \
      gsettings reset #{new_resource.schema} \
      #{new_resource.key} #{new_resource.value}
    RESET_GSETTINGS_SCRIPT
    environment 'HOME' => "/home/#{new_resource.user}"
    only_if "gsettings list-schemas | grep  #{schema}"
    not_if "test -e /run/user/$(id -u #{new_resource.user})/bus"
  end
end
