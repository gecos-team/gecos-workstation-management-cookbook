default[:gecos_ws_mgmt][:network_mgmt][:network_res][:ip_address] = ''
default[:gecos_ws_mgmt][:network_mgmt][:network_res][:gateway] = ''
default[:gecos_ws_mgmt][:network_mgmt][:network_res][:netmask] = ''
default[:gecos_ws_mgmt][:network_mgmt][:network_res][:dns_servers] = []
default[:gecos_ws_mgmt][:network_mgmt][:network_res][:network_type] = 'wired'
default[:gecos_ws_mgmt][:network_mgmt][:network_res][:use_dhcp] = true
default[:gecos_ws_mgmt][:network_mgmt][:network_res][:users] = []
default[:gecos_ws_mgmt][:network_mgmt][:network_res][:job_ids] = []

default[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][:repo_list] = []
default[:gecos_ws_mgmt][:software_mgmt][:software_sources_res][:job_ids] = []

default[:gecos_ws_mgmt][:software_mgmt][:package_res] = {}

default[:gecos_ws_mgmt][:printers_mgmt][:printers_res][:printer_list] = []
default[:gecos_ws_mgmt][:printers_mgmt][:printers_res][:job_ids] = []

default[:gecos_ws_mgmt][:misc_mgmt][:auto_updates_res][:auto_updates_rules][:logout_update] = false
default[:gecos_ws_mgmt][:misc_mgmt][:auto_updates_res][:auto_updates_rules][:start_update] = false
default[:gecos_ws_mgmt][:misc_mgmt][:auto_updates_res][:auto_updates_rules][:days_update] = []
default[:gecos_ws_mgmt][:misc_mgmt][:tz_date_res][:server] = ""
default[:gecos_ws_mgmt][:misc_mgmt][:local_users_res][:users_list] =[]
default[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][:delete_files] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_file_res][:copy_files] = []
default[:gecos_ws_mgmt][:misc_mgmt][:scripts_launch_res][:scripts] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_groups_res][:groups_list] = []
default[:gecos_ws_mgmt][:misc_mgmt][:local_admin_users_res][:local_admin_list] = []

default[:gecos_ws_mgmt][:users_mgmt][:user_apps_autostart_res][:autostart_files] = []
