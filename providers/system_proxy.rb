#
### Cookbook Name:: gecos-ws-mgmt
### Provider:: system_proxy
###
### Copyright 2013, Junta de Andalucia
### http://www.juntadeandalucia.es/
###
### All rights reserved - EUPL License V 1.1
### http://www.osor.eu/eupl
###

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :setup do

  begin
  
    if new_resource.support_os.include?($gecos_os)

      # GLOBAL CONFIG
      if not new_resource.global_config.empty?

        # Parameters
        global_settings = {
          'http_proxy' => new_resource.global_config['http_proxy'],
          'http_proxy_port' => new_resource.global_config['http_proxy_port'],
          'https_proxy' => new_resource.global_config['https_proxy'],
          'https_proxy_port' => new_resource.global_config['https_proxy_port'],
          'proxy_autoconfig_url' => new_resource.global_config['proxy_autoconfig_url'],
          'disable_proxy' => new_resource.global_config['disable_proxy']
        }

        # Checking params
        if !(global_settings['http_proxy'].nil? || global_settings['http_proxy'].include?('http://'))
           global_settings['http_proxy'] = 'http://'.concat(global_settings['http_proxy'])
        end

        if !(global_settings['https_proxy'].nil? || global_settings['https_proxy'].include?('https://'))
           global_settings['https_proxy'] = 'https://'.concat(global_settings['https_proxy'])
        end
        global_settings['http_proxy'] ||= ''
        global_settings['http_proxy_port'] ||= 0
        global_settings['https_proxy'] ||= ''
        global_settings['https_proxy_port'] ||= 0
        Chef::Log.debug("system_proxy.rb - global_settings:#{global_settings}")

        if not global_settings['disable_proxy'] 

          # DESKTOP APPLICATIONS
          if global_settings['proxy_autoconfig_url'].nil? || global_settings['proxy_autoconfig_url'].empty?
          
            Chef::Log.debug("system_proxy.rb - System-Wide Proxy Mode Manual")
            gecos_ws_mgmt_system_settings "System-Wide Proxy Mode" do
              provider "gecos_ws_mgmt_system_settings"
              schema   "system/proxy"
              name     "mode"
              value    "manual"
            end.run_action(:set)

            gecos_ws_mgmt_system_settings "System-Wide HTTP Proxy" do
              provider "gecos_ws_mgmt_system_settings"
              schema   "system/proxy/http"
              name     "host"
              value     global_settings['http_proxy']
            end.run_action(:set)

            gecos_ws_mgmt_system_settings "System-Wide HTTP Proxy PORT" do
              provider "gecos_ws_mgmt_system_settings"
              schema   "system/proxy/http"
              name     "port"
              value     global_settings['http_proxy_port']
            end.run_action(:set)

            gecos_ws_mgmt_system_settings "System-Wide HTTPS Proxy" do
              provider "gecos_ws_mgmt_system_settings"
              schema  "system/proxy/https"
              name    "host"
              value    global_settings['https_proxy']
            end.run_action(:set)

            gecos_ws_mgmt_system_settings "System-Wide HTTPS Proxy PORT" do
              provider "gecos_ws_mgmt_system_settings"
              schema  "system/proxy/https"
              name    "port"
              value    global_settings['https_proxy_port']
            end.run_action(:set)

            # ENVIRONMENT
            ruby_block "Add proxy environment variables" do
              block do
                fe = Chef::Util::FileEdit.new("/etc/environment")
                fe.search_file_replace_line(/HTTP_PROXY/i,"HTTP_PROXY=\"#{global_settings['http_proxy']}:#{global_settings['http_proxy_port']}\"")
                fe.search_file_replace_line(/HTTPS_PROXY/i,"HTTPS_PROXY=\"#{global_settings['https_proxy']}:#{global_settings['https_proxy_port']}\"")
                fe.write_file
                fe.insert_line_if_no_match(/HTTP_PROXY/i,"HTTP_PROXY=\"#{global_settings['http_proxy']}:#{global_settings['http_proxy_port']}\"")
                fe.write_file
                fe.insert_line_if_no_match(/HTTPS_PROXY/i,"HTTPS_PROXY=\"#{global_settings['https_proxy']}:#{global_settings['https_proxy_port']}\"")
                fe.write_file
                fe.search_file_delete_line(/HTTP_PROXY/i) if global_settings['http_proxy'].empty?
                fe.search_file_delete_line(/HTTPS_PROXY/i) if global_settings['https_proxy'].empty?
                fe.write_file
              end
              action :nothing
            end.run_action(:run)

            # APT
            template "/etc/apt/apt.conf.d/80proxy" do
              source "apt_proxy.erb"
              variables(
                 :proxy_settings => global_settings
              )
               action :nothing
            end.run_action(:create)

          else # PROXY AUTOCONFIG URL (PAC)
            Chef::Log.debug("system_proxy.rb - System-Wide Proxy Autoconfig URL")

            gecos_ws_mgmt_system_settings "System-Wide Proxy Mode" do
              provider "gecos_ws_mgmt_system_settings"
              schema   "system/proxy"
              name     "mode"
              value    "auto"
            end.run_action(:set)

            gecos_ws_mgmt_system_settings "System-Wide Proxy Autoconfig URL" do
              provider "gecos_ws_mgmt_system_settings"
              schema   "system/proxy"
              name     "autoconfig-url"
              value   global_settings['proxy_autoconfig_url']
            end.run_action(:set)

          end

      elsif global_settings['disable_proxy']

        # DESKTOP APPLICATIONS
        gecos_ws_mgmt_system_settings "System-Wide Proxy Mode [:unset]" do
          provider "gecos_ws_mgmt_system_settings"
          schema   "system/proxy"
          name     "mode"
          value    "none"
         end.run_action(:unset)

        gecos_ws_mgmt_system_settings "System-Wide HTTP Proxy [:unset]" do
          provider "gecos_ws_mgmt_system_settings"
          schema   "system/proxy/http"
          name     "host"
          value   global_settings['http_proxy']
         end.run_action(:unset)
                                                       
        gecos_ws_mgmt_system_settings "System-Wide HTTP Proxy PORT [:unset]" do
          provider "gecos_ws_mgmt_system_settings"
          schema   "system/proxy/http"
          name     "port"
          value     global_settings['http_proxy_port']
        end.run_action(:unset)

        gecos_ws_mgmt_system_settings "System-Wide HTTPS Proxy [:unset]" do
          provider "gecos_ws_mgmt_system_settings"
          schema   "system/proxy/https"
          name     "host"
          value     global_settings['https_proxy']
        end.run_action(:unset)

        gecos_ws_mgmt_system_settings "System-Wide HTTPS Proxy PORT [:unset]" do
          provider "gecos_ws_mgmt_system_settings"
          schema  "system/proxy/https"
          name    "port"
          value    global_settings['https_proxy_port']
        end.run_action(:unset)

        gecos_ws_mgmt_system_settings "System-Wide Proxy Autoconfig URL [:unset]" do
          provider "gecos_ws_mgmt_system_settings"
          schema  "system/proxy"
          name    "autoconfig-url"
          value    global_settings['proxy_autoconfig_url']
        end.run_action(:unset)

        # ENVIRONMENT
         ruby_block "Delete proxy environment variables" do
           block do
             fe = Chef::Util::FileEdit.new("/etc/environment")
             fe.search_file_delete_line(/HTTPS?_PROXY/i)
            fe.write_file
           end
           action :nothing
        end.run_action(:run)

        file "/etc/apt/apt.conf.d/80proxy" do
          action :nothing
        end.run_action(:delete)
        
      end
      
    end
      
    # MOZILLA APPS CONFIG
      if not new_resource.mozilla_config.empty?

        mozilla_settings = {}
        case new_resource.mozilla_config['mode']

          when "NO PROXY"            
            mozilla_settings['mode'] = 0                     
          when "AUTODETECT"
            mozilla_settings['mode'] = 4          
          when "SYSTEM"
            mozilla_settings['mode'] = 5
          when "MANUAL"
            mozilla_settings = {
              'mode' => 1,
              'http_proxy' => new_resource.mozilla_config['http_proxy'],
              'http_proxy_port' => new_resource.mozilla_config['http_proxy_port'],
              'https_proxy' => new_resource.mozilla_config['https_proxy'],
              'https_proxy_port' => new_resource.mozilla_config['https_proxy_port'],
            }
          when "AUTOMATIC" 
            mozilla_settings = {
              'mode' => 2,
              'proxy_autoconfig_url' => new_resource.mozilla_config['proxy_autoconfig_url']
            }
        end
        mozilla_settings['no_proxies_on'] = new_resource.mozilla_config['no_proxies_on']

        # Checking params
        if !(mozilla_settings['http_proxy'].nil? || mozilla_settings['http_proxy'].include?('http://'))
          mozilla_settings['http_proxy'] = 'http://'.concat(mozilla_settings['http_proxy'])
        end

        if !(mozilla_settings['https_proxy'].nil? || mozilla_settings['https_proxy'].include?('https://'))
          mozilla_settings['https_proxy'] = 'https://'.concat(mozilla_settings['https_proxy'])
        end

        Chef::Log.debug("system_proxy.rb - Mozilla_settings: #{mozilla_settings}")

        # FIREFOX
        gecos_ws_mgmt_appconfig_firefox "Firefox proxy configuration" do
           provider "gecos_ws_mgmt_appconfig_firefox"
           config_firefox mozilla_settings
          job_ids new_resource.job_ids
          support_os new_resource.support_os
        end.run_action(:setup)

        # THUNDERBIRD
        gecos_ws_mgmt_appconfig_thunderbird "Thunderbird proxy configuration" do
          provider "gecos_ws_mgmt_appconfig_thunderbird"
          config_thunderbird mozilla_settings
          job_ids new_resource.job_ids
          support_os new_resource.support_os
        end.run_action(:setup)

      end

    else
      Chef::Log.info("Your operative system does not support this resource")
    end

    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 0
    end

  rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e.message)
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 1
      if not e.message.frozen?
        node.normal['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
      else
        node.normal['job_status'][jid]['message'] = e.message
      end
    end
  ensure
    
    gecos_ws_mgmt_jobids "system_proxy_res" do
       recipe "software_mgmt"
    end.run_action(:reset)
    
   end
end
