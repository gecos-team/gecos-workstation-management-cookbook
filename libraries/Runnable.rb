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
  module Helper

    require 'chef/cookbook/metadata'

    COOKBOOK_NAME = "gecos_ws_mgmt".freeze
    UPDATED = "updated_by".freeze
    AUTOREVERSE = "autoreverse".freeze

    $schema = nil
    
    def load_metadata
      if $schema.nil?
        cookbook_path = Chef::Config[:cookbook_path] + '/' + COOKBOOK_NAME
        Chef::Log.debug("Runnable Helper :::  load_metadata - cookbook_path = #{cookbook_path}")
        if File.exist?(File.join(cookbook_path, 'metadata.rb'))
          metadata_file = File.join(cookbook_path, 'metadata.rb')
        else 
          metadata_file = File.join(cookbook_path, 'metadata.json')
        end
        metadata = Chef::Cookbook::Metadata.new
        metadata.from_file(metadata_file)
        $schema = metadata.attributes[:json_schema][:object][:properties][COOKBOOK_NAME.to_sym][:properties]
      end
    end

    def has_applied_policy?(recipe, policy)
      !node[COOKBOOK_NAME.to_sym][recipe.to_sym][policy.to_sym][UPDATED.to_sym].empty? rescue false
    end

    def is_autoreversible?(recipe, policy)
      $schema[recipe.to_sym][:properties][policy.to_sym][AUTOREVERSE.to_sym] rescue false
    end

    def is_supported?
      new_resource.support_os.include?($gecos_os)
    end
  end
end

Chef::Recipe.send(:include, Runnable::Helper)
Chef::Provider.send(:include, Runnable::Helper)
