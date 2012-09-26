# Puppet module for redmine installation

Installs redmine and all dependencies on remote node. Did not installs webservers, as in ruby world we have WEBrick. Requires DB installed. Allows to add redmine theme and plugin.

## Usage

### Redmine install

```ruby
class {"redmine":
  require         => Database_grant["redmine@localhost/redmine"],
  version         => "2.0.3",
  admin_password  => "Sengaezeivei7ku6feej",
  database        => "redmine",
  username        => "redmine",
  password        => "redmine",
  # Redmine admin settings
  app_title       => "My Own Redmine",
  host_name       => "redmine.company.com",
  ui_theme        => "CM-red",
}
```

### Redmine theme

```ruby
redmine::theme {"CM-red":
  url             => "git://github.com/garex/puppet-theme-CM-red.git"
}
```

### Redmine plugin

```ruby
redmine::plugin {"redmine_local_avatars":
  source              => "puppet:///modules/some_main_module/redmine_local_avatars",
  # If you use thin for your ruby. It also could be apache, passenger, mongrel or else. We assume here, that you are at production
  service_to_restart  => Service["thin"]
}
```

## Why?

Why did I create it? Just because non of current top redmine puppet modules fits:
* they are all bundled with concrete webservers
* they are complex

## GOODTODO

* Make settings part less specific (concrete trackers settings in Russian language)
* Make less specicific DB part (currently mysql)
