#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: system_proxy
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

require 'chef/mixin/shell_out'
require 'uri'
require 'fileutils'
include Chef::Mixin::ShellOut

# Constants
#DATE = DateTime.now.strftime("%Y-%m-%d")
DATE = DateTime.now.to_time.to_i.to_s
ROOT = '/var/lib/gecos-agent/network/proxy/'
CHANGED_FILES_OR_DIRECTORIES = [
    '/etc/environment', 
    '/etc/apt/apt.conf.d/',
    '/etc/dconf/',
    '/etc/firefox/',
    '/etc/thunderbird/'
]

# Regex pattern
BLOCK     = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
IP_REGX   = /\A#{BLOCK}\.#{BLOCK}\.#{BLOCK}\.#{BLOCK}\z/
HOST_REGX = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)+([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/

global_settings  = {}
mozilla_settings = {}
nochanges = true

# Checking if resource changed
action :presetup do

    Chef::Log.info("system_proxy.rb ::: Starting PRESETUP ...")
    
    begin

        if new_resource.support_os.include?($gecos_os)
            Chef::Log.info("system_proxy.rb ::: new_resource.global_config :#{new_resource.global_config}")
            Chef::Log.info("system_proxy.rb ::: new_resource.mozilla_config:#{new_resource.mozilla_config}")
            # SYSTEM GLOBAL CONFIG
            if not new_resource.global_config.empty?
            
                # Parameters and defaults
                global_settings = {
                  'http_proxy' => (new_resource.global_config['http_proxy'] || ''),
                  'http_proxy_port' => (new_resource.global_config['http_proxy_port'] || 80),
                  'https_proxy' => (new_resource.global_config['https_proxy'] || ''),
                  'https_proxy_port' => (new_resource.global_config['https_proxy_port'] || 443),
                  'proxy_autoconfig_url' => new_resource.global_config['proxy_autoconfig_url'],
                  'disable_proxy' => new_resource.global_config['disable_proxy']
                }
            
                # Checking params       
                http_uri = URI.parse(global_settings['http_proxy'])
                if http_uri.host.nil? # Bad url
                    # is ip? is hostname?
                    if global_settings['http_proxy'] =~ IP_REGX or global_settings['http_proxy'] =~ HOST_REGX
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
                    if global_settings['https_proxy'] =~ IP_REGX or  global_settings['https_proxy'] =~ HOST_REGX
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
                
                # Checking if there are changes between system and policy configuration
                system_http_proxy  = node['ohai_gecos']['envs']['HTTP_PROXY']  || ENV['HTTP_PROXY']  || ENV['http_proxy']  || ''
                system_https_proxy = node['ohai_gecos']['envs']['HTTPS_PROXY'] || ENV['HTTPS_PROXY'] || ENV['https_proxy'] || ''

                system_http_proxy_host  = URI.parse(system_http_proxy).host
                system_http_proxy_port  = URI.parse(system_http_proxy).port || 80
                system_https_proxy_host = URI.parse(system_https_proxy).host
                system_https_proxy_port = URI.parse(system_https_proxy).port || 443
                policy_http_proxy_host  = URI.parse(global_settings['http_proxy']).host
                policy_http_proxy_port  = global_settings['http_proxy_port']
                policy_https_proxy_host = URI.parse(global_settings['https_proxy']).host
                policy_https_proxy_port = global_settings['https_proxy_port']

                Chef::Log.debug("system_proxy.rb ::: system_http_proxy_host:  #{system_http_proxy_host}")                   
                Chef::Log.debug("system_proxy.rb ::: system_http_proxy_port:  #{system_http_proxy_port}")                   
                Chef::Log.debug("system_proxy.rb ::: system_https_proxy_host: #{system_https_proxy_host}")                   
                Chef::Log.debug("system_proxy.rb ::: system_https_proxy_port: #{system_https_proxy_port}")                   
                Chef::Log.debug("system_proxy.rb ::: policy_http_proxy_host:  #{policy_http_proxy_host}")                   
                Chef::Log.debug("system_proxy.rb ::: policy_http_proxy_port:  #{policy_http_proxy_port}")                   
                Chef::Log.debug("system_proxy.rb ::: policy_https_proxy_host: #{policy_https_proxy_host}")                   
                Chef::Log.debug("system_proxy.rb ::: policy_https_proxy_port: #{policy_https_proxy_port}")                   

                nochanges = system_http_proxy_host  == policy_http_proxy_host  &&
                            system_http_proxy_port  == policy_http_proxy_port  &&
                            system_https_proxy_host == policy_https_proxy_host &&
                            system_https_proxy_port == policy_https_proxy_port 

                Chef::Log.debug("system_proxy.rb ::: nochanges: #{nochanges}")                   
            end
            
            # MOZILLA APPS CONFIG
            if not new_resource.mozilla_config.empty?

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
                        'http_proxy' => (new_resource.mozilla_config['http_proxy'] || ''),
                        'http_proxy_port' => (new_resource.mozilla_config['http_proxy_port'] || 80),
                        'https_proxy' => (new_resource.mozilla_config['https_proxy'] || ''),
                        'https_proxy_port' => (new_resource.mozilla_config['https_proxy_port'] || 443),
                      }

                      # Checking params
                      moz_http_uri = URI.parse(mozilla_settings['http_proxy'])           
                      if moz_http_uri.host.nil?      
                          if mozilla_settings['http_proxy'] =~ IP_REGX or  mozilla_settings['http_proxy'] =~ HOST_REGX
                              mozilla_settings['http_proxy'] = "http://".concat(mozilla_settings['http_proxy'])
                          elsif not mozilla_settings['http_proxy'].empty?
                              raise "Mozilla: http_proxy URL or Hostname not valid"
                          end
                      elsif moz_http_uri.scheme =~ /https/
                          mozilla_settings['http_proxy'] = "http://".concat(moz_http_uri.host)          
                      end
                
                      moz_https_uri = URI.parse(mozilla_settings['https_proxy'])
                      if moz_https_uri.host.nil?      
                          if mozilla_settings['https_proxy'] =~ IP_REGX or mozilla_settings['https_proxy'] =~ HOST_REGX
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
                            
                    when "AUTOMATIC" 
                      mozilla_settings = {
                        'mode' => 2,
                        'proxy_autoconfig_url' => new_resource.mozilla_config['proxy_autoconfig_url']
                      }
                end
                
                mozilla_settings['no_proxies_on'] = new_resource.mozilla_config['no_proxies_on']
                Chef::Log.debug("system_proxy.rb - mozilla_settings: #{mozilla_settings}")
            end
                
            if (nochanges && node.normal['gcc_link']) || (!nochanges && !node.override['gcc_link'])
                job_ids = new_resource.job_ids
                job_ids.each do |jid|
                    node.normal['job_status'][jid]['status'] = 0
                end

                gecos_ws_mgmt_jobids "network_res" do
                    recipe "network_mgmt"
                end.run_action(:reset)

                new_resource.updated_by_last_action(false)
            else
                gecos_ws_mgmt_connectivity 'proxy_backup' do
                    action :nothing
                    #only_if {not nochanges}
                end.run_action(:backup)
                            
                action_setup
            end

        else
            Chef::Log.info("This resource is not support into your OS")
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
            recipe "network_mgmt"
        end.run_action(:reset)
    end
end

action :setup do

    Chef::Log.info("system_proxy.rb ::: Starting SETUP ... Applying new settings")

    begin

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

        # save current job ids (new_resource.job_ids) as "ok"
        job_ids = new_resource.job_ids
        job_ids.each do |jid|
            node.normal['job_status'][jid]['status'] = 0
        end

        # NOTIFICATIONS
        # Do notify the connectivity resource to test the connection                               
        new_resource.updated_by_last_action(true)
        
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
            recipe "network_mgmt"
        end.run_action(:reset)
    end
end

action :warn do
   job_ids = new_resource.job_ids
   job_ids.each do |jid|
       node.normal['job_status'][jid]['status'] = 2
       node.normal['job_status'][jid]['message'] = "Network problems connecting to Control Center."
       Chef::Log.debug("network.rb ::: recovery action - jid = #{jid}")
   end
end
