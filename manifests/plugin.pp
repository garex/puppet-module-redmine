define redmine::plugin (
  $source,
  $service_to_restart
) {

  file {"Adding redmine module $name":
    require => Exec["Initializing redmine"],
    path    => "${redmine::real_path}/plugins/${name}",
    source  => $source,
    ensure  => "directory",
    recurse => true,
    notify  => $service_to_restart
  }

}