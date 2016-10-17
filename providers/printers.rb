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

def install_printer(prt_name, prt_id, prt_model, prt_uri, prt_policy)
	print "installing printer #{prt_name}... "
	printer_drv = `foomatic-ppdfile -P #{prt_model}|grep "'#{prt_id}'"`.scan(/CompatibleDrivers='(\S+)\s.*'/)
	if printer_drv.length >= 0
		ppd_file=`foomatic-ppdfile -p #{prt_id} -d #{printer_drv[0][0]}`
		ppd_f = open("/usr/share/cups/model/#{prt_name}.ppd", "w")
  		ppd_f.write(ppd_file)
		ppd_f.close
	else
		## TODO: contemplar error
		puts "\nthere's no PPD for #{prt_id} in foomatic"
	end
	lpadm_comm = Mixlib::ShellOut.new("/usr/sbin/lpadmin  -p #{prt_name} -E -m #{prt_name}.ppd -v #{prt_uri}")
	lpopt_comm = Mixlib::ShellOut.new("/usr/bin/lpoptions -p #{prt_name} -o printer-op-policy=#{prt_policy} -o auth-info-required=none -o managed-by-GCC=true")
	lpadm_comm.run_command
	if lpadm_comm.exitstatus == 0
	    lpopt_comm = Mixlib::ShellOut.new("/usr/bin/lpoptions -p #{prt_name} -o printer-op-policy=#{prt_policy} -o auth-info-required=none -o managed-by-GCC=true")
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

def update_printer(prt_name, prt_policy)
	puts "updating printer #{prt_name}... "
	lpopt_updt = Mixlib::ShellOut.new("/usr/bin/lpoptions -p #{prt_name} -o printer-op-policy=#{prt_policy} -o auth-info-required=none -o managed-by-GCC=true")
	lpopt_updt.run_command
	if lpopt_updt.exitstatus == 0
		puts "done."
	else
		puts "error updating policies to #{prt_name}."
	end
end

def delete_printer(prt_name)
	puts "deleting printer #{prt_name}... "
	lpadm_dele = Mixlib::ShellOut.new("/usr/sbin/lpadmin -x #{prt_name}")
	lpadm_dele.run_command
	if lpadm_dele.exitstatus == 0
		puts "#{prt_name} has been deleted successfully..."
	else
		puts "ERROR: deleting #{prt_name}"
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

        curr_ptr_name   = printer.manufacturer.gsub(" ","+") + "+" + printer.model.gsub(" ","+")
        curr_ptr_id     = printer.manufacturer.gsub(" ","-") + "-" + printer.model.gsub(" ","_")
        gecos_ptr_name  = printer.name.gsub(" ","+")

		if `/usr/bin/lpoptions -p #{gecos_ptr_name}`.length <= 1
            install_printer(curr_ptr_name, curr_ptr_id, printer.model, printer.uri, oppolicy)
        else
            cups_list.each do |cups_printer|
                if cups_printer.eql? gecos_ptr_name
                    update_printer(curr_ptr_name, oppolicy)
                    break
                end
            end
        end
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
