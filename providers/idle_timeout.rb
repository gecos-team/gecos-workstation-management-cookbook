#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: idle_timeout
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

      $required_pkgs['idle_timeout'].each do |pkg|
        Chef::Log.debug("idle_timeout.rb - REQUIRED PACKAGE = %s" % pkg)
        package pkg do
          action :nothing
        end.run_action(:nothing)
      end

      cookbook_file '/usr/bin/autolock.sh' do
        source 'autolock.sh'
        mode '0755'
      end

      users = new_resource.users

      users.each_key do |user_key|
        nameuser = user_key
        username = nameuser.gsub('###','.')
        user = users[user_key]
        gid = Etc.getpwnam(username).gid

        autostart = ::File.expand_path("~#{username}/.config/autostart")
        home = ::File.expand_path("~#{username}")
        Chef::Log.debug("idle_timeout ::: autostart = #{autostart}")
        Chef::Log.debug("idle_timeout ::: home = #{home}")

        if user.idle_enabled

          directory "#{autostart}" do
            owner username
            group gid
            recursive true
            action :nothing
            mode '0755'
          end.run_action(:create)

          cookbook_file "#{username}_autolock.desktop" do
            source "autolock.desktop"
            path "#{autostart}/autolock.desktop"
            owner username
            group gid
            mode '0544'
            action :nothing
          end

          template "#{home}/.autolock" do
            source 'autolock.erb'
            mode '0644'
            variables ({
              :timeout => user.idle_options['timeout'],
              :command => user.idle_options['command'],
              :notification => user.idle_options['notification']
            })
            notifies :create, "cookbook_file[#{username}_autolock.desktop]", :immediately
          end

        else

          %W(#{autostart}/autolock.desktop #{home}/.autolock).each do |f|
            file f do
              action :delete
              only_if { ::File.exists?(f) }
            end
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
    
    gecos_ws_mgmt_jobids "idle_timeout_res" do
       recipe "users_mgmt"
    end.run_action(:reset) 
    
  end
end

