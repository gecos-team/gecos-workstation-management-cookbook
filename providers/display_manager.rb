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
ETC_DISPLAY_MANAGER = '/etc/X11/default-display-manager'
CURRENT_DISPLAY_MANAGER = ::File.basename(::File.read(ETC_DISPLAY_MANAGER).chomp)

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

      unless new_resource.dm.empty?
      
        case new_resource.dm
          when 'MDM'
            PACKAGES = %w(mdm gecosws-mdm-theme)
            NEW_DISPLAY_MANAGER = 'mdm'
            TEMPLATE = 'mdm.conf.erb'
            CONFIGFILE = '/etc/mdm/mdm.conf'
            BIN = '/usr/sbin/mdm'
          when 'Lightdm'
            PACKAGES = if new_resource.autologin
              %w(gir1.2-lightdm-1 python-gobject lightdm lightdm-gtk-greeter gecosws-lightdm-autologin)
            else
              %w(gir1.2-lightdm-1 python-gobject lightdm lightdm-gtk-greeter)
            end
            NEW_DISPLAY_MANAGER = 'lightdm'
            TEMPLATE = 'lightdm.conf.erb'
            CONFIGFILE = '/etc/lightdm/lightdm.conf'
            BIN = '/usr/sbin/lightdm'
        end

        Chef::Log.debug("display_manager.rb ::: ETC_DISPLAY_MANAGER = #{ETC_DISPLAY_MANAGER}")
        Chef::Log.debug("display_manager.rb ::: CURRENT_DISPLAY_MANAGER = #{CURRENT_DISPLAY_MANAGER}")
        Chef::Log.debug("display_manager.rb ::: PROVIDER = #{PROVIDER}")
        Chef::Log.debug("display_manager.rb ::: NEW_DISPLAY_MANAGER  = #{NEW_DISPLAY_MANAGER}")
        Chef::Log.debug("display_manager.rb ::: PACKAGES = #{PACKAGES}")
        Chef::Log.debug("display_manager.rb ::: TEMPLATE = #{TEMPLATE}")
        Chef::Log.debug("display_manager.rb ::: CONFIGFILE = #{CONFIGFILE}")

        # Packages installation
        PACKAGES.each do |pkg|
          package pkg do
            ignore_failure true
            action :install
          end
        end

        # Removes extra package (only for lightdm)
        package 'gecosws-lightdm-autologin' do
          action :remove
          only_if { !new_resource.autologin and NEW_DISPLAY_MANAGER=='lightdm' }
        end

        # Sets default display manager
        file ETC_DISPLAY_MANAGER do
          content "#{BIN}\n"
          action :create
          #notifies :stop, "service[#{CURRENT_DISPLAY_MANAGER}]", :delayed
          notifies :disable, "service[#{CURRENT_DISPLAY_MANAGER}]", :delayed
        end

        # Stops current display manager
        service CURRENT_DISPLAY_MANAGER do
          provider PROVIDER
          action :nothing
        end

        # Enables and starts new DM
        service NEW_DISPLAY_MANAGER do
          provider PROVIDER
          action :enable
          #action [:enable, :start]
          only_if "dpkg-query -W #{NEW_DISPLAY_MANAGER}"
        end

        # Configures DM
        template CONFIGFILE do
          source TEMPLATE
          variables ({
            :autologin => new_resource.autologin,
            :autologin_user => new_resource.autologin_options['username'],
            :autologin_timeout => new_resource.autologin_options['timeout']
          })
          only_if { Etc.getpwnam(new_resource.autologin_options['username']) rescue false }
          #notifies :restart, "service[#{NEW_DISPLAY_MANAGER}]", :delayed
        end
      end

    else
      Chef::Log.info("This resource is not support into your OS")
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

