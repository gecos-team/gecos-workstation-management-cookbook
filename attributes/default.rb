#
# Cookbook Name:: gecos-ws-mgmt
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
ALL_GECOS_VERS = ['GECOS V4', 'GECOS V3', 'GECOS V2', 'GECOS V3 Lite',
                  'Gecos V2 Lite'].freeze
UBUNTU_BASED = ['GECOS V4', 'GECOS V3', 'GECOS V2', 'GECOS V3 Lite', 'Gecos V2 Lite',
                'Ubuntu 14.04.1 LTS'].freeze
GECOS_FULL = ['GECOS V4', 'GECOS V3', 'GECOS V2'].freeze

default[:gecos_ws_mgmt][:single_node][:network_res][:job_ids] = []
default[:gecos_ws_mgmt][:single_node][:network_res][
  :support_os] = ALL_GECOS_VERS
default[:gecos_ws_mgmt][:single_node][:network_res][:connections] = []

default[:gecos_ws_mgmt][:single_node][:debug_mode_res][:job_ids] = []
default[:gecos_ws_mgmt][:single_node][:debug_mode_res][
  :support_os] = ALL_GECOS_VERS
default[:gecos_ws_mgmt][:single_node][:debug_mode_res][:enable_debug] = false
default[:gecos_ws_mgmt][:single_node][:debug_mode_res][:expire_datetime] = ''


default[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][:global_config] = {}
default[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][:mozilla_config] = {}
default[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][:job_ids] = []
default[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][:updated_by] = {}
default[:gecos_ws_mgmt][:network_mgmt][:system_proxy_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][:proxyserver] = ''
default[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][:proxyport] = ''
default[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][:proxyuser] = ''
default[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][:keepalive] = 0
default[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][:autostart] = false
default[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][:connections] = []
default[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][:job_ids] = []
default[:gecos_ws_mgmt][:network_mgmt][:forticlientvpn_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:network_mgmt][:mobile_broadband_res][:job_ids] = []
default[:gecos_ws_mgmt][:network_mgmt][:mobile_broadband_res][:connections] = []
default[:gecos_ws_mgmt][:network_mgmt][:mobile_broadband_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][:repo_list] = []
default[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][:job_ids] = []
default[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][:updated_by] = {}
default[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:software_mgmt][:package_res][:package_list] = []
default[:gecos_ws_mgmt][:software_mgmt][:package_res][:job_ids] = []
default[:gecos_ws_mgmt][:software_mgmt][:package_res][:updated_by] = {}
default[:gecos_ws_mgmt][:software_mgmt][:package_res][
  :support_os] = UBUNTU_BASED

default[:gecos_ws_mgmt][:software_mgmt][:appconfig_libreoffice_res][
  :config_libreoffice] = {}
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_libreoffice_res][
  :job_ids] = []
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_libreoffice_res][
  :updated_by] = {}
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_libreoffice_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:software_mgmt][:appconfig_thunderbird_res][
  :config_thunderbird] = {}
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_thunderbird_res][
  :job_ids] = []
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_thunderbird_res][
  :updated_by] = {}
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_thunderbird_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:software_mgmt][:appconfig_firefox_res][
  :config_firefox] = {}
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_firefox_res][:job_ids] = []
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_firefox_res][
  :updated_by] = {}
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_firefox_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:software_mgmt][:appconfig_java_res][:config_java] = {}
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_java_res][:job_ids] = []
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_java_res][:updated_by] = {}
default[:gecos_ws_mgmt][:software_mgmt][:appconfig_java_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][:dm] = ''
default[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][
  :autologin] = false
default[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][
  :autologin_options] = {}
default[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][:job_ids] = []
default[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][:updated_by] = {}
default[:gecos_ws_mgmt][:software_mgmt][:display_manager_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:printers_mgmt][:printers_res][:printers_list] = []
default[:gecos_ws_mgmt][:printers_mgmt][:printers_res][:job_ids] = []
default[:gecos_ws_mgmt][:printers_mgmt][:printers_res][:updated_by] = {}
default[:gecos_ws_mgmt][:printers_mgmt][:printers_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:auto_updates_res][:auto_updates_rules][
  :onstop_update] = false
default[:gecos_ws_mgmt][:misc_mgmt][:auto_updates_res][:auto_updates_rules][
  :onstart_update] = false
default[:gecos_ws_mgmt][:misc_mgmt][:auto_updates_res][:auto_updates_rules][
  :days] = []
default[:gecos_ws_mgmt][:misc_mgmt][:auto_updates_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:auto_updates_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:auto_updates_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:boot_lock_res][:lock_boot] = false
default[:gecos_ws_mgmt][:misc_mgmt][:boot_lock_res][:unlock_user] = ''
default[:gecos_ws_mgmt][:misc_mgmt][:boot_lock_res][:unlock_pass] = ''
default[:gecos_ws_mgmt][:misc_mgmt][:boot_lock_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:boot_lock_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:boot_lock_res][:support_os] = UBUNTU_BASED

