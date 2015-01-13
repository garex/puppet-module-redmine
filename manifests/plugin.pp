define redmine::plugin (
  $source = undef,
  $url = undef
) {

  $plugin_root = "${redmine::real_path}/plugins/${name}"

  if $url {

    exec {"Getting sources of redmine module $name":
      require => Exec["Initializing redmine"],
      cwd     => $redmine::path,
      creates => $plugin_root,
      command => "git submodule add $url plugins/$name",
    }

    Exec ["Getting sources of redmine module $name"] -> File ["Adding redmine module $name"]

  }

  file {"Adding redmine module $name":
    require => Exec["Initializing redmine"],
    path    => $plugin_root,
    source  => $source,
    ensure  => "directory",
    recurse => true,
  }

  exec {"Updating gems for redmine module $name":
    require   => File["Adding redmine module $name"],
    creates   => "${plugin_root}/GEMS_UPDATED",
    cwd       => $redmine::real_path,
    command   => "bundle install --without development test postgresql sqlite && touch ${plugin_root}/GEMS_UPDATED"
  }

  exec {"Migrating redmine module $name":
    require   => Exec["Updating gems for redmine module $name"],
    creates   => "${plugin_root}/MIGRATED",
    cwd       => $redmine::real_path,
    command   => "bundle exec rake db:migrate RAILS_ENV=production && touch ${plugin_root}/MIGRATED",
    notify    => $redmine::service_to_restart
  }

}