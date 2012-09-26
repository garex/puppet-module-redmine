class redmine (
  $version        = "2.0.3",
  $admin_password = "admin",
  $database       = "redmine",
  $username       = "redmine",
  $password       = "redmine",
  $host           = "localhost",
  # Redmine admin settings
  $app_title      = "Redmine",
  $host_name      = "localhost",
  $ui_theme       = ""
) {
  $path     = "/./usr/local/lib/redmine"
  $real_path= "/usr/local/lib/redmine" # Needs due to a bug in "file as directory, recurse true"
  $owner    = "www-data"
  $gem_bin  = "$(gem env gemdir)/bin"

  file {"Create redmine directory":
    path    => $path,
    ensure  => directory,
    owner   => $owner,
  }

  package {"rubygems":
    name  => ["rubygems", "rake"]
  }

  if defined(Package["git"]) != true {
    package {"git":}
  }


  exec {"Download redmine":
    require => [Package["git"], File["Create redmine directory"]],
    cwd     => $path,
    onlyif  => "test ! -d $path/app",
    command => "git clone git://github.com/redmine/redmine.git .",
  }

  exec {"Choosing redmine version":
    require => Exec["Download redmine"],
    cwd     => $path,
    onlyif  => "test '$version' != $(git describe --exact-match --all --tags --always HEAD)",
    command => "git checkout $version",
  }

  $command_fetch_changesets = template("redmine/command_fetch_changesets.sh.erb")
  file {"Making production log writable to allow execute fetch changesets from hooks":
    require => Exec["Choosing redmine version"],
    ensure  => present,
    path    => "${path}/log/production.log",
    owner   => $owner,
    group   => $owner,
    mode    => 0666,
  }

  exec {"Setting redmine owner":
    require => Exec["Choosing redmine version"],
    cwd     => $path,
    onlyif  => "test '$owner' != $(stat --format=%U $path/app)",
    command => "chown --recursive $owner:$owner .",
  }

  file {"Setting up redmine database":
    require => Exec["Choosing redmine version"],
    ensure  => present,
    owner   => $owner,
    group   => $owner,
    path    => "$path/config/database.yml",
    content => template("redmine/database.yml.erb")
  }

  $gems_libraries = ["libmysqlclient-dev", "imagemagick", "libmagickwand-dev"]
  package {$gems_libraries:}

  $gems = ["rack", "i18n", "rails", "bundler", "mysql", "rmagick"]
  package {$gems:
    require   => [Package["rubygems"], Package[$gems_libraries]],
    provider  => "gem",
  }

  exec {"Making bundle bin visible":
    require   => Package[$gems],
    command   => "ln --symbolic $gem_bin/bundle /usr/bin/bundle",
    creates   => "/usr/bin/bundle",
  }

  exec {"Installing needed bundles":
    require   => [Exec["Making bundle bin visible"], Exec["Choosing redmine version"]],
    creates   => "$path/config/initializers/secret_token.rb",
    cwd       => $path,
    command   => "bundle install --without development test postgresql sqlite",
  }

  exec {"Initializing redmine":
    require   => [File["Setting up redmine database"], Exec["Installing needed bundles"], Exec["Setting redmine owner"]],
    creates   => "$path/config/initializers/secret_token.rb",
    user      => $owner,
    cwd       => $path,
    command   => "bundle exec rake generate_secret_token db:migrate RAILS_ENV=production REDMINE_LANG=ru",
  }

  exec {"Loading defaults in redmine":
    require   => Exec["Initializing redmine"],
    onlyif    => "test 0 = $(mysql -e 'select count(*) from $database.trackers' | tail -n1)",
    cwd       => $path,
    command   => "bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=ru",
  }

  file {"Preparing redmine settings":
    require => Exec["Choosing redmine version"],
    ensure  => present,
    path    => "$path/config/settings.mysql.sql",
    content => template("redmine/settings.mysql.sql.erb")
  }

  exec {"Applying redmine settings":
    require     => [File["Preparing redmine settings"], Exec["Loading defaults in redmine"]],
    subscribe   => File["Preparing redmine settings"],
    refreshonly => true,
    cwd         => "$path/config",
    command     => "mysql --default_character_set utf8 $database < settings.mysql.sql",
  }

}
