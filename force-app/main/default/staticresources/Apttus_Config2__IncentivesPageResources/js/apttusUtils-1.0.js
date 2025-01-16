/*
 *  Project: Incentives
 *  Description: Apttus core JS functions
 *  Dependencies: (none)
 *  Author: Ian Gallagher - Apttus
 *  License:
 */
;(function (window, document, undefined ) {
    var Apttus = Apttus || {};

    // Store the functions in a global property to keep closure compiler from renaming
    window['Apttus'] = Apttus;

    Apttus.utils = {};
    Apttus['utils'] = Apttus.utils;

    /**
     * Locates complex object based on key value and returns index of position in array
     * @param {array} arrayOfObjects
     * @param {?} value
     * @param {string} uniqueKeyPropertyName
     * @return {number} index indicating position of found object in array
     */
    Apttus.utils.elementIndex = function(arrayOfObjects, value, uniqueKeyPropertyName) {
        var recordIndex = -1;

        // get record index
        for(var i = 0;i < arrayOfObjects.length; i++) {
            var currentRecord = arrayOfObjects[i];
            if(currentRecord[uniqueKeyPropertyName] == value) {
                recordIndex = i;
                break;
            }
        }

        return recordIndex;
    };
    Apttus.utils['elementIndex'] = Apttus.utils.elementIndex;

    /**
     * Generates list containing data key values only from list of complex objects
     * @param {Array} arrayOfObjects
     * @param {String} uniqueKeyPropertyName
     * @return {Array} list of all data key values
     */
    Apttus.utils.getDataKeysArray = function(arrayOfObjects, uniqueKeyPropertyName) {
        var selectedValues = [];

        // get record index
        for(var i = 0;i < arrayOfObjects.length; i++) {
            selectedValues.push(arrayOfObjects[i][uniqueKeyPropertyName]);
        }

        return selectedValues;
    };
    Apttus.utils['getDataKeysArray'] = Apttus.utils.getDataKeysArray;

    /**
     * Escape SFDC style Id
     * @return escaped id
     */
    Apttus.utils.escSfId = function( sfid ) {
        return sfid.replace( /(:|\.|\[|\])/g, "\\$1" );
    };
    Apttus.utils['escSfId'] = Apttus.utils.escSfId;

    /**
     * Escape SFDC style Id and return as jquery selector
     * @return escaped SFDC id as jquery selector
     */
    Apttus.utils.sfIdSelector = function( sfid ) {
        return "#" + sfid.replace( /(:|\.|\[|\])/g, "\\$1" );
    };
    Apttus.utils['sfIdSelector'] = Apttus.utils.sfIdSelector;

    /**
     * Returns true if value is null or empty string
     * @return {boolean} value true or false
     */
    Apttus.utils.isNullOrEmpty = function( value ) {
        return (value == null || !value.trim())
    };
    Apttus.utils['isNullOrEmpty'] = Apttus.utils.isNullOrEmpty;

    /**
     * Creates list of values from delimited string
     * @param {string} delimitedStr
     * @param {string} separator
     * @return {array} list of values
     */
    Apttus.utils.arrayFromString = function(delimitedStr, separator) {
        delimitedStr = (delimitedStr.indexOf("[") > -1 ? delimitedStr.substring(1, delimitedStr.length - 1) : delimitedStr);
        return (delimitedStr === '' || delimitedStr === '[]' ? [] : delimitedStr.split(separator));
    };
    Apttus.utils['arrayFromString'] = Apttus.utils.arrayFromString;

    /**
     * Adds or remove value from delimited string
     * @param delimitedStr
     * @param value
     * @param separator
     * @param addValue
     * @param includeBrackets
     * @returns {string} returns updated delimited string of values
     */
    Apttus.utils.updateDelimitedList = function(delimitedStr,
                                                        value,
                                                        separator,
                                                        addValue,
                                                        includeBrackets) {
        var separator = (separator === undefined ? "," : separator );

        var values = Apttus.utils.arrayFromString(delimitedStr, separator),
            includeBrackets = (includeBrackets === undefined ? true : includeBrackets );

        if(!addValue) {
            for(var i = 0 ; i < values.length ; i++) {
                if(values[i] == value) {
                    values.splice(i, 1);
                    break;
                }
            }
        } else {
            values.push(value);
        }

        var updatedList = values.join(separator);

        return (includeBrackets ? '[' + updatedList + ']' : updatedList);
    };
    Apttus.utils['updateDelimitedList'] = Apttus.utils.updateDelimitedList;

    Apttus.utils.getScrollbarSize = function() {
        var inner = document.createElement('p');
        inner.style.width = "100%";
        inner.style.height = "100%";

        var outer = document.createElement('div');
        outer.style.position = "absolute";
        outer.style.top = "0px";
        outer.style.left = "0px";
        outer.style.visibility = "hidden";
        outer.style.width = "100px";
        outer.style.height = "100px";
        outer.style.overflow = "hidden";
        outer.appendChild (inner);

        document.body.appendChild (outer);

        var w1 = inner.offsetWidth;
        var h1 = inner.offsetHeight;
        outer.style.overflow = 'scroll';
        var w2 = inner.offsetWidth;
        var h2 = inner.offsetHeight;
        if (w1 == w2) w2 = outer.clientWidth;
        if (h1 == h2) h2 = outer.clientHeight;

        document.body.removeChild (outer);

        // adjust for zoom as pixel widths will be incorrect for scrollbar size when zoomed
        var pixelAspectRatio = this.detectZoom().device();

        return {
            width: Math.ceil((w1 - w2) * pixelAspectRatio),
            height: Math.ceil((h1 - h2) * pixelAspectRatio)
        };
    };
    Apttus.utils['getScrollbarWidth'] = Apttus.utils.getScrollbarWidth;

    Apttus.utils.getScrollTop = function() {
        var doc = document.documentElement;
        return (window.pageYOffset || doc.scrollTop)  - (doc.clientTop || 0);
    };
    Apttus.utils['getScrollTop'] = Apttus.utils.getScrollTop;

    Apttus.utils.getScrollLeft = function() {
        var doc = document.documentElement;
        return (window.pageXOffset || doc.scrollLeft) - (doc.clientLeft || 0);
    };
    Apttus.utils['getScrollLeft'] = Apttus.utils.getScrollLeft;

    Apttus.utils.detectZoom = function() {

        /**
         * Use devicePixelRatio if supported by the browser
         * @return {Number}
         * @private
         */
        var devicePixelRatio = function () {
            return window.devicePixelRatio || 1;
        };

        /**
         * Fallback function to set default values
         * @return {Object}
         * @private
         */
        var fallback = function () {
            return {
                zoom: 1,
                devicePxPerCssPx: 1
            };
        };
        /**
         * IE 8+: no trick needed!
         * TODO: Test on IE10 and Windows 8 RT
         * @return {Object}
         * @private
         **/
        var ie8 = function () {
            var zoom = Math.round((screen.deviceXDPI / screen.logicalXDPI) * 100) / 100;
            return {
                zoom: zoom,
                devicePxPerCssPx: zoom * devicePixelRatio()
            };
        };

        /**
         * Mobile WebKit
         * the trick: window.innerWIdth is in CSS pixels, while
         * screen.width and screen.height are in system pixels.
         * And there are no scrollbars to mess up the measurement.
         * @return {Object}
         * @private
         */
        var webkitMobile = function () {
            var deviceWidth = (Math.abs(window.orientation) == 90) ? screen.height : screen.width;
            var zoom = deviceWidth / window.innerWidth;
            return {
                zoom: zoom,
                devicePxPerCssPx: zoom * devicePixelRatio()
            };
        };

        /**
         * Desktop Webkit
         * the trick: an element's clientHeight is in CSS pixels, while you can
         * set its line-height in system pixels using font-size and
         * -webkit-text-size-adjust:none.
         * device-pixel-ratio: http://www.webkit.org/blog/55/high-dpi-web-sites/
         *
         * Previous trick (used before http://trac.webkit.org/changeset/100847):
         * documentElement.scrollWidth is in CSS pixels, while
         * document.width was in system pixels. Note that this is the
         * layout width of the document, which is slightly different from viewport
         * because document width does not include scrollbars and might be wider
         * due to big elements.
         * @return {Object}
         * @private
         */
        var webkit = function () {
            var important = function (str) {
                return str.replace(/;/g, " !important;");
            };

            var div = document.createElement('div');
            div.innerHTML = "1<br>2<br>3<br>4<br>5<br>6<br>7<br>8<br>9<br>0";
            div.setAttribute('style', important('font: 100px/1em sans-serif; -webkit-text-size-adjust: none; height: auto; width: 1em; padding: 0; overflow: visible;'));

            // The container exists so that the div will be laid out in its own flow
            // while not impacting the layout, viewport size, or display of the
            // webpage as a whole.
            // Add !important and relevant CSS rule resets
            // so that other rules cannot affect the results.
            var container = document.createElement('div');
            container.setAttribute('style', important('width:0; height:0; overflow:hidden; visibility:hidden; position: absolute;'));
            container.appendChild(div);

            document.body.appendChild(container);
            var zoom = 1000 / div.clientHeight;
            zoom = Math.round(zoom * 100) / 100;
            document.body.removeChild(container);

            return{
                zoom: zoom,
                devicePxPerCssPx: zoom * devicePixelRatio()
            };
        };

        /**
         * no real trick; device-pixel-ratio is the ratio of device dpi / css dpi.
         * (Note that this is a different interpretation than Webkit's device
         * pixel ratio, which is the ratio device dpi / system dpi).
         *
         * Also, for Mozilla, there is no difference between the zoom factor and the device ratio.
         *
         * @return {Object}
         * @private
         */
        var firefox4 = function () {
            var zoom = mediaQueryBinarySearch('min--moz-device-pixel-ratio', '', 0, 10, 20, 0.0001);
            zoom = Math.round(zoom * 100) / 100;
            return {
                zoom: zoom,
                devicePxPerCssPx: zoom
            };
        };

        /**
         * Firefox 18.x
         * Mozilla added support for devicePixelRatio to Firefox 18,
         * but it is affected by the zoom level, so, like in older
         * Firefox we can't tell if we are in zoom mode or in a device
         * with a different pixel ratio
         * @return {Object}
         * @private
         */
        var firefox18 = function () {
            return {
                zoom: firefox4().zoom,
                devicePxPerCssPx: devicePixelRatio()
            };
        };

        /**
         * works starting Opera 11.11
         * the trick: outerWidth is the viewport width including scrollbars in
         * system px, while innerWidth is the viewport width including scrollbars
         * in CSS px
         * @return {Object}
         * @private
         */
        var opera11 = function () {
            var zoom = window.outerWidth / window.innerWidth;
            zoom = Math.round(zoom * 100) / 100;
            return {
                zoom: zoom,
                devicePxPerCssPx: zoom * devicePixelRatio()
            };
        };

        /**
         * Use a binary search through media queries to find zoom level in Firefox
         * @param property
         * @param unit
         * @param a
         * @param b
         * @param maxIter
         * @param epsilon
         * @return {Number}
         */
        var mediaQueryBinarySearch = function (property, unit, a, b, maxIter, epsilon) {
            var matchMedia;
            var head, style, div;
            if (window.matchMedia) {
                matchMedia = window.matchMedia;
            } else {
                head = document.getElementsByTagName('head')[0];
                style = document.createElement('style');
                head.appendChild(style);

                div = document.createElement('div');
                div.className = 'mediaQueryBinarySearch';
                div.style.display = 'none';
                document.body.appendChild(div);

                matchMedia = function (query) {
                    style.sheet.insertRule('@media ' + query + '{.mediaQueryBinarySearch ' + '{text-decoration: underline} }', 0);
                    var matched = getComputedStyle(div, null).textDecoration == 'underline';
                    style.sheet.deleteRule(0);
                    return {matches: matched};
                };
            }
            var ratio = binarySearch(a, b, maxIter);
            if (div) {
                head.removeChild(style);
                document.body.removeChild(div);
            }
            return ratio;

            function binarySearch(a, b, maxIter) {
                var mid = (a + b) / 2;
                if (maxIter <= 0 || b - a < epsilon) {
                    return mid;
                }
                var query = "(" + property + ":" + mid + unit + ")";
                if (matchMedia(query).matches) {
                    return binarySearch(mid, b, maxIter - 1);
                } else {
                    return binarySearch(a, mid, maxIter - 1);
                }
            }
        };

        /**
         * Generate detection function
         * @private
         */
        var detectFunction = (function () {
            var func = fallback;
            //IE8+
            if (!isNaN(screen.logicalXDPI) && !isNaN(screen.systemXDPI)) {
                func = ie8;
            }
            //Mobile Webkit
            else if ('ontouchstart' in window && typeof document.body.style.webkitTextSizeAdjust === 'string') {
                func = webkitMobile;
            }
            //WebKit
            else if (typeof document.body.style.webkitTextSizeAdjust === 'string') {
                func = webkit;
            }
            //Opera
            else if (navigator.userAgent.indexOf('Opera') >= 0) {
                func = opera11;
            }
            //Last one is Firefox
            //FF 18.x
            else if (window.devicePixelRatio) {
                func = firefox18;
            }
            //FF 4.0 - 17.x
            else if (firefox4().zoom > 0.001) {
                func = firefox4;
            }

            return func;
        }());


        return {

            /**
             * Ratios.zoom shorthand
             * @return {Number} Zoom level
             */
            zoom: function () {
                return detectFunction().zoom;
            },

            /**
             * Ratios.devicePxPerCssPx shorthand
             * @return {Number} devicePxPerCssPx level
             */
            device: function () {
                return detectFunction().devicePxPerCssPx;
            }
        };
    };
    Apttus.utils['detectZoom'] = Apttus.utils.detectZoom;

    Apttus.utils.decodeEntities = (function() {
          // this prevents any overhead from creating the object each time
          var element = document.createElement('div');

          function decodeHTMLEntities (str) {
            if(str && typeof str === 'string') {
              // strip script/html tags
              str = str.replace(/<script[^>]*>([\S\s]*?)<\/script>/gmi, '');
              str = str.replace(/<\/?\w(?:[^"'>]|"[^"]*"|'[^']*')*>/gmi, '');
              element.innerHTML = str;
              str = element.textContent;
              element.textContent = '';
            }

            return str;
          }

          return decodeHTMLEntities;
        })();
        
    Apttus.utils['decodeEntities'] = Apttus.utils.decodeEntities;    


    Apttus.utils.getUniqueValueArray = function( items, propertyName ) {
        var u = {},
            uniqueArray = [];

        for(var i = 0, l = items.length; i < l; ++i) {
            if(u.hasOwnProperty(items[i][propertyName])) {
                continue;
            }

            uniqueArray.push(items[i][propertyName]);
            u[items[i][propertyName]] = 1;
        }

        return uniqueArray;
    };
    Apttus.utils['getUniqueValueArray'] = Apttus.utils.getUniqueValueArray;


    Apttus.utils.findIndex = function(array, callbackMethod) {        
        for(var i = 0; i < array.length; i++) {
            if(callbackMethod(array[i], i, array)) return i;
        }
    };

    Apttus.utils['findIndex'] = Apttus.utils.findIndex;

    Apttus.utils.stringToDate = function(input, userDateSettings) {
        if (typeof input !== 'string') {
            return input;

        }
        var dateSettings = userDateSettings;
        var digitGroups = input.match(dateSettings.groupingExp);
        // Return input if string cannot be matched to date format
        if (!digitGroups) {
            return input;

        }
        // Discard first element which is the full string match
        digitGroups.shift();
        
        for(var i = 0; i < digitGroups.length; i++){
            digitGroups[i] = parseInt(digitGroups[i]);
            
        }
        //digitGroups = _.map(digitGroups, _.parseInt);
        

        var year, month, day;
        for(var i = 0; i < dateSettings.ordering.length; i++){
            var ymdSymbol = dateSettings.ordering[i],
                    symbolIndex = i;
            
            var foundIndex;
            ymdSymbol = ymdSymbol[0].toLowerCase();
            if (ymdSymbol === 'y') {

                foundIndex = Apttus.utils.findIndex(digitGroups, function (numVal, nextIndex, currentArr) {
                    return numVal === undefined ? false : numVal > 31 || (symbolIndex == 2);
                    
                });
                year = digitGroups[foundIndex];

            } else if (ymdSymbol === 'm') {
                foundIndex = Apttus.utils.findIndex(digitGroups, function (numVal, nextIndex, currentArr) {
                    return numVal === undefined ? false : numVal <= 12;
                    
                });
                month = digitGroups[foundIndex]
                
            } else if (ymdSymbol === 'd') {
                foundIndex = Apttus.utils.findIndex(digitGroups, function (numVal, nextIndex, currentArr) {
                    return numVal === undefined ? false : numVal <= 31;
                    
                });
                day = digitGroups[foundIndex];

            }
            digitGroups[foundIndex] = undefined;
        }

        year = year ? (year < 100 ? 2000 + year : year) : 2000; 
        month = month || 1;
        day = day || 1;

        // Note that month is zero-indexed with with January = 0, December = 11
        return new Date(year, month - 1, day);

    };

    Apttus.utils['stringToDate'] = Apttus.utils.stringToDate;

    /**
     * Construct settings required for date rendering. May turn this into
     *  a way of making salesforce date format compatible with the 'moment'
     *  library so that the date filter can take advantage of moment.
     *   
     */
    Apttus.utils.buildUserDateSettings = function(dateTemplate) {
        var settings = {
            separator: '/',
            ordering: ['mm', 'dd', 'yyyy'],
            groupingExp: undefined
        };

        /**
         * Regex for capturing date digits
         * Matched groups: 
         *      0           1         2           ignore          3
         * [1-4 digits][separator][1|2 digits][same separator][2-4 digits]
         */
        var templateRegex = /(\d{1,4})([\/\s\-\.])(\d{1,2})(?:\2)(\d{1,4})/;
        var matches = dateTemplate.match(templateRegex);
        if (matches) {
            //Discard first element -- the full string match
            matches.shift();
            settings.separator = matches[1] || "/";
            [0,2,3].forEach(function(matchIndex, loopIndex) {
                var digits = matches[matchIndex];
                var component = '';
                var str = '';
                var numVal = Number(digits);
                if (numVal <= 12) {
                    component = 'm';

                } else if (numVal <= 31 ) {
                    component = 'd';

                } else {
                    component = 'y';

                }
                
                // TODO : .repeat method is part of ES6 and not compatible with IE and safari 
                // settings.ordering[loopIndex] = component.repeat(digits.length);

                // put the simple logic instead of .repeat method to fix the issue
                for(var i = 0; i < digits.length; i++) {
                    str += component;
                }

                settings.ordering[loopIndex] = str;

            });

        }
        /**
         * Compile the grouping regexp for fast reuse
         * Matching groups: 
         *    ignored     0       ignored    1       ignored    2       ignored
         * [whitespace][digits][separator][digits][separator][digits][whitespace]
         */
        var paddingExp = "\\s*";
        var separatorExp = paddingExp + "\\" + settings.separator + "?" + paddingExp;
        var regexpStr = ["^", paddingExp, "(\\d{1,4})", separatorExp, "(\\d{1,4})?", separatorExp, "(\\d{1,4})?", paddingExp, "$"].join('');
        settings.groupingExp = new RegExp(regexpStr);
        return settings;
    };

    Apttus.utils['buildUserDateSettings'] =  Apttus.utils.buildUserDateSettings;

    Apttus.utils.getOutputFieldText = function(fieldId) {
        var fieldElement = document.querySelector('#' + fieldId + ' span');
        if (fieldElement) {
            return fieldElement.textContent;
        }
        return void 0;
    };

    Apttus.utils['getOutputFieldText'] =  Apttus.utils.getOutputFieldText;

    Apttus.utils.insertUrlQueryParam = function(key, value) {
        key = encodeURIComponent(key); 
        value = encodeURIComponent(value);

        var kvp = document.location.search.substr(1).split('&');

        var i=kvp.length; 
        var x; 

        while(i--) {
            x = kvp[i].split('=');

            if (x[0]==key)
            {
                x[1] = value;
                kvp[i] = x.join('=');
                break;
            }
        }

        if(i<0) {kvp[kvp.length] = [key,value].join('=');}

        return kvp.join('&');
    };

    Apttus.utils['insertUrlQueryParam'] =  Apttus.utils.insertUrlQueryParam;

    Apttus.utils.updateReturnUrlFromReferrer = function(sfDcBaseUrl, returnUrlParamName) {
        // get previous page/screen URL since none was specified
        var returnUrl = document.referrer;

        if(returnUrl != "" && returnUrl != null) {
            // remove SF domain base URL
            returnUrl = returnUrl.replace(sfDcBaseUrl, '/');

            // insert return URL param
            var params = Apttus.utils.insertUrlQueryParam(returnUrlParamName, returnUrl);

            // reload page with return URL set
            document.location.search = params;
        }
    };

    Apttus.utils['updateReturnUrlFromReferrer'] =  Apttus.utils.updateReturnUrlFromReferrer;

}(window, document, undefined));
