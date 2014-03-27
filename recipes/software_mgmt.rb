#
# Cookbook Name:: gecos_ws_mgmt
# Recipe:: software_management
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
include_recipe "apt"

gecos_ws_mgmt_software_sources 'apt sources list manage' do
  repo_list node[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][:repo_list]
  jobs_id node[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][:jobs_id]
  action :setup
end
