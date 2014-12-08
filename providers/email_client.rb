#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: email_client
#
# Copyright 2014, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :setup do

  begin
    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
    if new_resource.support_os.include?(os)

      users = new_resource.users
      users.each_key do |user_key|

        username = user_key
        user = users[user_key]

        homedir = `eval echo ~#{username}`.gsub("\n","")

        execute "Create new Profile" do
          command "thunderbird -CreateProfile hola #{homedir}/.thunderbird/hola"
          action :nothing
        end.run_action(:run)

        template "#{homedir}/.thunderbird/hola/prefs.js" do
          owner username
          source "email_client_prefs.js.erb"
          variables(
            :identity_name => user.identity.name,
            :identity_email => user.identity.email,
            :imap_hostname => user.imap.hostname,
            :imap_port => user.imap.port,
            :imap_username => user.imap.username,
            :smtp_hostname => user.smtp.hostname,
            :smtp_port => user.smtp.port,
            :smtp_username => user.smtp.username
          )
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
    gecos_ws_mgmt_jobids "email_client_res" do
      provider "gecos_ws_mgmt_jobids"
      recipe "software_mgmt"
    end.run_action(:reset)
  end
end