#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: display_manager
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#


V2 = ["GECOS V2","Gecos V2 Lite"]


action :setup do

  begin

    # Constants
    Chef::Log.debug("display_manager.rb ::: $gecos_os = #{$gecos_os}")
    PROVIDER = case $gecos_os
      when *V2
        Chef::Provider::Service::Upstart
      else 
        Chef::Provider::Service::Systemd
    end
 
    if new_resource.support_os.include?($gecos_os)

      case new_resource.dm
        when 'MDM'
          PACKAGES = %w(mdm gecosws-mdm-theme)
          SERVICE = 'mdm'
          TEMPLATE = 'mdm.conf.erb'
          CONFIGFILE = '/etc/mdm/mdm.conf'
          BIN = '/usr/sbin/mdm'
          OTHER = 'lightdm'
        else
          PACKAGES = if new_resource.autologin
            %w(gir1.2-lightdm-1 python-gobject lightdm gecosws-lightdm-autologin)
          else
            %w(gir1.2-lightdm-1 python-gobject lightdm lightdm-gtk-greeter)
          end
          SERVICE = 'lightdm'
          TEMPLATE = 'lightdm.conf.erb'
          CONFIGFILE = '/etc/lightdm/lightdm.conf'
          BIN = '/usr/sbin/lightdm'
          OTHER = 'mdm'
      end

      Chef::Log.debug("display_manager.rb ::: PROVIDER = #{PROVIDER}")
      Chef::Log.debug("display_manager.rb ::: SERVICE  = #{SERVICE}")
      Chef::Log.debug("display_manager.rb ::: PACKAGES = #{PACKAGES}")
      Chef::Log.debug("display_manager.rb ::: TEMPLATE = #{TEMPLATE}")
      Chef::Log.debug("display_manager.rb ::: CONFIGFILE = #{CONFIGFILE}")

      # Packages installation
      PACKAGES.each do |pkg|
        package pkg do
          action :install
        end
      end

      # Removes extra package (only for lightdm)
      package 'gecosws-lightdm-autologin' do
        action :remove
        only_if { !new_resource.autologin and SERVICE=='lightdm' }
      end

      # Stops current DM
      service OTHER do
        provider PROVIDER
        action :nothing
      end

      # Enables and starts new DM
      service SERVICE do
        provider PROVIDER
        action [:enable]
#        action [:enable, :start]
      end

      # Sets default display manager
      file '/etc/X11/default-display-manager' do
        content "#{BIN}\n"
        action :create
#        notifies :stop, "service[#{OTHER}]", :immediately
        notifies :disable, "service[#{OTHER}]", :immediately
      end          

      # Configures DM
      template CONFIGFILE do
        source TEMPLATE
        variables ({
          :autologin => new_resource.autologin,
          :autologin_user => new_resource.autologin_options['username'],
          :autologin_timeout => new_resource.autologin_options['timeout']
        })
        notifies :restart, "service[#{SERVICE}]", :delayed
      end

    else
      Chef::Log.info("Policy is not compatible with this operative system")
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
    
    gecos_ws_mgmt_jobids "display_manager_res" do
       recipe "software_mgmt"
    end.run_action(:reset) 
    
  end
end

