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
			puts "done."
		else
			puts "\nerror setting policies to #{prt_name}."
		end
	else
		puts "\nerror creating printer #{prt_name}."
	end
end

def delete_printer(prt_name)
    Chef::Log.info("Deleting printer #{prt_name}... ")
	lpadm_dele = Mixlib::ShellOut.new("/usr/sbin/lpadmin -x #{prt_name}")
	lpadm_dele.run_command
	if lpadm_dele.exitstatus == 0
		puts "done successfully."
	else
		puts "\nERROR: deleting #{prt_name}"
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

      pkgs = ['python-cups', 'cups-driver-gutenprint', 'foomatic-db', 'foomatic-db-engine', 'foomatic-db-gutenprint', 'smbclient']
      pkgs.each do |pkg|
        package pkg do
          action :nothing
        end.run_action(:install)
      end

      cups_ptr_list    = []
      cups_ptr_list    = Mixlib::ShellOut.new("lpstat -a | egrep '^\\S' | awk '{print $1}'")
      cups_ptr_list.run_command
      cups_list = cups_ptr_list.stdout.split(/\r?\n/)

      printers_list.each do |printer|
        Chef::Log.info("Processing printer: #{printer.name}")

        name = printer.name
        make = printer.manufacturer
        model = printer.model
        oppolicy = 'default'
        if printer.attribute?("oppolicy")
          oppolicy = printer.oppolicy
        end
        ppd = ""
        if printer.attribute?("ppd")
          ppd = printer.ppd
        end

        uri = printer.uri
        ppd_uri = ""
        if printer.attribute?("ppd_uri")
          ppd_uri = printer.ppd_uri
        end

        if ppd_uri != '' and ppd != ''
          FileUtils.mkdir_p("/usr/share/ppd/#{make}/#{model}")
          remote_file "/usr/share/ppd/#{make}/#{model}/#{ppd}" do
            source ppd_uri
            mode "0644"
            action :nothing
          end.run_action(:create)
        end

        curr_ptr_name   = printer.name.gsub(" ","+")
        curr_ptr_id     = printer.manufacturer.gsub(" ","-") + "-" + printer.model.gsub(" ","_")
        inst_prt_uri = `lpoptions -p #{curr_ptr_name}`.scan(/^.*\sdevice-uri=(\S+)\s.*$/)

        if not inst_prt_uri[0][0].empty? and not inst_prt_uri[0][0].eql? printer.uri
            create_ppd(curr_ptr_name, printer.model, curr_ptr_id)
        end
        install_or_update_printer(curr_ptr_name, printer.uri, printer.oppolicy, ppd_uri)

      end
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
  ensure
    gecos_ws_mgmt_jobids "printers_res" do
      provider "gecos_ws_mgmt_jobids"
      recipe "printers_mgmt"
    end.run_action(:reset)
  end
end
