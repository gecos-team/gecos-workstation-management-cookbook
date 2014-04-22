#
# Cookbook Name:: gecos-ws-mgmt
# Recipe:: local
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
include_recipe "gecos_ws_mgmt::sssd_mgmt"

gecos_ws_mgmt_tz_date 'localtime' do
  server node[:gecos_ws_mgmt][:misc_mgmt][:tz_date_res][:server]
  job_ids node[:gecos_ws_mgmt][:misc_mgmt][:tz_date_res][:job_ids]
  action :setup
end

