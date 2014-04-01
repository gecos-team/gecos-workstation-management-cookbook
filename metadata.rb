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

user_mount_js = {
  type: "object",
  required: ["users"],
  properties: {
    users: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "obejct",
        required: ["username","can_mount"],
        properties: {
          username: {type: "string"},
          can_mount: {type: "boolean"}
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

screensaver_js = {
  type: "object",
  required: ["users"],
  properties: {
    users: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "object",
        required: ["username", "lock_enabled"],
        properties: {
          username: {
            type: "string"
          },
          idle_delay: {
            type: "string"
          },
          lock_enabled: {
            type: "boolean"
          },
          lock_delay: {
            type: "string"
          }
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

folder_sharing_js = {
  type: "object",
  required: ["users"],
  properties: {
    users: {
      type: "array",
      minItem: 0,
      uniqueItem: true,
      items: {
        type: "object",
        required: ["username", "can_share"],
        properties: {
          username: {type: "string"},
          can_share: {type: "boolean"}
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

desktop_control_js = {
  type: "object",
  required: ["users"],
  properties: {
    users: {
      type: "array",
      minItem: 0,
      uniqueItem: true,
      items: {
        type: "object",
        required: ["username", "desktop_files"],
        properties: {
          username: {type: "string"},
          desktop_files: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
              type: "string"
            }
          }
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


desktop_menu_js = {
  type: "object",
  required: ["users"],
  properties: {
    users: {
      type: "array",
      minItem: 0,
      uniqueItem: true,
      items: {
        type: "object",
        required: ["username", "desktop_files"],
        properties: {
          username: {type: "string"},
          desktop_files: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
              type: "string"
            }
          }
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

user_launchers_js = {
  type: "object",
  required: ["users"],
  properties: {
    launchers: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items:{
        type: "object",
        required: ["username", "launchers"],
        properties: {
          username: {type: "string"},
          launchers: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
              type: "string"
            }
          }
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

desktop_background_js = {
  type: "object",
  required: ["users"],
  properties: {
    users: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "object",
        required: ["username", "desktop_file"],
        properties: {
          username: {type: "string"},
          desktop_file: {type: "string"}
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


file_browser_js = {
  type: "object",
  required: ["users"],
  properties:{
    file_browser_conf: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "object",
        required: ["username", "auto_mount", "explore_net", "show_options_mount", "burn_disc"],
        properties: {
          user: {type: "srting"},
          auto_mount: {type: "boolean"},
          explore_net: {type: "boolean"},
          show_options_mount: {type: "boolean"},
          burn_disc: {type: "boolean"}
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






web_browser_js = {
  type: "object",
  required: ["users"],
  properties: {
    users: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "object",
        required: ["username"],
        properties: {
          username: {type: "string"},
          plugins: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
              type: "object",
              required: ["title", "uri"],
              properties: {
                title: {type: "string"},
                uri: {type: "string"}
              }
            }
          },
          bookmarks: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
              type: "object",
              required: ["title", "uri"],
              properties: {
                title: {type: "string"},
                uri: {type: "string"}
              }
            }
          },
          config: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
              type: "object",
              required: ["key", "value"],
              properties: {
                key: {type: "string"},
                value: {type: "string"}
              }
            }
          },
          certs: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
              type: "object",
              required: [ "name", "uri"],
              properties: {
                name: {type: "string"},
                uri: {type: "string"}
              }
            }
          }
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

user_shared_folders_js = {
  type: "object",
  required: ["users"],
  properties: {
    users: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "object",
        required: ["username", "gtkbookmarks"],
        properties: {
          username: {type: "string"},
          gtkbookmarks: {    
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
              type: "object",
              required: ["title", "uri"],
              properties: {
                title: {type: "string"},
                uri: {type: "string"}
              }
            }
          }
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

app_config_js = {
  type: "object",
  required: ["adobe_config", "java_config", "firefox_config", "thunderbird_config"],
  properties: {
    adobe_config: {type: "object"},
    java_config: {type: "object"},
    firefox_config: {type: "object"},
    thunderbird_config: {type: "object"},
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

auto_updates_js = {
  type: "object",
  required: ["auto_updates_rules"],
  properties: {
    auto_updates_rules: {
      type: "object",
      required: ["logout_update", "start_update", "days"],
      properties: {
        logout_update: {type: "boolean"},
        start_update: {type: "boolean"},
        days: {
          type: "array",
          minItems: 0,
          uniqueItems: true,
          items: {
            type: "object",
            required: ["day", "hour", "period"],
            properties: {
              day: {
                type: "string", 
                pattern: "(monday|tuesday|wednesday|thursday|friday|saturday|sunday)"
              },
              hour: {
                type: "integer",
                pattern: "[0-12]"
              },
              period: {
                type: "string",
                pattern: "(am|pm)"
              }
            }
          }
        },
        date: {
          type: "object",
          required: ["day", "month", "year"],
          properties: {
            day: {type: "integer", maximum: 31},
            month: {type: "integer", maximum: 12},
            year: {type: "integer"}
          }
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


user_apps_autostart_js = {
  type: "object",
  required: ["users"],
  properties: {
    autostart_files: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "object",
        required: ["username", "desktops"],
        properties: {
          username: {type: "string"},
          desktops: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {type: "string"}
          }
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
          use_dhcp: { type: "boolean" },
          certs: {
            type: "array",
            minItems: 0,
            uniqueItems: true,
            items: {
              type: "object",
              required: ["name","uri"],
              properties: {
                name: {type: "string"},
                uri: {type: "string"}
              }
            }
          }
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

software_sources_js = {
  type: "object",
  required: ["repo_list"],
  properties: 
  {repo_list: {
      type:"array",
      items: {
        type:"object",
        required: ["repo_name","distribution","components","uri","deb_src","repo_key","key_server"],
        properties:{
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

package_js = {
  type: "object",
  required: ["package_list"],
  properties: 
  {package_list: {type:"array"},
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

printers_resource_js = {
  type: "object",
  required: ["printer_list"],
  properties: 
  {
    printer_list: {
      type:"array",
      items: {
        type:"object",
        required: [ "name", "manufacturer", "model", "shared", "users_allowed", "groups_allowed" ],
        properties:{
          name: { type: "string" },
          manufacturer: { type: "string" },
          model: { type: "string" },
          uri: { type: "string" },
          shared: { type: "boolean", default: false },
          ppd: { type: "string", default: ""},
          ppd_uri: { type: "string", default: ""},
          users_allowed: { type: "array", items: { type: "string" } },
          groups_allowed: { type: "array", items: { type: "string" } }
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

local_users_js = {
  type: "object",
  required: ["users_list"],
  properties: 
  {users_list: {
      type:"array",
      items: {
        type:"object",
        required: ["user","actiontorun"],
        properties:{
          actiontorun: {pattern: "(create|delete)",type: "string"},
          groups: { type: "array",items: { type: "string" } },
          user: { type: "string" },
          password: { type: "string"}
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

local_groups_js = {
  type: "object",
  required: ["groups_list"],
  properties: 
  {groups_list: {
      type:"array",
      items: {
        type:"object",
        required: ["group"],
        properties:{
          group: { type: "string" },
          users: { type: "array",items: { type: "string" } }
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

local_file_js = {
  type: "object",
  required: ["delete_files", "copy_files"],
  properties: 
  {delete_files: {
      type:"array",
      items: {
        type:"object",
        required: ["file"],
        properties:{
          file: {type: "string"},
          backup: { type: "boolean" }
        }
     }
  },
  copy_files: {
    type: "array",
    items: {
      type: "object",
      required: ["file_orig","file_dest"],
      properties:{
        file_orig: {type: "string"},
        file_dest: {type: "string"},
        user: {type: "string"},
        group: {type: "string"},
        mode: {type: "string"},
        overwrite: {type: "boolean"}
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

local_admin_users_js = {
  type: "object",
  required: ["local_admin_list"],
  properties: 
  {local_admin_list: {
      type:"array",
      items: { type:"string"}
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

folder_sync_js = {
  type: "object",
  required: ["folder_sync"],
  properties: 
  {folder_sync: {
    type: "array",
    items: {
      type: "object",
      required: ["user","remote_folders"],
      properties:{
        user: {type: "string"},
        remote_folders: {
          type: "object",
          required: ["Documentos","Escritorio"],
          properties:{
            documentos: {type: "string"},
            Escritorio: {type: "string"}
          }
        }
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

shutdown_options_js = {
  type: "object",
  required: ["users"],
  properties:
  {users: {
    type: "array",
    items: {
      type: "object",
      required: ["user","options"],
      properties:{
        user: {type: "string"},
        options: {type: "array",items:{pattern: "(shutdown|restart|close_session)",type:"string"}}
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
      required: ["network_mgmt","software_mgmt", "printers_mgmt", "misc_mgmt", "users_mgmt"],
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
          required: ["tz_date_res", "scripts_launch_res", "local_users_res", "local_groups_res", "local_file_res", "local_admin_users_res", "auto_updates_res"], 
          properties: {
            tz_date_res: tz_date_js,
            scripts_launch_res: scripts_launch_js,
            local_users_res: local_users_js,
            local_file_res: local_file_js,
            auto_updates_res: auto_updates_js,
            local_groups_res: local_groups_js,
            local_admin_users_res: local_admin_users_js
          }
        },
        software_mgmt: {
          type: "object",
          required: ["software_sources_res","package_res", "app_config_res"],
          properties: {
            software_sources_res: software_sources_js,
            package_res: package_js,
            app_config_res: app_config_js
          }
        },
        printers_mgmt: {
          type: "object",
          required: ["printers_res"],
          properties: {
            printers_res: printers_resource_js
          }
        },
        users_mgmt: {
          type: "object",
          required: ["user_apps_autostart_res", "user_shared_folders_res", "web_browser_res", "file_browser_res", "desktop_background_res", "user_launchers_res", "desktop_menu_res", "desktop_control_res", "folder_sharing_res", "screensaver_res","folfer_sync_res", "user_mount_res","shutdown_options_res"],
          properties: {
            user_shared_folders_res: user_shared_folders_js,
            web_browser_res: web_browser_js,
            file_browser_res: file_browser_js,
            user_launchers_res: user_launchers_js,
            desktop_background_res: desktop_background_js,
            desktop_menu_res: desktop_menu_js,
            desktop_control_res: desktop_control_js,
            user_apps_autostart_res: user_apps_autostart_js,
            folder_sharing_res: folder_sharing_js,
            screensaver_res: screensaver_js,
            folder_sync_res: folder_sync_js,
            user_mount_res: user_mount_js,
            shutdown_options_res: shutdown_options_js
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
