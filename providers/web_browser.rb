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

action :setup do
  begin
    ffx = ShellUtil.shell('apt-cache policy firefox').exitstatus
    if os_supported? &&
       ((ffx &&
         policy_active?('users_mgmt', 'web_browser_res')) ||
         policy_autoreversible?('users_mgmt', 'web_browser_res'))

      $required_pkgs['web_browser'].each do |pkg|
        Chef::Log.debug("web_browser.rb - REQUIRED PACKAGES = #{pkg}")
        package "web_browser_#{pkg}" do
          package_name pkg
          action :nothing
        end.run_action(:install)
      end

      gem_depends = ['sqlite3']

      gem_depends.each do |gem|
        gem_package gem do
          gem_binary($gem_path)
          action :nothing
        end.run_action(:install)
      end

      Gem.clear_paths

      require 'sqlite3'

      #
      # Installs a Firefox plugin
      #
      def install_plugin(plugin_file, exdir, xid, username)
        # Getting Firefox version
        firefox = ShellUtil.shell('firefox -v')
        Chef::Log.debug("web_browser.rb - FF command out: #{firefox.stdout}")

        /(?<version>\d+)\.(?<release>\d+)(\.(?<minor>\d+))?/ =~ firefox.stdout
        Chef::Log.debug("web_browser.rb - FF version: #{version}."\
            " #{release}. #{minor}")

        MozillaPluginManager.install_plugin_on_version(
          version, plugin_file, exdir, xid, username
        )
      end

      def remove_plugin(plugin_file, exdir, xid, expath)
        destination = "#{exdir}/#{xid}"
        # Escape special characters for glob directive
        destination = destination.gsub(/[\{\}]/) { |x| '\\' + x }
        Chef::Log.debug("web_browser.rb - Removing extension #{destination}")
        # Delete plugin file
        ::FileUtils.rm_rf(Dir.glob("#{destination}*"))
        # Delete extensions files (extensions.json/extensions.sqlite,
        # extensions.rdf, extensions.ini, extensions.cache)
        # to reset these files
        ::FileUtils.rm(Dir.glob("#{expath.parent}/extensions.*"))
        ::FileUtils.rm(plugin_file)
      end

      def download_plugin(username, exdir, plugin)
        # vars
        plugin_file = "#{exdir}/#{plugin.name.tr(' ', '_')}.xpi"
        gid = UserUtil.get_group_id(username)
        Chef::Log.debug("web_browser.rb - plugin file: #{plugin_file}")

        # Download extension if not exists
        remote_file plugin_file do
          source plugin.uri
          user username
          group gid
          action :nothing
        end.run_action(:create_if_missing)

        plugin_file
      end

      #
      # Plugin Manager: install/uninstall plugin
      #
      def add_or_remove_plugin(username, exdir, plugin, xid, plugin_file)
        expath = Pathname.new(exdir)
        installed = MozillaPluginManager.extension_installed?(xid, expath)

        if !installed && plugin.action == 'add'
          install_plugin(plugin_file, exdir, xid, username)
        elsif installed && plugin.action == 'remove'
          remove_plugin(plugin_file, exdir, xid, expath)
        end
      end

      #
      # Plugin Manager: install/uninstall plugin
      #
      def plugin_manager(username, exdir, plugin)
        plugin_file = download_plugin(username, exdir, plugin)
        xid = MozillaPluginManager.get_extension_id(plugin_file)
        p = plugin_file
        add_or_remove_plugin(username, exdir, plugin, xid, p) unless xid.empty?
      end

      #
      # Transform a configuration to a (key, value) pair
      #
      def get_value_of_type(conf)
        case conf[:value_type]
        when 'string'
          value = conf[:value_str]
        when 'boolean'
          value = conf[:value_bool]
        when 'number'
          value = conf[:value_num]
        end

        value
      end

      #
      # Returns a (key, value) pair
      #
      def to_key_and_value(key, value)
        config = {}
        config['key'] = key
        config['value'] = value

        config
      end

      #
      # Transform a configuration to a (key, value) pair
      #
      def configuration_to_key_and_value(conf)
        key = conf[:key]
        Chef::Log.info("Setting #{key} of type "\
            "#{conf[:value_type]} = /#{conf[:value_str]}/"\
            "#{conf[:value_bool]}/#{conf[:value_num]}/")

        value = get_value_of_type(conf)
        if value.nil?
          Chef::Log.warn("The key #{key} (#{conf[:value_type]}) has no value, "\
              'Please check it')
        end

        to_key_and_value(key, value)
      end

      #
      # Get Firefox configurarion as a (key, value) array
      #
      def get_configuration(config)
        arr_conf = []
        config.each do |conf|
          arr_conf << configuration_to_key_and_value(conf)
        end

        arr_conf
      end

      #
      # Apply configuration to Firefox profiles
      #
      def apply_configuration(username, config, profile_dirs)
        Chef::Log.info("Setting user #{username} web configs")
        var_hash = { config: get_configuration(config) }

        profile_dirs.each do |prof|
          template "#{prof}/user.js" do
            owner username
            source 'web_browser_user.js.erb'
            variables var_hash
            action :nothing
          end.run_action(:create)
        end
      end

      users = new_resource.users

      directory '/etc/firefox/pref' do
        owner    'root'
        group    'root'
        mode     '0755'
        recursive true
        action :nothing
      end.run_action(:create)

      template '/etc/firefox/pref/web_browser_res.js' do
        source 'web_browser_scope.js.erb'
        action :nothing
      end.run_action(:create)

      users.each_key do |user_key|
        username = user_key.gsub('###', '.')
        user = users[user_key]
        Chef::Log.info("web_browser.rb ::: user = #{username}")
        uid = UserUtil.get_user_id(username)
        if uid == UserUtil::NOBODY
          Chef::Log.error("web_browser.rb ::: can't find user = #{username}")
          next
        end
        gid = UserUtil.get_group_id(username)

        homedir = `eval echo ~#{username}`.delete("\n")
        plugins = user.plugins
        bookmarks = user.bookmarks
        profile_dirs = []
        extensions_dirs = []
        sqlitefiles = []

        profiles = "#{homedir}/.mozilla/firefox/profiles.ini"
        next unless ::File.exist? profiles

        # Read firefox default profile directory and initializes file names
        ::File.open(profiles, 'r') do |infile|
          while (line = infile.gets)
            aline = line.split('=')
            next unless aline[0] == 'Path'

            dir = "#{homedir}/.mozilla/firefox/#{aline[1].chomp}"
            profile_dirs << dir
            extensions_dirs << "#{dir}/extensions"
            sqlitefiles << "#{dir}/places.sqlite"
          end
        end

        ## CONFIGS STUFF
        unless user.config.empty?
          apply_configuration(username, user.config, profile_dirs)
        end

        ## Plugins STUFF
        unless plugins.empty?
          Chef::Log.info("Setting user #{username} web plugins")

          extensions_dirs.each do |xdir|
            directory xdir do
              owner uid
              group gid
              action :nothing
            end.run_action(:create)

            plugins.each do |plugin|
              Chef::Log.debug('web_browser.rb - Starting plugin installation: '\
                "#{plugin.name}, #{username}")
              plugin_manager(username, xdir, plugin)
            end
          end
        end

        ## BOOKMARKS STUFF
        Chef::Log.info("Setting user #{username} web bookmarks")
        sqlitefiles.each do |sqlitedb|
          next unless ::FileTest.exist? sqlitedb

          db = SQLite3::Database.open(sqlitedb)

          id_folder_bookmarks = db.get_first_value('SELECT id FROM '\
              'moz_bookmarks WHERE title=\'Marcadores corporativos\'')
          unless id_folder_bookmarks.nil?
            db.execute('delete from moz_bookmarks where parent = '\
                "#{id_folder_bookmarks} ")
          end

          bookmarks.each do |bkm|
            next if bkm.name.empty?

            date_now = Time.now.to_i * 1_000_000
            url = db.get_first_value('SELECT url FROM moz_places '\
                "WHERE url LIKE \'#{bkm.uri}\'")
            unless url.nil?
              db.execute("delete from moz_places where url LIKE \'#{bkm.uri}\'")
            end

            id_toolbar_bookmarks = db.get_first_value('SELECT id '\
                'FROM moz_bookmarks '\
                'WHERE guid = \'toolbar_____\'')
            last_pos_toolbar = db.get_first_value('SELECT MAX(position) '\
                'FROM moz_bookmarks '\
                "WHERE parent=#{id_toolbar_bookmarks}")
            last_pos_folder = 0

            if id_folder_bookmarks.nil?
              db.execute('INSERT INTO moz_bookmarks '\
                  '(type,parent,position,title,dateAdded,lastModified) '\
                  "VALUES (2,#{id_toolbar_bookmarks},#{last_pos_toolbar + 1},"\
                  "\'Marcadores corporativos\',#{date_now},#{date_now})")
              id_folder_bookmarks = db.get_first_value(
                'SELECT last_insert_rowid()'
              )
            else
              last_pos_folder = db.get_first_value('SELECT MAX(position) '\
                  "FROM moz_bookmarks WHERE id=#{id_folder_bookmarks}")
            end

            db.execute('INSERT INTO moz_places '\
                '(url,title,rev_host,visit_count,hidden,typed,'\
                'last_visit_date)'\
                "VALUES  (\'#{bkm.uri}\',\'#{bkm.name}\',"\
                "\'#{bkm.uri.reverse}.\',1,0,1,#{date_now})")
            foreign_key = db.get_first_value('SELECT last_insert_rowid()')

            db.execute('INSERT INTO moz_bookmarks '\
                '(type,fk,parent,position,title,dateAdded,lastModified) '\
                "VALUES (1,#{foreign_key},#{id_folder_bookmarks},"\
                "#{last_pos_folder + 1},\'#{bkm.name}\',#{date_now},"\
                "#{date_now})")
          end
        end
      end
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
    gecos_ws_mgmt_jobids 'web_browser_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
