define redmine::plugin (
  $source
) {

  file {"Adding redmine module $name":
    require => Exec["Initializing redmine"],
    path    => "${redmine::real_path}/plugins/${name}",
    source  => $source,
    ensure  => "directory",
    recurse => true,
    notify  => $redmine::service_to_restart
  }

}