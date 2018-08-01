#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: web_browser
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :setup do

  begin
    # OS identification moved to recipes/default.rb
    #    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
    #    if new_resource.support_os.include?(os)
    
    ffx = shell_out("apt-cache policy firefox").exitstatus
    if new_resource.support_os.include?($gecos_os) and ffx

      $required_pkgs['web_browser'].each do |pkg|
         Chef::Log.debug("web_browser.rb - REQUIRED PACKAGES = %s" % pkg)
         package pkg do
           action :nothing
         end.run_action(:install)
      end

      gem_depends = [ 'sqlite3' ]
      
      gem_depends.each do |gem|
        gem_package gem do
          gem_binary($gem_path)
          action :nothing
        end.run_action(:install)
      end

      Gem.clear_paths

      require "sqlite3"
      require 'pathname'  

      #
      # Plugin Manager: install/uninstall plugin
      #
      def plugin_manager(username, exdir, plugin)
      
        Chef::Log.debug("web_browser.rb - Starting plugin installation: #{plugin.name}, #{username}")
        
        # vars
        plugin_name = "#{plugin.name.gsub(" ","_")}.xpi"
        plugin_file = "#{exdir}/#{plugin_name}"
        plugin_dir_temp = "#{plugin_file}_temp"
        xfiles = [ "extensions.json", "extensions.sqlite", "extensions.rdf" ]        
        installed = false
        source = ''
        destination = ''
        expath = Pathname.new(exdir)
        groupname = Etc.getpwnam(username).gid
        
        Chef::Log.debug("web_browser.rb - plugin file: #{plugin_file}")
        Chef::Log.debug("web_browser.rb - plugin dir temp: #{plugin_dir_temp}")
        Chef::Log.debug("web_browser.rb - Extensions files: #{xfiles}") 

        # Download extension if not exists
        remote_file plugin_file do
          source plugin.uri
          user username
          group groupname
          action :nothing
        end.run_action(:create_if_missing)
        
        # Determine ID extension                    
        xid = shell_out("unzip -qc #{plugin_file} install.rdf |  xmlstarlet sel \
                        -N rdf=http://www.w3.org/1999/02/22-rdf-syntax-ns# \
                        -N em=http://www.mozilla.org/2004/em-rdf# \
                        -t -v \
                        \"//rdf:Description[@about='urn:mozilla:install-manifest']/em:id\"").stdout

        Chef::Log.debug("web_browser.rb - Extension ID = #{xid}")
                                                                   
        # Checking if extension is already installed for this profile
        # Querying firefox extensions databases
        xfiles.each do |xfile|        
          xf = "#{expath.parent}/#{xfile}"
          Chef::Log.debug("web_browser.rb - Extension file = #{xf}")
          if ::File.exist?(xf)
            installed = case xfile
              when /\.json$/i
                require 'json'
                jfile = ::File.read(xf)
                addons = JSON.parse(jfile)["addons"]                
                Chef::Log.debug("web_browser.rb - JSON addons: #{addons}")
                addons.any?{|h| h["id"] == xid}
              when /\.sqlite$/
                db = SQLite3::Database.open(xf)
                addons = db.get_first_value("SELECT locale.name, locale.description, addon.version, addon.active, addon.id FROM addon 
                    INNER JOIN locale on locale.id = addon.defaultLocale WHERE addon.type = 'extension' AND addon.id = '#{xid}'
                    ORDER BY addon.active DESC, UPPER(locale.name)")
                Chef::Log.debug("SELECT locale.name, locale.description, addon.version, addon.active, addon.id FROM addon 
                    INNER JOIN locale on locale.id = addon.defaultLocale WHERE addon.type = 'extension' AND addon.id = '#{xid}'
                    ORDER BY addon.active DESC, UPPER(locale.name)")
                Chef::Log.debug("web_browser.rb - SQLite addons: #{addons}")
                !addons.nil?
              else   
                !!::File.open(xf).read().match(xid) # operator !! forces true/false returned
            end
          end
          break if installed
        end
        Chef::Log.debug("web_browser.rb - Installed plugin? #{installed}")
                      
        if not installed and plugin.action == "add"                                 
                          
          # NEW installation procedure
          # https://developer.mozilla.org/en-US/Add-ons/Installing_extensions
          # In Firefox 4 you may also just copy the extension's XPI to the directory 
          # and name it <ID>.xpi as long as the extension does not require extraction to work correctly        
          if $ffver.to_i >= node[:gecos_ws_mgmt][:users_mgmt][:web_browser_res][:ver_threshold]
            Chef::Log.debug("web_browser.rb - FF ver = #{$ffver}. New installation procedure FF >= #{node[:gecos_ws_mgmt][:users_mgmt][:web_browser_res][:ver_threshold]}")   
            source = plugin_file
            destination = "#{exdir}/#{xid}.xpi"

          # OLD installation procedure
          else  
            Chef::Log.debug("web_browser.rb - FF version = #{$ffver}. New installation procedure for FF < #{node[:gecos_ws_mgmt][:users_mgmt][:web_browser_res][:ver_threshold]}")
            plugin_dir_temp = "#{plugin_file}_temp"
            gid = Etc.getpwnam(username).gid
            directory plugin_dir_temp do
              owner username
              group gid
              action :nothing
            end.run_action(:create)

            bash "extract plugin #{plugin_file}" do
              action :nothing
              user username
              code <<-EOH
                unzip -o #{plugin_file} -d #{plugin_dir_temp}
              EOH
            end.run_action(:run)

            source = plugin_dir_temp
            destination = "#{exdir}/#{xid}"
          end
          
          ::FileUtils.mv(source, destination)

        elsif installed and plugin.action == "remove"
      
          destination = "#{exdir}/#{xid}"         
          # Escape special characters for glob directive
          destination = destination.gsub(/[\{\}]/) { |x| '\\'+x}
          Chef::Log.debug("web_browser.rb - Removing extension #{destination}")
          # Delete plugin file
          ::FileUtils.rm_rf(Dir.glob("#{destination}*"))
          # Delete extensions files (extensions.json/extensions.sqlite, extensions.rdf, extensions.ini, extensions.cache) 
          # to reset these files
          ::FileUtils.rm(Dir.glob("#{expath.parent}/extensions.*"))
          ::FileUtils.rm(plugin_file)
          
        end        

      end

      # Getting Firefox version
      firefox = shell_out("firefox -v")
      Chef::Log.debug("web_browser.rb - FF command out: #{firefox.stdout}")

      /(?<version>\d+)\.(?<release>\d+)(\.(?<minor>\d+))?/ =~ firefox.stdout
      Chef::Log.debug("web_browser.rb - FF version: #{version}")
      Chef::Log.debug("web_browser.rb - FF release: #{release}")
      Chef::Log.debug("web_browser.rb - FF minor: #{minor}")
      
      $ffver = version

      users = new_resource.users

      users.each_key do |user_key|
        nameuser = user_key 
        username = nameuser.gsub('###','.')
        user = users[user_key]

        homedir = `eval echo ~#{username}`.gsub("\n","")
        plugins = user.plugins
        bookmarks =  user.bookmarks
        profiles = "#{homedir}/.mozilla/firefox/profiles.ini"
        profile_dirs = []
        extensions_dirs = []
        sqlitefiles = []

        profiles = "#{homedir}/.mozilla/firefox/profiles.ini"
        if ::File.exist? profiles
          ::File.open(profiles, "r") do |infile|
            while (line = infile.gets)
              aline=line.split('=')
              if aline[0] == 'Path'
                profile_dirs << "#{homedir}/.mozilla/firefox/#{aline[1].chomp}"
                extensions_dirs << "#{homedir}/.mozilla/firefox/#{aline[1].chomp}/extensions"
                sqlitefiles << "#{homedir}/.mozilla/firefox/#{aline[1].chomp}/places.sqlite"
              end
            end
          end

          ## CONFIGS STUFF   
          if !user.config.empty?
            Chef::Log.info("Setting user #{username} web configs")
            arr_conf = []
            user.config.each do |conf|
              value = nil
              Chef::Log.info("Setting #{conf[:key]} of type #{conf[:value_type]} = /#{conf[:value_str]}/#{conf[:value_bool]}/#{conf[:value_num]}/")
              if conf[:value_type] == "string"
                value = conf[:value_str]
                if conf[:value_str].nil?
                  Chef::Log.warn("The key #{conf[:key]} (string) has no value, Please check it")
                end
              elsif conf[:value_type] == "boolean"
                value = conf[:value_bool]
                if conf[:value_bool].nil? 
                  Chef::Log.warn("The key #{conf[:key]} (boolean) has no value, Please check it")
                end
              elsif conf[:value_type] == "number"
                value = conf[:value_num]
                if conf[:value_num].nil? 
                  Chef::Log.warn("The key #{conf[:key]} (number) has no value, Please check it")
                end
              end
              config = {}
              config['key'] = conf[:key]
              config['value'] = value
              arr_conf << config
            end

            profile_dirs.each do |prof|
              template "#{prof}/user.js" do
                owner username
                source "web_browser_user.js.erb"
                variables ({:config => arr_conf})
                action :nothing
              end.run_action(:create)
            end
          end

          ## Plugins STUFF
          unless plugins.empty?
            Chef::Log.info("Setting user #{username} web plugins")  

            directory "/etc/firefox/pref" do
              owner    'root'
              group    'root'
              mode     '0755'
              recursive true
              action :nothing
            end.run_action(:create)

            template "/etc/firefox/pref/web_browser_res.js" do
              source "web_browser_scope.js.erb"
              action :nothing
            end.run_action(:create)
            
            extensions_dirs.each do |xdir|
              directory xdir do
                owner username
                group username
                action :nothing
              end.run_action(:create)
              
              plugins.each do |plugin|
                plugin_manager(username, xdir, plugin)                
              end
            end
          end 

          ## BOOKMARKS STUFF
          Chef::Log.info("Setting user #{username} web bookmarks")     
          sqlitefiles.each do |sqlitedb|
            if ::FileTest.exist? sqlitedb
              db = SQLite3::Database.open(sqlitedb)

              id_folder_bookmarks = db.get_first_value("SELECT id FROM moz_bookmarks WHERE title=\'Marcadores corporativos\'")
              if !id_folder_bookmarks.nil?
                db.execute("delete from moz_bookmarks where parent=#{id_folder_bookmarks} ")
              end
              
              bookmarks.each  do |bkm|
                unless bkm.name.empty? 
                  date_now = Time.now.to_i*1000000
                  url = db.get_first_value("SELECT url FROM moz_places WHERE url LIKE \'#{bkm.uri}\'")
                  if !url.nil?
                    db.execute("delete from moz_places where url LIKE \'#{bkm.uri}\'")
                  end

                  id_toolbar_bookmarks = db.get_first_value("SELECT id FROM moz_bookmarks WHERE title=\'Barra de herramientas de marcadores\'")
                  last_pos_toolbar = db.get_first_value("SELECT MAX(position) FROM moz_bookmarks WHERE parent=#{id_toolbar_bookmarks}")
                  last_pos_folder = 0

                  if id_folder_bookmarks.nil?
                    db.execute("INSERT INTO moz_bookmarks (type,parent,position,title,dateAdded,lastModified) VALUES (2,#{id_toolbar_bookmarks},#{last_pos_toolbar+1},\'Marcadores corporativos\',#{date_now},#{date_now})")
                    id_folder_bookmarks = db.get_first_value("SELECT last_insert_rowid()")
                  else
                    last_pos_folder = db.get_first_value("SELECT MAX(position) FROM moz_bookmarks WHERE id=#{id_folder_bookmarks}")
                  end

                  db.execute("INSERT INTO moz_places (url,title,rev_host,visit_count,hidden,typed,last_visit_date) VALUES  (\'#{bkm.uri}\',\'#{bkm.name}\',\'#{bkm.uri.reverse}.\',1,0,1,#{date_now})")
                  foreign_key = db.get_first_value("SELECT last_insert_rowid()")

                  db.execute("INSERT INTO moz_bookmarks (type,fk,parent,position,title,dateAdded,lastModified) VALUES (1,#{foreign_key},#{id_folder_bookmarks},#{last_pos_folder+1},\'#{bkm.name}\',#{date_now},#{date_now})") 
                end
              end
            end
          end  
                    ## CERTS STUFF
          #profile_dirs.each do |prof|
          #  user.certs.each do |cert|
          #
          #    certfile = "/var/tmp/#{cert.name}.pem"
          #
          #    remote_file certfile do
          #      source cert.uri
          #      action :nothing
          #    end.run_action(:create_if_missing)
          #
          #    bash "Installing #{cert.name} cert to user #{username}" do
          #      action :nothing
          #      user username
          #      code <<-EOH
          #        certutil -A -d #{prof} -n #{cert.name} -i #{certfile} -t C,C,C
          #      EOH
          #    end.run_action(:run)
          #  end
          #end
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
    
    gecos_ws_mgmt_jobids "web_browser_res" do
       recipe "users_mgmt"
    end.run_action(:reset)
    
  end
end

