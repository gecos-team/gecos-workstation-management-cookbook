name              "gecos_ws_mgmt"
maintainer        "Roberto C. Morano"
maintainer_email  "rcmorano@emergya.com"
license           "Apache 2.0"
description       "Cookbook for GECOS workstations administration"
version           "0.3.3"

depends "apt"
depends "chef-client"

%w{ ubuntu debian }.each do |os|
  supports os
end

# more complete input definition via json-schemas:

updated_js = {
  title: "Updated by",
  title_es: "Actualizado por",
  type: "object",
  properties: {
    group: {title: "Groups", type: "array", items: {type:"string"}},
    user: {type:"string"},
    computer: {type:"string"},
    ou: {title: "Ous", type: "array", items: {type:"string"}}
  }
}

support_os_js = {
  title: "Support OS",
  title_es: "Sistemas operativos compatibles",
  type: "array",
  minItems: 0,
  uniqueItems: true,
  items: {
    type: "string"
  }

}
    

sssd_js = {
  title: "Authenticate System",
  title_es: "Autenticación del sistema",
  type: "object",
  required: ["auth_type", "enabled"],
  properties: {
    krb_url: { type: "string" , title: "Url Kerberos file configuration"},
    smb_url: { type: "string" , title: "Url Samba file configuration" },
    sssd_url: { type: "string" , title: "Url SSSD file configuration" },
    domain_list: {
      type:"array",
      items: {
        type:"object",
        required: ["domain_name"],
        properties: {
          domain_name: {pattern: "(?=^.{1,254}$)(^(?:(?!\\d+\\.)[a-zA-Z0-9_\\-]{1,63}\\.?)+(?:[a-zA-Z]{2,})$)", type: "string", title: "Domain name"}
        }
      }
    },
    workgroup: {
        title: "Workgroup",
        title_es: "Grupo de trabajo",
        type: "string"
    },
    enabled: {
      title: "Enabled",
      title_es: "Habilitado",
      type: "boolean", default: false
    },
    auth_type:{
      title: "Authenticate type",
      title_es: "Autenticación del tipo",
      type: "string"
    },
    uri:{
      title: "LDAP Uri",
      title_es: "Uri LDAP",
      type: "string"
    },
    basegroup:{
      title: "Base Group",
      title_es: "Grupo de base",
      type: "string"
    },
    base:{
      title: "Search Base",
      title_es: "Grupo de búsqueda",
      type: "string"
    },
    basegroup:{
      title: "Base Group",
      title_es: "Grupo de base",
      type: "string"
    },
    binddn:{
      title: "BindDN",
      title_es: "BindDN",
      type: "string"
    },
    bindpwd:{
      title: "Bin Password",
      title_es: "Bin contraseña",
      type: "string"
    },
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "string"
      }
    }, 
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

user_mount_js = {
  title: "User mount external units",
  title_es: "Montaje de unidades externas",
  type: "object",
  required: ["users"],
  properties: {
    users: {
      title: "Users",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["can_mount"],
          properties: {
            can_mount: {type: "boolean", title: "Can Mount?"}, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "string"
      }
    }
  }
}

screensaver_js = {
  title: "Screensaver",
  title_es: "Salvapantallas",
  type: "object",
  required: ["users"],
  properties: {
    users: {
      title: "Users",
      title_es: "Usuarios",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["idle_enabled", "lock_enabled"],
          properties: {
            idle_enabled: {
              type: "boolean",
              title: "Idle Enabled?",
	      title_es: "¿Inactividad habilitada?"
            },
            idle_delay: {
              type: "string",
              description: "Seconds",
              description_es: "Segundos",
              title: "Idle Delay",
              title_es: "Retraso de inactividad"              
            },
            lock_enabled: {
              type: "boolean",
              title: "Lock Enabled?",
              title_es: "¿Bloqueo habilitado?"
            },
            lock_delay: {
              type: "string",
              description: "Seconds",
              description_es: "Segundos",
              title: "Lock Delay",
              title_es: "Tiempo de bloqueo"              
            }, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "string"
      }
    }
  }
}

