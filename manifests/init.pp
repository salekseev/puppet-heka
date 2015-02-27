# == Class: heka
#
# Full description of class heka here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'heka': }
#
# === Authors
#
# Nicholas Chappell <nchappell@newrelic.com>
#
# === Copyright
#
# Copyright 2015 Nicholas Chappell, unless otherwise noted.
class heka (
  $package_download_url = $heka::params::package_download_url,
  $manage_service       = $heka::params::manage_service,
  $service_ensure       = $heka::params::service_ensure,
  $service_enable       = $heka::params::service_enable,
) inherits heka::params {


  if $manage_service == true {
    #Apply our classes in the right order. Use the squiggly arrows (~>) to ensure that the
    #class left is applied before the class on the right and that it also refreshes the
    #class on the right.
    class { 'heka::install':
      package_download_url => $package_download_url,
    } ~>
    class { 'heka::config': } ~>
    class { 'heka::service': }
  }
  else {
    #Like the class chain above, but without the `class { 'heka::service': }`.
    class { 'heka::install':
      package_download_url => $package_download_url,
    } ~>
    class { 'heka::config': }
  }

}