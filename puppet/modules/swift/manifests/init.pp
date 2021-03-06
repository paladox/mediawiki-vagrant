# == Class: Swift
#
# This Puppet class installs and configures a Swift instance
#
# === Parameters
#
# [*storage_dir*]
#   Path where Swift content will be stored (example: '/var/swift').
#
# [*port*]
#   Port for the proxy server to listen on.
#
# [*key*]
#   Secret key.
#
# [*project*]
#   Project the user belongs to.
#
# [*user*]
#   User.
#
# [*cfg_file*]
#   Swift configuration file. The file will be generated by Puppet.
#
# [*proxy_cfg_file*]
#   Swift proxy server configuration file. The file will be generated by Puppet.
#
# [*account_cfg_file*]
#   Swift account server configuration file. The file will be generated by Puppet.
#
# [*object_cfg_file*]
#   Swift object server configuration file. The file will be generated by Puppet.
#
# [*container_cfg_file*]
#   Swift container server configuration file. The file will be generated by Puppet.
#
class swift (
    $storage_dir,
    $port,
    $key,
    $project,
    $user,
    $cfg_file,
    $proxy_cfg_file,
    $account_cfg_file,
    $object_cfg_file,
    $container_cfg_file,
) {
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http

    $packages = [
        'python-cryptography',
        'python-openssl',
        'python-dnspython',
        'python-eventlet',
        'python-pkg-resources',
        'python-pyasn1',
        'python-setuptools',
        'python-swift*',
        'python-webob',
        'swift*'
    ]

    apt::pin { 'swift-python-backports':
        package  => join(sort($packages), ' '),
        pin      => 'release a=jessie-backports',
        priority => '1000',
    }

    package { ['swift', 'swift-account', 'swift-container', 'swift-object', 'swift-proxy', 'python-webob']:
        ensure  => 'present',
        require => [
            Apt::Pin['swift-python-backports'],
        ],
    }

    exec { 'ins-apt-python-swiftclient':
        command     => '/usr/bin/apt-get update && /usr/bin/apt-get install -y --force-yes -t jessie-backports "python-swiftclient"',
        environment => 'DEBIAN_FRONTEND=noninteractive',
        unless      => '/usr/bin/dpkg -l python-swiftclient',
    }

    user { 'swift':
        ensure     => present,
        managehome => true,
        home       => '/home/swift',
    }

    file { '/etc/swift':
        ensure => 'directory',
        owner  => 'swift',
        group  => 'swift',
    }

    file { '/etc/swift/backups':
        ensure => 'directory',
        owner  => 'swift',
        group  => 'swift',
    }

    file { $storage_dir:
        ensure => 'directory',
        owner  => 'swift',
        group  => 'swift',
    }

    file { "${storage_dir}/1":
        ensure => 'directory',
        owner  => 'swift',
        group  => 'swift',
    }

    file { $cfg_file:
        ensure  => present,
        group   => 'www-data',
        content => template('swift/swift.conf.erb'),
        mode    => '0644',
    }

    file { $proxy_cfg_file:
        ensure  => present,
        group   => 'www-data',
        content => template('swift/proxy-server.conf.erb'),
        mode    => '0644',
    }

    file { '/usr/local/lib/python2.7/dist-packages/wmf/':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/swift/SwiftMedia/wmf/',
        recurse => 'remote',
        require => Package['python-webob'],
    }

    swift::ring { $account_cfg_file:
        ring_type   => 'account',
        cfg_file    => $account_cfg_file,
        storage_dir => $storage_dir,
        ring_port   => 6010,
        require     => Package['swift-account'],
    }

    swift::ring { $object_cfg_file:
        ring_type   => 'object',
        cfg_file    => $object_cfg_file,
        storage_dir => $storage_dir,
        ring_port   => 6020,
        require     => Package['swift-object'],
    }

    swift::ring { $container_cfg_file:
        ring_type   => 'container',
        cfg_file    => $container_cfg_file,
        storage_dir => $storage_dir,
        ring_port   => 6030,
        require     => Package['swift-container'],
    }

    swift::service { 'account-server':
        cfg_file => $account_cfg_file,
        require  => Ring[$account_cfg_file],
    }

    swift::service { 'account-auditor':
        cfg_file => $account_cfg_file,
        require  => Ring[$account_cfg_file],
    }

    swift::service { 'account-reaper':
        cfg_file => $account_cfg_file,
        require  => Ring[$account_cfg_file],
    }

    swift::service { 'account-replicator':
        cfg_file => $account_cfg_file,
        require  => Ring[$account_cfg_file],
    }

    swift::service { 'container-server':
        cfg_file => $container_cfg_file,
        require  => Ring[$container_cfg_file],
    }

    swift::service { 'container-auditor':
        cfg_file => $container_cfg_file,
        require  => Ring[$container_cfg_file],
    }

    swift::service { 'container-replicator':
        cfg_file => $container_cfg_file,
        require  => Ring[$container_cfg_file],
    }

    swift::service { 'container-sync':
        cfg_file => $container_cfg_file,
        require  => Ring[$container_cfg_file],
    }

    swift::service { 'container-updater':
        cfg_file => $container_cfg_file,
        require  => Ring[$container_cfg_file],
    }

    swift::service { 'object-server':
        cfg_file => $object_cfg_file,
        require  => Ring[$object_cfg_file],
    }

    swift::service { 'object-auditor':
        cfg_file => $object_cfg_file,
        require  => Ring[$object_cfg_file],
    }

    swift::service { 'object-replicator':
        cfg_file => $object_cfg_file,
        require  => Ring[$object_cfg_file],
    }

    swift::service { 'object-updater':
        cfg_file => $object_cfg_file,
        require  => Ring[$object_cfg_file],
    }

    swift::service { 'proxy-server':
        cfg_file  => $proxy_cfg_file,
        require   => File['/usr/local/lib/python2.7/dist-packages/wmf/'],
        subscribe => File['/usr/local/lib/python2.7/dist-packages/wmf/'],
    }
}