folder_sharing_js = {
  title: "Sharing permissions",
  title_es: "Permisos para compartir",
  type: "object",
  required: ["users"],
  properties: {
    users: {
      title: "Users",
      title_es: "Usuarios",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["can_share"],
          properties: {
            can_share: {title: "Can Share?", type: "boolean"}, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }
  }
}

desktop_control_js = {
  title: "Desktop Control",
  title_es: "Control de escritorio",
  type: "object",
  required: ["users"],
  properties: {
    users: {
      title: "Users",
      title_es: "Usuarios",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["desktop_files"],
          properties: {
            desktop_files: {
              type: "array",
              title: "Desktop Files",
              title_es: "Archivos de escritorio",
              minItems: 0,
              uniqueItems: true,
              items: {
                type: "string"
              }
            }, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }
  }
}


desktop_menu_js = {
  title: "Desktop Menu",
  title_es: "Menú de escritorio",
  type: "object",
  required: ["users"],
  properties: {
    users: {
      title: "Users",
      title_es: "Usuarios",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["desktop_files_include", "desktop_files_exclude"],
          properties: {
            desktop_files_include: {
              type: "array",
              title: "Desktop Files to include",
              title_es: "Archivos de escritorio para incluir",
              minItems: 0,
              uniqueItems: true,
              items: {
                type: "string"
              }
            },
            desktop_files_exclude: {
              type: "array",
              title: "Desktop Files to exclude",
              title_es: "Archivos de escritorio para excluir",
              minItems: 0,
              uniqueItems: true,
              items: {
                type: "string"
              }
            }, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }
  }
}

user_launchers_js = {
  title: "User Launchers",
  title_es: "Lanzadores de usuario",
  type: "object",
  required: ["users"],
  properties: {
    users: {
      title: "Users",
      title_es: "Usuarios",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["launchers"],
          properties: {
            launchers: {
              type: "array",
              title: "Launchers",
              title_es: "Lanzadores",
              minItems: 0,
              uniqueItems: true,
              items: {
                type: "string"
              }
            }, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }
  }
}

#desktop_background_js = {
#  title: "Desktop Background",
#  type: "object",
#  required: ["desktop_file"],
#  properties: {
#    desktop_file: {type: "string", title: "Desktop File"},
#    job_ids: {
#      type: "array",
#      minItems: 0,
#      uniqueItems: true,
#      items: {
#        type: "string"
#      }
#    }, 
#    updated_by: updated_js
#  }
#}
desktop_background_js = {
  type: "object",
  title: "Desktop Background",
  title_es: "Fondo de escritorio",
  required: ["users"],
  properties: {
    users: {
      title: "Users",
      title_es: "Usuarios",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["desktop_file"],
          properties: {
            desktop_file: {type: "string", title: "Desktop File"},
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string",
        }
    }
  }
}


file_browser_js = {
  title: "File Browser",
  title_es: "Explorador de archivos",
  type: "object",
  required: ["users"],
  properties:{
    users: {
      title: "Users",
      title_es: "Usuarios",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["default_folder_viewer", "show_hidden_files", "show_search_icon_toolbar", "click_policy", "confirm_trash"],
          properties: {
            default_folder_viewer: {type: "string", title: "Folder viewer", enum: ["icon-view", "compact-view", "list-view"], default: "icon-view"},
            show_hidden_files: {type: "string", title: "Show hidden files?", enum: ["true","false"], default: "false"},
            show_search_icon_toolbar: {type: "string", title: "Show search icon on toolbar?", enum: ["true", "false"], default: "true"},
            confirm_trash: {type: "string", title: "Confirm trash?", enum: ["true","false"], default: "true"},
            click_policy: {type: "string", title: "Click policy", enum: ["single", "double"], default: "double"}, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }
  }
}






web_browser_js = {
  title: "Web Browser",
  title_es: "Navegador Web",
  type: "object",
  required: ["users"],
  properties: {
    users: {
      type: "object",
      title: "Users",
      title_es: "Usuarios",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          properties: {
            plugins: {
              type: "array",
              title: "Plugins",
              title_es: "Plugins", 
              minItems: 0,
              uniqueItems: true,
              items: {
                type: "object",
                required: ["name", "uri", "action"],
                properties: {
                  name: {title: "Name", type: "string"},
                  uri: {title: "Uri", type: "string"},
                  action: {title: "Action", type: "string", enum: ["add", "remove"]}
                }
              }
            },
            bookmarks: {
              type: "array",
              title: "Bookmarks",
              title_es: "Marcadores",
              minItems: 0,
              uniqueItems: true,
              items: {
                type: "object",
                required: ["name", "uri"],
                properties: {
                  name: {title: "Name", type: "string"},
                  uri: {title: "Uri", type: "string"}
                }
              }
            },
            config: {
              type: "array",
              title: "Configs",
              title_es: "Configuraciones",
              minItems: 0,
              uniqueItems: true,
              items: {
                type: "object",
                required: ["key"],
                properties: {
                  key: {type: "string", title: "Key"},
                  value_str: {type: "string",
                              description: "Only if Value Type is string",
                              description_es: "Solo si el tipo de valor es una cadena",
                              title: "Value",
                              title_es: "Valor"                              
                              },
                  value_num: {type: "number", 
                              description: "Only if Value Type is number",
                              description_es: "Solo si el tipo de valor es un numero",
                              title: "Value",
                              title_es: "Valor"                              
                              },
                  value_bool: {type: "boolean", 
                               description: "Only if Value Type is boolean",
                               description_es: "Solo si el tipo de valor es booleano",
                               title: "Value",
                               title_es: "Valor"                               
                               },
                  value_type: {title: "Value type", type: "string", enum: ["string", "number", "boolean"]}

                }
              }
            },
            #certs: {
            #  type: "array",
            #  title: "Certificates",
            #  title_es: "Certificados",
            #  minItems: 0,
            #  uniqueItems: true,
            #  items: {
            #    type: "object",
            #    required: [ "name", "uri"],
            #    properties: {
            #      name: {title: "Name", type: "string"},
            #      uri: {title: "Uri", type: "string"}
            #    }
            #  }
            #}, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }
  }
}

user_shared_folders_js = {
  title: "Shared Folders",
  title_es: "Carpetas Compartidas",
  type: "object",
  required: ["users"],
  properties: {
    users: {
      title: "Users",
      title_es: "Usuarios",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["gtkbookmarks"],
          properties: {
            gtkbookmarks: {
              type: "array",
              title: "Bookmarks",
              title_es: "Marcadores", 
              minItems: 0,
              uniqueItems: true,
              items: {
                type: "object",
                required: ["name", "uri"],
                properties: {
                  name: {title: "Name", type: "string"},
                  uri: {title: "Uri", type: "string"}
                }
              }
            }, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }
  }
}

app_config_js = {
  title: "Applications Config",
  title_es: "Configuración de aplicaciones",
  type: "object",
 # required: ["citrix_config", "java_config", "firefox_config", "thunderbird_config", "loffice_config"],
  required: ["java_config"],
  properties: {
    #citrix_config: {title: "Citrix Configuration", type: "object"},
    java_config: {
      title: "Java Configuration",
      title_es: "Configuración de Java",
      type: "object",
      properties: {
        version: {
          title: "Java Version",
          title_es: "Versión de Java",
          type: "string"
        },
        plug_version: {
          title: "Plugins Java version",
          title_es: "Plugins versión de Java",
          type: "string"
        },
        sec: {
          title: "Security Level",
          title_es: "Nivel de Seguridad",
          type: "string",
          enum: ["MEDIUM", "HIGH", "VERY_HIGH"],
          default: "MEDIUM"
        },
        crl: {
          title: "Use Certificate Revocation List",
          title_es: "Utilizar lista de revocación de certificados",
          type: "boolean",
          enum: [true,false],
          default: false
        },
        ocsp: {
          title: "Enable or disable Online Certificate Status Protocol",
          title_es: "Activar o desactivar el protocolo de estado de certificados en linea",
          type: "boolean",
          enum: [true,false],
          default: false
        },
        warn_cert: {
          title: "Show host-mismatch warning for certificate?",
          title_es: "¿Mostrar advertencia de incompatibilidad de host para el certificado?",
          type: "boolean",
          enum: [true,false],
          default: false
        },
        mix_code: {
          title: "Security verification of mix code",
          title_es: "Verificación de la seguridad de la combinación de código",
          type: "string",
          enum: ["ENABLE", "HIDE_RUN", "HIDE_CANCEL", "DISABLED"],
          default: "ENABLE"
        },
        array_attrs: {
          type: "array",
          minItems: 0,
          title: "Another configuration properties",
          uniqueItems: true,
          items:{
            type: "object",
            required: ["key", "value"],
            properties: {
              key: {type: "string", title: "Key"},
              value: {type: "string", title: "Value"}
            }
          }
        }

      }
    },
    firefox_config: {
      title: "Firefox Configuration",
      type: "object",
      properties: {
        app_update:{
          title: "Enable/Disable auto update",
          type: "boolean",
          enum: [true,false],
          default: false
        }
      }
    },
    #thunderbird_config: {title: "Thuderbird Configuration", type: "object"},
    #loffice_config: {title: "Libre Office Configuration", type: "object"},
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }, 
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

auto_updates_js = {
  title: "Automatic Updates",
  type: "object",
  required: ["auto_updates_rules"],
  properties: {
    auto_updates_rules: {
      type: "object",
      title: "Auto Updates Rules",
      required: ["onstop_update", "onstart_update", "days"],
      properties: {
        onstop_update: {title: " On stop Update?", type: "boolean"},
        onstart_update: {title: "On start Update?", type: "boolean"},
        days: {
          type: "array",
          title: "Days",
          minItems: 0,
          uniqueItems: true,
          items: {
            type: "object",
            required: ["day", "hour", "minute"],
            properties: {
              day: {
                title: "Day",
                type: "string",
                enum: ["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]
              },
              hour: {
                title: "Hour",
                type: "integer",
                maximum: 23
              },
              minute: {
                title: "Minute",
                type: "integer",
                maximum: 59
              }

            }
          }
        },
        date: {
          title: "Date",
          type: "object",
          properties: {
            day: {title: "Day", type: "string", pattern: "^([0-9]|[0-2][0-9]|3[0-1]|\\\*)$"},
            month: {title: "Month", type: "string",pattern: "^(0?[1-9]|1[0-2]|\\\*)$"},
            hour: {title: "Hour", type: "string", pattern: "^((([0-1][0-9])|[0-2][0-3])|\\\*)$"},
            minute: {title: "Minute", type: "string",pattern: "^([0-5][0-9]|\\\*)$"},
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }, 
    updated_by: updated_js
  }
}


user_apps_autostart_js = {
  title: "Autostart applications",
  type: "object",
  required: ["users"],
  properties: {
    users: {
      title: "Users",
      type: "object",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["desktops"],
          properties: {
            desktops: {
              title: "Desktops",
              type: "array",
              minItems: 0,
              uniqueItems: true,
              items: {type: "string"}
            }, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }
  }
}

tz_date_js = {
  title: "Date/Time Manager",
  type: "object",
  required: ["server"],
  properties: {
    server: {
      type: "string",
      title: "Server"
    },
    support_os: support_os_js.clone,
    job_ids: {
        type: "array",
        minItems: 0,
        uniqueItems: true,
        items: {
          type: "string"
        }
    }, 
    updated_by: updated_js
  }
}

scripts_launch_js = {
  title: "Scripts Launcher",
  type: "object",
  required: ["on_startup","on_shutdown"],
  properties:
  {
    on_startup: {
      type: "array",
      title: "Script list to run on startup",
      minItems: 0,
      uniqueItems: false,
      items: {
        type: "string",
        }
    },
    on_shutdown: {
      type: "array",
      title: "Script list to run on shutdown",
      minItems: 0,
      uniqueItems: false,
      items: {
        type: "string",
        }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "string"
      }
    }, 
    updated_by: updated_js
  }
}

network_resource_js = {
  type: "object",
  title: "Network Manager",
  required: ["connections"],
  properties:
  {
    connections: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "object",
        required: ["name", "mac_address", "use_dhcp", "net_type"],
        properties: {
          fixed_con: {
           # title: "DHCP Disabled properties",
           # description: "Only if DHCP is disabled",
            type: "object",
            properties:{
              addresses: {
                type: "array",
                uniqueItems: true,
                minItems: 0,
            #    description: "With DHCP disable",
                title: "IP addresses",
                items: {
                  type: "object",
                  #required: [ "ip_addr","netmask"],
                  properties:{
                    ip_addr: {
                      type: "string",
                      title: "IP address",
                      #description: "ipv4 format",
                      format: "ipv4"
                    },
                    netmask: {
                      type: "string",
                      title: "Netmask",
                      #description: "ipv4 format",
                      format: "ipv4"
                    }
                  }
                } 
              },
              gateway: {
                type: "string",
                title: "Gateway",
                #description: "ipv4 format",
                format: "ipv4"
              },
              dns_servers: {
                type: "array",
                title: "DNS Servers",
                #description: "With DHCP disable",
                minItems: 0,
                uniqueItems: true,
                items: {
                  type: "string",
                  title: "DNS",
                  #description: "ipv4 format",
                  format: "ipv4"
                }
              }
            }
          },
          name: {type: "string", title: "Name"},
          mac_address: {pattern: "^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$", type: "string", title: "MAC address"},
          use_dhcp: {type: "boolean", enum: [true,false], default:true, title: "DHCP"},
          net_type:{
            enum: ["wired", "wireless"], title: "Connection type", type: "string"
          },
          wireless_conn:{
            type:"object",
            #title: "Wireless Configuration",
            properties:{
              essid: { type: "string", title: "ESSID" },
              security: { 
                type: "object", 
                title: "Security Configuration",
                required: ["sec_type"],
                properties:{
                  sec_type: { enum: [ "none", "WEP", "Leap", "WPA_PSK"], default:"none", title: "Security type", type:"string"},
                  enc_pass: { type: "string", 
                              #description: "WEP, WPA_PSK security",
                              title: "Password"                   
                            },
                  auth_type: { enum: ["OpenSystem", "SharedKey"], 
                               title: "Authentication type",
                               #description: "WEP security",
                               type: "string", 
                               default: "OpenSystem"},
                  auth_user: { type: "string",
                               #description: "Leap security",
                               title: "Username"                                
                               },
                  auth_password: { type: "string",
                                   #description: "Leap security",
                                   title: "Password"
                                 }

                }
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
        type: "string"
      }
    }, 
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

software_sources_js = {
  title: "Software Sources",
  type: "object",
  required: ["repo_list"],
  properties:{
    repo_list: {
      type:"array",
      items: {
        type:"object",
        required: ["repo_name","distribution","components","uri","deb_src","repo_key","key_server"],
        properties:{
          components: { title: "Components", type: "array",items: { type: "string" } },
          deb_src: { title: "Sources", type: "boolean", default: false },
          repo_key: { title: "Repository key", type: "string", default: ""},
          key_server: { title: "Server key", type: "string", default: ""},
          distribution: { title: "Distribution", type: "string"},
          repo_name: { title: "Repository name", type: "string"},
          uri: { title: "Uri", type: "string" }
        }
      }
    },
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "string"
      }
    }, 
    support_os: support_os_js.clone,
    updated_by: updated_js
   }
}


package_js = {
  title: "Packages",
  type: "object",
  properties:
  {
    package_list: {
      type:"array",
      title: "Package list to install",
      minItems: 0,
      uniqueItems: true,
      items: {type: "string"}
    },
    pkgs_to_remove: {
      type:"array",
      title: "Package list to remove",
      minItems: 0,
      uniqueItems: true,
      items: {type: "string"}
    },
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "string"
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

printers_js = {
  title: "Printers",
  type: "object",
  required: ["printers_list"],
  properties:
  {
    printers_list: {
      type:"array",
      title: "Printer list to enable",
      items: {
        type:"object",
        required: [ "name", "manufacturer", "model", "uri"],
        properties:{
          name: { type: "string", title: "Name" },
          manufacturer: { type: "string", title: "Manufacturer" },
          model: { type: "string" , title: "Model"},
          uri: { type: "string", title: "Uri" },
          ppd_uri: { type: "string", title: "Uri PPD", default: "", pattern: "(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]"},
          ppd: { type: "string", title: "PPD Name"}
        }
      }
    },
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "string"
      }
    }, 
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

local_users_js = {
  title: "Local users",
  type: "object",
  required: ["users_list"],
  properties:
  {users_list: {
      type:"array",
      title: "User list to manage",
      items: {
        type:"object",
        required: ["user","actiontorun"],
        properties:{
          actiontorun: {enum: ["create","modify","delete"],type: "string"},
          groups: { title: "Groups", type: "array",items: { type: "string" } },
          user: { title: "User", type: "string" },
          name: { title: "Full Name", type: "string" },
          password: { title: "Password", type: "string"}
        }
     }
  },
  job_ids: {
    type: "array",
    minItems: 0,
    uniqueItems: true,
    items: {
      type: "string"
    }
  }, 
  support_os: support_os_js.clone,
  updated_by: updated_js
 }
}

local_groups_js = {
  title: "Local groups",
  type: "object",
  required: ["groups_list"],
  properties:
  {groups_list: {
      type:"array",
      title: "Group List to manage",
      items: {
        type:"object",
        required: ["group"],
        properties:{
          group: { type: "string", title: "Group" },
          users: { type: "array",title: "Users", items: { type: "string" } }
        }
     }
  },
  job_ids: {
    type: "array",
    minItems: 0,
    uniqueItems: true,
    items: {
      type: "string"
    }
  }, 
  support_os: support_os_js.clone,
  updated_by: updated_js
 }
}

local_file_js = {
  title: "Local files",
  type: "object",
  required: ["delete_files", "copy_files"],
  properties:
  {delete_files: {
      type:"array",
      title: "File list to delete",
      items: {
        type:"object",
        required: ["file"],
        properties:{
          file: {type: "string", title:"File"},
          backup: { type: "boolean", title: "Create backup?" }
        }
     }
  },
  copy_files: {
    type: "array",
    title: "File list to copy",
    items: {
      type: "object",
      required: ["file_orig","file_dest"],
      properties:{
        file_orig: {type: "string", title: "Url File"},
        file_dest: {type: "string", title: "File path destination"},
        user: {type: "string", title:"User"},
        group: {type: "string", title: "Group"},
        mode: {type: "string", title: "Mode"},
        overwrite: {type: "boolean", title: "Overwrite?"}
      }
    }
  },
  job_ids: {
    type: "array",
    minItems: 0,
    uniqueItems: true,
    items: {
      type: "string"
    }
  }, 
  support_os: support_os_js.clone,
  updated_by: updated_js
 }
}

local_admin_users_js = {
  title: "Local Admin Users",
  type: "object",
  required: ["local_admin_list"],
  properties:
  {local_admin_list: {
      type:"array",
      title: "Local users to grant admin permissions", 
      items: { type:"string"}
  },
  job_ids: {
    type: "array",
    minItems: 0,
    uniqueItems: true,
    items: {
      type: "string"
    }
  }, 
  support_os: support_os_js.clone,
  updated_by: updated_js
 }
}

folder_sync_js = {
  title: "Folder to sync",
  type: "object",
  required: ["users"],
  properties:
  {users: {
    title: "Users", 
    type: "object",
    patternProperties: {
      ".*" => { type: "object", title: "Username",
        required: ["remote_folders"],
        properties: {
          username: {title: "Username", type: "string"},
          remote_folders: {
            type: "array",
            title: "Remote Folders",
            items: {type: "string"},
            minItems: 0,
            uniqueItems:true
          }, 
          updated_by: updated_js
        }
      }
    }
  },
  support_os: support_os_js.clone,
  job_ids: {
    type: "array",
    minItems: 0,
    uniqueItems: true,
    items: {
      type: "string"
    }
  }
 }
}

power_conf_js = {
  title: "Power management",
  type: "object",
  required: ["cpu_freq_gov","auto_shutdown","usb_autosuspend"],
  properties:
    {cpu_freq_gov: {
       title: "CPU frequency governor", 
       type: "string",
       enum: ["userspace","powersave","conservative","ondemand","performance",""]
       },
    usb_autosuspend: 
      {
       title: "USB autosuspend",
       type: "string",  
       enum: ["enable","disable", ""]
       },
     auto_shutdown: {
       type: "object",
       properties: {
         hour: {
           title: "Hour",
           #description:"Time to shutdown",
           type: "integer",
           maximum: 23
           },
         minute: {
           title: "Minute",
           #description:"Time to shutdown",                                                                                                                                                                                     
           type: "integer",
           maximum: 59
         }
       }  
  },
  support_os: support_os_js.clone,
  job_ids: {
    type: "array",
    minItems: 0,
    uniqueItems: true,
    items: {
      type: "string"
    }
  }, 
  updated_by: updated_js
 }
}

shutdown_options_js = {
  title: "Shutdown Options",
  type: "object",
  required: ["users"],
  properties: { 
    systemlock: { type: "boolean", title: "System-wide lockdown of the key" },
    users: {
      type: "object", 
      title: "Users",
      patternProperties: {
        ".*" => { type: "object", title: "Username",
          required: ["disable_log_out"],
          properties:{
            disable_log_out: {
              title: "Disable log out?",
              type: "boolean",
              default: false
            }, 
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: "array",
      minItems: 0,
      uniqueItems: true,
      items: {
        type: "string"
      }
    }
 }
}

network_resource_js[:properties][:support_os][:default]=["GECOS V2"]
tz_date_js[:properties][:support_os][:default]=["GECOS V2"]
scripts_launch_js[:properties][:support_os][:default]=["GECOS V2"]
local_users_js[:properties][:support_os][:default]=["GECOS V2"]
local_file_js[:properties][:support_os][:default]=["GECOS V2"]
auto_updates_js[:properties][:support_os][:default]=["GECOS V2"]
local_groups_js[:properties][:support_os][:default]=["GECOS V2"]
power_conf_js[:properties][:support_os][:default]=["GECOS V2"]
local_admin_users_js[:properties][:support_os][:default]=["GECOS V2"]
software_sources_js[:properties][:support_os][:default]=["GECOS V2"]
package_js[:properties][:support_os][:default]=["GECOS V2","Ubuntu 14.04.1 LTS"]
app_config_js[:properties][:support_os][:default]=["GECOS V2"]
printers_js[:properties][:support_os][:default]=["GECOS V2"]
user_shared_folders_js[:properties][:support_os][:default]=["GECOS V2"]
web_browser_js[:properties][:support_os][:default]=["GECOS V2"]
file_browser_js[:properties][:support_os][:default]=["GECOS V2"]
user_launchers_js[:properties][:support_os][:default]=["GECOS V2"]
desktop_background_js[:properties][:support_os][:default]=["GECOS V2"]
desktop_menu_js[:properties][:support_os][:default]=[]
desktop_control_js[:properties][:support_os][:default]=[]
user_apps_autostart_js[:properties][:support_os][:default]=["GECOS V2"]
folder_sharing_js[:properties][:support_os][:default]=["GECOS V2"]
screensaver_js[:properties][:support_os][:default]=["GECOS V2"]
folder_sync_js[:properties][:support_os][:default]=[]
user_mount_js[:properties][:support_os][:default]=["GECOS V2"]
shutdown_options_js[:properties][:support_os][:default]=["GECOS V2"]


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
            #sssd_res: sssd_js
          }
        },
        misc_mgmt: {
          type: "object",
          required: ["tz_date_res", "scripts_launch_res", "local_users_res", "local_groups_res", "local_file_res", "local_admin_users_res", "auto_updates_res","power_conf_res"],
          properties: {
            tz_date_res: tz_date_js,
            scripts_launch_res: scripts_launch_js,
            local_users_res: local_users_js,
            local_file_res: local_file_js,
           # desktop_background_res: desktop_background_js,
            auto_updates_res: auto_updates_js,
            local_groups_res: local_groups_js,
            power_conf_res: power_conf_js,
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
            printers_res: printers_js
          }
        },
        users_mgmt: {
          type: "object",
          required: ["user_apps_autostart_res", "user_shared_folders_res", "web_browser_res", "file_browser_res", "user_launchers_res", "desktop_menu_res", "desktop_control_res", "folder_sharing_res", "screensaver_res","folder_sync_res", "user_mount_res","shutdown_options_res","desktop_background_res"],
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
