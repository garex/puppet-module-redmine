class redmine (
  $version  = "2.0.3",
  $database = "redmine",
  $username = "redmine",
  $password = "redmine",
  $host     = "localhost"
) {
  $path     = "/usr/local/lib/redmine"
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
    cwd       => $path,
    command   => "bundle install --without development test postgresql sqlite",
  }

  exec {"Initializing redmine":
    require   => [File["Setting up redmine database"], Exec["Installing needed bundles"], Exec["Setting redmine owner"]],
    creates   => "$path/config/initializers/secret_token.rb",
    user      => $owner,
    cwd       => $path,
    command   => "bundle exec rake generate_secret_token db:migrate redmine:load_default_data RAILS_ENV=production REDMINE_LANG=en",
  }

}
