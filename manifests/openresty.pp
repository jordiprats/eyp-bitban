define bitban::openresty	(
				$basedir='/opt',
				$srcdir='/usr/local/src',
				$instancename=$name,
				$version='1.7.10.1',
				$servicename='nginx',
				$initscript=undef,
				$confball=undef,
				$defaultvhost_dir='/var/www/void',
				$nginxctl=undef,
				$instance_alias=undef,
			) {

	Exec {
		path => '/bin:/sbin:/usr/bin:/usr/sbin',
	}

	$openresty_dependencies = [ 'libreadline-dev',  'libncurses5-dev',
		'libpcre3-dev',  'libssl-dev',  'perl',  'make',  'git'
		]

	validate_absolute_path($basedir)
	validate_absolute_path($srcdir)

	if($nginxctl)
	{
		validate_absolute_path($nginxctl)

		file { $nginxctl:
			ensure  => 'present',
			owner   => 'root',
			group   => 'root',
			mode    => '0755',
			content => template("bitban/nginxctl.erb"),
		}
	}

	# ensure_packages($openresty_dependencies,
	# 	{
	# 		ensure => 'installed',
	# 		before => File['$basedir'],
	# 	}
	# )

	file { $basedir:
		ensure => directory,
		owner  => "root",
		group  => "root",
		mode   => 0755,
	}

	file { "${srcdir}/.ngx_openresty-${version}.tar.gz":
		ensure  => present,
		owner   => "root",
		group   => "root",
		mode    => 0444,
		require => File["${basedir}"],
		source  => "puppet:///modules/bitban/ngx_openresty-${version}.tar.gz",
	}

	exec { "untar ${basedir}/${instancename}":
		command => "tar --no-same-owner -xzf ${srcdir}/.ngx_openresty-${version}.tar.gz",
		creates => "${srcdir}/ngx_openresty-${version}",
		cwd     => "${srcdir}",
		require => File["${srcdir}/.ngx_openresty-${version}.tar.gz"],
	}

	exec { "configure ${basedir}/${instancename}":
		command => "bash -c './configure --prefix=${basedir}/${instancename}-${version} --with-pcre-jit --with-luajit --without-http_xss_module --without-http_coolkit_module --without-http_set_misc_module --without-http_encrypted_session_module --without-http_srcache_module --without-http_lua_upstream_module --without-http_array_var_module --without-http_redis2_module --without-http_redis_module --without-http_rds_json_module --without-http_rds_csv_module --with-http_iconv_module --without-lua_redis_parser --without-lua_resty_dns --without-lua_resty_redis --without-lua_resty_mysql --without-lua_resty_upload --without-lua_resty_upstream_healthcheck --without-lua_resty_string --without-lua_resty_websocket --without-lua_resty_lock --without-lua_resty_lrucache --without-lua_resty_core --without-lua_rds_parser --with-debug --with-http_stub_status_module'",
		cwd     => "${srcdir}/ngx_openresty-${version}",
		require => [ Exec["untar ${basedir}/${instancename}"], Package[$openresty_dependencies] ],
		creates => "${srcdir}/ngx_openresty-${version}/Makefile",
	}

	exec { "make make install ${basedir}/${instancename}":
		command => 'bash -c \'make && make install\'',
		cwd     => "${srcdir}/ngx_openresty-${version}",
		require => Exec["configure ${basedir}/${instancename}"],
		creates => "${basedir}/${instancename}-${version}",
	}

	exec { "mkdir p directoris ${basedir}/${instancename}-${version}/nginx/lua/modules/resty":
		command => "mkdir -p ${basedir}/${instancename}-${version}/nginx/lua/modules/resty",
		require => Exec["make make install ${basedir}/${instancename}"],
		creates => "${basedir}/${instancename}-${version}/nginx/lua/modules",
	}

  exec { "mkdir p directoris ${basedir}/${instancename}-${version}/nginx/lua/lib":
    command => "mkdir -p ${basedir}/${instancename}-${version}/nginx/lua/lib",
    require => Exec["make make install ${basedir}/${instancename}"],
    creates => "${basedir}/${instancename}-${version}/nginx/lua/lib",
  }

  exec { "mkdir p directoris ${basedir}/${instancename}-${version}/nginx/conf/vhosts":
    command => "mkdir -p ${basedir}/${instancename}-${version}/nginx/conf/vhosts",
    require => Exec["make make install ${basedir}/${instancename}"],
    creates => "${basedir}/${instancename}-${version}/nginx/conf/vhosts",
  }


	#TODO: polir canvi de nom
	file { "${basedir}/${instancename}":
		ensure  => "${basedir}/${instancename}-${version}",
		require => Exec[ [
      "mkdir p directoris ${basedir}/${instancename}-${version}/nginx/lua/modules/resty",
      "mkdir p directoris ${basedir}/${instancename}-${version}/nginx/lua/lib",
      "mkdir p directoris ${basedir}/${instancename}-${version}/nginx/conf/vhosts"
      ] ],
	}

	#d) instalacion de modulos
	package { 'luarocks':
		ensure  => 'installed',
		require => File["${basedir}/${instancename}"],
	}

	exec { 'luarocks install utf8':
		command => 'luarocks install utf8',
		require => Package['luarocks'],
		creates => '/usr/local/lib/lua/5.1/utf8.so',
	}

	file {"${basedir}/${instancename}/nginx/lua/lib/lua-utf8.so":
		ensure  => '/usr/local/lib/lua/5.1/utf8.so',
		require => Exec['luarocks install utf8'],
	}

	#lua_resty_http - ho integro, ja veurem si s'ha de separar a posteriori

	exec { "git clone lua-resty-http ${basedir}/${instancename}":
		command => 'git clone https://github.com/pintsized/lua-resty-http.git',
		cwd     => "${srcdir}",
		require => File["${basedir}/${instancename}/nginx/lua/lib/lua-utf8.so"],
		creates => "${srcdir}/lua-resty-http",
	}

	exec { "cp lua_resty_http to ${basedir}/${instancename}":
		command => "cp ${srcdir}/lua-resty-http/lib/resty/http* ${basedir}/${instancename}-${version}/nginx/lua/modules/resty",
		require => [ Exec["git clone lua-resty-http ${basedir}/${instancename}"],
                 Exec["mkdir p directoris ${basedir}/${instancename}-${version}/nginx/lua/modules/resty"]
               ],
		creates => "${basedir}/${instancename}/nginx/lua/modules/resty/http.lua",
	}

	exec { "git clone lua-resty-template ${basedir}/${instancename}":
		command => 'git clone https://github.com/bungle/lua-resty-template.git',
		cwd     => "${srcdir}",
		require => File["${basedir}/${instancename}/nginx/lua/lib/lua-utf8.so"],
		creates => "${srcdir}/lua-resty-template",
	}

	exec { "cp lua_resty_template to ${basedir}/${instancename}":
		command => "cp ${srcdir}/lua-resty-template/lib/resty/* ${basedir}/${instancename}-${version}/nginx/lua/modules/resty",
		require => [ Exec["git clone lua-resty-template ${basedir}/${instancename}"],
								 Exec["mkdir p directoris ${basedir}/${instancename}-${version}/nginx/lua/modules/resty"]
							 ],
		creates => "${basedir}/${instancename}-${version}/nginx/lua/modules/resty/template.lua",
	}


	if($initscript)
	{
		file {"/etc/init.d/${servicename}":
			ensure  => 'present',
			owner   => 'root',
			group   => 'root',
			mode    => '0755',
			content => template("bitban/nginxinitopenresty.erb"),
			notify  => Service[$servicename],
			require => Exec[["cp lua_resty_http to ${basedir}/${instancename}", "cp lua_resty_template to ${basedir}/${instancename}"]],
		}
	}
	else
	{
		file {"/etc/init.d/${servicename}":
			ensure  => 'present',
			owner   => 'root',
			group   => 'root',
			mode    => '0755',
			content => template("bitban/initnginx.erb"),
			notify  => Service[$servicename],
			require => Exec["cp lua_resty_http to ${basedir}/${instancename}"],
		}
	}

	if($confball)
	{
		file { "${srcdir}/${instancename}":
			ensure  => 'directory',
			owner   => 'root',
			group   => 'root',
			mode    => '0755',
			require => File["/etc/init.d/${servicename}"],
		}

		file { "${srcdir}/${instancename}/confball.tgz":
			ensure  => 'present',
			owner   => 'root',
			group   => 'root',
			mode    => '0644',
			require => File["${srcdir}/${instancename}"],
			source  => $confball,
			notify  => Exec['tar xvf confball'],
		}

		exec { 'tar xvf confball':
			command     => "tar xzf ${srcdir}/${instancename}/confball.tgz -C ${basedir}/${instancename}/nginx/conf/ --strip-components =1",
			refreshonly => true,
			notify      => Service[$servicename]
		}

	}

	service { $servicename:
		ensure  => 'running',
		enable  => true,
		require => File["/etc/init.d/${servicename}"],
	}

	if($instance_alias)
	{
		validate_absolute_path($instance_alias)

		file { $instance_alias:
			ensure => "${basedir}/${instancename}",
			require => File["${basedir}/${instancename}"],
			before => Service[$servicename],
		}
	}

	if($defaultvhost_dir)
	{
		validate_absolute_path($defaultvhost_dir)

		exec { "mkdir p df vhost $defaultvhost_dir":
			command => "mkdir -p $defaultvhost_dir",
			creates => $defaultvhost_dir,
		}

		file { $defaultvhost_dir:
			ensure  => 'directory',
			owner   => 'root',
			group   => 'root',
			mode    => '0755',
			require => Exec["mkdir p df vhost $defaultvhost_dir"],
		}

		file { "${defaultvhost_dir}/check":
			ensure  => 'present',
			owner   => 'root',
			group   => 'root',
			mode    => '0644',
			require => File[$defaultvhost_dir],
			before  => Service[$servicename],
		}
	}

}
