#TODO: desplacar a una classe d'utils
define bitban::nfsmount (
                          $mount=$name,
                          $nfsdevice,
                          $nfsrw=false,
                          $ensure='mounted',
                          $opts='vers=3,tcp,timeo=600,rsize=65536,wsize=65536,hard,noac,_netdev',
                          $mkdir_mount=false,
                          $mount_owner='root',
                          $mount_group='root',
                          $mount_mode='0755',
                        ) {

  Exec {
		path => '/bin:/sbin:/usr/bin:/usr/sbin',
	}

  if($nfsrw)
  {
    $nfsoptions="rw,${opts}"

    file { "${mount}/is.mounted":
      ensure => 'present',
      owner => 'root',
      group => 'root',
      mode => '0644',
      content => "OK\n",
      require => Mount[$mount],
    }
  }
  else
  {
    $nfsoptions="ro,${opts}"
  }

  validate_re($ensure, [ 'mounted', 'absent' ], "not valid: mounted/absent")

  if($mkdir_mount)
  {
    exec { "mkdir p ${mount}":
      command => "mkdir -p ${mount}",
      creates => $mount,
    }

    file { $mount:
      ensure => 'present',
      owner => $mount_owner,
      group => $mount_group,
      mode => $mount_mode,
      require => Exec["mkdir p ${mount}"],
    }

    $require_mount= [
                      Exec["mkdir p dirs bb"],
                      Package['nfs-common'],
                      File[$mount]
                    ]
  }
  else
  {
    $require_mount=[ Exec["mkdir p dirs bb"], Package['nfs-common'] ]
  }

  mount { $mount:
        ensure => $ensure,
        atboot => true,
        device => $nfsdevice,
        fstype => 'nfs',
        options => $nfsoptions,
        remounts => true,
        require => $require_mount,
  }

}
