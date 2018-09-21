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

action :setup do
  begin
    if new_resource.support_os.include?($gecos_os)
      unless new_resource.config_firefox.empty?
        Chef::Log.debug('appconfig_firefox - config_firefox: '\
            "#{new_resource.config_firefox}")

        # Detecting default prefs directory
        defaults_prefs = ShellUtil.shell(
          'dpkg -L firefox | grep -E \'defaults/pref$\''
        ).stdout.chomp
        Chef::Log.debug("appconfig_firefox - defaults_prefs: #{defaults_prefs}")

        # Detecting system prefs directory
        system_prefs = ShellUtil.shell(
          'dpkg -L firefox | grep -E \'defaults/preferences$\''
        ).stdout.chomp
        if system_prefs.empty?
          firefox_dir = ::File.dirname(::File.dirname(defaults_prefs))
          system_prefs = "#{firefox_dir}/browser/defaults/preferences"
          ::FileUtils.mkdir_p system_prefs
        end
        Chef::Log.debug("appconfig_firefox - system_prefs: #{system_prefs}")

        # vars
        app_update = new_resource.config_firefox['app_update']

        unless ::File.directory?('/etc/firefox')
          FileUtils.mkdir_p '/etc/firefox'
        end

        var_hash = {
          app_update: app_update
        }
        template '/etc/firefox/update.js' do
          source 'update.js.erb'
          action :nothing
          variables var_hash
          not_if { app_update.nil? }
          action :nothing
        end.run_action(:create)

        var_hash = {
          settings: new_resource.config_firefox
        }
        template '/etc/firefox/proxy-prefs.js' do
          source 'mozilla_proxy.erb'
          action :nothing
          variables var_hash
          not_if { defaults_prefs.empty? }
          not_if { new_resource.config_firefox['mode'].nil? }
          action :nothing
        end.run_action(:create)

        link "#{system_prefs}/update.js" do
          to '/etc/firefox/update.js'
          only_if 'test -f /etc/firefox/update.js'
        end

        link "#{defaults_prefs}/proxy-prefs.js" do
          to '/etc/firefox/proxy-prefs.js'
          only_if 'test -f /etc/firefox/proxy-prefs.js'
        end
      end
    else
      Chef::Log.info('This resource is not supported in your OS')
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
    gecos_ws_mgmt_jobids 'appconfig_firefox_res' do
      recipe 'software_mgmt'
    end.run_action(:reset)
  end
end
