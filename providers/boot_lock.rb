#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: book_lock
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  begin
    lock_boot = new_resource.lock_boot
    unlock_user = new_resource.unlock_user
    unlock_pass = new_resource.unlock_pass
    grub_conf = '/boot/grub/grub.cfg'
    if is_os_supported? &&
      (is_policy_active?('misc_mgmt','boot_lock_res') ||
       is_policy_autoreversible?('misc_mgmt','boot_lock_res'))
    
      if ::File.file?(grub_conf)
        is_boot_locked = ::File.read(grub_conf).include? 'superusers'
        execute_update = (lock_boot != is_boot_locked)
      else
        Chef::Log.warn('File not found: /boot/grub/grub.conf')
        execute_update = true
      end
      if execute_update
        if lock_boot
          Chef::Log.info('Locking boot menu')
        else
          Chef::Log.info('Unlocking boot menu!')
        end

        template '/etc/grub.d/05_unrestricted' do
          source 'grubconf_unrestricted.erb'
          owner 'root'
          group 'root'
          mode '0700'
          action :nothing
        end.run_action(:create)

        if lock_boot && (unlock_user.empty? || unlock_pass.empty?)
          Chef::Log.info('Empty unlock username or password!')
          lock_boot = false
        end

        var_hash = {
          unlock_user: unlock_user,
          unlock_pass: unlock_pass,
          lock_boot: lock_boot
        }
        template '/etc/grub.d/40_custom' do
          source 'grubconf_custom.erb'
          owner 'root'
          group 'root'
          mode '0700'
          variables var_hash
          action :nothing
        end.run_action(:create)

        execute 'grub-update' do
          command 'update-grub'
          action :nothing
        end.run_action(:run)
      else
        Chef::Log.info('Boot lock status: change not needed')
      end
    end

    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 0
    end
  rescue StandardError => e
    # just save current job ids as 'failed'
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
    gecos_ws_mgmt_jobids 'boot_lock_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
