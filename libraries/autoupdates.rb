
# This library code install a new version of client when it is available in the repositories
# We do not use chef common procedures to avoid compile phase errors

Chef::Log.info('Chef client version check')

require 'fileutils'

new_version = `aptitude search '?and(?upgradable,?exact-name(chef))'`

# Force chef-client update if new version available
if !new_version.empty?
  Chef::Log.info('Chef client upgrade required!')
  $update_cmd = `apt-get update`
  $upgrade_agent =  `apt-get install chef`
# Configure embedded gemrc as system gemrc
  if File.exists?('/opt/chef/embedded')
    FileUtils.mkdir_p('/opt/chef/embedded/etc/')
    FileUtils.install('/etc/gemrc','/opt/chef/embedded/etc/gemrc')
# Install required gems
    $gems_installation=`/opt/chef/embedded/bin/gem install rest-client json activesupport netaddr`
  end
# Relaunch itself right now
  Chef::Log.info('New chef client relaunch')
  exec( '/usr/bin/chef-client' )
end

