group { 'puppet': ensure => present }
Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }
File { owner => 0, group => 0, mode => 0644 }

package { 'lsb-release':
	ensure => installed,
}

class {'apt':
  always_apt_update => true
}

Class['::apt::update'] -> Package <|
    title != 'python-software-properties'
and title != 'software-properties-common'
|>

apt::source { 'packages.dotdeb.org':
  location          => 'http://packages.dotdeb.org',
  release           => $lsbdistcodename,
  repos             => 'all',
  required_packages => 'debian-keyring debian-archive-keyring',
  key               => '89DF5277',
  key_server        => 'keys.gnupg.net',
  include_src       => true
}



file { '/home/vagrant/.bash_aliases':
  ensure => 'present',
  source => 'puppet:///modules/puphpet/dot/.bash_aliases',
}

package { [
    'build-essential',
    'vim',
    'curl',
    'git-core',
    'htop',
  ]:
  ensure  => 'installed',
}


include 'varnish'

class { 'nginx': }

file { ['/var/www/', '/var/www/web/']:
    ensure => directory,
    force => true
}

file { ['current']:
    path => '/var/www/current',
    target => '/var/www/',
    ensure => link,
}

file { 'index.php':
    path => '/var/www/web/index.php',
    ensure => present,
    content => 'It\'s working!'
}

nginx::resource::vhost { 'tpb.syncr.com.ar':
  ensure       => present,
  server_name  => [
    'tpb.syncr.com.ar'  ],
  listen_port  => 8080,
  index_files  => [
    'index.php'
  ],
  www_root     => '/var/www/current/web/',
  try_files    => ['$uri', '$uri/', '/index.php?$args'],
}

$path_translated = 'PATH_TRANSLATED $document_root$fastcgi_path_info'
$script_filename = 'SCRIPT_FILENAME $document_root$fastcgi_script_name'

nginx::resource::location { 'tpb.syncr.com.ar-php':
  ensure              => 'present',
  vhost               => 'tpb.syncr.com.ar',
  location            => '~ \.php$',
  proxy               => undef,
  try_files           => ['$uri', '$uri/', '/index.php?$args'],
  www_root            => '/var/www/current/web',
  location_cfg_append => {
    'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
    'fastcgi_param'           => 'PATH_INFO $fastcgi_path_info',
    'fastcgi_param '          => $path_translated,
    'fastcgi_param  '         => $script_filename,
    'fastcgi_pass'            => '127.0.0.1:9000',
    'fastcgi_index'           => 'index.php',
    'include'                 => 'fastcgi_params'
  },
  notify              => Class['nginx::service'],
}

class { 'php':
  package             => 'php5-fpm',
  service             => 'php5-fpm',
  service_autorestart => false,
  config_file         => '/etc/php5/fpm/php.ini',
  module_prefix       => ''
}

php::module {
  [
    'php5-cli',
    'php5-curl',
  ]:
  service => 'php5-fpm',
}

service { 'php5-fpm':
  ensure     => running,
  enable     => true,
  hasrestart => true,
  hasstatus  => true,
  require    => Package['php5-fpm'],
}

class { 'php::devel':
  require => Class['php'],
}

class { 'php::pear':
  require => Class['php'],
}

class { 'composer':
  require => Package['php5-fpm', 'curl'],
}

puphpet::ini { 'xdebug':
  value   => [
    'xdebug.default_enable = 1',
    'xdebug.remote_autostart = 0',
    'xdebug.remote_connect_back = 1',
    'xdebug.remote_enable = 1',
    'xdebug.remote_handler = "dbgp"',
    'xdebug.remote_port = 9000'
  ],
  ini     => '/etc/php5/conf.d/zzz_xdebug.ini',
  notify  => Service['php5-fpm'],
  require => Class['php'],
}

puphpet::ini { 'php':
  value   => [
    'date.timezone = "UTC"'
  ],
  ini     => '/etc/php5/conf.d/zzz_php.ini',
  notify  => Service['php5-fpm'],
  require => Class['php'],
}

puphpet::ini { 'custom':
  value   => [
    'display_errors = On',
    'error_reporting = -1',
    'allow_url_fopen = "true"',
    'allow_url_include = "false"',
    'asp_tags = "false"',
    'expose_php = "false"',
    'file_uploads = "false"',
    'memory_limit = "256M"'
  ],
  ini     => '/etc/php5/conf.d/zzz_custom.ini',
  notify  => Service['php5-fpm'],
  require => Class['php'],
}


