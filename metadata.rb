name              "gecos_ws_mgmt"
maintainer        "Roberto C. Morano"
maintainer_email  "rcmorano@emergya.com"
license           "Apache 2.0"
description       "Cookbook for GECOS workstations administration"
version           "0.2.0"

depends "apt"

%w{ ubuntu debian }.each do |os|
  supports os
end

# more complete input definition via json-schemas:
tz_date_js = {
  type: "object",
  required: ["server"],
  properties: {
    server: {
      type: "string"
    },
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "object",
          required: ["id"],
          properties: {
            id: { type: "string" },
            status: { type: "string" }
          }
        }
    }
  }
}

scripts_launch_js = {
  type: "object",
  required: ["scripts"],
  properties:
  {
    scripts: {
      type: "array",
      minItems: 0,
      uniqueItems: false,
      items: {
        type: "object",
        required: ["command","c_type"],
        properties: {
          command: {type: "string"},
          c_type: {type: "string", pattern: "(autostart|logout)"}
        }
      }
    },
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "object",
        required: ["id"],
        properties: {
          id: { type: "string" },
          status: { type: "string" }
        }
      }
    }
  } 
}
network_resource_js = {
  type: "object",
  required: ["network_type"],
  properties:
  {
    gateway: { type: "string" },
    ip_address: { type:"string" },
    netmask: { type: "string" },
    network_type: { pattern: "(wired|wireless)", type: "string" },
    use_dhcp: { type: "boolean" },
    dns_server: {
      type: "array",
      minItems: 1,
      uniqueItems: true,
      items: {
        type: "string"
      }
    },
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
          network_type: { pattern: "(wired|wireless|vpn|proxy)", type: "string" },
          use_dhcp: { type: "boolean" }
        }
      }
    },
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "object",
        required: ["id"],
        properties: {
          id: { type: "string" },
          status: { type: "string" }
        }
      }
    }
  }
}

software_sources_resource_js = {
  type: "object",
  required: ["repo_list"],
  properties: 
  {repo_list: {
      type:"array",
      items: {
        type:"object",
        required: ["repo_name","distribution","components","actiontorun","uri","deb_src","repo_key","key_server"],
        properties:{
          actiontorun: {pattern: "(add|remove)",type: "string"},
          components: { type: "array",items: { type: "string" } },
          deb_src: { type: "boolean", default: false },
          repo_key: { type: "string", default: ""},
          key_server: { type: "string", default: ""},
          distribution: { type: "string"},
          repo_name: { type: "string"},
          uri: { type: "string" }
        }
     }
   
  },
  job_ids: {
    type: "array",
    minItems: 0,
    uniqueItems: true,
    items: {
      type: "object",
      required: ["id"],
      properties: {
        id: { type: "string" },
        status: { type: "string" }
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
      required: ["network_mgmt","software_mgmt","misc_mgmt"],
      properties: {
        network_mgmt: {
          type: "object",
          required: ["network_res"],
          properties: {
            network_res: network_resource_js
          }
        },
        misc_mgmt: {
          type: "object",
          required: ["tz_date_res", "scripts_launch_res"], 
          properties: {
            tz_date_res: tz_date_js,
            scripts_launch_res: scripts_launch_js
          }
        },
        software_mgmt: {
          type: "object",
          required: ["software_sources_res"],
          properties: {
            software_sources_res: software_sources_resource_js
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

