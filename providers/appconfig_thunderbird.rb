#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: appconfig_thunderbird
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  app_update = nil
  begin
    # Check if thunderbird is installed
    thunderbird_istalled = system('dpkg -L thunderbird > /dev/null 2>&1')
    if os_supported? && thunderbird_istalled &&
       ((!new_resource.config_thunderbird.empty? &&
         policy_active?('software_mgmt', 'appconfig_thunderbird_res')) ||
        policy_autoreversible?('software_mgmt', 'appconfig_thunderbird_res'))

      Chef::Log.debug('appconfig_thunderbird.rb - config_thunderbird:'\
          " #{new_resource.config_thunderbird}")

      # Detecting installation directory
      installdir = ShellUtil.shell(
        'dpkg -L thunderbird | grep -E \'defaults/pref$\''
      ).stdout.chomp
      Chef::Log.debug('appconfig_thunderbird - installdir: '\
          "#{installdir}")

      app_update = new_resource.config_thunderbird['app_update']
      unless ::File.directory?('/etc/thunderbird')
        FileUtils.mkdir_p '/etc/thunderbird'
      end

      unless app_update.nil?
        # Only when this provider is not called from system_proxy provider
        if app_update
          execute 'enable thunderbird upgrades' do
            command 'apt-mark unhold thunderbird thunderbird*'
            action :nothing
          end.run_action(:run)
        else
          execute 'disable thunderbird upgrades' do
            command 'apt-mark hold thunderbird thunderbird*'
            action :nothing
          end.run_action(:run)
        end
      end

      unless new_resource.config_thunderbird['mode'].nil?
        # This provider is called from system_proxy provider
        var_hash = {
          settings: new_resource.config_thunderbird
        }
        template '/etc/thunderbird/proxy-prefs.js' do
          source 'mozilla_proxy.erb'
          action :nothing
          variables var_hash
          not_if { installdir.empty? }
        end.run_action(:create)

        link "#{installdir}/proxy-prefs.js" do
          to '/etc/thunderbird/proxy-prefs.js'
          only_if 'test -f /etc/thunderbird/proxy-prefs.js'
        end
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
    unless app_update.nil?
      # Only when this provider is not called from system_proxy provider
      gecos_ws_mgmt_jobids 'appconfig_thunderbird_res' do
        recipe 'software_mgmt'
      end.run_action(:reset)
    end
  end
end
