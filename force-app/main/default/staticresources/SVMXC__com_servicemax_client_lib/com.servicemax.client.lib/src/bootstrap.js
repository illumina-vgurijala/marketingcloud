
/*
 * This is a small utility method to load the client core library
 *
 */
var __SVMX_BOOTSTRAP_PARAMS__ = null;
(function() {
  var allScripts = [
    'jquery/jquery-3.0.0.min.js',
    'jquery/jquery.inherit-1.3.6.js',
    'jquery/jquery.parseXml-1.0.0.js',
    'jquery/jquery.json-2.3.min.js',
    'jquery/jquery.browser.js',
    'jquery/jquery.browser.min.js',
    'utils.js',
    'utils/array.js',
    'utils/spin.js',
    'utils/moment.min.js',
    'utils/moment-with-locales.min.js',
    'utils/moment-timezone-with-data.min.js',
    'api.js',
    'services.js',
    'core.js' ,
    'datetimeutils.js',
    'usertiming.js'
  ];

  var scripts = document.getElementsByTagName('script');

  var script = '',
    match = null,
    path='',
    paramsIndex;

  for (var i = 0; i < scripts.length; i++) {
    script = scripts[i].src;

    paramsIndex = script.indexOf('?');
    if(paramsIndex != -1){
      __SVMX_BOOTSTRAP_PARAMS__ = script.substring(paramsIndex + 1, script.length);
      script = script.substring(0, paramsIndex);
    }

    match = script.match(/bootstrap\.js$/);

    if (match) {
      path = script.substring(0, script.length - match[0].length);
      break;
    }
  }

  var loadVersion = 'debug';

    //checks if it exist
    //sets the load and lib path
  if (window['__SVMX_LOAD_VERSION__'] == undefined) {
    window['__SVMX_LOAD_VERSION__'] = loadVersion;
  } else if(window['__SVMX_LOAD_VERSION__'] != ''){
    loadVersion = window['__SVMX_LOAD_VERSION__'];
  }

  if (!window['__SVMX_CLIENT_LIB_PATH__']) {
    window['__SVMX_CLIENT_LIB_PATH__'] = 'com.servicemax.client.lib';
  }

    // Temp disabled min and micro until build process fixed to automatically build
  if(loadVersion == 'micro'){
    document.write('<script type="text/javascript" src="' + path + '__all__-min.js' + '"></script>');
  }else{
        // load all the scripts
    for(var j = 0; j < allScripts.length; j++){
      var scriptToLoad = allScripts[j];
      if(loadVersion == 'min'){
        scriptToLoad = scriptToLoad.substring(0,scriptToLoad.length - 3) + '-min.js';
      }
      document.write('<script type="text/javascript" src="' + path + scriptToLoad + '"></script>');
    }
  }
})();

// end of file
