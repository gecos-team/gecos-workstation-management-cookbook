#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: printers
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

def create_ppd(prt_name, prt_model, prt_id)
	Chef::Log.info("Creating PPD file for #{prt_name}... ")

	# foomatic needs all compatible drivers (CompatibleDrivers) for one printer in
	# order to create the PPD file. But sometimes, there's only one driver available (Driver).
	temp = `foomatic-ppdfile -P '#{prt_model}'|grep "Id='#{prt_id}'"`.scan(/CompatibleDrivers='(.*)'/)

	begin
		printer_drv = temp[0][0]
	rescue
		temp = `foomatic-ppdfile -P '#{prt_model}'|grep "Id='#{prt_id}'"`.scan(/Driver='(\S+)*'/)
		printer_drv = temp[0][0]
	end

	ppd_file=`foomatic-ppdfile -p #{prt_id} -d #{printer_drv}`
	ppd_f = open("/usr/share/cups/model/#{prt_name}.ppd", "w")
	ppd_f.write(ppd_file)
	ppd_f.close
end

def install_or_update_printer(prt_name, prt_uri, prt_policy, prt_ppd_uri)
	Chef::Log.info("Installing or updating printer #{prt_name}... ")
	lpadm_comm = Mixlib::ShellOut.new("/usr/sbin/lpadmin  -p #{prt_name} -E -m #{prt_name}.ppd -v #{prt_uri} -o printer-op-policy=#{prt_policy} -o auth-info-required=none")
	lpopt_comm = Mixlib::ShellOut.new("/usr/bin/lpoptions -p #{prt_name} -o managed-by-GCC=true -o external-ppd-uri=#{prt_ppd_uri}")
	lpadm_comm.run_command
	if lpadm_comm.exitstatus == 0
		lpopt_comm.run_command
		if lpopt_comm.exitstatus == 0
			Chef::Log.info(" - installed successfully")
		else
            		Chef::Log.info(" - error setting policies to #{prt_name}")
		end
	else
        	Chef::Log.info(" - error creating printer #{prt_name}")
	end
end

def delete_printer(prt_name)
	Chef::Log.info("Deleting printer #{prt_name}... ")
	lpadm_dele = Mixlib::ShellOut.new("/usr/sbin/lpadmin -x #{prt_name}")
	lpadm_dele.run_command
	if lpadm_dele.exitstatus == 0
        	Chef::Log.info(" - deleted successfully")
	else
        	Chef::Log.info(" - error deleting #{prt_name}")
	end
end

require 'chef/shell_out'

action :setup do
  begin
    printers_list = new_resource.printers_list

    if printers_list.any?

      service "cups" do
        action :nothing
      end.run_action(:restart)

      pkgs = ['printer-driver-gutenprint', 'foomatic-db', 'foomatic-db-engine', 'foomatic-db-gutenprint', 'smbclient']
      pkgs.each do |pkg|
        package pkg do
          action :nothing
        end.run_action(:install)
      end

      printers_list.each do |printer|
        Chef::Log.info("Processing printer: #{printer.name}")

        curr_ptr_name  = printer.name.gsub(" ","+")
        curr_ptr_id    = printer.manufacturer.gsub(" ","-") + "-" + printer.model.gsub(" ","_")

        oppolicy = 'default'
        if printer.attribute?('oppolicy')
          oppolicy = printer.oppolicy
        end

        ppd = ''
        if printer.attribute?('ppd')
          ppd = printer.ppd
        end

        inst_prt_uri   = `lpoptions -p #{curr_ptr_name}`.scan(/^.*\sdevice-uri=(\S+)\s.*$/)
        if inst_prt_uri.empty?
            inst_prt_uri = [[]]
        end

        is_prt_installed = false
        is_prt_in_cups = Mixlib::ShellOut.new("lpstat -p #{curr_ptr_name}")
        is_prt_in_cups.run_command
        if is_prt_in_cups.exitstatus == 0
            is_prt_installed = true
        end

        create_ppd_with_ppd_uri = false
	if printer.attribute?('ppd_uri')
		if not ::File.exists?("/usr/share/cups/model/#{curr_ptr_name}.ppd")
			Chef::Log.info(" - using PPD_URI: #{printer.ppd_uri}")
			FileUtils.mkdir_p('/usr/share/cups/model')
			ppd_uri_dw = Mixlib::ShellOut.new("/usr/bin/wget --no-check-certificate -O /usr/share/cups/model/#{curr_ptr_name}.ppd #{printer.ppd_uri}")
			ppd_uri_dw.run_command
			if ppd_uri_dw.exitstatus == 0
				file "/usr/share/cups/model/#{curr_ptr_name}.ppd" do
					mode '0644'
					owner 'root'
					group 'root'
				end
				create_ppd_with_ppd_uri = true
			else
				Chef::Log.info(" - failed to obtain PPD using #{printer.ppd_uri}")
			end
		end
        else
		ppd_uri = ''
        end

        if not create_ppd_with_ppd_uri
            if not is_prt_installed or not inst_prt_uri[0][0].eql? printer.uri
                create_ppd(curr_ptr_name, printer.model, curr_ptr_id)
            end
        end

	install_or_update_printer(curr_ptr_name, printer.uri, printer.oppolicy, ppd_uri)

	cups_ptr_list = []
	cups_ptr_list = Mixlib::ShellOut.new("lpstat -a | egrep '^\\S' | awk '{print $1}'")
	cups_ptr_list.run_command
	cups_list = cups_ptr_list.stdout.split(/\r?\n/)

	cups_list.each do |cups_printer|
		ptr_found = false
		printers_list.each do |printer|
			if cups_printer.eql? printer.name.gsub(" ","+")
				ptr_found = true
				break
			end
		end
		if not ptr_found
			if `/usr/bin/lpoptions -p #{cups_printer}`.include? 'managed-by-GCC=true'
            			delete_printer(cups_printer)
			end
		end
	end
  end
end

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
  
    gecos_ws_mgmt_jobids "printers_res" do
       recipe "printers_mgmt"
    end.run_action(:reset)
  
  end
end
