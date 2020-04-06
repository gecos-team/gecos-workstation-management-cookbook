#
# Cookbook Name:: gecos-ws-mgmt
# Class UserUtil
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

require 'etc'

# Utility class used to work with users
class UserUtil
  NOBODY = 65_534
  NOGROUP = 65_534

  #
  # Finds the ID of a user.
  #
  # @param [String] username The name of the user.
  #
  # @return [int] 65534 (nobody) if the user can't be found.
  # @return [int] Id of the user.
  #
  def self.get_user_id(username)
    uid = NOBODY
    begin
      uid = Etc.getpwnam(username).uid
    rescue ArgumentError => e
      Chef::Log.warn("Can't get the ID for user #{username}: #{e.message}")
    end
    uid
  end

  #
  # Finds the main group ID of a user.
  #
  # @param [String] username The name of the user.
  #
  # @return [int] 65534 (nogroup) if the user can't be found.
  # @return [int] Group Id of the user.
  #
  def self.get_group_id(username)
    gid = NOGROUP
    begin
      gid = Etc.getpwnam(username).gid
    rescue ArgumentError => e
      Chef::Log.warn("Can't get group ID for user #{username}: #{e.message}")
    end
    gid
  end
end
