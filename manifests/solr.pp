define bitban::solr (
                      $java_package='openjdk-7-jre',
                      $tomcatfile,
                      $solrfile,
                      $srcdir='/usr/local/src',
                      $tomcatdir='/opt/tomcat',
                      $pwdigest="sha",
                      $tomcatpw,
                      $user='solr',
                      $userhome="${bitban::basedir}/VAR/solr"
                    ) {
  Exec {
  	path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  if ! defined(Package[$java_package])
  {
    package { $java_package:
      ensure => 'installed',
    }
  }

  exec { "check java solr ${name}":
    command => "update-alternatives --display java",
    require => Package[$java_package],
  }

  exec { "mkdir p ${bitban::basedir}/VAR/solr":
    command => "mkdir -p ${bitban::basedir}/VAR/solr",
    creates => "${bitban::basedir}/VAR/solr",
    require => Exec["check java solr ${name}"],
  }

  if ! defined(Group[$user])
  {
  	group { 'solr':
      ensure => present,
      require => Exec["check java solr ${name}"],
    }
  }

  if ! defined(User[$user])
  {
    user { 'solr':
      ensure => present,
      shell => "/bin/bash",
      gid => 'solr',
      managehome => true,
      home => $userhome,
      require => [ Group['solr'], Exec["mkdir p ${bitban::basedir}/VAR/solr"] ],
    }
  }

  file { "${bitban::basedir}/VAR/solr":
    ensure => 'directory',
    owner => $user,
    group => $user,
    mode => '0755',
    require => User[$user],
  }

  tomcat::instance{ 'tomcat-solr':
    java_package => $java_package,
    tomcatfile => $tomcatfile,
    srcdir => $srcdir,
    tomcatdir => $tomcatdir,
    pwdigest => $pwdigest,
    tomcatpw => $tomcatpw,
    user => $user,
    userhome => $userhome,
    require => File["${bitban::basedir}/VAR/solr"],
  }

  file { "${tomcatdir}/conf/Catalina":
    ensure => 'directory',
    owner => $user,
    group => $user,
    mode => '0755',
    require => Tomcat::Instance['tomcat-solr'],
  }

  file { "${tomcatdir}/conf/Catalina/localhost":
    ensure => 'directory',
    owner => $user,
    group => $user,
    mode => '0755',
    require => File["${tomcatdir}/conf/Catalina"],
  }

  file { "${tomcatdir}/conf/Catalina/localhost/solr.xml":
    ensure => 'present',
    owner => $user,
    group => $user,
    mode => '0644',
    require => File[ [ "${tomcatdir}/conf/Catalina/localhost",
                      "${tomcatdir}/conf/Catalina" ] ],
    content => template("bitban/solrxml.erb"),
  }

  file { "${tomcatdir}/solr":
    ensure => "${bitban::basedir}/VAR/solr",
    require => File["${tomcatdir}/conf/Catalina/localhost/solr.xml"],
  }

  file { "${srcdir}/solr.tgz":
    ensure => 'present',
    owner => 'root',
    group => 'root',
    mode => '0444',
    source => $solrfile,
    require => Exec["check java solr ${name}"],
    notify => Exec["untar solr ${bitban::basedir}"],
  }

  exec { "untar solr ${bitban::basedir}":
    command => "tar --strip 2 --wildcards -xzf ${srcdir}/solr.tgz solr*/dist/solr-*war -O > ${bitban::basedir}/VAR/solr/solr.war",
    creates => "${bitban::basedir}/VAR/solr/solr.war",
    require => [ Tomcat::Instance['tomcat-solr'], File[ ["${srcdir}/solr.tgz", "${bitban::basedir}/VAR/solr"]] ],
    notify => Exec["untar libs ${bitban::basedir}"],
  }

  exec { "untar libs ${bitban::basedir}":
    command => "tar -C ${tomcatdir}/lib --strip 4 --wildcards -xzf /usr/local/src/solr.tgz solr*/example/lib/ext",
    refreshonly => true,
    require => [ Tomcat::Instance['tomcat-solr'], Exec["untar solr ${bitban::basedir}"] ],
  }

  file { "${userhome}/elespanol_content":
    ensure => 'directory',
    owner => $user,
    group => $user,
    mode => '0644',
    require => [ Tomcat::Instance['tomcat-solr'], Exec["untar solr ${bitban::basedir}"] ],
  }

  file { "${userhome}/elespanol_content/conf":
    ensure => "${bitban::basedir}projects/elespanol/sites/elespanol/default/packages/BBTSolrContent/etc/es_ES",
    require => [ File["${userhome}/elespanol_content"], Tomcat::Instance['tomcat-solr'], Exec["untar solr ${bitban::basedir}"] ],
  }

  file { "${userhome}/solr.xml":
    ensure => 'present',
    owner => $user,
    group => $user,
    mode => '0644',
    require => [ Tomcat::Instance['tomcat-solr'], Exec["untar solr ${bitban::basedir}"] ],
    content => template("bitban/coresxml.erb"),
  }

}
