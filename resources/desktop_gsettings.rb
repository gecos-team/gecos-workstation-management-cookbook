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

include Chef::Mixin::ShellOut

resource_name :desktop_gsettings

property :schema, String, name_property:true, required:true
property :user, String, required:true
property :key, String, required:true
property :value, String


load_current_value do |desired|

  cmd_out = shell_out("sudo -iu  #{desired.user} HOME=/home/#{desired.user} dbus-launch --exit-with-session gsettings get #{desired.schema} #{desired.key}")

  current_value_does_not_exist! unless cmd_out.exitstatus==0 && !cmd_out.stdout.nil?

  value cmd_out.stdout.chomp
end

###############
## action :set
###############
action :set do

  package "libglib2.0-bin" do
    action :nothing
  end.run_action(:install)

  converge_if_changed :value do
    execute "set key" do
      command "sudo -iu #{new_resource.user} HOME=/home/#{new_resource.user} dbus-launch gsettings set #{new_resource.schema} #{new_resource.key} #{new_resource.value}"
      only_if "gsettings list-schemas | grep  #{schema}"
    end
  end

end

################
## action :unset
################
action :unset do

  package "libglib2.0-bin" do
    action :nothing
  end.run_action(:install)

  execute "unset key" do
    command "sudo -iu #{new_resource.user} HOME=/home/#{new_resource.user} dbus-launch --exit-with-session gsettings reset #{new_resource.schema} #{new_resource.key}"
    only_if "gsettings list-schemas | grep  #{new_resource.schema}"
  end

end
