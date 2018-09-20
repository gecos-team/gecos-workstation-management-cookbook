#
# Cookbook Name:: gecos-ws-mgmt
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
name              'gecos_ws_mgmt'
maintainer        'GECOS Team'
maintainer_email  'gecos@guadalinex.org'
license           'Apache 2.0'
description       'Cookbook for GECOS Workstations management'
version           '0.7.0'

depends 'compat_resource'

supports 'ubuntu'
supports 'debian'

# better fields definition via json-schemas:

updated_js = {
  title: 'Updated by',
  title_es: 'Actualizado por',
  type: 'object',
  properties: {
    group: {
      title: 'Groups',
      title_es: 'Grupos',
      type: 'array',
      items: {
        type: 'string'
      }
    },
    user: {
      type: 'string'
    },
    computer: {
      type: 'string'
    },
    ou: {
      title: 'Ous',
      title_es: 'Ous',
      type: 'array',
      items: {
        type: 'string'
      }
    }
  }
}

support_os_js = {
  title: 'Supported OS',
  title_es: 'Sistemas operativos compatibles',
  type: 'array',
  minItems: 0,
  uniqueItems: true,
  items: {
    type: 'string'
  }

}

mobile_broadband_js = {
  title: 'Mobile broadband connections',
  title_es: 'Conexiones de banda ancha móvil',
  type: 'object',
  required: ['connections'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    connections: {
      title: 'Connections',
      title_es: 'Conexiones',
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'object',
        title: 'Provider',
        title_es: 'Proveedor',
        required: %w[country provider],
        order: %w[country provider],
        properties: {
          provider: {
            type: 'string',
            title: 'Provider',
            title_es: 'Proveedor'
          },
          country: {
            type: 'string',
            title: 'Country code',
            title_es: 'Código de país'
          }
        }
      }
    },
    updated_by: updated_js,
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

forticlientvpn_js = {
  title: 'FortiClient VPN connections',
  title_es: 'Conexiones VPN de FortiClient',
  type: 'object',
  required: ['connections'],
  is_mergeable: false,
  autoreverse: false,
  order: %w[connections proxyserver proxyport proxyuser autostart keepalive],
  properties: {
    connections: {
      title: 'Connections',
      title_es: 'Conexiones',
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'object',
        required: %w[name server port],
        order: %w[name server port],
        properties: {
          server: {
            type: 'string',
            title: 'Server',
            title_es: 'Servidor'
          },
          port: {
            type: 'string',
            title: 'Port',
            title_es: 'Puerto'
          },
          name: {
            type: 'string',
            title: 'Name',
            title_es: 'Nombre'
          }
        }
      }
    },
    proxyserver: {
      type: 'string',
      title: 'Proxy Server',
      title_es: 'Servidor Proxy'
    },
    proxyport: {
      type: 'string',
      title: 'Proxy Port',
      title_es: 'Puerto del Proxy'
    },
    proxyuser: {
      type: 'string',
      title: 'Proxy user',
      title_es: 'Usuario del Proxy'
    },
    autostart: {
      type: 'boolean',
      title: 'Proxy user',
      default: false,
      title_es: 'Arranque automatico'
    },
    keepalive: {
      title: 'Keepalive frequency',
      title_es: 'Frecuencia del keepalive',
      type: 'integer'
    },
    updated_by: updated_js,
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

user_mount_js = {
  title: 'User mount external units',
  title_es: 'Montaje de unidades externas',
  type: 'object',
  required: ['users'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: ['can_mount'],
          properties: {
            can_mount: {
              type: 'boolean',
              title: 'Can Mount?',
              title_es: '¿Puede montar?',
              description: 'User can mount external units',
              description_es: 'El usuario podra montar unidades externas'
            },
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

screensaver_js = {
  title: 'Screensaver',
  title_es: 'Salvapantallas',
  type: 'object',
  required: ['users'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: %w[idle_enabled lock_enabled],
          order: %w[lock_enabled lock_delay idle_enabled idle_delay],
          properties: {
            idle_enabled: {
              type: 'boolean',
              title: 'Dim screen',
              title_es: 'Oscurecer pantalla'
            },
            idle_delay: {
              type: 'string',
              description: 'Time to dim screen in seconds',
              description_es: 'Tiempo hasta el oscurecimiento en segundos',
              title: 'Idle delay',
              title_es: 'Retraso de inactividad'
            },
            lock_enabled: {
              type: 'boolean',
              title: 'Allow screen lock',
              title_es: 'Permitir bloqueo de pantalla'
            },
            lock_delay: {
              type: 'string',
              description: 'Time to lock the screen in seconds',
              description_es: ' Tiempo hasta el bloqueo de la pantalla '\
                'en segundos',
              title: 'Time to lock',
              title_es: 'Tiempo hasta el bloqueo'
            },
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

folder_sharing_js = {
  title: 'Sharing permissions',
  title_es: 'Permisos para compartir',
  type: 'object',
  required: ['users'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: %w[can_share],
          properties: {
            can_share: {
              title: 'Can Share?',
              title_es: '¿Puede compartir?',
              description: 'User can share folders',
              description_es: 'El usuario tendrá permisos para '\
                'compartir carpetas',
              type: 'boolean'
            },
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

user_launchers_js = {
  title: 'User Launchers',
  title_es: 'Acceso directo en el escritorio',
  type: 'object',
  required: ['users'],
  is_mergeable: true,
  autoreverse: false,
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: %w[launchers],
          properties: {
            launchers: {
              type: 'array',
              title: 'Shortcut',
              title_es: 'Acceso directo',
              description: 'Enter the name of a .desktop '\
                'file describing the application',
              description_es: 'Introduzca el nombre del fichero '\
                '.desktop que describe la aplicación',
              minItems: 0,
              uniqueItems: true,
              items: {
                type: 'object',
                required: %w[name action],
                order: %w[name action],
                mergeIdField: %w[name],
                mergeActionField: 'action',
                properties: {
                  name: {
                    title: 'Name',
                    title_es: 'Nombre',
                    type: 'string'
                  },
                  action: {
                    title: 'Action',
                    title_es: 'Acción',
                    type: 'string',
                    enum: %w[add remove]
                  }
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
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

desktop_background_js = {
  type: 'object',
  title: 'Desktop Background',
  title_es: 'Fondo de escritorio',
  required: ['users'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: %w[desktop_file],
          properties: {
            desktop_file: {
              type: 'string',
              title: 'Image',
              title_es: 'Imagen',
              description: 'Fill with the absolute path to the image file',
              description_es: 'Introduzca la ruta absoluta al archivo de imagen'
            },
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

file_browser_js = {
  title: 'File Browser',
  title_es: 'Explorador de archivos',
  type: 'object',
  required: %w[users],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: %w[default_folder_viewer show_hidden_files
                       show_search_icon_toolbar click_policy confirm_trash],
          order: %w[click_policy show_hidden_files default_folder_viewer
                    show_search_icon_toolbar confirm_trash],
          properties: {
            default_folder_viewer: {
              type: 'string',
              title: 'files viewer',
              title_es: 'Visualización de archivos',
              enum: ['icon-view', 'compact-view', 'list-view'],
              default: 'icon-view'
            },
            show_hidden_files: {
              type: 'string',
              title: 'Show hidden files?',
              title_es: 'Mostrar archivos ocultos',
              enum: %w[true false],
              default: 'false'
            },
            show_search_icon_toolbar: {
              type: 'string',
              title: 'Show search icon on toolbar?',
              title_es: 'Mostrar el icono de búsqueda en la barra de'\
                ' herramientas',
              enum: %w[true false],
              default: 'true'
            },
            confirm_trash: {
              type: 'string',
              title: 'Confirm trash?',
              title_es: 'Confirmar al vaciar la papelera',
              enum: %w[true false],
              default: 'true'
            },
            click_policy: {
              type: 'string',
              title: 'Click policy',
              title_es: 'Política de click',
              enum: %w[single double],
              default: 'double'
            },
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

cert_js = {
  title: 'Certificate Management',
  title_es: 'Gestion de Certificados',
  type: 'object',
  is_mergeable: true,
  autoreverse: false,
  properties: {
    java_keystores: {
      title: 'Java Keystores',
      title_es: 'Almacenes de claves de Java',
      description: 'Path of java keystore: e.g. /etc/java/cacerts-gcj',
      description_es: 'Ruta del almacén de claves: p.ej. /etc/java/cacerts-gcj',
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    ca_root_certs: {
      title: 'CA root certificates',
      title_es: 'Certificados raices de Autoridades de Certificación (CA)',
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'object',
        properties: {
          name: {
            title: 'Name',
            title_es: 'Nombre',
            type: 'string'
          },
          uri: {
            title: 'Uri certificate',
            title_es: 'Uri del certificado',
            type: 'string'
          }
        }
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }

}

web_browser_js = {
  title: 'Web Browser',
  title_es: 'Navegador Web',
  type: 'object',
  required: ['users'],
  is_mergeable: true,
  autoreverse: false,
  properties: {
    users: {
      type: 'object',
      title: 'Users',
      title_es: 'Usuarios',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          properties: {
            plugins: {
              type: 'array',
              title: 'Plugins',
              title_es: 'Plugins',
              minItems: 0,
              uniqueItems: true,
              items: {
                type: 'object',
                required: %w[name uri action],
                order: %w[name uri action],
                properties: {
                  name: {
                    title: 'Name',
                    title_es: 'Nombre',
                    type: 'string'
                  },
                  uri: {
                    title: 'Uri',
                    title_es: 'Uri',
                    type: 'string'
                  },
                  action: {
                    title: 'Action',
                    title_es: 'Acción',
                    type: 'string',
                    enum: %w[add remove]
                  }
                }
              }
            },
            bookmarks: {
              type: 'array',
              title: 'Bookmarks',
              title_es: 'Marcadores',
              minItems: 0,
              uniqueItems: true,
              items: {
                type: 'object',
                required: %w[name uri],
                order: %w[name uri],
                properties: {
                  name: {
                    title: 'Name',
                    title_es: 'Nombre',
                    type: 'string'
                  },
                  uri: {
                    title: 'Uri',
                    title_es: 'Uri',
                    type: 'string'
                  }
                }
              }
            },
            config: {
              type: 'array',
              title: 'Configs',
              title_es: 'Configuraciones',
              minItems: 0,
              uniqueItems: true,
              items: {
                type: 'object',
                required: ['key'],
                order: %w[key value_type value_str value_num value_bool],
                properties: {
                  key: {
                    type: 'string',
                    title: 'Key',
                    title_es: 'Clave',
                    description: 'Enter a key to about:config',
                    description_es: 'Introduzca una clave de about:config'
                  },
                  value_str: {
                    type: 'string',
                    description: 'Only if Value Type is string',
                    description_es: 'Sólo si el tipo de valor es una cadena',
                    title: 'Value',
                    title_es: 'Valor'
                  },
                  value_num: {
                    type: 'number',
                    description: 'Only if Value Type is number',
                    description_es: 'Sólo si el tipo de valor es un numero',
                    title: 'Value',
                    title_es: 'Valor'
                  },
                  value_bool: {
                    type: 'boolean',
                    description: 'Only if Value Type is boolean',
                    description_es: 'Sólo si el tipo de valor es booleano',
                    title: 'Value',
                    title_es: 'Valor'
                  },
                  value_type: {
                    title: 'Value type',
                    title_es: 'Tipo de valor',
                    type: 'string',
                    enum: %w[string number boolean]
                  }
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
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

email_setup_js = {
  title: 'Email Configuration',
  title_es: 'Configuración de email',
  type: 'object',
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      type: 'object',
      title: 'Users',
      title_es: 'Usuarios',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: %w[base identity],
          order: %w[base identity],
          properties: {
            base: {
              title: 'Base setup',
              title_es: 'Configuración base',
              type: 'object',
              order: %w[email_setup default_email email_template],
              properties: {
                email_setup: {
                  title: 'Perform email setup?',
                  title_es: '¿Configurar correo?',
                  description: 'If this box is not checked the email setup '\
                    'will not be applied',
                  description_es: 'Si no se marca esta casilla no se '\
                    'configurará el correo',
                  type: 'boolean',
                  default: false
                },
                default_email: {
                  title: 'Default profile?',
                  title_es: '¿Perfil por defecto?',
                  description: 'If this box is checked the email will be '\
                    'configured as the default email profile',
                  description_es: 'Si se marca esta casilla se configurará el '\
                    'email como perfil por defecto',
                  type: 'boolean',
                  default: false
                },
                email_template: {
                  title: 'Configuration template',
                  title_es: 'Plantilla de configuración',
                  type: 'string',
                  enum: %w[Plain Secure]
                }
              }
            },
            identity: {
              title: 'Identity of the user',
              title_es: 'Identidad del usuario',
              type: 'object',
              order: %w[name surname email],
              properties: {
                name: {
                  title: 'Name',
                  title_es: 'Nombre',
                  type: 'string'
                },
                surname: {
                  title: 'Surname',
                  title_es: 'Apellidos',
                  type: 'string'
                },
                email: {
                  title: 'Email address',
                  title_es: 'Dirección de correo electrónico',
                  type: 'string'
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
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

im_client_js = {
  title: 'Instant messaging client configuration',
  title_es: 'Configuración del cliente de mensajería intantánea',
  type: 'object',
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      type: 'object',
      title: 'Users',
      title_es: 'Usuarios',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: %w[base identity],
          order: %w[base identity],
          properties: {
            base: {
              title: 'Base setup',
              title_es: 'Configuración base',
              type: 'object',
              order: %w[im_setup overwrite],
              properties: {
                im_setup: {
                  title: 'Perform instant messaging client setup?',
                  title_es: '¿Configurar el cliente de mensajería intantánea?',
                  description: 'If this box is not checked the instant '\
                    'messaging client setup will not be applied',
                  description_es: 'Si no se marca esta casilla no se '\
                    'configurará el cliente de mensajería intantánea',
                  type: 'boolean',
                  default: false
                },
                overwrite: {
                  title: 'Overwrite the whole configuration?',
                  title_es: '¿Sobreescribir toda la configuración?',
                  description: 'If this box is checked the whole configuration'\
                    ' file will be overwriten',
                  description_es: 'Si se marca esta casilla se sobreescribirá '\
                    'el fichero de configuración completo',
                  type: 'boolean',
                  default: false
                }
              }
            },
            identity: {
              title: 'Identity of the user',
              title_es: 'Identidad del usuario',
              type: 'object',
              order: %w[name surname email],
              properties: {
                name: {
                  title: 'Name',
                  title_es: 'Nombre',
                  type: 'string'
                },
                surname: {
                  title: 'Surname',
                  title_es: 'Apellidos',
                  type: 'string'
                },
                email: {
                  title: 'Email address',
                  title_es: 'Dirección de correo electrónico',
                  type: 'string'
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
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

user_alerts_js = {
  title: 'User alert',
  title_es: 'Alertas de usuario',
  type: 'object',
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      type: 'object',
      title: 'Users',
      title_es: 'Usuarios',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: %w[summary body],
          order: %w[summary body urgency icon],
          properties: {
            summary: {
              title: 'Summary for the alert message',
              title_es: 'Titulo para el mensaje de alerta',
              type: 'string'
            },
            body: {
              title: 'Body of the alert message',
              title_es: 'Cuerpo del mensaje de alerta',
              type: 'string'
            },
            urgency: {
              title: 'Urgency level for the alert',
              title_es: 'Nivel de urgencia de la alerta',
              type: 'string',
              enum: %w[low normal critical],
              default: 'normal'
            },
            icon: {
              title: 'Icon filename or stock icon to display',
              title_es: 'Fichero de icono o icono del stock a mostrar',
              description: 'This policy will apply 5 minutes after '\
                'synchronization',
              description_es: 'Esta politica se aplicará 5 minutos después de '\
                'la sincronización',
              type: 'string',
              default: 'info'
            },
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

remote_shutdown_js = {
  title: 'Remote shutdown',
  title_es: 'Apagado remoto',
  type: 'object',
  required: ['shutdown_mode'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    shutdown_mode: {
      title: 'Shutdown mode',
      title_es: 'Tipo de apagado',
      description: 'This policy will apply 5 minutes after synchronization',
      description_es: 'Esta politica se aplicará 5 minutos después de la '\
        'sincronización',
      type: 'string',
      enum: ['halt', 'reboot', ''],
      default: 'halt'
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

user_shared_folders_js = {
  title: 'Shared Folders',
  title_es: 'Carpetas Compartidas',
  type: 'object',
  required: ['users'],
  is_mergeable: false,
  autoreverse: true,
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: ['gtkbookmarks'],
          properties: {
            gtkbookmarks: {
              type: 'array',
              title: 'Bookmarks',
              title_es: 'Marcadores',
              minItems: 0,
              uniqueItems: true,
              items: {
                type: 'object',
                required: %w[name uri],
                properties: {
                  name: {
                    title: 'Name',
                    title_es: 'Nombre',
                    type: 'string'
                  },
                  uri: {
                    title: 'Uri',
                    title_es: 'Uri',
                    type: 'string'
                  }
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
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

appconfig_libreoffice_js = {
  title: 'LibreOffice Config',
  title_es: 'Configuración de LibreOffice',
  type: 'object',
  required: ['config_libreoffice'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    config_libreoffice: {
      title: 'LibreOffice Configuration',
      title_es: 'Configuración de LibreOffice',
      type: 'object',
      properties: {
        app_update: {
          title: 'Enable/Disable auto update',
          title_es: 'Activar/Desactivar actualizaciones automáticas',
          type: 'boolean',
          enum: [true, false],
          default: false
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

appconfig_thunderbird_js = {
  title: 'Thunderbird Config',
  title_es: 'Configuración de Thunderbird',
  type: 'object',
  required: ['config_thunderbird'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    config_thunderbird: {
      title: 'Thunderbird Configuration',
      title_es: 'Configuración de Thunderbird',
      type: 'object',
      properties: {
        app_update: {
          title: 'Enable/Disable auto update',
          title_es: 'Activar/Desactivar actualizaciones automáticas',
          type: 'boolean',
          enum: [true, false],
          default: false
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

appconfig_firefox_js = {
  title: 'Firefox Config',
  title_es: 'Configuración de Firefox',
  type: 'object',
  required: ['config_firefox'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    config_firefox: {
      title: 'Firefox Configuration',
      title_es: 'Configuración de Firefox',
      type: 'object',
      properties: {
        app_update: {
          title: 'Enable/Disable auto update',
          title_es: 'Activar/Desactivar actualizaciones automáticas',
          type: 'boolean',
          enum: [true, false],
          default: false
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

appconfig_java_js = {
  title: 'Java Config',
  title_es: 'Configuración de Java',
  type: 'object',
  required: ['config_java'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    config_java: {
      title: 'Java Configuration',
      title_es: 'Configuración de Java',
      type: 'object',
      order: %w[version plug_version sec crl warn_cert mix_code ocsp tls
                array_attrs],
      properties: {
        version: {
          title: 'Java Version',
          title_es: 'Versión de Java',
          description: 'Path to an installed Java version, example: '\
            '/usr/lib/jvm/java-7-oracle',
          description_es: 'Path a una versión instalada de Java, ej.: '\
            '/usr/lib/jvm/java-7-oracle',
          type: 'string'
        },
        plug_version: {
          title: 'Plugins Java version',
          title_es: 'Plugins versión de Java',
          description: 'Path to an installed Java version, example: '\
            '/usr/lib/jvm/java-7-oracle',
          description_es: 'Path a una versión instalada de Java, ej.: '\
            '/usr/lib/jvm/java-7-oracle',
          type: 'string'
        },
        sec: {
          title: 'Security Level',
          title_es: 'Nivel de Seguridad',
          type: 'string',
          enum: %w[MEDIUM HIGH VERY_HIGH],
          default: 'MEDIUM'
        },
        crl: {
          title: 'Use Certificate Revocation List',
          title_es: 'Utilizar lista de revocación de certificados',
          type: 'boolean',
          enum: [true, false],
          default: false
        },
        ocsp: {
          title: 'Enable or disable Online Certificate Status Protocol',
          title_es: 'Activar o desactivar el protocolo de estado de '\
            'certificados en linea',
          type: 'boolean',
          enum: [true, false],
          default: false
        },
        warn_cert: {
          title: 'Show host-mismatch warning for certificate?',
          title_es: '¿Mostrar advertencia de incompatibilidad de host para el '\
            'certificado?',
          type: 'boolean',
          enum: [true, false],
          default: false
        },
        mix_code: {
          title: 'Security verification of mix code',
          title_es: 'Verificación de la seguridad de la combinación de código',
          type: 'string',
          enum: %w[ENABLE HIDE_RUN HIDE_CANCEL DISABLED],
          default: 'ENABLE'
        },
        tls: {
          title: 'Check validity of TLS certificate',
          title_es: 'Realizar comprobaciones derevocación de certificado TLS',
          type: 'string',
          enum: ['SERVER_CERTIFICATE_ONLY', 'NO_CHECK', ''],
          default: ''
        },
        array_attrs: {
          type: 'array',
          minItems: 0,
          title: 'Another configuration properties',
          title_es: 'Otras propiedades de configuración',
          uniqueItems: true,
          items: {
            type: 'object',
            required: %w[key value],
            properties: {
              key: {
                type: 'string',
                title: 'Key',
                title_es: 'Clave'
              },
              value: {
                type: 'string',
                title: 'Value',
                title_es: 'Valor'
              }
            }
          }
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

auto_updates_js = {
  title: 'Automatic Updates Repository',
  title_es: 'Actualizaciones automáticas de repositorios',
  type: 'object',
  required: ['auto_updates_rules'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    auto_updates_rules: {
      type: 'object',
      title: 'Auto Updates Rules',
      title_es: 'Reglas de actualizaciones automáticas',
      required: %w[onstop_update onstart_update days],
      order: %w[onstart_update onstop_update days],
      properties: {
        onstop_update: {
          title: 'Update on shutdown?',
          title_es: 'Actualizar al apagado',
          type: 'boolean'
        },
        onstart_update: {
          title: 'Update on start',
          title_es: 'Actualizar al inicio',
          type: 'boolean'
        },
        days: {
          type: 'array',
          title: 'Periodic dates',
          title_es: 'Fechas periódicas',
          minItems: 0,
          uniqueItems: true,
          items: {
            type: 'object',
            required: %w[day hour minute],
            order: %w[day hour minute],
            properties: {
              day: {
                title: 'Day',
                title_es: 'Día',
                type: 'string',
                enum: %w[monday tuesday wednesday thursday friday saturday
                         sunday]
              },
              hour: {
                title: 'Hour',
                title_es: 'Hora',
                type: 'integer',
                maximum: 23
              },
              minute: {
                title: 'Minute',
                title_es: 'Minuto',
                type: 'integer',
                maximum: 59
              }
            }
          }
        },
        date: {
          title: 'Specific Date',
          title_es: 'Fecha específica',
          type: 'object',
          order: %w[month day hour minute],
          properties: {
            day: {
              title: 'Day',
              title_es: 'Día',
              type: 'string',
              pattern: '^([0-9]|[0-2][0-9]|3[0-1]|\\\*)$'
            },
            month: {
              title: 'Month',
              title_es: 'Mes',
              type: 'string',
              pattern: '^(0?[1-9]|1[0-2]|\\\*)$'
            },
            hour: {
              title: 'Hour',
              title_es: 'Hora',
              type: 'string',
              pattern: '^((([0-1][0-9])|[0-2][0-3])|\\\*)$'
            },
            minute: {
              title: 'Minute',
              title_es: 'Minuto',
              type: 'string',
              pattern: '^([0-5][0-9]|\\\*)$'
            }
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    updated_by: updated_js
  }
}

boot_lock_js = {
  title: 'Lock boot menu',
  title_es: 'Bloqueo del menú de arranque',
  type: 'object',
  order: %w[lock_boot unlock_user unlock_pass],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    lock_boot: {
      title: 'Lock boot menu?',
      title_es: '¿Bloquear el menú de inicio?',
      type: 'boolean'
    },
    unlock_user: {
      title: 'Unlock user',
      title_es: 'Usuario de desbloqueo',
      type: 'string'
    },
    unlock_pass: {
      title: 'Unlock pass',
      title_es: 'Clave de desbloqueo',
      type: 'string'
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    updated_by: updated_js
  }
}

user_modify_nm_js = {
  title: 'Give network privileges to user',
  title_es: 'Conceder permisos de red al usuario',
  type: 'object',
  required: ['users'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: ['can_modify'],
          properties: {
            can_modify: {
              title: 'Can modify network?',
              title_es: '¿Permisos para modificar la red?',
              type: 'boolean',
              enum: [true, false],
              default: true
            },
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

user_apps_autostart_js = {
  title: 'Applications that will run at the start of the system',
  title_es: 'Aplicaciones que se ejecutarán al inicio',
  type: 'object',
  required: ['users'],
  is_mergeable: true,
  autoreverse: false,
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: ['desktops'],
          additionalProperties: false,
          properties: {
            desktops: {
              title: 'Applications',
              title_es: 'Aplicaciones',
              description: '.desktop file must exist in '\
                '/usr/share/applications',
              description_es: 'Es necesario que exista el .desktop en '\
                '/usr/share/applications',
              type: 'array',
              minItems: 0,
              uniqueItems: true,
              items: {
                type: 'object',
                required: %w[name action],
                order: %w[name action],
                mergeIdField: ['name'],
                mergeActionField: 'action',
                properties: {
                  name: {
                    title: 'Name',
                    title_es: 'Nombre',
                    type: 'string'
                  },
                  action: {
                    title: 'Action',
                    title_es: 'Acción',
                    type: 'string',
                    enum: %w[add remove]
                  }
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
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

tz_date_js = {
  title: 'Administration Date/Time',
  title_es: 'Administración fecha/hora',
  type: 'object',
  required: ['server'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    server: {
      type: 'string',
      title: 'Server NTP',
      title_es: 'Servidor NTP',
      description: 'Enter the URI of an NTP server',
      description_es: 'Introduzca la URI de un servidor NTP'
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    updated_by: updated_js
  }
}

scripts_launch_js = {
  title: 'Scripts Launcher',
  title_es: 'Lanzador de scripts',
  type: 'object',
  required: %w[on_startup on_shutdown],
  is_mergeable: true,
  autoreverse: true,
  order: %w[on_startup on_shutdown],
  properties:
  {
    on_startup: {
      type: 'array',
      title: 'Script to run on startup',
      title_es: 'Script para ejecutar al inicio',
      description: 'Enter the absolute path to the script',
      description_es: 'Introduzca la ruta absoluta al script',
      minItems: 0,
      uniqueItems: false,
      items: {
        type: 'string'
      }
    },
    on_shutdown: {
      type: 'array',
      title: 'Script to run on shutdown',
      title_es: 'Script para ejecutar al apagado',
      description: 'Enter the absolute path to the script',
      description_es: 'Introduzca la ruta absoluta al script',
      minItems: 0,
      uniqueItems: false,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    updated_by: updated_js
  }
}

debug_mode_js = {
  type: 'object',
  title: 'Debug mode',
  title_es: 'Modo diagnóstico',
  required: %w[enable_debug expire_datetime],
  is_mergeable: false,
  autoreverse: true,
  properties:
  {
    enable_debug: {
      title: 'Enable debug mode for this computer?',
      title_es: '¿Habilitar el modo diagnóstico para este puesto?',
      description: 'If this box is checked the computer will send logs to '\
        'the GECOS Control Center.',
      description_es: 'Si se marca esta casilla el puesto enviará logs al '\
        'Centro de Control GECOS',
      type: 'boolean',
      default: false
    },
    expire_datetime: {
      title: 'Expire date and time',
      title_es: 'Fecha y hora de expiración',
      type: 'string'
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

network_resource_js = {
  type: 'object',
  title: 'Network Manager',
  title_es: 'Administrador de red',
  required: ['connections'],
  is_mergeable: false,
  autoreverse: false,
  properties:
  {
    connections: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'object',
        required: %w[name mac_address use_dhcp net_type],
        properties: {
          fixed_con: {
            title: 'DHCP Disabled properties',
            title_es: 'Propiedades desactivadas de DHCP',
            description: 'Only if DHCP is disabled',
            description_es: 'Solo si el DHCP esta desactivado',
            type: 'object',
            properties: {
              addresses: {
                type: 'array',
                uniqueItems: true,
                minItems: 0,
                description: 'This field is only used if DHCP is disabled',
                description_es: 'Este campo solo se usará si el DHCP está '\
                  'desactivado',
                title: 'IP addresses',
                title_es: 'Dirección IP',
                items: {
                  type: 'object',
                  properties: {
                    ip_addr: {
                      type: 'string',
                      title: 'IP address',
                      title_es: 'Dirección IP',
                      description: 'ipv4 format',
                      description_es: 'Formato IPV4',
                      format: 'ipv4'
                    },
                    netmask: {
                      type: 'string',
                      title: 'Netmask',
                      title_es: 'Máscara de red',
                      description: 'ipv4 format',
                      description_es: 'Formato IPV4',
                      format: 'ipv4'
                    }
                  }
                }
              },
              gateway: {
                type: 'string',
                title: 'Gateway',
                title_es: 'Puerta de enlace',
                description: 'ipv4 format',
                description_es: 'Formato ipv4',
                format: 'ipv4'
              },
              dns_servers: {
                type: 'array',
                title: 'DNS Servers',
                title_es: 'Servidor DNS',
                description: 'With DHCP disable',
                description_es: 'Con DHCP desactivado',
                minItems: 0,
                uniqueItems: true,
                items: {
                  type: 'string',
                  title: 'DNS',
                  title_es: 'DNS',
                  description: 'ipv4 format',
                  description_es: 'Formato ipv4',
                  format: 'ipv4'
                }
              }
            }
          },
          name: {
            type: 'string',
            title: 'Network name',
            title_es: 'Nombre de la red'
          },
          mac_address: {
            pattern: '^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$',
            type: 'string',
            title: 'MAC address',
            title_es: 'Dirección MAC'
          },
          use_dhcp: {
            type: 'boolean',
            enum: [true, false],
            default: true,
            title: 'DHCP',
            title_es: 'DHCP'
          },
          net_type: {
            enum: %w[wired wireless],
            title: 'Connection type',
            title_es: 'Tipo de conexión',
            type: 'string'
          },
          wireless_conn: {
            type: 'object',
            title: 'Wireless Configuration',
            title_es: 'Configuración Wireless',
            properties: {
              essid: {
                type: 'string',
                title: 'ESSID',
                title_es: 'ESSID'
              },
              security: {
                type: 'object',
                title: 'Security Configuration',
                title_es: 'Configuración de Seguridad',
                required: ['sec_type'],
                order: %w[sec_type auth_type enc_pass auth_user auth_password],
                properties: {
                  sec_type: {
                    enum: %w[none WEP Leap WPA_PSK],
                    default: 'none',
                    title: 'Security type',
                    title_es: 'Tipo de seguridad',
                    type: 'string'
                  },
                  enc_pass: {
                    type: 'string',
                    description: 'WEP, WPA_PSK security',
                    description_es: 'WEP, seguridad WPA_PSK ',
                    title: 'Password',
                    title_es: 'Contraseña'
                  },
                  auth_type: {
                    enum: %w[OpenSystem SharedKey],
                    title: 'Authentication type',
                    title_es: 'Tipo de autenticación',
                    description: 'WEP security',
                    description_es: 'Seguridad WEP',
                    type: 'string',
                    default: 'OpenSystem'
                  },
                  auth_user: {
                    type: 'string',
                    description: 'Leap security',
                    description_es: 'Seguridad Leap',
                    title: 'Username',
                    title_es: 'Nombre de usuario'
                  },
                  auth_password: {
                    type: 'string',
                    description: 'Leap security',
                    description_es: 'Seguridad Leap',
                    title: 'Password',
                    title_es: 'Contraseña'
                  }
                }
              }
            }
          }
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

software_sources_js = {
  title: 'Software Sources',
  title_es: 'Fuentes de software',
  type: 'object',
  required: ['repo_list'],
  is_mergeable: true,
  autoreverse: true,
  properties: {
    repo_list: {
      type: 'array',
      items: {
        type: 'object',
        required: %w[repo_name uri deb_src repo_key key_server],
        properties: {
          components: {
            title: 'Components',
            title_es: 'Componentes',
            type: 'array',
            items: {
              type: 'string'
            }
          },
          deb_src: {
            title: 'Sources',
            title_es: 'Fuentes',
            type: 'boolean',
            default: false
          },
          repo_key: {
            title: 'Repository key',
            title_es: 'Clave del repositorio',
            type: 'string',
            default: ''
          },
          key_server: {
            title: 'Server key',
            title_es: 'Clave del servidor',
            type: 'string', default: ''
          },
          distribution: {
            title: 'Distribution',
            title_es: 'Distribución',
            type: 'string'
          },
          repo_name: {
            title: 'Repository name',
            title_es: 'Nombre del repositorio',
            type: 'string'
          },
          uri: {
            title: 'Uri',
            title_es: 'Uri',
            type: 'string'
          }
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

package_js = {
  title: 'Packages management',
  title_es: 'Administración de paquetes',
  type: 'object',
  order: ['package_list'],
  is_mergeable: true,
  autoreverse: false,
  properties:
  {
    package_list: {
      type: 'array',
      title: 'Package list',
      title_es: 'Lista de paquetes',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'object',
        required: %w[name version action],
        order: %w[name version action],
        mergeIdField: ['name'],
        mergeActionField: 'action',
        properties: {
          name: {
            title: 'Name',
            title_es: 'Nombre',
            type: 'string'
          },
          version: {
            title: 'Version',
            title_es: 'Versión',
            type: 'string'
          },
          action: {
            title: 'Action',
            title_es: 'Acción',
            type: 'string',
            enum: %w[add remove]
          }
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

printers_js = {
  title: 'Printers',
  title_es: 'Impresoras',
  type: 'object',
  required: ['printers_list'],
  is_mergeable: true,
  autoreverse: true,
  properties:
  {
    printers_list: {
      type: 'array',
      title: 'Printer list to enable',
      title_es: 'Lista de impresoras para activar',
      items: {
        type: 'object',
        required: %w[name manufacturer model uri],
        properties: {
          name: {
            type: 'string',
            title: 'Name',
            title_es: 'Nombre'
          },
          manufacturer: {
            type: 'string',
            title: 'Manufacturer',
            title_es: 'Manufactura'
          },
          model: {
            type: 'string',
            title: 'Model',
            title_es: 'Modelo'
          },
          uri: {
            type: 'string',
            title: 'Uri',
            title_es: 'Uri'
          },
          ppd_uri: {
            type: 'string',
            title: 'Uri PPD',
            title_es: 'Uri PPD',
            default: '',
            pattern: '(https?|ftp|file)://'\
              '[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]'
          },
          ppd: {
            type: 'string',
            title: 'PPD Name',
            title_es: 'Nombre PPD'
          },
          oppolicy: {
            enum: %w[default authenticated kerberos-ad],
            default: 'default',
            type: 'string',
            title: 'Operation Policy',
            title_es: 'Politica de Autenticación'
          }
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

local_users_js = {
  title: 'Users',
  title_es: 'Usuarios',
  type: 'object',
  required: ['users_list'],
  is_mergeable: true,
  autoreverse: false,
  properties: {
    users_list: {
      type: 'array',
      title: 'User list to manage',
      title_es: 'Lista de usuarios para gestionar',
      items: {
        type: 'object',
        required: %w[user actiontorun password],
        order: %w[actiontorun user password name],
        mergeIdField: ['user'],
        mergeActionField: 'actiontorun',
        additionalProperties: false,
        properties: {
          actiontorun: {
            enum: %w[add remove],
            type: 'string',
            title: 'Action',
            title_es: 'Acción'
          },
          user: {
            title: 'User',
            title_es: 'Usuario',
            type: 'string'
          },
          name: {
            title: 'Full Name',
            title_es: 'Nombre Completo',
            type: 'string'
          },
          password: {
            title: 'Password',
            title_es: 'Contraseña',
            type: 'string'
          }
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

local_groups_js = {
  title: 'Local groups',
  title_es: 'Grupos locales',
  type: 'object',
  required: ['groups_list'],
  is_mergeable: true,
  autoreverse: false,
  properties: {
    groups_list: {
      type: 'array',
      title: 'Group to manage',
      title_es: 'Grupos para gestionar',
      uniqueItems: true,
      items: {
        type: 'object',
        required: %w[group user action],
        order: %w[group user action],
        mergeIdField: %w[group user],
        mergeActionField: 'action',
        additionalProperties: false,
        properties: {
          group: {
            type: 'string',
            title: 'Group',
            title_es: 'Grupo'
          },
          user: {
            type: 'string',
            title: 'User',
            title_es: 'Usuario'
          },
          action: {
            title: 'Action',
            title_es: 'Acción',
            type: 'string',
            enum: %w[add remove]
          }
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

local_file_js = {
  title: 'Local files',
  title_es: 'Archivos locales',
  type: 'object',
  required: ['localfiles'],
  is_mergeable: true,
  autoreverse: false,
  additionalProperties: false,
  form: {
    type: 'array',
    title: 'Files list',
    title_es: 'Lista de archivos',
    items: {
      type: 'section',
      items: [
        'localfiles[].file_dest',
        {
          type: 'selectfieldset',
          title: 'Select an action',
          title_es: 'Seleccione una acción',
          key: 'localfiles[].action',
          items: [
            {
              type: 'section',
              items: [
                'localfiles[].file',
                'localfiles[].user',
                'localfiles[].group',
                'localfiles[].mode',
                'localfiles[].overwrite'
              ]
            },
            {
              type: 'section',
              items: [
                'localfiles[].backup'
              ]
            }
          ]
        }
      ]
    }
  },
  properties:
  {
    localfiles: {
      type: 'array',
      title: 'Files list',
      title_es: 'Lista de archivos',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'object',
        required: %w[action file_dest],
        order: %w[action file_dest],
        mergeIdField: ['file_dest'],
        mergeActionField: 'action',
        properties: {
          action: {
            title: 'Action',
            title_es: 'Acción',
            type: 'string',
            enum: %w[add remove]
          },
          file_dest: {
            type: 'string',
            title: 'File Path',
            title_es: 'Ruta del archivo',
            description: 'Enter the absolute path where the file is saved',
            description_es: 'Introduzca la ruta absoluta donde se guardará el'\
              ' archivo'
          },
          user: {
            type: 'string',
            title: 'User',
            title_es: 'Usuario'
          },
          group: {
            type: 'string',
            title: 'Group',
            title_es: 'Grupo'
          },
          mode: {
            type: 'string',
            title: 'Mode',
            title_es: 'Permisos'
          },
          overwrite: {
            type: 'boolean',
            title: 'Overwrite?',
            title_es: 'Sobrescribir'
          },
          backup: {
            type: 'boolean',
            title: 'Create backup?',
            title_es: '¿Crear copia de seguridad?'
          },
          file: {
            type: 'string',
            title: 'File URL',
            title_es: 'URL del archivo',
            description: 'Enter the URL where the file was downloaded',
            description_es: 'Introduzca la URL donde se descargará el archivo'
          }
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

local_admin_users_js = {
  title: 'Local Administrators',
  title_es: 'Administradores locales',
  type: 'object',
  required: ['local_admin_list'],
  order: ['local_admin_list'],
  is_mergeable: true,
  autoreverse: false,
  properties: {
    local_admin_list: {
      type: 'array',
      title: 'users',
      title_es: 'Usuarios',
      description: 'Enter a local user to grant administrator rights',
      description_es: 'Escriba un usuario local para concederle permisos de'\
        ' administrador',
      items: {
        type: 'object',
        required: %w[name action],
        order: %w[name action],
        mergeIdField: ['name'],
        mergeActionField: 'action',
        properties: {
          name: {
            title: 'Name',
            title_es: 'Nombre',
            type: 'string'
          },
          action: {
            title: 'Action',
            title_es: 'Acción',
            type: 'string',
            enum: %w[add remove]
          }
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

folder_sync_js = {
  title: 'Folder to sync',
  title_es: 'Carpeta para sincronizar',
  type: 'object',
  required: ['users'],
  is_mergeable: false,
  autoreverse: false,
  form: {
    type: 'section',
    items: [
      'owncloud_url',
      'owncloud_authuser',
      'owncloud_notifications',
      {
        key: 'owncloud_ask',
        value: 0
      },
      {
        key: 'owncloud_upload_bandwith',
        type: 'range',
        value: 50
      },
      {
        key: 'owncloud_download_bandwith',
        type: 'range',
        value: 100
      },
      'owncloud_folders'
    ]
  },
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          order: %w[
            owncloud_url
            owncloud_authuser
            owncloud_notifications
            owncloud_ask
            owncloud_upload_bandwith
            owncloud_download_bandwith
            owncloud_folders
          ],
          properties: {
            owncloud_url: {
              title: 'Owncloud URL',
              title_es: 'URL de Owncloud',
              type: 'string'
            },
            owncloud_authuser: {
              title: 'User',
              title_es: 'Usuario',
              type: 'string'
            },
            owncloud_notifications: {
              title: 'Desktop Notifications',
              title_es: 'Notificaciones de Escritorio',
              type: 'boolean'
            },
            owncloud_ask: {
              title: 'Ask confirmation before downloading folders larger than',
              title_es: 'Preguntar antes de descargar carpetas de más de',
              type: 'integer'
            },
            owncloud_upload_bandwith: {
              title: 'Upload Bandwith',
              title_es: 'Ancho de banda de subida',
              type: 'integer',
              minimum: 0,
              maximum: 500,
              exclusiveMinimum: false,
              exclusiveMaximum: false,
              description: 'Between 0 and 500 KB/s'
            },
            owncloud_download_bandwith: {
              title: 'Download Bandwith',
              title_es: 'Ancho de banda de bajada',
              type: 'integer',
              minimum: 0,
              maximum: 500,
              exclusiveMinimum: false,
              exclusiveMaximum: false,
              description: 'Between 0 and 500 KB/s'
            },
            owncloud_folders: {
              title: 'Sync folders',
              title_es: 'Carpetas a sincronizar',
              minItems: 0,
              uniqueItems: true,
              type: 'array',
              items: {
                type: 'string'
              }
            },
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

power_conf_js = {
  title: 'Power management',
  title_es: 'Administración de energía',
  type: 'object',
  order: %w[cpu_freq_gov usb_autosuspend auto_shutdown],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    cpu_freq_gov: {
      title: 'CPU frequency governor',
      title_es: 'Control de la frecuencia de la CPU',
      type: 'string',
      enum: ['userspace', 'powersave', 'conservative', 'ondemand',
             'performance', '']
    },
    usb_autosuspend: {
      title: 'USB autosuspend',
      title_es: 'Suspensión automática de USB',
      type: 'string',
      enum: ['enable', 'disable', '']
    },
    auto_shutdown: {
      type: 'object',
      order: %w[hour minute],
      properties: {
        hour: {
          title: 'Hour',
          title_es: 'Hora',
          description: 'Time when the computer is shutdown',
          description_es: 'Hora en que se apagará el equipo',
          type: 'integer',
          maximum: 23
        },
        minute: {
          title: 'Minute',
          title_es: 'Minuto',
          description: 'Minute the computer will shutdown',
          description_es: 'Minuto en que se apagará el equipo',
          type: 'integer',
          maximum: 59
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    updated_by: updated_js
  }
}

shutdown_options_js = {
  title: 'Shutdown Options',
  title_es: 'Opciones de apagado',
  type: 'object',
  required: ['users'],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      type: 'object',
      title: 'Users',
      title_es: 'Usuarios',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: ['disable_log_out'],
          properties: {
            disable_log_out: {
              title: 'Disable log out?',
              title_es: '¿Desactivar apagado?',
              description: 'Checking the box will not allow the computer '\
                'turns off',
              description_es: 'Si activa la casilla no permitira el apagado '\
                'del equipo',
              type: 'boolean',
              default: false
            },
            updated_by: updated_js
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

mimetypes_js = {
  title: 'Default aplications per (MIME) type',
  title_es: 'Aplicaciones preferidas por tipo (MIME)',
  type: 'object',
  is_mergeable: false,
  autoreverse: false,
  properties: {
    users: {
      type: 'object',
      title: 'Users',
      title_es: 'Usuarios',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          properties: {
            mimetyperelationship: {
              type: 'array',
              items: {
                type: 'object',
                required: %w[desktop_entry mimetypes],
                order: %w[desktop_entry mimetypes],
                properties: {
                  desktop_entry: {
                    title: 'Default Program',
                    title_es: 'Programa por defecto',
                    type: 'string'
                  },
                  mimetypes: {
                    title: 'Mimetypes',
                    title_es: 'Tipos MIME',
                    type: 'array',
                    items: {
                      type: 'string'
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

system_proxy_js = {
  title: 'Proxy Configuration',
  title_es: 'Configuración de Proxy',
  type: 'object',
  required: %w[global_config mozilla_config],
  order: %w[global_config mozilla_config],
  is_mergeable: false,
  autoreverse: false,
  properties: {
    global_config: {
      title: 'Global Proxy Configuration',
      title_es: 'Configuración General del Proxy',
      type: 'object',
      order: %w[http_proxy http_proxy_port https_proxy https_proxy_port
                proxy_autoconfig_url disable_proxy],
      properties: {
        http_proxy: {
          title: 'HTTP Proxy',
          title_es: 'Proxy HTTP',
          type: 'string'
        },
        http_proxy_port: {
          title: 'HTTP Proxy Port',
          title_es: 'Puerto del Proxy HTTP',
          type: 'number',
          default: 80
        },
        https_proxy: {
          title: 'HTTPS Proxy',
          title_es: 'Proxy HTTPS',
          type: 'string'
        },
        https_proxy_port: {
          title: 'HTTPS Proxy Port',
          title_es: 'Puerto del Proxy HTTPS',
          type: 'number',
          default: 443
        },
        proxy_autoconfig_url: {
          title: 'Proxy Autoconfiguration URL',
          title_es: 'Url de Autoconfiguración del Proxy',
          type: 'string'
        },
        disable_proxy: {
          title: 'Disable proxy configuration?',
          title_es: '¿Desactivar proxy?',
          description_es: 'Si activa la casilla, desactiva la configuración '\
            'del proxy',
          type: 'boolean',
          default: false
        }
      }
    },
    mozilla_config: {
      title: 'Mozilla Proxy Configuration (Firefox/Thunderbird)',
      title_es: 'Configuración del Proxy en Mozilla (Firefox/Thunderbird)',
      type: 'object',
      order: %w[mode http_proxy http_proxy_port https_proxy https_proxy_port
                proxy_autoconfig_url no_proxies_on],
      properties: {
        mode: {
          type: 'string',
          title: 'Configuration Mode',
          title_es: 'Forma de Configurarlo',
          enum: ['NO PROXY', 'AUTODETECT', 'SYSTEM', 'MANUAL', 'AUTOMATIC']
        },
        http_proxy: {
          title: 'HTTP Proxy',
          title_es: 'Proxy HTTP',
          type: 'string'
        },
        http_proxy_port: {
          title: 'HTTP Proxy Port',
          title_es: 'Puerto del Proxy HTTP',
          type: 'number',
          default: 80
        },
        https_proxy: {
          title: 'HTTPS Proxy',
          title_es: 'Proxy HTTPS',
          type: 'string'
        },
        https_proxy_port: {
          title: 'HTTPS Proxy Port',
          title_es: 'Puerto del Proxy HTTPS',
          type: 'number',
          default: 443
        },
        proxy_autoconfig_url: {
          title: 'Proxy Autoconfiguration URL',
          title_es: 'URL de Autoconfiguración Proxy',
          type: 'string'
        },
        no_proxies_on: {
          title: 'Ignore proxy for',
          title_es: 'No usar proxy para',
          type: 'string'
        }
      }
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

display_manager_js = {
  title: 'Display Manager',
  title_es: 'Gestor de inicio de sesión',
  type: 'object',
  is_mergeable: false,
  autoreversible: false,
  form: {
    type: 'section',
    items: [
      'dm',
      'autologin',
      type: 'section',
      items: [
        {
          key: 'autologin_options.username',
          value: ' '
        },
        {
          key: 'autologin_options.timeout',
          value: 0
        }
      ]
    ]
  },
  properties:
  {
    dm: {
      type: 'string',
      title: 'Select a Display Manager',
      title_es: 'Seleccione un Display Manager',
      enum: %w[MDM LightDM],
      description: 'Autologin timeout in MDM can not be less than 5 seconds.'\
        ' For a kiosk workstation LightDM is recommended because it has got no'\
        ' minimum timeout',
      description_es: 'MDM tiene un tiempo de espera de login automático no '\
        'inferior a 5 segundos. Para un kiosco se recomienda LightDM al no '\
        'tener tiempo de espera mínimo'
    },
    autologin: {
      type: 'boolean',
      title: 'Check this box to enable automatic login',
      title_es: 'Si activa la casilla, habilitará el login automático'
    },
    autologin_options: {
      type: 'object',
      required: %w[username timeout],
      properties: {
        username: {
          title: 'Username',
          title_es: 'Usuario',
          type: 'string',
          default: ''
        },
        timeout: {
          title: 'Autologin user timeout ',
          title_es: 'Timeout de autologin',
          type: 'integer',
          default: 15
        }
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  },
  dependencies: {
    autologin: ['autologin_options']
  },
  customFormItems: {
    autologin: {
      inlinetitle: 'Si activa la casilla, habilitará el login automático',
      toggleNext: 1
    }
  }
}

idle_timeout_js = {
  title: 'Idle session timeout',
  title_es: 'Control de inactividad de sesión',
  type: 'object',
  required: ['users'],
  is_mergeable: false,
  autoreverse: false,
  form: {
    type: 'section',
    items: [
      'idle_enabled',
      type: 'section',
      items: [
        {
          key: 'idle_options.timeout',
          value: 0
        },
        {
          key: 'idle_options.command',
          value: ' '
        },
        {
          key: 'idle_options.notification',
          type: 'textarea',
          value: ' '
        }
      ]
    ]
  },
  properties: {
    users: {
      title: 'Users',
      title_es: 'Usuarios',
      type: 'object',
      patternProperties: {
        '.*' => {
          type: 'object',
          title: 'Username',
          title_es: 'Nombre de usuario',
          required: ['idle_enabled'],
          properties: {
            idle_enabled: {
              title: 'Idle session enabled?',
              title_es: '¿Control de inactividad habilitado?',
              type: 'boolean',
              enum: [true, false],
              default: true
            },
            idle_options: {
              type: 'object',
              title: 'Idle options',
              title_es: 'Opciones de configuración',
              required: %w[timeout command],
              properties: {
                timeout: {
                  title: 'Idle time',
                  title_es: 'Tiempo de inactividad',
                  type: 'integer',
                  description: '(mins)'
                },
                command: {
                  title: 'Command',
                  title_es: 'Comando',
                  type: 'string'
                },
                notification: {
                  title: 'Notification',
                  title_es: 'Notificacion',
                  type: 'string'
                }
              }
            },
            updated_by: updated_js
          },
          dependencies: {
            idle_enabled: ['idle_options']
          },
          customFormItems: {
            idle_enabled: {
              inlinetitle: 'Si activa la casilla, habilitará el control de '\
                'sesión',
              toggleNext: 1
            }
          }
        }
      }
    },
    support_os: support_os_js.clone,
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    }
  }
}

ttys_js = {
  title: 'TTYs Configuration',
  title_es: 'Configuración de Consolas Virtuales',
  type: 'object',
  is_mergeable: false,
  autoreversible: false,
  properties: {
    disable_ttys: {
      type: 'boolean',
      title: 'Disable ttys',
      title_es: 'Deshabilitar consolas virtuales',
      description: 'Checking the box will disable all ttys',
      description_es: 'Si activa la casilla, deshabilitará todas las consolas'\
        ' virtuales del equipo',
      default: false
    },
    job_ids: {
      type: 'array',
      minItems: 0,
      uniqueItems: true,
      items: {
        type: 'string'
      }
    },
    support_os: support_os_js.clone,
    updated_by: updated_js
  }
}

ALL_GECOS_VERS = ['GECOS V3', 'GECOS V2', 'GECOS V3 Lite',
                  'Gecos V2 Lite'].freeze
UBUNTU_BASED = ['GECOS V3', 'GECOS V2', 'GECOS V3 Lite', 'Gecos V2 Lite',
                'Ubuntu 14.04.1 LTS'].freeze
GECOS_FULL = ['GECOS V3', 'GECOS V2'].freeze
debug_mode_js[:properties][:support_os][:default] = ALL_GECOS_VERS
network_resource_js[:properties][:support_os][:default] = ALL_GECOS_VERS
tz_date_js[:properties][:support_os][:default] = ALL_GECOS_VERS
scripts_launch_js[:properties][:support_os][:default] = ALL_GECOS_VERS
local_users_js[:properties][:support_os][:default] = ALL_GECOS_VERS
local_file_js[:properties][:support_os][:default] = ALL_GECOS_VERS
auto_updates_js[:properties][:support_os][:default] = ALL_GECOS_VERS
boot_lock_js[:properties][:support_os][:default] = UBUNTU_BASED
local_groups_js[:properties][:support_os][:default] = ALL_GECOS_VERS
power_conf_js[:properties][:support_os][:default] = ALL_GECOS_VERS
local_admin_users_js[:properties][:support_os][:default] = ALL_GECOS_VERS
software_sources_js[:properties][:support_os][:default] = ALL_GECOS_VERS
package_js[:properties][:support_os][:default] = UBUNTU_BASED
appconfig_libreoffice_js[:properties][:support_os][:default] = ALL_GECOS_VERS
appconfig_thunderbird_js[:properties][:support_os][:default] = ALL_GECOS_VERS
appconfig_firefox_js[:properties][:support_os][:default] = ALL_GECOS_VERS
appconfig_java_js[:properties][:support_os][:default] = ALL_GECOS_VERS
printers_js[:properties][:support_os][:default] = ALL_GECOS_VERS
user_shared_folders_js[:properties][:support_os][:default] = GECOS_FULL
web_browser_js[:properties][:support_os][:default] = ALL_GECOS_VERS
email_setup_js[:properties][:support_os][:default] = ALL_GECOS_VERS
im_client_js[:properties][:support_os][:default] = ALL_GECOS_VERS
file_browser_js[:properties][:support_os][:default] = GECOS_FULL
user_launchers_js[:properties][:support_os][:default] = ALL_GECOS_VERS
desktop_background_js[:properties][:support_os][:default] = GECOS_FULL
user_apps_autostart_js[:properties][:support_os][:default] = ALL_GECOS_VERS
folder_sharing_js[:properties][:support_os][:default] = GECOS_FULL
screensaver_js[:properties][:support_os][:default] = GECOS_FULL
folder_sync_js[:properties][:support_os][:default] = GECOS_FULL
user_mount_js[:properties][:support_os][:default] = ALL_GECOS_VERS
user_alerts_js[:properties][:support_os][:default] = ALL_GECOS_VERS
remote_shutdown_js[:properties][:support_os][:default] = ALL_GECOS_VERS
forticlientvpn_js[:properties][:support_os][:default] = ALL_GECOS_VERS
user_modify_nm_js[:properties][:support_os][:default] = ALL_GECOS_VERS
shutdown_options_js[:properties][:support_os][:default] = ALL_GECOS_VERS
cert_js[:properties][:support_os][:default] = ALL_GECOS_VERS
mobile_broadband_js[:properties][:support_os][:default] = ALL_GECOS_VERS
mimetypes_js[:properties][:support_os][:default] = ALL_GECOS_VERS
system_proxy_js[:properties][:support_os][:default] = ALL_GECOS_VERS
display_manager_js[:properties][:support_os][:default] = ['GECOS Kiosk']
idle_timeout_js[:properties][:support_os][:default] = ['GECOS Kiosk']
ttys_js[:properties][:support_os][:default] = ['GECOS Kiosk']

complete_js = {
  description: 'GECOS workstation management LWRPs json-schema',
  description_es: 'Estación de trabajo de gestión GECOS LWRPs json-schema',
  id: "http://gecos-server/cookbooks/#{name}/#{version}/network-schema#",
  required: ['gecos_ws_mgmt'],
  type: 'object',
  properties: {
    gecos_ws_mgmt: {
      type: 'object',
      required: %w[network_mgmt software_mgmt printers_mgmt misc_mgmt
                   users_mgmt single_node],
      properties: {
        network_mgmt: {
          type: 'object',
          required: %w[forticlientvpn_res mobile_broadband_res
                       system_proxy_res],
          properties: {
            forticlientvpn_res: forticlientvpn_js,
            mobile_broadband_res: mobile_broadband_js,
            system_proxy_res: system_proxy_js
          }
        },
        single_node: {
          type: 'object',
          required: %w[network_res debug_mode_res],
          properties: {
            network_res: network_resource_js,
            debug_mode_res: debug_mode_js
          }
        },
        misc_mgmt: {
          type: 'object',
          required: %w[tz_date_res scripts_launch_res local_users_res
                       local_groups_res local_file_res local_admin_users_res
                       auto_updates_res power_conf_res remote_shutdown_res
                       cert_res boot_lock_res ttys_res],
          properties: {
            tz_date_res: tz_date_js,
            scripts_launch_res: scripts_launch_js,
            local_users_res: local_users_js,
            local_file_res: local_file_js,
            auto_updates_res: auto_updates_js,
            boot_lock_res: boot_lock_js,
            local_groups_res: local_groups_js,
            power_conf_res: power_conf_js,
            local_admin_users_res: local_admin_users_js,
            remote_shutdown_res: remote_shutdown_js,
            cert_res: cert_js,
            ttys_res: ttys_js
          }
        },
        software_mgmt: {
          type: 'object',
          required: %w[software_sources_res package_res
                       appconfig_libreoffice_res appconfig_thunderbird_res
                       appconfig_firefox_res appconfig_java_res
                       display_manager_res],
          properties: {
            software_sources_res: software_sources_js,
            package_res: package_js,
            appconfig_libreoffice_res: appconfig_libreoffice_js,
            appconfig_thunderbird_res: appconfig_thunderbird_js,
            appconfig_firefox_res: appconfig_firefox_js,
            appconfig_java_res: appconfig_java_js,
            display_manager_res: display_manager_js
          }
        },
        printers_mgmt: {
          type: 'object',
          required: ['printers_res'],
          properties: {
            printers_res: printers_js
          }
        },
        users_mgmt: {
          type: 'object',
          required: %w[user_apps_autostart_res
                       user_shared_folders_res web_browser_res
                       email_setup_res im_client_res file_browser_res
                       user_launchers_res folder_sharing_res screensaver_res
                       folder_sync_res user_mount_res shutdown_options_res
                       desktop_background_res user_alerts_res mimetypes_res
                       idle_timeout_res],
          properties: {
            user_shared_folders_res: user_shared_folders_js,
            web_browser_res: web_browser_js,
            email_setup_res: email_setup_js,
            im_client_res: im_client_js,
            file_browser_res: file_browser_js,
            user_alerts_res: user_alerts_js,
            user_launchers_res: user_launchers_js,
            desktop_background_res: desktop_background_js,
            user_apps_autostart_res: user_apps_autostart_js,
            folder_sharing_res: folder_sharing_js,
            screensaver_res: screensaver_js,
            folder_sync_res: folder_sync_js,
            user_mount_res: user_mount_js,
            user_modify_nm_res: user_modify_nm_js,
            shutdown_options_res: shutdown_options_js,
            mimetypes_res: mimetypes_js,
            idle_timeout_res: idle_timeout_js
          }
        }
      }
    }
  }
}

attribute 'json_schema',
          display_name: 'json-schema',
          description: 'Special attribute to include json-schema for defining'\
            ' cookbook\'s input',
          type: 'hash',
          object: complete_js
