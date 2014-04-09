#
# Cookbook Name:: gecos-ws-mgmt
# Recipe:: users_management
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

gecos_ws_mgmt_user_apps_autostart 'user apps autostart' do
  users node[:gecos_ws_mgmt][:users_mgmt][:user_apps_autostart_res][:users]
  job_ids node[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][:job_ids]
  action :setup
end

