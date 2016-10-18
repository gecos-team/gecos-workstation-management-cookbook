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
        Chef::Log.info("lock packages versions")
        new_resource.package_list.each do |pkg|
            # Only ONE <package>=<version> per line accepted
            pkg.strip!
            if pkg =~ /\S+\s*=\s*\d+\S+\Z/
                parts = pkg.split("=")
                file '/etc/apt/preferences.d/'+parts[0].strip+'.ref' do
                  content "Package: #{parts[0].strip}\nPin: version #{parts[1].strip}\nPin-Priority: 1000\n"
                  mode '0644'
                  owner 'root'
                  group 'root'
                  action :create
                end
                
            else
                Chef::Log.info("Bad line in package version lock: "+pkg)
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
  
    resource = gecos_ws_mgmt_jobids "package_version_lock_res" do
       recipe "software_mgmt"
    end
    resource.provider = Chef::ProviderResolver.new(node, resource , :reset).resolve
    resource.run_action(:reset)        
    
  end
end

