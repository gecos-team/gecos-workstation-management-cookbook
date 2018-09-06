#
# Cookbook Name:: gecos-ws-mgmt
# Class MozillaPluginManager
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

require 'chef/mixin/shell_out'
require 'sqlite3'
require 'pathname'

FIREFOX_VERSION_LIMIT = 4

# Class used to manipulate Mozilla software plugins
# (Firefox and Thunderbird plugins)
class MozillaPluginManager
  include Chef::Mixin::ShellOut

  #
  # Checks if a extension is installed
  # by checking if is contained in a sqlite database
  #
  def self.extension_instaled_in_sqlitedb?(xid, sqlitedb)
    db = SQLite3::Database.open(sqlitedb)
    addons = db.get_first_value('SELECT locale.name, '\
        'locale.description, addon.version, addon.active, addon.id '\
        'FROM addon INNER JOIN locale ON locale.id = addon.defaultLocale '\
        "WHERE addon.type = 'extension' and addon.id = '#{xid}'"\
        'ORDER BY addon.active DESC, UPPER(locale.name)')
    Chef::Log.debug("web_browser.rb - SQLite addons: #{addons}")
    !addons.nil?
  end

  #
  # Checks if a extension is installed
  # by checking if is contained in a json file
  #
  def self.extension_instaled_in_json?(xid, jsonfile)
    require 'json'
    jfile = ::File.read(jsonfile)
    addons = JSON.parse(jfile)['addons']
    Chef::Log.debug("web_browser.rb - JSON addons: #{addons}")
    addons.any? { |h| h['id'] == xid }
  end

  #
  # Checks if a extension is installed
  # by checking if is contained in xfile
  #
  def self.extension_instaled_in_file?(xid, xfile, filepath)
    case xfile
    when /\.json$/i
      extension_instaled_in_json?(xid, filepath)
    when /\.sqlite$/
      extension_instaled_in_sqlitedb?(xid, filepath)
    else
      !::File.open(filepath).read.match(xid).nil?
      # operator !! forces true/false returned
    end
  end

  #
  # Creates a temporal directory
  #
  def self.create_temp_dir(plugin_file, username)
    plugin_dir_temp = "#{plugin_file}_temp"
    gid = Etc.getpwnam(username).gid
    directory plugin_dir_temp do
      owner username
      group gid
      action :nothing
    end.run_action(:create)

    plugin_dir_temp
  end

  #
  # Extracts a Firefox plugin in a temporal directory
  #
  def self.extract_plugin_to_temp_dir(plugin_file, username)
    plugin_dir_temp = create_temp_dir(plugin_dir_temp, username)

    bash "extract plugin #{plugin_file}" do
      action :nothing
      user username
      code "rm -rf #{plugin_dir_temp}\n"\
        "mkdir -p #{plugin_dir_temp}\n"\
        "unzip -o #{plugin_file} -d #{plugin_dir_temp}"
    end.run_action(:run)

    plugin_dir_temp
  end

  #
  # Get extension ID
  #
  def self.get_extension_id(plugin_file)
    xid = shell_out("unzip -qc #{plugin_file} install.rdf "\
        '|  xmlstarlet sel -N rdf=http://www.w3.org/1999/02/22-rdf'\
        '-syntax-ns# -N em=http://www.mozilla.org/2004/em-rdf# -t -v '\
        '"//rdf:Description[@about=\'urn:mozilla:install-manifest\']'\
        '/em:id\"').stdout

    Chef::Log.debug("MozillaPluginManager - Extension ID = #{xid}")
    xid
  end

  #
  # Checks if a extension is installed
  #
  def self.extension_instaled?(xid, expath)
    xfiles = %w[extensions.json extensions.sqlite extensions.rdf]
    installed = false
    # Checking if extension is already installed for this profile
    # Querying firefox extensions databases
    xfiles.each do |xfile|
      xf = "#{expath.parent}/#{xfile}"
      Chef::Log.debug("MozillaPluginManager - Extension file = #{xf}")
      next unless ::File.exist?(xf)

      installed = extension_instaled_in_file?(xid, xfile, xf)
      break if installed
    end
    installed
  end

  #
  # Installs a plugin.
  # If version > 4 then the new installation procedure will be used.
  #
  def self.install_plugin_on_version(
    version, plugin_file, exdir, xid, username
  )
    if version.to_i >= FIREFOX_VERSION_LIMIT
      # NEW installation procedure
      # https://developer.mozilla.org/en-US/Add-ons/Installing_extensions
      # In Firefox 4 you may also just copy the extension's XPI to the
      # directory && name it <ID>.xpi as long as the extension does not
      # require extraction to work correctly
      Chef::Log.debug('MozillaPluginManager - New installation procedure ')
      source = plugin_file
      destination = "#{exdir}/#{xid}.xpi"
    else
      # OLD installation procedure
      Chef::Log.debug('MozillaPluginManager - OLD installation procedure')
      source = extract_plugin_to_temp_dir(plugin_file, username)
      destination = "#{exdir}/#{xid}"
    end
    ::FileUtils.mv(source, destination)
  end

  private_class_method :extension_instaled_in_sqlitedb?
  private_class_method :extension_instaled_in_json?
  private_class_method :extension_instaled_in_file?
  private_class_method :extract_plugin_to_temp_dir
  private_class_method :create_temp_dir
end
