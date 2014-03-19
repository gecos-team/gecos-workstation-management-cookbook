#
# Cookbook Name:: gecoscc-chef-server
# Recipe:: default
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#


gecos_workstation_management_apt_repository_manager "/etc/apt/sources.list.d/#{node[:gecos_workstation_management][:software_management][:sources_list_d][:repo1]}" do
  action :install
end
