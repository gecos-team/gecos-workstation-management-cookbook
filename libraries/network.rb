#
# Cookbook Name:: gecos-ws-mgmt
# Library:: network
#

module NetworkFunctions

    def setup_network_resource_depends()
        gem_depends = [ 'netaddr' ] 
        
        gem_depends.each do |gem|
        
          r = gem_package gem do
            action :nothing
          end
          r.run_action(:install)
        
        end
        Gem.clear_paths
    end

end
