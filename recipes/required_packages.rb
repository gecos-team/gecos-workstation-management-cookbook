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
  'cert' => ['p11-kit'],
  'software_sources' => ['gecosws-repository-compatibility'],
  'folder_sync' => ['owncloud-client'],
  'chef' => ['chef'],
  'tz_date' => ['ntpdate'],
  'idle_timeout' => %w[zenity xautolock],
  'desktop_background' => ['dconf-tools'],
  'printers' => %w[printer-driver-gutenprint foomatic-db foomatic-db-engine
                   foomatic-db-gutenprint smbclient],
  'folder_sharing' => ['samba'],
  'mimetypes' => ['xdg-utils'],
  'power_conf' => %w[cpufrequtils powernap],
  'web_browser' => %w[ruby-sqlite3 libsqlite3-dev unzip xmlstarlet],
  'shutdown_options' => ['dconf-tools'],
  'user_alerts' => ['libnotify-bin'],
  'local_users' => ['libshadow-ruby1.8'],
  'email_setup' => ['thunderbird-locale-' + ($locale.sub! '_', '-'), 'xvfb'],
  'im_client' => ['pidgin', 'libxml2-dev'],
  'auto_updates' => ['moreutils']
}

# Platform dependencies
case $gecos_os
when 'GECOS V2'
  $required_pkgs['folder_sharing'].push('nemo-share')

when 'GECOS V3'
  $required_pkgs['folder_sharing'].push('nemo-share')

when 'GECOS V4'
  $required_pkgs['local_users'] = ['ruby-shadow']
  $required_pkgs['printers'].delete('foomatic-db-gutenprint')

end
