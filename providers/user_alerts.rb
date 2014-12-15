#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: user_alerts
#
# Copyright 2014, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
require 'chef/mixin/shell_out'
require 'date'
include Chef::Mixin::ShellOut

action :setup do

  begin
    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
    if new_resource.support_os.include?(os)

      # Installs the notify-send command
      package "libnotify-bin" do
        action :nothing
      end.run_action(:install)

      users = new_resource.users
      users.each_key do |user_key|

        user = users[user_key]
        username = user_key
        homedir = `eval echo ~#{username}`.gsub("\n","")

        # Needed for notify-send to get the user display.
        # See: http://unix.stackexchange.com/questions/111188/using-notify-send-with-cron
        cron_vars = {"DISPLAY" => ":0.0", "XAUTHORITY" => "#{homedir}/.Xauthority"}
        now = DateTime.now

        cron "user alert" do
          environment cron_vars
          minute "#{now.minute + 5}" # In 5 mins from now
          hour "#{now.hour}"
          day "#{now.day}"
          month "#{now.month}"
          user "#{username}"
          command "/usr/bin/notify-send -u #{user.urgency} -i #{user.icon} \"#{user.summary}\" \"#{user.body}\""
          action :nothing
        end.run_action(:create)

      end
    else
      Chef::Log.info("This resource is not support into your OS")
    end
   
    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 0
    end

  rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e.message)
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 1
      node.set['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
    end
  ensure
    gecos_ws_mgmt_jobids "user_alerts_res" do
      provider "gecos_ws_mgmt_jobids"
      recipe "users_mgmt"
    end.run_action(:reset)
  end
end
