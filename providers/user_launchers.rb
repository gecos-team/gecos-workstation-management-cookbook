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
# OS identification moved to recipes/default.rb
#    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
#    if new_resource.support_os.include?(os)
    if new_resource.support_os.include?($gecos_os)
      users = new_resource.users 
      applications_path = "/usr/share/applications/"

      users.each_key do |user_key|
        nameuser = user_key 
        username = nameuser.gsub('###','.')
        user = users[user_key]

        homedir = Etc.getpwnam(username).dir
#TODO: change desktop path to localizated (xdg) version. Put it in a generic function in default.rb
        desktop_path = "#{homedir}/Escritorio/"
        gid = Etc.getpwnam(username).gid
#Create desktop directory if missing (user never logged in to desktop)        
        if !::File.directory? desktop_path
          directory desktop_path do
            owner username
            group gid
            mode '755'
            action :nothing
          end.run_action(:create)
        end

        user.launchers.each do |launcher|
          src = applications_path + launcher.name
          dst = desktop_path + launcher.name
 
          case launcher.action
            when "add"
              if ::File.file?(src)
                FileUtils.cp src, dst
                FileUtils.chown(username, gid, dst)
                FileUtils.chmod 0755, dst
                Chef::Log.info("Launcher created in #{dst}")
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
    
    gecos_ws_mgmt_jobids "user_launchers_res" do
       recipe "users_mgmt"
    end.run_action(:reset)
    
  end
end
