#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: software_sources
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

# Class to create an entry in the white list
# of software repositories
class RespositoriesWhiteListEntry
  attr_reader :name, :url, :distribution

  def initialize(name, url, distribution)
    @name = name
    @url = url
    @distribution = distribution
  end
end

# Class to create a white list of software repositories
class RespositoriesWhiteList
  def initialize
    @entries = []
  end

  # Adds a new entry to the white list
  def add_entry(name, url, distribution)
    @entries.push(RespositoriesWhiteListEntry.new(name, url, distribution))
  end

  # Returs true if a repository belongs to the white list
  def in_white_list(name, url, distribution)
    result = false

    @entries.each do |entry|
      next unless [name, '*'].include?(entry.name) &&
                  [url, '*'].include?(entry.url) &&
                  [distribution, '*'].include?(entry.distribution)

      result = true
      break
    end

    result
  end
end

action :setup do
  begin
    if is_os_supported? &&
      (is_policy_active?('software_mgmt','software_sources_res') ||
       is_policy_autoreversible?('software_mgmt','_software_sources_res'))
      repo_list = new_resource.repo_list

      current_lists = []
      remote_lists = []

      # Install or upgrade gecosws-repository-compatibility package
      $required_pkgs['software_sources'].each do |pkg|
        Chef::Log.debug("software_sources.rb - REQUIRED PACKAGE = #{pkg}")
        package pkg do
          action :nothing
        end.run_action(:install)
      end

      # We must always preserve the default repository for the distribution
      default_repo = $gecos_os.downcase
      default_repo = default_repo.gsub(/lite/, '').gsub(/[^A-Za-z0-9]/, '')
      default_repo += '.list'
      remote_lists.push(default_repo)

      # Capture in "current_lists" the list files inside
      # /etc/apt/sources.list.d directory
      Dir.foreach('/etc/apt/sources.list.d') do |item|
        next if ['.', '..'].include?(item)
        current_lists.push(item)
      end

      # Read the white list in /etc/gecos/repository-compatibility
      filename = '/etc/gecos/repository-compatibility'
      lineno = 0
      white_list = RespositoriesWhiteList.new
      if ::File.file?(filename)
        ::File.open(filename, 'r') do |f|
          f.each_line do |line|
            lineno += 1
            line = line.strip

            # ignore comments and empty lines
            next if line.start_with?('#') || line.empty?

            # NAME, URL, DISTRIBUTION format
            parts = line.split(',')
            if parts.nil? || parts.length < 3
              Chef::Log.warn("ERROR: #{filename}:#{lineno} "\
                "- Unrecognized line: #{line}")
              next
            end

            name = parts[0].strip
            url = parts[1].strip
            distribution = parts[2].strip
            Chef::Log.info("White list: #{name}, #{url}, #{distribution}")
            white_list.add_entry(name, url, distribution)
          end
        end
      else
        Chef::Log.info("White list configuration file (#{filename}) "\
          'not found!')
      end

      if repo_list.any?
        repo_list.each do |repo|
          # Replace non alpha-numeric characters by "_"
          rname = repo.repo_name.gsub(/[^A-Za-z0-9]/, '_')

          if remote_lists.include? "#{rname}.list"
            Chef::Log.warn("Ignore '#{rname}' repository because the name"\
              ' is duplicated!')
            next
          end

          if white_list.in_white_list(rname, repo.uri, repo.distribution)
            # Add this repository to the system
            remote_lists.push("#{rname}.list")
            apt_repository rname do
              uri repo.uri
              distribution repo.distribution
              components repo.components
              action :nothing
              key repo.repo_key
              keyserver repo.key_server
              deb_src repo.deb_src
            end.run_action(:add)
          else
            Chef::Log.info("Ignore '#{rname}' repository because it is"\
              'NOT in the white list!')
          end
        end
      end

      # Remove all files in "current_lists" that doesn't belong
      # to "remote_lists"
      files_to_remove = current_lists - remote_lists
      files_to_remove.each do |value|
        ::File.delete("/etc/apt/sources.list.d/#{value}")
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
    gecos_ws_mgmt_jobids 'software_sources_res' do
      recipe 'software_mgmt'
    end.run_action(:reset)
  end
end
