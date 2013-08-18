class varnish {

 package { varnish:
  ensure => installed
 }

 file { "/etc/varnish/default.vcl":
  ensure => present,
  require => Package["varnish"],
  source => "puppet:///modules/varnish/varnish.vcl";

  "/etc/default/varnish":
   ensure => present,
   require => Package["varnish"],
   source => "puppet:///modules/varnish/default-varnish";
 }

 service { varnish:
  ensure => running,
  enable => true,
  subscribe => File["/etc/default/varnish"];
 }

}
