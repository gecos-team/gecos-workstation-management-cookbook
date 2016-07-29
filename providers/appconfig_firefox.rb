#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: appconfig_firefox
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :setup do

  begin

  	if new_resource.support_os.include?($gecos_os)

    	if not new_resource.config_firefox.empty?
				# Detecting installation directory
				installdir = shell_out("dpkg -L firefox | grep -E 'defaults/pref$'")
				Chef::Log.debug("appconfig_firefox - installdir: #{installdir.stdout}")

				# vars
    		app_update = new_resource.config_firefox['app_update']
	
				# Proxy configuration
				http_proxy = new_resource.config_firefox['http_proxy']
				http_proxy_port = new_resource.config_firefox['http_proxy_port']
				https_proxy = new_resource.config_firefox['https_proxy']
				https_proxy_port = new_resource.config_firefox['https_proxy_port']
				proxy_autoconfig_url = new_resource.config_firefox['proxy_autoconfig_url']
				disable_proxy = new_resource.config_firefox['disable_proxy']
				Chef::Log.debug("appconfig_firefox - http_proxy: #{http_proxy}")

     		unless Kernel::test('d', '/etc/firefox')
     			FileUtils.mkdir_p '/etc/firefox'
      	end

      	template "/etc/firefox/update.js" do
     			source "update.js.erb"
        	action :nothing
        	variables(
        		:app_update => app_update
        	)
      	end.run_action(:create)

      	template "/etc/firefox/proxy-prefs.js" do
     			source "mozilla_proxy.js.erb"
        	action :nothing
        	variables(
        		:http_proxy => http_proxy,
        		:http_proxy_port => http_proxy_port,
        		:https_proxy => https_proxy,
        		:https_proxy_port => https_proxy_port,
        		:proxy_autoconfig_url => proxy_autoconfig_url,
						:disable_proxy => disable_proxy
        	)
      	end.run_action(:create)

				link "#{installdir.stdout.chomp}/update.js" do
			    to "/etc/firefox/update.js" 
					only_if 'test -f /etc/firefox/update.js'
				end

				link "#{installdir.stdout.chomp}/proxy-prefs.js" do
					to "/etc/firefox/proxy-prefs.js"
					only_if 'test -f /etc/firefox/proxy-prefs.js'
				end

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
