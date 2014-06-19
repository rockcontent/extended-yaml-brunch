(function (global) {
    'use strict';
    global.yamlBrunch = function (path, data) {
        var container = global, part, last, parts = path.split('.');
        last = parts.pop();
        while (parts.length) {
            part = parts.shift();
            if (!container[part]) {
                container[part] = {};
            }
            container = container[part];
        }
        container[last] = data;
    };
}(this));
