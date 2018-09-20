#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: local_file
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
      localfiles = new_resource.localfiles

      Chef::Log.debug("local_file.rb ::: localfiles = #{localfiles}")

      localfiles.each do |local|
        case local.action
        when 'add'
          # Variables
          act   = local.overwrite ? 'create' : 'create_if_missing'
          dest  = if ::File.directory?(local.file_dest)
                    ::File.join(
                      local.file_dest, ::File.basename(local.file)
                    )
                  else
                    local.file_dest
                  end
          uid  = local.attribute?('user') ? Etc.getpwnam(local.user).uid : '0'
          gid  = if local.attribute?('group')
                   Etc.getgrnam(local.group).gid
                 else
                   Etc.getpwuid(uid).gid
                 end
          mode = local.attribute?('mode') ? local.mode : '755'

          Chef::Log.debug("local_file.rb ::: act   = #{act}")
          Chef::Log.debug("local_file.rb ::: dest  = #{dest}")
          Chef::Log.debug("local_file.rb ::: uid   = #{uid}")
          Chef::Log.debug("local_file.rb ::: group = #{gid}")
          Chef::Log.debug("local_file.rb ::: mode  = #{mode}")

          remote_file dest do
            source local.file
            action :nothing
          end.run_action(act)

          execute 'Changing file perms' do
            command "chown #{uid}:#{gid} #{dest} && chmod #{mode} #{dest}"
            not_if do
              ::File.stat(dest).mode.to_s(8)[3..5] == mode &&
                ::File.stat(dest).uid  == uid &&
                ::File.stat(dest).gid  == gid
            end
            action :nothing
          end.run_action(:run)

        when 'remove'
          # Variables
          makebackup = local.backup ? 1 : 0
          Chef::Log.debug("local_file.rb ::: makebackup = #{makebackup}")
          Chef::Log.debug('local_file.rb ::: local.file_dest = '\
              "#{local.file_dest}")
          file local.file_dest do
            backup makebackup
            only_if { ::File.file?(local.file_dest) }
            action :nothing
          end.run_action(:delete)

          directory local.file_dest do
            recursive true
            only_if { ::File.directory?(local.file_dest) }
            action :nothing
          end.run_action(:delete)
        end
      end
    else
      Chef::Log.info('This resource is not supported in your OS')
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
    gecos_ws_mgmt_jobids 'local_file_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
