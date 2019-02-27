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
    if !is_supported?
      Chef::Log.info('This resource is not supported in your OS')
    elsif has_applied_policy?('misc_mgmt','local_users_res') || \
          is_autoreversible?('misc_mgmt','local_users_res')
      require 'etc'

      $required_pkgs['local_users'].each do |pkg|
        Chef::Log.debug("local_users.rb - REQUIRED PACKAGE = #{pkg}")
        package pkg do
          action :nothing
        end.run_action(:install)
      end

      users = new_resource.users_list
      users.each do |usrdata|
        username = usrdata.user
        fullname = usrdata.name
        passwd = usrdata.password
        actiontorun = usrdata.actiontorun
        user_home = "/home/#{username}"

        if actiontorun == 'remove'
          Chef::Log.info("Removing local user #{username}")
          user username do
            action :nothing
            not_if "who | grep -q #{username}"
          end.run_action(:remove)
        else
          Chef::Log.info("Managing local user #{username}")
          user username do
            password passwd
            home user_home
            comment fullname
            shell '/bin/bash'
            manage_home true
            action :nothing
          end.run_action(:create)

          bash "copy skel to #{username}" do
            user username.to_s
            code "export LC_ALL=$LANG\n"\
              "/usr/bin/xdg-user-dirs-update --force\n"
            action :nothing
          end.run_action(:run)
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
    gecos_ws_mgmt_jobids 'local_users_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
