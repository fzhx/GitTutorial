class pootle {

  # Pootle - Localization and translation webapp
  package { "pootle": ensure => "MINE" }

  # Pootle needs Django and other goodies
  package { "Django": ensure => "MINE" }
  package { "Django-south": ensure => "MINE" }
  package { "python-Levenshtein": ensure => "MINE" }
  package { "python-djblets": ensure => "MINE" }
  package { "python-imaging": ensure => "MINE" }
  package { "python-memcached": ensure => "MINE" }
  package { "python-sqlite2": ensure => "MINE" }
  package { "tix": ensure => "MINE" }
  package { "tkinter": ensure => "MINE" }
  package { "python-lxml": ensure => "MINE" }
  package { "translate-toolkit": ensure => "MINE" }
  package { "python-MySQL-python": ensure => "MINE" }


  # Optional, ISO codes to translate language names
  package { "iso-codes": ensure => "MINE" }

  # Optional, Lucene indexer, for faster pootle searching
  package { "lucene": ensure => "MINE" }
  package { "java-1.6.0-openjdk": ensure => "MINE" }
  package { "PyLucene": ensure => "MINE" }

  # Enable wsgi_module
  file { '/etc/httpd/conf.d/wsgi.conf':
    source  => 'puppet:///modules/pootle/wsgi.conf',
  }

  # Pootle settings
  file {
    '/etc/pootle/localsettings.py':
      content => template('pootle/localsettings.py.erb');
    '/etc/httpd/conf.d/pootle.conf':
      content => template('pootle/pootle-http.conf.erb'),
      require => Package['httpd'],
      notify  => Service['httpd'];
  }

  # Directories
  file {
    '/var/lib/pootle':
      owner   => 'apache',
      group   => 'apache',
      mode    => 0776,
      recurse => true,
      ensure  => directory;
    '/var/lib/pootle/po':
      owner   => 'apache',
      group   => 'apache',
      mode    => 0776,
      recurse => true,
      ensure  => directory;
    '/var/lib/pootle/po/tumblr-web':
      ensure  => link,
      owner   => 'apache',
      group   => 'apache',
      mode    => 777,
      recurse => true,
      target  => '/opt/translations/tumblr-web/po';
    '/var/lib/pootle/po/tumblr-ios':
      ensure  => link,
      owner   => 'apache',
      group   => 'apache',
      mode    => 777,
      recurse => true,
      target  => '/opt/translations/tumblr-ios/po';
    '/var/lib/pootle/po/tumblr-android':
      ensure  => link,
      owner   => 'apache',
      group   => 'apache',
      mode    => 777,
      recurse => true,
      target  => '/opt/translations/tumblr-android/po';
    '/var/lib/pootle/po/photoset-ios':
      ensure  => link,
      owner   => 'apache',
      group   => 'apache',
      mode    => 777,
      recurse => true,
      target  => '/opt/translations/photoset-ios/po';
    '/var/lib/pootle/po/docs':
      ensure  => link,
      owner   => 'apache',
      group   => 'apache',
      mode    => 777,
      recurse => true,
      target  => '/opt/translations/docs/po';
  }

  # Stuff for git
  file {
    '/opt/translations':
      mode    => 777,
      recurse => true;
    '/opt/translations/.git/config':
      source  => 'puppet:///modules/pootle/gitconfig';
    '/opt/translations/.git/hooks/post-commit':
      mode    => 777,
      source  => 'puppet:///modules/pootle/gitpostcommit';
  }

  # Enabling command line updates
  file {
    '/usr/lib/python2.4/site-packages/pootle_app/management/commands/update_from_vcs.py':
      mode    => 755,
      require => Package['pootle'],
      source  => 'puppet:///modules/pootle/update_from_vcs.py';
    '/usr/lib/python2.4/site-packages/pootle_app/management/commands/commit_to_vcs.py':
      mode    => 755,
      require => Package['pootle'],
      source  => 'puppet:///modules/pootle/commit_to_vcs.py';
  }

  # Clean up auth_message entries
  file {
    '/opt/tumblr/bin/pootle_message_cleanup.sh':
      mode    => 0755,
      require => Package['pootle'],
      content => template('pootle/pootle_message_cleanup.sh.erb');
  }

  cron {
  'pootle-repo-sync':
    command => '/opt/translations/sync.sh > /var/log/pootle-repo-sync.last 2>&1',
    user    => 'root',
    hour    => '*/6',
    minute  => '0',
    require => File['/opt/translations'];
  'pootle-message-cleanup':
    command => '/opt/tumblr/bin/pootle_message_cleanup.sh &>/dev/null',
    user    => 'root',
    minute  => '*/5',
    require => File['/opt/tumblr/bin/pootle_message_cleanup.sh'];
  }

  # Requirements
  Package['pootle'] -> File['/etc/httpd/conf.d/wsgi.conf']
  Package['pootle'] -> File['/etc/pootle/localsettings.py']
  Class["yum"] -> Class['pootle']
}
