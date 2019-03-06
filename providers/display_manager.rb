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

ETC_DISPLAY_MANAGER = '/etc/X11/default-display-manager'.freeze
CURRENT_DISPLAY_MANAGER = ::File.basename(
  ::File.read(ETC_DISPLAY_MANAGER).chomp
)

action :setup do
  begin
    if is_os_supported? &&
      ((!new_resource.dm.empty? &&
        is_policy_active?('software_mgmt','display_manager_res')) ||
        is_policy_autoreversible?('software_mgmt','display_manager_res'))

      # Template variables
      var_hash = {
        autologin: new_resource.autologin,
        autologin_user: new_resource.autologin_options['username'],
        autologin_timeout: new_resource.autologin_options['timeout']
      }

      case new_resource.dm
      when 'MDM'
        PACKAGES = %w[mdm gecosws-mdm-theme].freeze
        NEW_DISPLAY_MANAGER = 'mdm'.freeze
        TEMPLATE = 'mdm.conf.erb'.freeze
        CONFIGFILE = '/etc/mdm/mdm.conf'.freeze
        BIN = '/usr/sbin/mdm'.freeze
      when 'LightDM'
        PACKAGES = if new_resource.autologin
                     %w[gir1.2-lightdm-1 python-gobject lightdm
                        lightdm-gtk-greeter gecosws-lightdm-autologin].freeze
                   else
                     %w[gir1.2-lightdm-1 python-gobject lightdm
                        lightdm-gtk-greeter].freeze
                   end
        NEW_DISPLAY_MANAGER = 'lightdm'.freeze
        TEMPLATE = 'lightdm.conf.erb'.freeze
        CONFIGFILE = '/etc/lightdm/lightdm.conf'.freeze
        BIN = '/usr/sbin/lightdm'.freeze

        # user-session lightdm ootion with LXDE
        var_hash[:lxde] = $gecos_os.include?('Lite')
      end

      Chef::Log.debug('display_manager.rb ::: ETC_DISPLAY_MANAGER = '\
          "#{ETC_DISPLAY_MANAGER}")
      Chef::Log.debug('display_manager.rb ::: CURRENT_DISPLAY_MANAGER = '\
          "#{CURRENT_DISPLAY_MANAGER}")
      Chef::Log.debug('display_manager.rb ::: NEW_DISPLAY_MANAGER  = '\
          "#{NEW_DISPLAY_MANAGER}")
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
        only_if { !new_resource.autologin && NEW_DISPLAY_MANAGER == 'lightdm' }
      end

      # Bugfix ligthdm package (Ubuntu 16.04 Xenial)
      # systemctl enable lightdm command no create symlink in
      # /etc/systemd/system
      #
      # Must be:
      # /etc/systemd/system/display-manager.service
      #   -> /lib/systemd/system/lightdm.service
      #
      # WORKAROUND
      # Ubuntu 18.04 resolved:
      #  https://bugs.launchpad.net/ubuntu/+source/lightdm/+bug/1757091
      cookbook_file '/lib/systemd/system/lightdm.service' do
        source 'lightdm.service'
        action :nothing
        only_if { NEW_DISPLAY_MANAGER == 'lightdm' }
      end.run_action(:create)

      # Sets default display manager
      file ETC_DISPLAY_MANAGER do
        content "#{BIN}\n"
        action :create
        notifies :disable, "service[#{CURRENT_DISPLAY_MANAGER}]", :immediately
        notifies :enable, "service[#{NEW_DISPLAY_MANAGER}]", :immediately
      end

      # Stops current display manager
      service CURRENT_DISPLAY_MANAGER do
        provider Chef::Provider::Service::Systemd
        action :nothing
      end

      # Enables new DM
      service NEW_DISPLAY_MANAGER do
        provider Chef::Provider::Service::Systemd
        action :nothing
        only_if "dpkg-query -W #{NEW_DISPLAY_MANAGER}"
      end

      # Presession script
      if new_resource.session_script && \
         ::File.file?(new_resource.session_script) && \
         ::File.executable?(new_resource.session_script)

        if NEW_DISPLAY_MANAGER == 'lightdm'
          var_hash[:session_script] = new_resource.session_script
        else # MDM
          file '/etc/mdm/PreSession/Default' do
            action :nothing
            not_if 'test -h /etc/mdm/PreSession/Default'
          end.run_action(:delete)

          link '/etc/mdm/PreSession/Default' do
            to new_resource.session_script
          end.run_action(:create)
        end

      else

        link '/etc/mdm/PreSession/Default' do
          action :nothing
          only_if 'test -h /etc/mdm/PreSession/Default'
        end.run_action(:delete)
      end

      Chef::Log.debug("display_manager.rb ::: var_hash = #{var_hash}")

      # Configures DM
      template CONFIGFILE do
        source TEMPLATE
        variables var_hash
        not_if "#{new_resource.autologin} && "\
          "! getent passwd #{new_resource.autologin_options['username']}"
      end
    end

    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 0
    end
  rescue StandardError => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e.message)
    Chef::Log.error(e.backtrace.join("\n"))

    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 1
      if !e.message.frozen?
        node.normal['job_status'][jid]['message'] =
          e.message.force_encoding('utf-8')
      else
        node.normal['job_status'][jid]['message'] = e.message
      end
    end
  ensure
    gecos_ws_mgmt_jobids 'display_manager_res' do
      recipe 'software_mgmt'
    end.run_action(:reset)
  end
end
