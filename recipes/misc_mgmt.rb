#
# Cookbook Name:: gecos-ws-mgmt
# Recipe:: misc_management
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

gecos_ws_mgmt_local_file 'manage local files' do
  delete_files node[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][:delete_files]
  copy_files node[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][:copy_files]
  jobs_id node[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][:jobs_id]
  action :setup
end

