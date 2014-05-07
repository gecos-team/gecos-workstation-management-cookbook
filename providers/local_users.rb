#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: local_users
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
action :setup do
  begin

    package "libshadow-ruby1.8" do
      action :nothing
    end.run_action(:install)

    require 'digest/sha2'

    users = new_resource.users_list
    users.each do |usrdata| 
      usr = usrdata.user
      passwd = usrdata.password
      salt = rand(36**8).to_s(36)
      password_hashed = passwd.crypt("$6$" + salt)
      actiontorun = usrdata.actiontorun
      grps = usrdata.groups
      user_home = "/home/#{usr}"

      user usr do
        password password_hashed
        home user_home
        shell "/bin/bash"
        action :create
      end      

      if !::File.directory?(user_home) 
        directory user_home do
          owner usr
          group usr
          action :create
        end
      #  bash "copy skel to #{usr}" do
      #    code <<-EOH 
      #      cp /etc/skel/* #{home}/
      #      chown -R #{usr}: #{home}
      #      EOH
      #  end

      #  end
      end

    end


    # TODO:
    # save current job ids (new_resource.job_ids) as "ok"

  rescue
    # TODO:
    # just save current job ids as "failed"
    # save_failed_job_ids
    raise
  end
end

