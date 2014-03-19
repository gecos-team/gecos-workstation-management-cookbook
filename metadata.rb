name              "gecos_workstation_management"
maintainer        "Roberto C. Morano"
maintainer_email  "rcmorano@emergya.com"
license           "Apache 2.0"
description       "Cookbook for GECOS workstations administration"
version           "0.2.0"


%w{ ubuntu debian }.each do |os|
  supports os
end

# more complete input definition via json-schema:
js = Hash.new
js["id"] = "http://some.site.somewhere/entry-schema#"
# TODO: provide a valid schema URL
#js["$schema"] = "http://github.com/gecos-team/networkmanagement-cookbook/json-schemas/root-schema#"
js["description"] = "GECOS Network Management cookbook attributes json-schema"
js["type"] = "object"
js["required"] = [ "gecos_network_management" ]
js["properties"] = Hash.new
js["properties"]["gecos_network_management"] = Hash.new
js["properties"]["gecos_network_management"]["type"] = "object"
js["properties"]["gecos_network_management"]["required"] = ["default_recipe"]

js["properties"]["gecos_network_management"]["default_recipe"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["type"] = "object"
js["properties"]["gecos_network_management"]["default_recipe"]["required"] = ["setup_connection_resource"]

js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["type"] = "object"
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["required"] = ["network_type"]

js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["network_type"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["network_type"]["type"] = "string"
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["network_type"]["pattern"] = "(wired|wireless)"

js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["use_dhcp"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["use_dhcp"]["type"] = "boolean"

js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["ip_address"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["ip_address"]["type"] = "string"
# TODO: dependency handling
#js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["ip_address"]["dependencies"] = Hash.new
#js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["ip_address"]["dependencies"]["use_dhcp"]
#js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["ip_address"]["dependencies"] = Hash.new

js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["gateway"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["gateway"]["type"] = "string"

js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["netmask"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["netmask"]["type"] = "string"

js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["dns_servers"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["dns_servers"]["type"] = "array"
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["dns_servers"]["minItems"] = 1
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["dns_servers"]["uniqueItems"] = true
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["dns_servers"]["items"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["dns_servers"]["items"]["type"] = "string"
# TODO: add ip patterns
#js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["dns_servers"]["items"]["pattern"] = "_ipregex_here_"

js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["users"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["users"]["type"] = "array"
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["users"]["minItems"] = "0"
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["users"]["uniqueItems"] = "true"
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["users"]["items"] = Hash.new
js["properties"]["gecos_network_management"]["default_recipe"]["setup_connection_resource"]["users"]["items"]["$ref"] = "#/gecos_network_management/default_recipe/setup_connection_resource"

attribute 'json_schema',
  :display_name => "json-schema",
  :description  => "Special attribute to include json-schema for defining cookbook's input",
  :type         => "hash",
  :object       => js

