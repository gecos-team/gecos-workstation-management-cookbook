#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: power_conf
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  begin

    package 'cpufrequtils' do
      action :nothing
    end.run_action(:install)

    cpu_freq_gov = new_resource.cpu_freq_gov
    auto_shutdown = new_resource.auto_shutdown
     
    min_cpu_file = "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"

    unless cpu_freq_gov.empty?
      execute "Setting CPU freq governor to #{cpu_freq_gov}" do
        command "echo #{cpu_freq_gov} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
        only_if { ::File.exists?(min_cpu_file) and ::File.readlines(min_cpu_file).grep(/#{cpu_freq_gov}/).empty? }
        action :nothing
      end.run_action(:run)
    end

    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 0
    end

  rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 1
      node.set['job_status'][jid]['message'] = e.message
    end
  end
end
