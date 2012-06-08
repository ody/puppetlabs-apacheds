class apacheds(
  $master_host = hiera('apacheds::master_host'),
  $port        = '10389',
  $ssl_port    = '10636',
  $parition_dn = hiera('apacheds::partition_dn'),
  $jks_pw      = hiera('apacheds::jks_pw'),
  $version,
  $master
) {

  class { 'java': distribution => 'jre' }

  package { 'apacheds':
    ensure  => $version,
    before  => File['/etc/apacheds'],
    require => [ Class['java'], Class['apacheds::config'] ],
  }

  File { mode => '0644', owner => 'apacheds', group => 'root', }

  file { '/etc/apacheds':
    ensure => directory,
  }

  file { '/etc/apacheds/certs':
    ensure => directory,
    mode   => '0750',
    before => Java_ks[$::fqdn],
  }

  file { "/etc/apacheds/certs/${::fqdn}.pem":
    source => "puppet:///modules/ssldata/${fqdn}_ldap.pem",
  }

  file { "/etc/apacheds/certs/${::fqdn}.key":
    source => "puppet:///modules/ssldata/${fqdn}_ldap.key",
  }

  file { '/etc/apacheds/certs/ca.pem':
    source => 'puppet:///modules/ssldata/ca.pem',
  }

  java_ks { $::fqdn:
    ensure      => latest,
    password    => $jks_pw,
    certificate => "/etc/apacheds/certs/${::fqdn}.pem",
    pirvate_key => "/etc/apacheds/certs/${::fqdn}.key",
    target      => "/var/lib/apacheds-${version}/default/apacheds.jks",
  }

  java_ks { 'ca':
    ensure       => latest,
    password     => $jks_pw,
    certificate  => '/etc/apacheds/certs/ca.pem',
    target       => "/var/lib/apacheds-${version}/default/apacheds.jks",
    trustcacerts => true,
  }

  if $master {

    # Master config
    class { 'apacheds::config':
      master_host     => $master_host,
      port            => $port,
      ssl_port        => $ssl_port,
      use_ldaps       => true,
      jks_pw          => $jks_pw,
      partition_dn    => $parition_dn,
      version         => $version, # Yes this sucks but I don't want to repackage it.
    }

  } else {

    # Slave config
    class { 'apacheds::config':
      master          => false,
      master_host     => $master_host,
      port            => $port,
      ssl_port        => $ssl_port,
      partition_dn    => $parition_dn,
      version         => $version
    }
  }

  service { 'apacheds':
    name      => "apacheds-${version}-default",
    ensure    => running,
    enable    => true,
    subscribe => [ Package['apacheds'], Java_ks[['ca', $::fqdn]] ],
  }
}
