#
# Cookbook Name:: gecos_ws_mgmt
# Recipe:: required_packages
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

# Commons
$required_pkgs = {
  'cert_res' => ['libnss3-tools'],
  'software_sources_res' => ['gecosws-repository-compatibility'],
  'folder_sync_res' => ['owncloud-client'],
  'chef_conf_res' => ['chef'],
  'tz_date_res' => ['ntpdate'],
  'idle_timeout' => ['zenity','xautolock'],
  'desktop_background_res' => ['dconf-tools'],
  'printers_res' => ['printer-driver-gutenprint', 'foomatic-db', 'foomatic-db-engine', 'foomatic-db-gutenprint', 'smbclient'],
  'folder_sharing_res' => ['samba'],
  'mimetypes_res' => ['xdg-utils'],
  'power_conf_res' => ['cpufrequtils','powernap'],
  'sssd_res' => ['sssd'],
  'web_browser_res' => ['libsqlite3-dev', 'unzip','xmlstarlet'],
  'shutdown_options_res' => ['dconf-tools'],
  'user_alerts_res' => ['libnotify-bin'],
  'local_users_res' => ['libshadow-ruby1.8']
}

# Platform dependencies
case $gecos_os
  when "GECOS V2"
    $required_pkgs['folder_sharing_res'].push('nemo-share')

  when "Gecos V2 Lite"

  when "GECOS Kiosk"

  when "GECOS V3" 
    $required_pkgs['folder_sharing_res'].push('nemo-share')

  when "GECOS V3 Lite"

  when "Ubuntu 14.04.1 LTS"

  when "GECOS V4"

  when "GECOS V4 Lite"
 
  else
    Chef::Log.info("This resource is not support into your OS")
end
