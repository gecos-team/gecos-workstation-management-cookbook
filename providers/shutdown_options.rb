#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: shutdown_options
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

GRP_POWER = 'power'.freeze

action :setup do
  begin
    if os_supported? &&
       (policy_active?('users_mgmt', 'shutdown_options_res') ||
        policy_autoreversible?('users_mgmt', 'shutdown_options_res'))
      $required_pkgs['shutdown_options'].each do |pkg|
        Chef::Log.debug("shutdown_options.rb - REQUIRED PACKAGE = #{pkg}")
        package "shutdown_options_#{pkg}" do
          package_name pkg
          action :nothing
        end.run_action(:install)
      end

      users = new_resource.users

      lite = ($gecos_os == 'Gecos V2 Lite' ||
        $gecos_os == 'GECOS V3 Lite')
      if lite
        powermgmt_pkla = '/var/lib/polkit-1/localauthority/50-local.d/'\
          'restrict-login-powermgmt.pkla'
        cookbook_file powermgmt_pkla do
          source 'restrict-login-powermgmt.pkla'
          owner 'root'
          group 'root'
          mode '0644'
          action :nothing
        end.run_action(:create_if_missing)

        group GRP_POWER do
          action :create
        end
      end

      # User-level key values
      users.each_key do |user_key|
        username = user_key.gsub('###', '.')
        user = users[user_key]
        Chef::Log.info("shutdown_options.rb ::: user = #{username}")
        uid = UserUtil.get_user_id(username)
        if uid == UserUtil::NOBODY
          Chef::Log.error('shutdown_options.rb ::: can\'t find user = '\
            "#{username}")
          next
        end

        disable_log_out = user.disable_log_out
        if !lite
          desktop_gsettings "org.cinnamon.desktop.lockdown-#{username}" do
            schema 'org.cinnamon.desktop.lockdown'
            key 'disable-log-out'
            user username
            value disable_log_out.to_s
            action :nothing
          end.run_action(:set)
        elsif disable_log_out
          group GRP_POWER do
            action :manage
            members [username]
            append true
          end
        else
          group GRP_POWER do
            action :manage
            excluded_members [username]
            append true
          end
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
    gecos_ws_mgmt_jobids 'shutdown_options_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
