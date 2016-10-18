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
# OS identification moved to recipes/default.rb
#    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
#    if new_resource.support_os.include?(os)
    if new_resource.support_os.include?($gecos_os)
  #  users = node[:gecos_ws_mgmt][:users_mgmt][:screensaver_res][:users] #if new_resource.users.nil?
      users = new_resource.users
      users.each_key do |user_key|
        nameuser = user_key 
        username = nameuser.gsub('###','.')
        user = users[user_key]

        idle_enabled = user.idle_enabled
        idle_delay = user.idle_delay
        lock_enabled = user.lock_enabled
        lock_delay = user.lock_delay
  ### TO-DO:
  ## Sacar el tipo de sesion con el plugin de ohai x-session-manager.rb (amunoz)
  ## Distinguir entre sesion Cinnamon y LXDE

  #     session = node["desktop_session"] 
        gecos_ws_mgmt_desktop_setting "idle-activation-enabled" do
          type "string"
          value idle_enabled.to_s
          schema "org.cinnamon.desktop.screensaver"
          username username
          provider "gecos_ws_mgmt_gsettings"
          action :nothing
        end.run_action(:set)
    
        gecos_ws_mgmt_desktop_setting "lock-enabled" do
          type "string"
          value lock_enabled.to_s
          schema "org.cinnamon.desktop.screensaver"
          username username
          provider "gecos_ws_mgmt_gsettings"
          action :nothing
        end.run_action(:set)
    
        gecos_ws_mgmt_desktop_setting "idle-delay" do
          type "string"
          value idle_delay
          schema "org.cinnamon.desktop.session"
          username username
          provider "gecos_ws_mgmt_gsettings"
          action :nothing
        end.run_action(:set)
    
        gecos_ws_mgmt_desktop_setting "lock-delay" do
          type "string"
          value lock_delay
          schema "org.cinnamon.desktop.screensaver"
          username username
          provider "gecos_ws_mgmt_gsettings"
          action :nothing
        end.run_action(:set)
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
    
    resource = gecos_ws_mgmt_jobids "screensaver_res" do
       recipe "users_mgmt"
    end
    resource.provider = Chef::ProviderResolver.new(node, resource , :reset).resolve
    resource.run_action(:reset)
    
  end
end
