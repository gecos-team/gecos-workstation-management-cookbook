#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: ttys
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

V2 = ["GECOS V2","Gecos V2 Lite"]
regex1 = "tty[1-6].conf"
regex2 = ".*(tty[1-6]).conf(.bak)?"
upstart_dir ="/etc/init/"
backup_suffix = ".bak"

action :setup do
  begin
    if new_resource.support_os.include?($gecos_os)

      Chef::Log.debug("ttys: #{new_resource.ttys}")

      if new_resource.ttys # DISABLE TTYs

        case $gecos_os

          when *V2
            # V2: UPSTART
            Dir.glob("#{upstart_dir}#{regex1}").each do |file|
              Chef::Log.debug("file: #{file}")

              job = file.sub(/#{regex2}/,'\\1')
              Chef::Log.debug("job: #{job}")

              service "#{job}" do 
                provider Chef::Provider::Service::Upstart
                action :nothing
	      end.run_action(:stop)

              ruby_block 'Rename ttyX.conf' do
                block do
                  ::File.rename(file, file.sub(/(.*)/,"\\1#{backup_suffix}"))
                end
                action :nothing
                only_if { ::File.exists?(file) }
              end.run_action(:run)

            end
          else
            # V3: SYSTEMD
            ruby_block "Configure logind.conf" do
              block do
                fe = Chef::Util::FileEdit.new('/etc/systemd/logind.conf')
                fe.search_file_delete_line("NAutoVTs")
                fe.search_file_delete_line("ReserveVT")
                fe.insert_line_if_no_match("NAutoVTs", "NAutoVTs=0")
                fe.insert_line_if_no_match("ReserveVT", "ReserveVT=0")
                fe.write_file
              end
              only_if { ::File.exist?('/etc/systemd/logind.conf') }
              notifies :restart, 'service[systemd-logind]', :immediately
            end

            service "systemd-logind" do
              provider Chef::Provider::Service::Systemd
              action :nothing
            end

            (1..6).to_a.each do |num|
              service "getty@tty#{num}.service" do
                provider Chef::Provider::Service::Systemd
                action [:stop,:disable]
              end
            end
            
        end

      else # ENABLE TTYs

        case $gecos_os

          when *V2

            Dir.glob("#{upstart_dir}#{regex1}#{backup_suffix}").each do |file|
              Chef::Log.debug("file: #{file}")

              job = file.sub(/#{regex2}/,'\\1')
              Chef::Log.debug("job: #{job}")

              ruby_block 'Rename ttyX.conf' do
                block do
                  ::File.rename(file, file.sub(/(.*)#{backup_suffix}/,'\\1'))
                end
                action :nothing
              end.run_action(:run)

              service "#{job}" do
                provider Chef::Provider::Service::Upstart
                action :nothing
              end.run_action(:start)
            end
          else

            ruby_block "Configure logind.conf" do
              block do
                fe = Chef::Util::FileEdit.new('/etc/systemd/logind.conf')
                fe.search_file_delete_line("NAutoVTs")
                fe.search_file_delete_line("ReserveVT")
                fe.write_file
              end
              only_if { ::File.exist?('/etc/systemd/logind.conf') }
              notifies :restart, 'service[systemd-logind]', :immediately
            end

            service "systemd-logind" do
              provider Chef::Provider::Service::Systemd
              action :nothing
            end

            service "getty@tty1.service" do
              provider Chef::Provider::Service::Systemd
              action [:enable,:start]
            end
 
        end
      end
    else
      Chef::Log.info("This resource is not support into your OS")
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
    gecos_ws_mgmt_jobids "ttys_res" do
       recipe "misc_mgmt"
    end.run_action(:reset)
  end
end

