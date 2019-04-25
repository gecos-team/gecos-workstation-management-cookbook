#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: user_launchers
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  begin
    if is_os_supported? &&
      (is_policy_active?('users_mgmt','user_launchers_res') ||
       is_policy_autoreversible?('users_mgmt','user_launchers_res'))
      users = new_resource.users

      case node['platform']
      when 'debian', 'ubuntu', 'redhat', 'centos', 'fedora'
        applications_path = '/usr/share/applications/'
        subdirs = %w[Escritorio/]
        file_ext = '.desktop'
      end

      users.each_key do |user_key|
        nameuser = user_key
        username = nameuser.gsub('###', '.')
        user = users[user_key]
        gid = Etc.getpwnam(username).gid

        desktop_path = ::File.expand_path("~#{username}")

        subdirs.each do |subdir|
          desktop_path = ::File.join(desktop_path, subdir)
          directory desktop_path do
            owner username
            group gid
            mode '0755'
            action :nothing
          end.run_action(:create)
        end
        Chef::Log.debug('user_launchers ::: setup - desktop_path = '\
            "#{desktop_path}")

        user.launchers.each do |launcher|
          unless launcher.name.end_with?(file_ext)
            launcher.name.concat(file_ext)
          end

          src = applications_path + launcher.name
          dst = desktop_path + launcher.name

          case launcher.action
          when 'add'
            if ::File.file?(src)
              FileUtils.cp src, dst
              FileUtils.chown(username, gid, dst)
              FileUtils.chmod 0o0755, dst
              Chef::Log.info("Launcher created in #{dst}")
            else
              Chef::Log.warn("Desktop file #{src} not found")
            end
          when 'remove'
            if ::File.file?(dst)
              FileUtils.rm dst
              Chef::Log.info("Launcher removed from #{dst}")
            else
              Chef::Log.warn("Desktop file #{dst} not found")
            end
          else
            Chef::Log.warn('No action found')
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
    gecos_ws_mgmt_jobids 'user_launchers_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
