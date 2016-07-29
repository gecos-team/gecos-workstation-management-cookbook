#
### Cookbook Name:: gecos-ws-mgmt
### Provider:: pdf_viewer
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

			users = new_resource.users
			Chef::Log.debug("proxy.rb - users: #{users}")
      users.each_key do |user_key|
      	nameuser = user_key
    		username = nameuser.gsub('###','.')
				user = users[user_key]

				# Defaults
				proxy_settings = {
					'http_proxy' => user['http_proxy'],
					'http_proxy_port' => user['http_proxy_port'],
					'https_proxy' => user['https_proxy'],
					'https_proxy_port' => user['https_proxy_port'],
					'proxy_autoconfig_url' => user['proxy_autoconfig_url'],
					'disable_proxy' => user['disable_proxy']
				}
				Chef::Log.debug("proxy.rb - proxy_settings:#{proxy_settings}")

				# DESKTOP APPLICATIONS 
				if !proxy_settings['disable_proxy'] and proxy_settings['proxy_autoconfig_url'] == nil 
      		gecos_ws_mgmt_desktop_settings "proxy config manual mode" do
	      		provider "gecos_ws_mgmt_gsettings"
        		schema "org.gnome.system.proxy"
        		type "string"
        		username username
						name "mode"
        		value "manual"
      		end.run_action(:set)

      		gecos_ws_mgmt_desktop_settings "proxy config http" do
	      		provider "gecos_ws_mgmt_gsettings"
        		schema "org.gnome.system.proxy.http"
        		type "string"
        		username username
						name "host"
        		value proxy_settings['http_proxy']
      		end.run_action(:set)

      		gecos_ws_mgmt_desktop_settings "proxy config http port" do
	      		provider "gecos_ws_mgmt_gsettings"
        		schema "org.gnome.system.proxy.http"
        		type "string"
        		username username
						name "port"
        		value proxy_settings['http_proxy_port']
      		end.run_action(:set)

      		gecos_ws_mgmt_desktop_settings "proxy config https" do
	      		provider "gecos_ws_mgmt_gsettings"
        		schema "org.gnome.system.proxy.https"
        		type "string"
        		username username
						name "host"
        		value proxy_settings['https_proxy']
      		end.run_action(:set)

      		gecos_ws_mgmt_desktop_settings "proxy config https port" do
	      		provider "gecos_ws_mgmt_gsettings"
        		schema "org.gnome.system.proxy.https"
        		type "string"
        		username username
						name "port"
        		value proxy_settings['https_proxy_port']
      		end.run_action(:set)
				
					# ENVIROMENT VARIABLES HTTP_PROXY, HTTPS_PROXY
	        ruby_block "include-bashrc-user" do
	          block do
  	          sed = Chef::Util::FileEdit.new("/home/#{username}/.bashrc")
							sed.search_file_replace_line(/HTTP_PROXY/i,"export HTTP_PROXY=\"#{proxy_settings['http_proxy']}:#{proxy_settings['http_proxy_port']}\"")
      	      #sed.write_file
							sed.search_file_replace_line(/HTTPS_PROXY/i,"export HTTPS_PROXY=\"#{proxy_settings['https_proxy']}:#{proxy_settings['https_proxy_port']}\"")
      	      #sed.write_file
    	        sed.insert_line_if_no_match(/HTTP_PROXY/i,"export HTTP_PROXY=\"#{proxy_settings['http_proxy']}:#{proxy_settings['http_proxy_port']}\"")
      	      sed.write_file
							sed.insert_line_if_no_match(/HTTPS_PROXY/i,"export HTTPS_PROXY=\"#{proxy_settings['https_proxy']}:#{proxy_settings['https_proxy_port']}\"")
      	      sed.write_file
        	  end
          	action :nothing
        	end.run_action(:run)


				elsif !proxy_settings['disable_proxy'] and proxy_settings['proxy_autoconfig_url'] != nil
      		gecos_ws_mgmt_desktop_settings "proxy config autoconfig mode" do
	      		provider "gecos_ws_mgmt_gsettings"
        		schema "org.gnome.system.proxy"
        		type "string"
        		username username
						name "mode"
        		value "auto"
      		end.run_action(:set)
				
      		gecos_ws_mgmt_desktop_settings "proxy config autoconfig url" do
	      		provider "gecos_ws_mgmt_gsettings"
        		schema "org.gnome.system.proxy"
        		type "string"
        		username username
						name "autoconfig-url"
        		value proxy_settings['proxy_autoconfig_url']
      		end.run_action(:set)
			
				elsif proxy_settings['disable_proxy']

          gecos_ws_mgmt_desktop_settings "proxy config None" do
            provider "gecos_ws_mgmt_gsettings"
            schema "org.gnome.system.proxy"
            type "string"
            username username
            name "mode"
            value "none"
          end.run_action(:set)

				 	ruby_block "include-bashrc-user" do
	       		block do
          		sed = Chef::Util::FileEdit.new("/home/#{username}/.bashrc")
            	sed.search_file_delete_line(/HTTPS?_PROXY/i)
              sed.write_file
          	end
          	action :nothing
        	end.run_action(:run)

				end

				# FIREFOX
				gecos_ws_mgmt_appconfig_firefox "Firefox proxy configuration" do
	      	provider "gecos_ws_mgmt_appconfig_firefox"
				 config_firefox proxy_settings
					job_ids new_resource.job_ids
					support_os new_resource.support_os
				end.run_action(:setup)
				
				# THUNDERBIRD
				gecos_ws_mgmt_appconfig_thunderbird "Thunderbird proxy configuration" do
					provider "gecos_ws_mgmt_appconfig_thunderbird"
					config_thunderbird proxy_settings
					job_ids new_resource.job_ids
					support_os new_resource.support_os
				end.run_action(:setup)
				
				# APT
				template "/etc/apt/apt.conf.d/80proxy" do
					source "apt_proxy.js.erb"
					variables(
				 		:proxy_settings => proxy_settings
					)
        	action :nothing
				end.run_action(:create)
	  	end

    else
      Chef::Log.info("This resource is not support into your OS")
    end

    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 0
    end

    rescue Exception => e
      # just save current job ids as "failed"
      # save_failed_job_ids
      Chef::Log.error(e.message)
      job_ids = new_resource.job_ids
      job_ids.each do |jid|
        node.set['job_status'][jid]['status'] = 1
        if not e.message.frozen?
          node.set['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
        else
          node.set['job_status'][jid]['message'] = e.message
        end
      end
    ensure
      gecos_ws_mgmt_jobids "appconfig_firefox_res" do
        provider "gecos_ws_mgmt_jobids"
        recipe "software_mgmt"
      end.run_action(:reset)
   end

  end
