{{flutter_js}}
{{flutter_build_config}}

// Cache-busting: the app code always has the same file name (main.dart.js),
// so Safari / home-screen web apps could keep running an old version. Adding
// the build's content hash to the URL makes every new build a new file.
(function () {
  var v = "__BUILD_ID__"; // replaced by CI with the commit id
  if (v.indexOf("__") === 0) return; // local build: leave as is
  (_flutter.buildConfig.builds || []).forEach(function (b) {
    if (b.mainJsPath && b.mainJsPath.indexOf("?") < 0) b.mainJsPath += "?v=" + v;
  });
})();

_flutter.loader.load();
