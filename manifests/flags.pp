# client indica root
class bitban::flags ($username='bbt-deploy', $conf, $func, $fpm) {

  # 5. echo "PRE" > /deploy/conf_tag.flag

  file { '/deploy/conf_tag.flag':
    ensure => 'present',
    owner => $username,
    group => $username,
    mode => '0644',
    content => "${conf}\n",
  }

  # 6. echo "ALL" > /deploy/func_tag.flag

  file { '/deploy/func_tag.flag':
    ensure => 'present',
    owner => $username,
    group => $username,
    mode => '0644',
    content => "${func}\n",
  }

  # 7. echo "127.0.0.1" > /deploy/fpm_tag.flag

  file { '/deploy/fpm_tag.flag':
    ensure => 'present',
    owner => $username,
    group => $username,
    mode => '0644',
    content => "${fpm}\n",
  }

}
