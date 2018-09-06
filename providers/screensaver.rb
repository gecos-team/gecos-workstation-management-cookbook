#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: screensaver
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
      users = new_resource.users
      users.each_key do |user_key|
        nameuser = user_key
        username = nameuser.gsub('###', '.')
        user = users[user_key]

        idle_enabled = user.idle_enabled
        idle_delay = user.idle_delay
        lock_enabled = user.lock_enabled
        lock_delay = user.lock_delay

        # TO-DO:
        # Sacar el tipo de sesion con el plugin de ohai x-session-manager.rb
        # (amunoz)
        # Distinguir entre sesion Cinnamon y LXDE

        desktop_gsettings 'idle-activation-enabled' do
          schema 'org.cinnamon.desktop.screensaver'
          key 'idle-activation-enabled'
          user username
          value idle_enabled.to_s
          action :nothing
        end.run_action(:set)

        desktop_gsettings 'lock-enabled' do
          schema 'org.cinnamon.desktop.screensaver'
          key 'lock-enabled'
          user username
          value lock_enabled.to_s
          action :nothing
        end.run_action(:set)

        desktop_gsettings 'idle-delay' do
          schema 'org.cinnamon.desktop.session'
          key 'idle-delay'
          user username
          value idle_delay
          action :nothing
        end.run_action(:set)

        desktop_gsettings 'lock-delay' do
          schema 'org.cinnamon.desktop.screensaver'
          key 'lock-delay'
          user username
          value lock_delay
          action :nothing
        end.run_action(:set)
      end
    else
      Chef::Log.info('This resource is not supported in your OS')
    end

    # save current job ids (new_resource.job_ids) as 'ok'
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 0
    end
  rescue StandardError => e
    # just save current job ids as 'failed'
    # save_failed_job_ids
    Chef::Log.error(e.message)
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
    gecos_ws_mgmt_jobids 'screensaver_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
