name              "gecos_ws_mgmt"
maintainer        "Roberto C. Morano"
maintainer_email  "rcmorano@emergya.com"
license           "Apache 2.0"
description       "Cookbook for GECOS workstations administration"
version           "0.2.0"


%w{ ubuntu debian }.each do |os|
  supports os
end



# more complete input definition via json-schemas:
network_resource_js = {
    type: "object",
    required: ["network_type"],
    properties:
    {
        gateway: { type: "string" },
        ip_address: { type:"string" },
        netmask: { type: "string" },
        network_type: { pattern: "(^wired$|wireless)", type: "string" },
        use_dhcp: { type: "boolean" },
        users: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
                type: "object",
                required: ["username","network_type"],
                properties: {
                    username: { type: "string" },
                    gateway: { type: "string" },
                    ip_address: { type:"string" },
                    netmask: { type: "string" },
                    network_type: { pattern: "(^wired$|wireless|vpn|proxy)", type: "string" },
                    use_dhcp: { type: "boolean" }
                }
            }
        }
    }
}


complete_js = { 
    description: "GECOS workstation management LWRPs json-schema",
    id: "http://gecos-server/cookbooks/#{name}/#{version}/network-schema#",
    required: ["gecos_ws_mgmt"],
    type: "object",
    properties: {
        gecos_ws_mgmt: {
            type: "object",
            required: ["network_management_recipe"],
            properties: {
                network_management_recipe: {
                    type: "object",
                    required: ["network_resource"],
                    properties: {
                        network_resource: network_resource_js
                    }
                }
            }
        }
    }
}

attribute 'json_schema',
  :display_name => "json-schema",
  :description  => "Special attribute to include json-schema for defining cookbook's input",
  :type         => "hash",
  :object       => complete_js

