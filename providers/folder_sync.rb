#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: folder_sync
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

      $required_pkgs['folder_sync'].each do |pkg|
        Chef::Log.debug("folder_sync.rb - REQUIRED PACKAGE = #{pkg}")
        package pkg do
          action :nothing
        end.run_action(:install)
      end

      users.each_key do |user_key|
        nameuser = user_key
        username = nameuser.gsub('###', '.')
        user = users[user_key]

        # Prepare environment variables
        VariableManager.reset_environ
        VariableManager.add_to_environ(user_key)

        # Authentication user
        owncloud_authuser = user.owncloud_authuser
        if VariableManager.expand_variables(owncloud_authuser)
          owncloud_authuser = VariableManager.expand_variables(
            owncloud_authuser
          )
        end
        Chef::Log.debug('folder_sync.rb ::: owncloud_authuser = '\
            "#{owncloud_authuser}")

        if owncloud_authuser.nil? || owncloud_authuser.empty?
          Chef::Log.warn("User #{username} not email configured.")
          next
        end

        autostart_dir = "/home/#{username}/.config/autostart"
        home = "/home/#{username}"
        owncloud_dir = "#{home}/.local/share/data/ownCloud"
        gid = Etc.getpwnam(username).gid
        directory autostart_dir do
          recursive true
          owner username
          group gid
          action :create
        end

        cookbook_file 'owncloud.desktop' do
          path "#{autostart_dir}/ownCloud.desktop"
          owner username
          group gid
          action :create
        end

        directory owncloud_dir do
          recursive true
          owner username
          group gid
          action :create
        end

        var_hash = {
          username: username,
          owncloud_url: user.owncloud_url,
          owncloud_notifications: user.owncloud_notifications,
          owncloud_ask: user.owncloud_ask,
          owncloud_upload: user.owncloud_upload_bandwith,
          owncloud_download: user.owncloud_download_bandwith
        }
        template "#{owncloud_dir}/owncloud.cfg" do
          source 'owncloud.cfg.erb'
          owner 'root'
          mode '0644'
          action :create
          variables var_hash
        end

        directory "#{owncloud_dir}/folders" do
          recursive true
          owner username
          group gid
          action :create
        end

        Chef::Log.debug('folder_sync.rb ::: owncloud_folders = '\
            "#{user.owncloud_folders}")
        var_hash = {
          username: username,
          folders: user.owncloud_folders
        }
        template "#{owncloud_dir}/folders/ownCloud" do
          source 'owncloud_folders.erb'
          owner 'root'
          mode '0644'
          action :create
          variables var_hash
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
    gecos_ws_mgmt_jobids 'folder_sync_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
