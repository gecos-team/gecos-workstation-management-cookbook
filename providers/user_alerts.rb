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
require 'date'
require 'json'

action :setup do
  begin
    if os_supported? &&
       (policy_active?('users_mgmt', 'user_alerts_res') ||
        policy_autoreversible?('users_mgmt', 'user_alerts_res'))
      # Installs the notify-send command
      $required_pkgs['user_alerts'].each do |pkg|
        Chef::Log.debug("user_alerts.rb - REQUIRED PACKAGE = #{pkg}")
        package "user_alerts_#{pkg}" do
          package_name pkg
          action :nothing
        end.run_action(:install)
      end

      usernames = []

      users = new_resource.users
      users.each_key do |user_key|
        user = users[user_key]
        username = user_key.gsub('###', '.')
        usernames << username
        homedir = `eval echo ~#{username}`.delete("\n")
        last_pid = `ps -u #{username} h -o pid| tail -n1`.strip
        grepcmd = "grep -z DBUS_SESSION_BUS_ADDRESS /proc/#{last_pid}/environ"
        dbus_address = `#{grepcmd} | cut -d= -f2-`.chop

        icon = ''
        icon = user.icon if user.attribute?('icon')

        change = false

        msg_hash = {}
        msg_hash['urgency'] = user.urgency
        msg_hash['icon'] = icon.gsub! '"', '\"'
        msg_hash['summary'] = user.summary.gsub! '"', '\"'
        msg_hash['body'] = user.body.gsub! '"', '\"'

        if ::File.exist?("#{homedir}/.user-alert")
          file = ::File.read("#{homedir}/.user-alert")
          json_file = JSON.parse(file)
          change = (json_file != msg_hash)
        end

        # Messages are sent only if
        # a) they are different from the previous message
        # b) there's no recorded previous message
        if !::File.exist?("#{homedir}/.user-alert") || change
          send_command = "sudo -u #{username} DBUS_SESSION_BUS_ADDRESS="\
            "#{dbus_address} /usr/bin/notify-send -u #{user.urgency} -i "\
            "\"#{icon}\" \"#{user.summary}\" \"#{user.body}\"".delete("\u0000")
          Chef::Log.info("Execute: #{send_command}")
          system send_command
        end

        # We copy sent message to a local, per user, file in order not to
        # repeat it
        ::File.open("#{homedir}/.user-alert", 'w') do |f|
          f.write(msg_hash.to_json)
        end
      end

      # Delete message file for user in this computer no longer included in
      # an alert policy
      node['ohai_gecos']['users'].each do |user|
        next if usernames.include?(user[:username])

        file "#{user.home}/.user-alert" do
          action :nothing
        end.run_action(:delete)
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
    gecos_ws_mgmt_jobids 'user_alerts_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
