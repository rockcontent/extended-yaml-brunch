## yaml-brunch
A [brunch](http://brunch.io) plugin to transform YAML files into JS object at a given location of the application.

## Usage
### Install
Add `"yaml-brunch": "x.y.z"` to `package.json` of your brunch app.
Pick a plugin version that corresponds to your minor (y) brunch version.

If you want the latest repository version, install the plugin by running the following command:
```sh
npm install --save "git+ssh://git@github.com:huafu/yaml-brunch.git"
```

### Usage in your application
Usage:

```coffeescript
sysPath = require 'path'

module.exports =
  #...
  yaml:
    # where to store the yaml converted data, default to window
    destination: 'window.MyNamespace'
    # name mapper, if needed. The default is to use the relative path and filename as the
    # js path to the file's content
    # So `app/i18n/user.yaml` => app.i18n.user => window.MyNamespace.app.i18n.user will hold the
    # YAML data
    # This function will receive an array with all relative path parts, in that case for example:
    # ['app', 'i18n', 'user']
    jsPathForFile: (pathArray) ->
      # here we don't want the first part (app) so we just remove it from the array and return it
      pathArray[1..]
```
