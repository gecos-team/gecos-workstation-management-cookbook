#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: package
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
      if new_resource.package_list.any? 
        Chef::Log.info("Installing package list")
        new_resource.package_list.each do |pkg|
            Chef::Log.debug("Package: #{pkg}")
            case pkg.action
            when 'add'
                # Add a package

                # Execute apt-get update every 24 hours
                execute "apt-get-update-periodic" do
                    command "apt-get update"
                    ignore_failure true
                    only_if {
                        ::File.exists?('/var/lib/apt/periodic/update-success-stamp') &&
                        ::File.mtime('/var/lib/apt/periodic/update-success-stamp') < Time.now - 86400
                    }
                end                
                
                # Check the version parameter
                case pkg.version
                when 'current'
                    # Remove the version pinning of this package (if exists)
                    file '/etc/apt/preferences.d/'+pkg.name+'.pref' do
                        action(:delete)
                    end
                    
                    # Install the current version of the package 
                    # or ensure that any version of this package is installed
                    package pkg.name do
                        action :install
                    end                
                
                when 'latest'
                    # Remove the version pinning of this package (if exists)
                    file '/etc/apt/preferences.d/'+pkg.name+'.pref' do
                        action(:delete)
                    end

                    # Install a package and/or ensure that a package is the latest version.
                    package pkg.name do
                        action :upgrade
                    end
                    
                else
                    # Install a certain version of the package
                    package pkg.name do
                        version pkg.version
                        # Added to support package downgrade
                        options "--force-yes"
                        action :install
                    end

                    # Ping this version to prevent updates
                    file '/etc/apt/preferences.d/'+pkg.name+'.pref' do
                        content "Package: #{pkg.name}\nPin: version #{pkg.version}\nPin-Priority: 1000\n"
                        mode '0644'
                        owner 'root'
                        group 'root'
                        action :create
                    end
                    
                
                end
                
            when 'remove'
                # Remove a package
                package pkg.name do
                    action :purge
                end
                
                # Remove the version pinning of this package (if exists)
                file '/etc/apt/preferences.d/'+pkg.name+'.pref' do
                    action(:delete)
                end
                
            else
                raise "Action for package #{pkg.name}=#{pkg.version} is not add nor remove (#{pkg.action})"
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
    
    gecos_ws_mgmt_jobids "package_res" do
       recipe "software_mgmt"
    end.run_action(:reset) 
    
  end
end

