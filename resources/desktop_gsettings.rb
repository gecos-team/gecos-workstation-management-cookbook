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

# dbus-1.8.0: dbus-run-session (better option than dbus-launch because
# dbus-daemon will run for as long as the program does, after which it
# will terminate.)

load_current_value do |desired|
  opts = {}
  opts[:user] = desired.user if desired.user
  opts[:environment] = {
    'USER' => opts[:user],
    'HOME' => "/home/#{opts[:user]}"
  }

  cmd_out = shell_out('eval `dbus-launch --sh-syntax`; gsettings get '\
      "#{desired.schema} #{desired.key}; "\
      'kill $DBUS_SESSION_BUS_PID', opts)
  Chef::Log.debug("desktop_gsettings.rb: cmd_out= #{cmd_out.stdout}")

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

  converge_if_changed :value do
    bash "set key #{key}" do
      user new_resource.user.to_s
      code <<-SET_GSETTINGS_SCRIPT
        eval `dbus-launch --sh-syntax`
        gsettings set #{new_resource.schema} #{new_resource.key} #{new_resource.value}
        kill $DBUS_SESSION_BUS_PID
      SET_GSETTINGS_SCRIPT
      environment 'USER' => new_resource.user.to_s, 'HOME' => '/home/'\
        "#{new_resource.user}"
      only_if "gsettings list-schemas | grep  #{schema}"
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

  bash 'unset key' do
    user new_resource.user.to_s
    code <<-RESET_GSETTINGS_SCRIPT
      eval `dbus-launch --sh-syntax`
      gsettings reset #{new_resource.schema} #{new_resource.key}
      kill $DBUS_SESSION_BUS_PID
    RESET_GSETTINGS_SCRIPT
    environment 'HOME' => "/home/#{new_resource.user}"
    only_if "gsettings list-schemas | grep  #{schema}"
  end
end
