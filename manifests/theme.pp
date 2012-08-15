define redmine::theme (
  $url
) {

  exec {"Adding redmine theme $name":
    require => Exec["Initializing redmine"],
    cwd     => $redmine::path,
    creates => "$redmine::path/public/themes/$name",
    command => "git submodule add $url public/themes/$name",
  }

}