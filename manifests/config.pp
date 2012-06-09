class apacheds::config(
  $jks             = '',
  $jks_pw          = '',
  $master          = true,
  $port            = '10389',
  $ssl_port        = '10636',
  $use_ldaps       = true,
  $allow_hashed_pw = true,
  $master_host,
  $parition_dn,
  $version,
) {

  validate_re($port, '^[0-9]+', 'Ports must be numbers')
  validate_re($ssl_port, '^[0-9]+', 'Ports must be numbers')

  $partition_name = regsubst($partition_dn, '^dc=(.*?)(\W.*)', '\1')

  File { mode => '0644', owner => 'apacheds', group => 'root', }

  if str2bool(inline_template("<%= ${version} < '2.0' -%>")) {
    validate_bool($master, '^true$', 'ApacheDS versions earlier than 2.0.0 did not support replication so your only option is a master ldap server')
    file { 'server.xml':
      path    => "/var/lib/apacheds-${version}/default/server.xml",
      content => template("${module_name}/server_xml.erb"),
    }
    file { 'config.ldif':
      path   => "/var/lib/apacheds-${version}/default/config.ldif",
      ensure => absent,
    }
  } else {
    file { "/var/lib/apacheds-${version}":
      ensure => directory,
    }
    file { "/var/lib/apacheds-${version}/default":
      ensure => directory,
    }
    file { 'server.xml':
      path   => "/var/lib/apacheds-${version}/default/server.xml",
      ensure => absent,
    }
    file { 'config.ldif':
      path    => "/var/lib/apacheds-${version}/default/config.ldif",
      content => template("${module_name}/config_ldif.erb"),
      mode    => '0640',
      replace => false,
    }
  }
}
