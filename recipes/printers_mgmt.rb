#
# Cookbook Name:: gecos-ws-mgmt
# Recipe:: printers_management
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

gecos_ws_mgmt_printers 'localhost' do
      repo_list node[:gecos_ws_mgmt][:printers_mgmt][:printers_res][:printer_list]
      jobs_id node[:gecos_ws_mgmt][:printers_mgmt][:printers_res][:jobs_id]
      action :setup
end

