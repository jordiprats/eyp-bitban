class bitban  (
                $basedir='/deploy',
                $username='bbt-deploy',
                $altusername='deploy',
                $altuserhome='/srv/www',
                $projects='/deploy/projects',
                $srvcache='/srv/cache',
                $srvmedia='/srv/media',
                $logs='/LOGS',
                $password=undef,
                $altuserpassword=undef,
                $tidy_varlocaldir=true,
              ) {

  if ! defined(Package['nfs-common'])
  {
    package { 'nfs-common':
      ensure => 'installed',
    }
  }

  group { $username:
    ensure => 'present',
    gid    => '1005'
  }

  group { $altusername:
    ensure => 'present',
    gid    => '1006'
  }

  if($altuserpassword)
  {
    user { $altusername:
      ensure   => present,
      uid      => '1005',
      home     => $altuserhome,
      shell    => '/bin/bash',
      gid      => $altusername,
      require  => Group[$altusername],
      password => $altuserpassword,
    }
  }
  else
  {
    user { $altusername:
      ensure  => present,
      uid     => '1005',
      home    => $altuserhome,
      shell   => '/bin/bash',
      gid     => $altusername,
      require => Group[$altusername],
    }
  }

  file { $altuserhome:
    ensure  => 'directory',
    owner   => $altusername,
    group   => $altusername,
    mode    => '0755',
    require => [ User[$altusername], Exec["mkdir p dirs bb"] ],
  }

  if($password)
  {
    user { $username:
      ensure   => present,
      uid      => '1004',
      home     => $basedir,
      shell    => '/bin/bash',
      gid      => $username,
      require  => Group[$username],
      password => $password,
    }
  }
  else
  {
    user { $username:
      ensure  => present,
      uid     => '1004',
      home    => $basedir,
      shell   => '/bin/bash',
      gid     => $username,
      require => Group[$username],
    }
  }

  $dirs_bb = [ $basedir, "${basedir}/DATA",
              "${basedir}/VAR", "${basedir}/VAR/global", $altuserhome,
              $projects, $srvcache, $srvmedia, $logs ]

  $join_dirs_bb=join($dirs_bb,' ')

  exec { "mkdir p dirs bb":
    command => "mkdir -p ${$join_dirs_bb}",
    path    => '/usr/sbin:/usr/bin:/sbin:/bin',
    require => User[$username],
  }

  file { $basedir:
    ensure => 'directory',
    owner => $username,
    group => $username,
    mode => '0755',
    require => User[$username],
  }

  $dirs_bb_local = [ "${basedir}/VAR/local",
                     "${basedir}/VAR/local/elespanol",
                     "${basedir}/VAR/local/elespanol/log",
                     "${basedir}/VAR/local/elespanol/run",
                     "${basedir}/VAR/local/elespanol/admin.elespanol.com",
                     "${basedir}/VAR/local/elespanol/admin.elespanol.com/log",
                     "${basedir}/VAR/local/elespanol/www.elespanol.com",
                     "${basedir}/VAR/local/elespanol/www.elespanol.com/log" ]

  file { $dirs_bb_local:
    ensure  => 'directory',
    owner   => $username,
    group   => 'www-data',
    mode    => '0755',
    require => [ User[$username], Exec["mkdir p dirs bb"] ],
  }

  if($tidy_varlocaldir)
  {
    tidy { "${basedir}/VAR/local/elespanol/www.elespanol.com/BB3Logs/":
      age     => "1w",
      recurse => true,
      rmdirs  => false,
      matches => "*.log*",
      require => File["${basedir}/VAR/local"],
    }

    tidy { "${basedir}/VAR/local/elespanol/admin.elespanol.com/BB3Logs/":
      age     => "1w",
      recurse => true,
      rmdirs  => false,
      matches => "*.log*",
      require => File["${basedir}/VAR/local"],
    }
  }

}
