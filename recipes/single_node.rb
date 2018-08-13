#
# Cookbook Name:: gecos-ws-mgmt
# Recipe:: single_node
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

gecos_ws_mgmt_network "localhost" do
  connections node[:gecos_ws_mgmt][:single_node][:network_res][:connections]
  job_ids node[:gecos_ws_mgmt][:single_node][:network_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:single_node][:network_res][:support_os]
  action  :presetup
  notifies :test, 'gecos_ws_mgmt_connectivity[gcc_connectivity]', :immediately
  subscribes :warn, 'gecos_ws_mgmt_connectivity[gcc_connectivity]', :immediately
end

gecos_ws_mgmt_debug_mode "debug mode" do
  expire_datetime node[:gecos_ws_mgmt][:single_node][:debug_mode_res][:expire_datetime]
  enable_debug node[:gecos_ws_mgmt][:single_node][:debug_mode_res][:enable_debug]
  job_ids node[:gecos_ws_mgmt][:single_node][:debug_mode_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:single_node][:debug_mode_res][:support_os]
  action :setup
end
