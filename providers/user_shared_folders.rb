#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: user_shared_folders
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

      pattern = '(smb|nfs|ftp|sftp|dav)(:\/\/)([\S]*\/.*)'
      users = new_resource.users
      users.each_key do |user_key|
        nameuser = user_key 
        VariableManager.add_to_environ(user_key)
        username = nameuser.gsub('###','.')
        user = users[user_key]
     
        homedir = `eval echo ~#{username}`.gsub("\n","")
        gid = Etc.getpwnam(username).gid
        gtkbookmark_files =  ["#{homedir}/.config/gtk-3.0/bookmarks", "#{homedir}/.gtk-bookmarks"]
# If user has been created but hasn't log in to his/her desktop, .config/gtk-3.0 directory will be missing
# The following block creates thos directories if missing        
        container_dirs = ["#{homedir}/.config","#{homedir}/.config/gtk-3.0" ]
        container_dirs.each do |dir|
          if !::File.directory? dir
            directory dir do
              owner username
              group gid
              mode '700'
              action :nothing
            end.run_action(:create)
          end
        end 
        gtkbookmark_files.each do |gtkbook|

           if !::File.exists? gtkbook      
            file gtkbook do
              owner username
              group gid
              action :nothing
            end.run_action(:create)
          end
        
          tmp_file = Chef::Util::FileEdit.new gtkbook
          user.gtkbookmarks.each do |bookmark|
            if bookmark.uri.match(pattern)
              bookmark_uri = VariableManager.expand_variables(bookmark.uri)
              bookmark_name = VariableManager.expand_variables(bookmark.name)
              # Do not create the bookmark if the variable expansion returns nil
              if bookmark_uri and bookmark_name
              	line_to_add = "#{bookmark_uri} #{bookmark_name}"
 # If there's no line containing the bookmark URI (removing lading spaces and trailing slash), insert the bookmark. We only search for URI, so renamed bookmarks are nor duplicated
                tmp_file.insert_line_if_no_match(bookmark_uri.chop().lstrip(), line_to_add)
                Chef::Log.info("Adding shortcuts to shared folders")
              end
            else
              Chef::Log.warn("Bookmark URI doesn't match the pattern: #{bookmark.uri} username: #{username}")
            end
          end
          tmp_file.write_file
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
    
    gecos_ws_mgmt_jobids "user_shared_folders_res" do
       recipe "users_mgmt"
    end.run_action(:reset) 
    
  end
end
