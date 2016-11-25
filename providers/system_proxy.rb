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
require 'uri'
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
        
        # Defaults
        global_settings['http_proxy'] ||= ''
        global_settings['http_proxy_port'] ||= 80
        global_settings['https_proxy'] ||= ''
        global_settings['https_proxy_port'] ||= 443

        # Regex pattern
        block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
        ValidIpAddressRegex = /\A#{block}\.#{block}\.#{block}\.#{block}\z/
        ValidHostnameRegex  = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)+([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/
        
        # Checking params:        
        http_uri = URI.parse(global_settings['http_proxy'])
        if http_uri.host.nil? # Bad url
            # is ipaddress? is hostname?
            if global_settings['http_proxy'] =~ ValidIpAddressRegex or global_settings['http_proxy'] =~ ValidHostnameRegex
              global_settings['http_proxy'] = "http://".concat(global_settings['http_proxy'])
            # Bad param
            elsif not global_settings['http_proxy'].empty?
              raise "System Wide: http_proxy URL or Hostname not valid"
            end
        # Bad scheme
        elsif http_uri.scheme =~ /https/
          global_settings['http_proxy'] = "http://".concat(http_uri.host)
        end
        
        https_uri = URI.parse(global_settings['https_proxy'])
        if https_uri.host.nil?  
            if global_settings['https_proxy'] =~ ValidIpAddressRegex or  global_settings['https_proxy'] =~ ValidHostnameRegex
              global_settings['https_proxy'] = "https://".concat(global_settings['https_proxy'])
            elsif not global_settings['https_proxy'].empty?
              raise "System Wide: https_proxy URL or Hostname not valid"
            end
        elsif https_uri.scheme =~ /http/
          global_settings['https_proxy'] = "https://".concat(https_uri.host)
        end        
                
        # Remove trailing slash
        global_settings['http_proxy']  = global_settings['http_proxy'].chomp('/')  unless global_settings['http_proxy'].empty?
        global_settings['https_proxy'] = global_settings['https_proxy'].chomp('/') unless global_settings['https_proxy'].empty?       
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
              value     URI.parse(global_settings['http_proxy']).host
              only_if   {!global_settings['http_proxy'].empty?}
            end.run_action(:set)

            gecos_ws_mgmt_system_settings "System-Wide HTTP Proxy PORT" do
              provider "gecos_ws_mgmt_system_settings"
              schema   "system/proxy/http"
              name     "port"
              value     global_settings['http_proxy_port']
              only_if   {!global_settings['http_proxy'].empty?}
            end.run_action(:set)

            gecos_ws_mgmt_system_settings "System-Wide HTTPS Proxy" do
              provider "gecos_ws_mgmt_system_settings"
              schema  "system/proxy/https"
              name    "host"
              value    URI.parse(global_settings['https_proxy']).host
              only_if {!global_settings['https_proxy'].empty?}
            end.run_action(:set)

            gecos_ws_mgmt_system_settings "System-Wide HTTPS Proxy PORT" do
              provider "gecos_ws_mgmt_system_settings"
              schema  "system/proxy/https"
              name    "port"
              value    global_settings['https_proxy_port']
              only_if {!global_settings['https_proxy'].empty?}
            end.run_action(:set)
            
            # ENVIRONMENT
            ruby_block "Add proxy environment variables" do
              block do
                http_proxy  = "HTTP_PROXY=#{global_settings['http_proxy']}:#{global_settings['http_proxy_port']}"
                https_proxy = "HTTPS_PROXY=#{global_settings['https_proxy']}:#{global_settings['https_proxy_port']}"
                
                fe = Chef::Util::FileEdit.new("/etc/environment")
                fe.search_file_replace_line(/HTTP_PROXY/i, http_proxy)
                fe.search_file_replace_line(/HTTPS_PROXY/i, https_proxy)
                fe.write_file
                fe.insert_line_if_no_match(/HTTP_PROXY/i, http_proxy)
                fe.write_file
                fe.insert_line_if_no_match(/HTTPS_PROXY/i, https_proxy)
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
        
        # Defaults
        mozilla_settings['http_proxy'] ||= ''
        mozilla_settings['http_proxy_port'] ||= 80
        mozilla_settings['https_proxy'] ||= ''
        mozilla_settings['https_proxy_port'] ||= 443

        # Checking params
        moz_http_uri = URI.parse(mozilla_settings['http_proxy'])
        if moz_http_uri.host.nil?      
            if mozilla_settings['http_proxy'] =~ ValidIpAddressRegex or  mozilla_settings['http_proxy'] =~ ValidHostnameRegex
              mozilla_settings['http_proxy'] = "http://".concat(mozilla_settings['http_proxy'])
            elsif not mozilla_settings['http_proxy'].empty?
              raise "Mozilla: http_proxy URL or Hostname not valid"
            end
        elsif moz_http_uri.scheme =~ /https/
          mozilla_settings['http_proxy'] = "http://".concat(moz_http_uri.host)          
        end
        
        moz_https_uri = URI.parse(mozilla_settings['https_proxy'])
        if moz_https_uri.host.nil?      
            if mozilla_settings['https_proxy'] =~ ValidIpAddressRegex or mozilla_settings['https_proxy'] =~ ValidHostnameRegex
              mozilla_settings['https_proxy'] = "https://".concat(mozilla_settings['https_proxy'])
            elsif not mozilla_settings['https_proxy'].empty?
              raise "Mozilla: https_proxy URL or Hostname not valid"
            end
        elsif moz_https_uri.scheme =~ /http/
          mozilla_settings['https_proxy'] = "https://".concat(moz_https_uri.host)
        end
        
        # Remove trailing slash
        mozilla_settings['http_proxy']  = mozilla_settings['http_proxy'].chomp('/')   unless mozilla_settings['http_proxy'].empty?
        mozilla_settings['https_proxy'] = mozilla_settings['https_proxy'].chomp('/')  unless mozilla_settings['http_proxy'].empty?
        Chef::Log.debug("system_proxy.rb - mozilla_settings: #{mozilla_settings}")

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
