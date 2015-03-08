#puppet-heka
> [github.com/nickchappell/puppet-heka](https://github.com/nickchappell/puppet-heka)
- - -

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
    * [Packages](#packages)
    * [Init scripts and Upstart/systemd files](#init-upstart-systemd-files)
    * [TOML config files](#toml-config-files)
        * [Global Heka configuration](#global-heka-configuration)
        * [TOML config files for plugins](#toml-config-files-for-plugins)
3. [Setup - The basics of getting started with heka](#setup)
    * [Setup requirements](#setup-requirements)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Basic usage](#basic-usage)
        * [Parameter data types](#parameter-data-types)
    * [Plugins](#plugins)
        * [Inputs](#plugins-inputs)
            * [`TcpInput`](#plugins_inputs_tcpinput)
            * [`UdpInput`](#plugins_inputs_udpinput)
            * [`StatsdInput`](#plugins_inputs_statsdinput)
        * [Custom plugins](#custom-plugins)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##[Overview](id:overview)

This module installs and configures [Heka](http://hekad.readthedocs.org/en/latest/index.html), a metric/log/event router and processor.

##[Module Description](id:module-description)

This module installs Heka via the published packages and configures it by templating TOML configuration files for both Heka's global configuration and for plugins.

###[Packages](id:packages)

This module uses the RPM packages available on Heka's Github releases page:

[https://github.com/mozilla-services/heka/releases](https://github.com/mozilla-services/heka/releases)

###[Init scripts and Upstart/systemd files](id:init-upstart-systemd-files)

Because the Heka packages do not include init scripts or Upstart/systemd unit files, this module includes an Upstart file template for Red Hat/CentOS 6 and a systemd unit file for Red Hat/CentOS 7.

###[TOML config files](id:toml-config-files)

####[Global Heka configuration](id:global-heka-configuration)

The module templates `/etc/heka.toml`. Currently, it only specifies a `maxprocs` value. 

To specify global configuration options the module doesn't explicitly provide parameters for, you can use the `global_config_settings` parameter, which is a hash and uses the key/value pairs as the key/value pairs printed in `heka.toml`:

```bash
class { '::heka':
  global_config_settings => {
    'poolsize' => 10000,
  },
}
```

Heka sets these to its own defaults. See [Configuring hekad > Global configuration options](http://hekad.readthedocs.org/en/latest/config/index.html#global-configuration-options) for more info on what global configuration options are available and what Heka's internal default values are.

####[TOML config files for plugins](id:toml-config-files-for-plugins)

This module has defined types and and accompanying ERB templates for a few commonly used plugins.

This module also has a more generic defined type and ERB template so you can configure any Heka plugin with the module without having to 

##[Setup](id:setup)

###[Setup Requirements](id:setup-requirements)

This module requires the following Puppet modules:

* nanlui/staging

##[Usage](id:usage)

###[Basic usage](id:basic-usage)

The following installs and configures Heka with it's default settings. The `maxprocs` in Heka's main config will be set to the value of the `processorcount` fact. All other global config values won't be printed in the main config file unless specified as parameters. If they aren't printed in the file, Heka will use its own internal default value for each setting.

```bash
class { '::heka':}
```

To specify a custom configuration option the module doesn't provide an explicit parameter for, use the `global_config_settings` parameter: 

```bash
class { '::heka':
  global_config_settings => {
    'poolsize' => 10000,
    'hostname' => "\"${::fqdn}\"",
  },
}
```

####[Puppet parameter and Heka data types](id:parameter-data-types)

**Booleans**

Config values that are supposed to be booleans in a TOML config can be used as a boolean in your Puppet code:


```bash
::heka::plugin::input::tcpinput { 'tcpinput1':
...  
  refresh_heka_service => true,
...
}
```

**Strings**

Config values that are supposed to be double-quoted strings in the TOML file should be entered as single-quoted strings in your Puppet code:

```bash
::heka::plugin::input::tcpinput { 'tcpinput1':
...
  address => '127.0.0.1:5565'
...
}
```

**Note:** This only applies to the included defined types already included in the module. If you use the generic `heka::plugin` type or the `global_config_settings` parameter of the main `heka` class, you must enter your value parameters for strings as they will appear in the TOML file. This means including the double-quotes:

```bash
::heka::plugin { 'dashboard1':
  type => 'DashboardOutput',
  settings => {
    'address' => '"0.0.0.0:4352"',
...
  },
}
```

If you need to interpolate Facter facts, enclose the whole parameter in double-quotes and escape the internal set of dobule-quotes that need to be printed:

```bash
::heka::plugin { 'dashboard1':
  type => 'DashboardOutput',
  settings => {
    'address' => "\"${::ipaddress_lo}:4352\"",
...
  },
}
```

**Integers**

Config values that are supposed to be integers in the TOML config file can be written as integers in your Puppet code:

```bash
::heka::plugin { 'dashboard3':
  type => 'DashboardOutput',
  settings => {
...
    'ticker_interval' => 6,
...
  },
}
```

**IP addresses and ports**

IP address/port combos in Heka TOML configs are entered as double-quoted strings. You can enter them in your Puppet code as regular strings with single quotes:

```bash
::heka::plugin::input::tcpinput { 'tcpinput1':
...
  address => '127.0.0.1:5565'
...
}
```

You can use Facter facts for IP addresses by using `${}` inside of double quotes for variable interpolation in your Puppet code:

```bash
::heka::plugin::input::tcpinput { 'tcpinput1':
...
  address => "${::ipaddress_lo}:5565"
...
}
```

###[Plugins](id:plugins)

####Common parameters

Each plugin's defined type and the custom plugin type have the following parameters in common:

* `plugin_dir`: the directory the TOML plugin file will be created in; defaults to `/etc/heka`.
* `plugin_file_name`: the name of the TOML plugin file; defaults to `$name.toml`.
* `plugin_file_ensure`: the type of file resource to create; defaults to `file`.
* `plugin_file_owner`: the owner of the TOML plugin file; defaults to `root`.
* `plugin_file_group`: the group of the TOML plugin file; defaults to `root`.
* `plugin_file_mode`: the mode of the TOML plugin file; defaults to `0644`.
* `plugin_file_template`: the ERB template to use to generate the TOML plugin file

####Plugin type settings

Heka allows just using the plugin's type as a name if there is only one instance of that plugin that's configured.

Plugins configured via this module, however, require explicit names. The `type` setting for the plugin is already specified for the plugin types the module includes. 

You'll have to specify the type if you use the `heka::plugin` type to create a custom plugin config.

####[Inputs](id:plugins-inputs)

#####[**TcpInput**](id:plugins_inputs_tcpinput)

[Heka documentation: TcpInput](http://hekad.readthedocs.org/en/latest/config/inputs/tcp.html)

```bash
::heka::plugin::input::tcpinput { 'tcpinput1':
  refresh_heka_service => true,
  address => "${::ipaddress_lo}:5565"
}
```

#####[**UdpInput**](id:plugins_inputs_udpinput)

[Heka documentation: UdpInput](http://hekad.readthedocs.org/en/latest/config/inputs/udp.html)

```bash
::heka::plugin::input::udpinput { 'udpinput1':
  refresh_heka_service => true,
  address => "${::ipaddress_lo}:4484"
}
```

####[**StatsdInput**](id:plugins_inputs_statsdinput)

[Heka documentation: UdpInput](http://hekad.readthedocs.org/en/latest/config/inputs/udp.html)

**Note:** An instance of this plugin **must** be accompanied by an instance of the `StatAccumInput` in order for Heka to start properly!

```bash
::heka::plugin::input::statsdinput { 'statsdinput1':
  address => "0.0.0.0:8125"
}
```

####[Custom plugins](id:custom-plugins)

You can use the `heka::plugin` defined type to generate TOML configs for plugins that the module doesn't already include:

```bash
::heka::plugin { 'dashboard3':
  type => 'DashboardOutput',
  settings => {
    'address' => '"10.0.1.120:4354"',
    'ticker_interval' => 6,
  },
}
```

The `type` parameter is required.

**Settings**

`settings` is a hash that will get used to generate the key/value pairs in the TOML file.

```bash
settings => {
  'script_type' => '"lua"',
  'filename' => '"lua_decoders/nginx_access.lua"',
},
```

...would generate the following in the final TOML file:

```bash
filename = "lua_decoders/nginx_access.lua"
script_type = "lua"
```

**Subsection settings**

You can use the `subsetting_sections` parameter to specify any sections of subsettings a plugin might require:

```bash
  subsetting_sections => {
    'config' => {
      'log_format' => '\'$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"\'',
      'type' => '"nginx.access"',
    },
  }
```

The `subsetting_sections` parameter above would generate the following TOML data:

```bash
[nginx_access_decoder.config]
log_format = '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'
type = "nginx.access"
```

A `heka::plugin` with a `subsetting_sections` parameter would look like:

```bash
::heka::plugin { 'nginx_access_decoder':
  refresh_heka_service => true,
  type => 'SandboxDecoder',
  settings => {
    'script_type' => '"lua"',
    'filename' => '"lua_decoders/nginx_access.lua"',
  },
  subsetting_sections => {
    'config' => {
      'log_format' => '\'$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"\'',
      'type' => '"nginx.access"',
    },
  }
}
```

The rendered TOML file the above `heka::plugin` generates would be:

```bash
[nginx_access_decoder]
type = "SandboxDecoder"
filename = "lua_decoders/nginx_access.lua"
script_type = "lua"

  [nginx_access_decoder.config]
  log_format = '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'
  type = "nginx.access"
```

##Limitations

Only Red Hat and CentOS are supported right now.

##Development

Make PRs against the develop branch on Github: [https://github.com/nickchappell/puppet-heka/tree/develop](https://github.com/nickchappell/puppet-heka/tree/develop)