#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: user_apps_autostart
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl



action :setup do
  begin
# OS identification moved to recipes/default.rb
#    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
#    if new_resource.support_os.include?(os)
    if new_resource.support_os.include?($gecos_os)
      users = new_resource.users 

      case node['platform']
        when 'debian', 'ubuntu', 'redhat', 'centos', 'fedora'
          applications_path = "/usr/share/applications/"
          subdirs = %w(.config/ autostart/)
          file_ext  = '.desktop'
        when 'windows'
          # TODO
        when 'mac_os_x'
          # TODO
      end
          
      users.each_key do |user_key|
        nameuser = user_key 
        username = nameuser.gsub('###','.')
        user = users[user_key]
        gid  = Etc.getpwnam(username).gid

        autostart_path = ::File.expand_path("~#{username}")

        subdirs.each do |subdir|
          autostart_path = ::File.join(autostart_path, subdir)
          directory autostart_path do
            owner username
            group gid
            mode '0755'
            action :nothing
          end.run_action(:create)
        end
        Chef::Log.debug("user_apps_autostart ::: setup - autostart_path = #{autostart_path}")

        user.desktops.each do |desktop|

          if !desktop.name.end_with?(file_ext)
            desktop.name.concat(file_ext)
          end

          src = applications_path + desktop.name
          dst = autostart_path + desktop.name

          case desktop.action
            when "add"
              if ::File.file?(src)
                FileUtils.cp src, dst
                FileUtils.chown(username, gid, dst)
                FileUtils.chmod 0755, dst
                Chef::Log.info("Desktop startup created in #{dst}")
              else
                Chef::Log.warn("Desktop file #{src} not found")
              end
            when "remove"
              if ::File.file?(dst)
                FileUtils.rm dst
                Chef::Log.info("Launcher removed from #{dst}")
              else
                Chef::Log.warn("Desktop file #{dst} not found")
              end
            else
              Chef::Log.warn("No action found")
          end
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

    gecos_ws_mgmt_jobids "user_apps_autostart_res" do
       recipe "users_mgmt"
    end.run_action(:reset)

  end
end
