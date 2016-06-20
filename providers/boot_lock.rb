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
    if new_resource.support_os.include?($gecos_os)
        if lock_boot
          Chef::Log.info("Locking boot menu")
        else
        Chef::Log.info("Unlocking lock boot menu!")
        end

        template "/etc/grub.d/05_unrestricted" do
          source "grubconf_unrestricted.erb"
          owner 'root'
          group 'root'
          mode 00700
          action :nothing
        end.run_action(:create)        
        
        if lock_boot and (unlock_user.empty? or unlock_pass.empty?)
            Chef::Log.info("Empty unlock username or password!")
            lock_boot = false
        end
          
        
        template "/etc/grub.d/40_custom" do
          source "grubconf_custom.erb"
          owner 'root'
          group 'root'
          mode 00700
          variables({ :unlock_user => unlock_user, :unlock_pass => unlock_pass, :lock_boot => lock_boot })
          action :nothing
        end.run_action(:create)
            
        execute "grup-update" do
            command "update-grub"
            action :nothing
        end.run_action(:run)
     
    else
      Chef::Log.info("This resource is not support into your OS")
    end

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
      if not e.message.frozen?
        node.set['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
      else
        node.set['job_status'][jid]['message'] = e.message
      end
    end
  end
end

