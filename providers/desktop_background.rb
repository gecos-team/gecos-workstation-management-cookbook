#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: desktop_background
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  begin
    if os_supported? &&
       (policy_active?('users_mgmt', 'desktop_background_res') ||
        policy_autoreversible?('users_mgmt', 'desktop_background_res'))
      $required_pkgs['desktop_background'].each do |pkg|
        Chef::Log.debug("desktop_background.rb - REQUIRED PACKAGE = #{pkg}")
        package "desktop_background_#{pkg}" do
          package_name pkg
          action :nothing
        end.run_action(:install)
      end

      if !new_resource.users.nil? && !new_resource.users.empty?
        users = new_resource.users
        users.each_key do |user_key|
          username = user_key.gsub('###', '.')
          user = users[user_key]
          Chef::Log.info("Setting wallpaper #{user.desktop_file}")
          desktop_file = user.desktop_file

          desktop_gsettings "org.cinnamon.desktop.background-#{username}" do
            schema 'org.cinnamon.desktop.background'
            key 'picture-uri'
            value "'file://#{desktop_file}'"
            user username
            action :nothing
          end.run_action(:set)

          desktop_gsettings "org.gnome.desktop.background-#{username}" do
            schema 'org.gnome.desktop.background'
            key 'picture-uri'
            value "'file://#{desktop_file}'"
            user username
            action :nothing
          end.run_action(:set)
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
    gecos_ws_mgmt_jobids 'desktop_background_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
