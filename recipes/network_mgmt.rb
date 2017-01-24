#
# Cookbook Name:: gecos-ws-mgmt
# Recipe:: network_management
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

gecos_ws_mgmt_connectivity 'gcc_connectivity' do
  action :nothing
  #target 'www.google.es'
  notifies :recovery, 'gecos_ws_mgmt_connectivity[gcc_connectivity]', :immediately
end

gecos_ws_mgmt_system_proxy 'proxyconf' do
  global_config node[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][:global_config]
  mozilla_config node[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][:mozilla_config]
  force node[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][:force]
  job_ids node[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][:support_os]
  action :presetup  
# Chef 12: notifies :backup, 'gecos_ws_mgmt_connectivity[gcc_connectivity]', :before
# Chef 11: invalid timing :before.  Valid timings are: :delayed, :immediate, :immediately
  notifies :test, 'gecos_ws_mgmt_connectivity[gcc_connectivity]', :immediately
  subscribes :warn, 'gecos_ws_mgmt_connectivity[gcc_connectivity]', :immediately
end

gecos_ws_mgmt_forticlientvpn 'configure vpn connections for all users' do
  job_ids node[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][:support_os]
  action  :setup
end

gecos_ws_mgmt_mobile_broadband "nm mobile broadband" do
  connections node[:gecos_ws_mgmt][:network_mgmt][:mobile_broadband_res][:connections]
  job_ids node[:gecos_ws_mgmt][:network_mgmt][:mobile_broadband_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:network_mgmt][:mobile_broadband_res][:support_os]
  action  :setup
end

gecos_ws_mgmt_network "localhost" do
  connections node[:gecos_ws_mgmt][:network_mgmt][:network_res][:connections]
  job_ids node[:gecos_ws_mgmt][:network_mgmt][:network_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:network_mgmt][:network_res][:support_os]
  action  :presetup
  notifies :test, 'gecos_ws_mgmt_connectivity[gcc_connectivity]', :immediately
  subscribes :warn, 'gecos_ws_mgmt_connectivity[gcc_connectivity]', :immediately
end
