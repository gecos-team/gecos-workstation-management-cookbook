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

gecos_ws_mgmt_sssd node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:domain] do
  enabled node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:enabled]
  job_ids node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:job_ids]
  action  :setup
end

#if not node[:gecos_ws_mgmt][:network_mgmt][:sssd_res].nil?
#  domain_name='ldap_conf'
#  if node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:domain].nil?
#    domain_name=node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:domain]
#  end
#  d_list = [{"domain_name"=>domain_name,
#    "type"=>node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:auth_type],
#    "ldap_uri"=>node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:uri],
#    "search_base"=>node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:base],
#    "basegroup"=>node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:basegroup],
#    "binddn"=>node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:binddn],
#    "bindpwd"=>node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:bindpwd]
#    }]
#  gecos_ws_mgmt_sssd 'configure_sssd' do
#    domain_list d_list
#    enabled node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:enabled]
#    workgroup node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:workgroup]
#    job_ids node[:gecos_ws_mgmt][:network_mgmt][:sssd_res][:job_ids]
#    action  :setup
#  end
#end