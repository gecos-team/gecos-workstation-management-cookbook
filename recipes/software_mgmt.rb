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

gecos_ws_mgmt_software_sources 'apt sources list manage' do
  repo_list node[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][
    :repo_list]
  job_ids node[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][
    :support_os]
  action :setup
end

gecos_ws_mgmt_package 'install packages list' do
  package_list node[:gecos_ws_mgmt][:software_mgmt][:package_res][:package_list]
  job_ids node[:gecos_ws_mgmt][:software_mgmt][:package_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:software_mgmt][:package_res][:support_os]
  action :setup
end

gecos_ws_mgmt_appconfig_libreoffice 'libreoffice config' do
  config_libreoffice node[:gecos_ws_mgmt][:software_mgmt][
    :appconfig_libreoffice_res][:config_libreoffice]
  job_ids node[:gecos_ws_mgmt][:software_mgmt][:appconfig_libreoffice_res][
    :job_ids]
  support_os node[:gecos_ws_mgmt][:software_mgmt][:appconfig_libreoffice_res][
    :support_os]
  action :setup
end

gecos_ws_mgmt_appconfig_thunderbird 'thunderbird config' do
  config_thunderbird node[:gecos_ws_mgmt][:software_mgmt][
    :appconfig_thunderbird_res][:config_thunderbird]
  job_ids node[:gecos_ws_mgmt][:software_mgmt][:appconfig_thunderbird_res][
    :job_ids]
  support_os node[:gecos_ws_mgmt][:software_mgmt][:appconfig_thunderbird_res][
    :support_os]
  action :setup
end

gecos_ws_mgmt_appconfig_firefox 'firefox config' do
  config_firefox node[:gecos_ws_mgmt][:software_mgmt][:appconfig_firefox_res][
    :config_firefox]
  job_ids node[:gecos_ws_mgmt][:software_mgmt][:appconfig_firefox_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:software_mgmt][:appconfig_firefox_res][
    :support_os]
  action :setup
end

gecos_ws_mgmt_appconfig_java 'java config' do
  config_java node[:gecos_ws_mgmt][:software_mgmt][:appconfig_java_res][
    :config_java]
  job_ids node[:gecos_ws_mgmt][:software_mgmt][:appconfig_java_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:software_mgmt][:appconfig_java_res][
    :support_os]
  action :setup
end

gecos_ws_mgmt_display_manager 'display manager' do
  dm node[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][:dm]
  autologin node[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][
    :autologin]
  autologin_options node[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][
    :autologin_options]
  job_ids node[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][:job_ids]
  support_os node[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][
    :support_os]
  action :setup
end
