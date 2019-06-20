#
# Cookbook Name:: gecos-ws-mgmt
# Runnable Helper
#
# Copyright 2019, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

module Runnable
  # Helper module
  module Helper
    require 'chef/cookbook/metadata'

    COOKBOOK_NAME = 'gecos_ws_mgmt'.freeze
    UPDATED = 'updated_by'.freeze
    AUTOREVERSE = 'autoreverse'.freeze

    class << self
      attr_accessor :schema
    end

    self.schema = nil

    def check_metadata_file
      cookbook_path = Chef::Config[:cookbook_path] + '/' + COOKBOOK_NAME
      Chef::Log.debug('Runnable Helper :::  load_metadata - cookbook_path = '\
        " #{cookbook_path}")
      metadata_file = File.join(cookbook_path, 'metadata.json')
      if File.exist?(File.join(cookbook_path, 'metadata.rb'))
        metadata_file = File.join(cookbook_path, 'metadata.rb')
      end

      metadata_file
    end

    def load_metadata
      return unless Runnable::Helper.schema.nil?
      metadata = Chef::Cookbook::Metadata.new
      metadata.from_file(check_metadata_file)
      Runnable::Helper.schema = metadata.attributes[:json_schema][:object]\
        [:properties][COOKBOOK_NAME.to_sym][:properties]
    end

    def user_policy_active?(policy_data)
      users = policy_data[:users]
      updated_users = users.select do |_, values|
        values.key?(UPDATED) && !values[UPDATED].empty?
      end
      updated_users != {}
    end

    def computer_policy_active?(policy_data)
      policy_data.key?(UPDATED.to_sym) && !policy_data[UPDATED.to_sym].empty?
    end

    def policy_active?(recipe, policy)
      policy_data = node[COOKBOOK_NAME.to_sym][recipe.to_sym][policy.to_sym]
      if recipe.include?('users_mgmt') # User policy
        user_policy_active?(policy_data)
      else # Workstation policy
        computer_policy_active?(policy_data)
      end
    rescue StandardError => e
      Chef::Log.error("Runnable Helper ::: Oooops! Has ocurred an error: #{e}")
      false
    end

    def policy_autoreversible?(recipe, policy)
      Runnable::Helper.schema[recipe.to_sym][:properties][
        policy.to_sym].key?(AUTOREVERSE.to_sym)
    end

    def os_supported?
      if new_resource.support_os.include?($gecos_os)
        true
      else
        Chef::Log.info('This resource is not supported in your OS')
        false
      end
    end
  end
end

Chef::Recipe.send(:include, Runnable::Helper)
Chef::Provider.send(:include, Runnable::Helper)
