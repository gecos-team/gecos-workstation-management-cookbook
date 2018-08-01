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
  'cert' => ['libnss3-tools'],
  'software_sources' => ['gecosws-repository-compatibility'],
  'folder_sync' => ['owncloud-client'],
  'chef' => ['chef'],
  'tz_date' => ['ntpdate'],
  'idle_timeout' => ['zenity','xautolock'],
  'desktop_background' => ['dconf-tools'],
  'printers' => ['printer-driver-gutenprint', 'foomatic-db', 'foomatic-db-engine', 'foomatic-db-gutenprint', 'smbclient'],
  'folder_sharing' => ['samba'],
  'mimetypes' => ['xdg-utils'],
  'power_conf' => ['cpufrequtils','powernap'],
  'sssd' => ['sssd'],
  'web_browser' => ['ruby-sqlite3','libsqlite3-dev', 'unzip','xmlstarlet'],
  'shutdown_options' => ['dconf-tools'],
  'user_alerts' => ['libnotify-bin'],
  'local_users' => ['libshadow-ruby1.8']
}

# Platform dependencies
case $gecos_os
  when "GECOS V2"
    $required_pkgs['folder_sharing'].push('nemo-share')

  when "Gecos V2 Lite"

  when "GECOS Kiosk"

  when "GECOS V3" 
    $required_pkgs['folder_sharing'].push('nemo-share')

  when "GECOS V3 Lite"

  when "Ubuntu 14.04.1 LTS"

  when "GECOS V4"

  when "GECOS V4 Lite"
 
  else
    Chef::Log.info("This resource is not support into your OS")
end
