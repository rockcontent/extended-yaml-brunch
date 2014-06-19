## extended-yaml-brunch
A [brunch](http://brunch.io) plugin to transform complex YAML files into JS object at a given location of the application.
It handles complex YAML data such as functions, regexps, udnefined and dates

## Usage
### Install
Add `"extended-yaml-brunch": "x.y.z"` to `package.json` of your brunch app.
Pick a plugin version that corresponds to your minor (y) brunch version.

If you want the latest repository version, install the plugin by running the following command:
```sh
npm install --save "git+ssh://git@github.com:huafu/extended-yaml-brunch.git"
```

### Usage in your application
Usage:

```coffeescript
sysPath = require 'path'

module.exports =
  #...
  extendedYaml:
    # Name mapper, if you need the YAML data to be defined on a specific variable/namespace.
    # The default is to not set it and just allow you to do `require('config/user');` to
    # access the whole YAML data as a JS object.
    # It has to return an array which gonna be join with '.' or directly the path where to
    # define the data: 'SomeNamespace.config.here'
    # If it returns `null` then it'll not define it anywhere
    # So if you want `app/config/user.yml` to be defined on window.MyCompany.config.user
    # you can define that config as function like this:
    jsPathForFile: (path, parts) ->
      # for the file under `app/config/user.yml` you'll have:
      # path: 'app/config/user.yml'
      # parts: ['app', 'config', 'user']
      # here we don't want the first part (app) and we want to prepend with 'MyCompany'
      ['MyCompany'].concat parts[1..]
```
