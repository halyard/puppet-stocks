# @summary Configure stock ticker metrics
#
# @param tickers lists the stock tickers to track
# @param version sets the version of stock-exporter to install
# @param binfile sets the install path for the stock-exporter binary
# @param prometheus_server_ip sets the IP range to allow for prometheus connections
# @param port to serve the metrics on
# @param interval sets how frequently to poll in seconds
class stocks (
  Array[String] $tickers,
  String $version = 'v0.0.2',
  String $binfile = '/usr/local/bin/stock-exporter',
  String $prometheus_server_ip = '0.0.0.0/0',
  Integer $port = 9092,
  Integer $interval = 300,
) {
  $kernel = downcase($facts['kernel'])
  $arch = $facts['os']['architecture'] ? {
    'x86_64'  => 'amd64',
    'arm64'   => 'arm64',
    'aarch64' => 'arm64',
    'arm'     => 'arm',
    default   => 'error',
  }

  $filename = "stock-exporter_${kernel}_${arch}"
  $url = "https://github.com/akerl/stock-exporter/releases/download/${version}/${filename}"

  file { $binfile:
    ensure => file,
    source => $url,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    notify => Service['stock-exporter'],
  }

  -> file { '/usr/local/etc/stock-exporter.yaml':
    ensure  => file,
    mode    => '0644',
    content => template('stocks/stock-exporter.yaml.erb'),
    notify  => Service['stock-exporter'],
  }

  -> file { '/etc/systemd/system/stock-exporter.service':
    ensure => file,
    source => 'puppet:///modules/stocks/stock-exporter.service',
  }

  ~> service { 'stock-exporter':
    ensure => running,
    enable => true,
  }

  firewall { '100 allow prometheus stock-exporter metrics':
    source => $prometheus_server_ip,
    dport  => $port,
    proto  => 'tcp',
    action => 'accept',
  }
}