default[:gecos_ws_mgmt][:misc_mgmt][:tz_date_res][:server] = ''
default[:gecos_ws_mgmt][:misc_mgmt][:tz_date_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:tz_date_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:tz_date_res][:support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:power_conf_res][:cpu_freq_gov] = ''
default[:gecos_ws_mgmt][:misc_mgmt][:power_conf_res][:auto_shutdown] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:power_conf_res][:usb_autosuspend] = ''
default[:gecos_ws_mgmt][:misc_mgmt][:power_conf_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:power_conf_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:power_conf_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:local_users_res][:users_list] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_users_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_users_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:local_users_res][
  :support_os] = ALL_GECOS_VERS
default[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][:localfiles] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:scripts_launch_res][:on_startup] = []
default[:gecos_ws_mgmt][:misc_mgmt][:scripts_launch_res][:on_shutdown] = []
default[:gecos_ws_mgmt][:misc_mgmt][:scripts_launch_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:scripts_launch_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:scripts_launch_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:local_groups_res][:groups_list] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_groups_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_groups_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:local_groups_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:local_admin_users_res][
  :local_admin_list] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_admin_users_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_admin_users_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:local_admin_users_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:cert_res][:java_keystores] = []
default[:gecos_ws_mgmt][:misc_mgmt][:cert_res][:ca_root_certs] = []
default[:gecos_ws_mgmt][:misc_mgmt][:cert_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:cert_res][:updated_by] = {}
default[:gecos_ws_mgmt][:misc_mgmt][:cert_res][:support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:user_apps_autostart_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:user_apps_autostart_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:user_apps_autostart_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:user_shared_folders_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:user_shared_folders_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:user_shared_folders_res][
  :support_os] = GECOS_FULL

default[:gecos_ws_mgmt][:users_mgmt][:web_browser_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:web_browser_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:web_browser_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:email_setup_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:email_setup_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:email_setup_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:im_client_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:im_client_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:im_client_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:file_browser_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:file_browser_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:file_browser_res][
  :support_os] = GECOS_FULL

default[:gecos_ws_mgmt][:users_mgmt][:desktop_background_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:desktop_background_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:desktop_background_res][
  :support_os] = GECOS_FULL

default[:gecos_ws_mgmt][:users_mgmt][:user_launchers_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:user_launchers_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:user_launchers_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:folder_sharing_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:folder_sharing_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:folder_sharing_res][
  :support_os] = GECOS_FULL

default[:gecos_ws_mgmt][:users_mgmt][:screensaver_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:screensaver_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:screensaver_res][:support_os] = GECOS_FULL

default[:gecos_ws_mgmt][:users_mgmt][:user_mount_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:user_mount_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:user_mount_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:user_modify_nm_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:user_modify_nm_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:user_modify_nm_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:folder_sync_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:folder_sync_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:folder_sync_res][
  :support_os] = GECOS_FULL

default[:gecos_ws_mgmt][:users_mgmt][:shutdown_options_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:shutdown_options_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:shutdown_options_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:user_alerts_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:user_alerts_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:user_alerts_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:mimetypes_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:mimetypes_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:mimetypes_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:users_mgmt][:idle_timeout_res][:users] = {}
default[:gecos_ws_mgmt][:users_mgmt][:idle_timeout_res][:job_ids] = []
default[:gecos_ws_mgmt][:users_mgmt][:idle_timeout_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:remote_shutdown_res][:shutdown_mode] = ''
default[:gecos_ws_mgmt][:misc_mgmt][:remote_shutdown_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:remote_shutdown_res][
  :support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:ttys_res][:disable_ttys] = false
default[:gecos_ws_mgmt][:misc_mgmt][:ttys_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:ttys_res][:support_os] = ALL_GECOS_VERS

default[:gecos_ws_mgmt][:misc_mgmt][:remote_control_res][:job_ids] = []
default[:gecos_ws_mgmt][:misc_mgmt][:remote_control_res][
  :support_os] = ALL_GECOS_VERS
default[:gecos_ws_mgmt][:misc_mgmt][:remote_control_res][:enable_helpchannel] = false
default[:gecos_ws_mgmt][:misc_mgmt][:remote_control_res][:enable_ssh] = false
default[:gecos_ws_mgmt][:misc_mgmt][:remote_control_res][:ssl_verify] = true
# tunnel_url and known_message moved to remote_control data_bag
#default[:gecos_ws_mgmt][:misc_mgmt][:remote_control_res][:tunnel_url] = ''
#default[:gecos_ws_mgmt][:misc_mgmt][:remote_control_res][:known_message] = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
