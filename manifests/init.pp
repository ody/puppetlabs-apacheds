class apacheds(
  $master_host = hiera('apacheds::master_host'),
  $port        = '10389',
  $ssl_port    = '10636',
  $parition_dn = hiera('apacheds::partition_dn'),
  $jks         = '',
  $jks_pw      = '',
  $replica_id  = '1',
  $version,
  $master
) {

  class { 'java': distribution => 'jre' }

  package { 'apacheds':
    ensure  => $version,
    require => [ Class['java'], Class['apacheds::config'] ],
  }

  File { mode => '0644', owner => 'apacheds', group => 'root', }

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
