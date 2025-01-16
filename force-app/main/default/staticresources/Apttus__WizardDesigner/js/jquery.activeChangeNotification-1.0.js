/**
 * Created by igallagher on 10/16/2015.
 */
;(function ( $, window, document, undefined ) {
    // Plugin definition.
    $.fn.activeChangeNotification = function( options ) {
        var defaults = {
            'onFieldChange': function() {}
        };

        var settings = $.extend( {}, defaults, options );

        return this.each(function() {

            var elem = $( this),
                originalValue = elem.val();

            var inputFieldEvent = function(event) {
                    var newValue = elem.val();

                    if(originalValue != newValue) {
                        // only trigger status change event if the value has changed
                        settings['onFieldChange'](event, {
                            originalValue: originalValue,
                            newValue: newValue
                        });

                        originalValue = newValue;
                    }

                };

            // only applies to fields of type text such as textarea input or input of type text etc.
            if(this.tagName == 'TEXTAREA' ||
                this.tagName == 'INPUT' && (this.type == 'text' || this.type == 'number')) {
                elem.on("keyup", inputFieldEvent);
            }

            if(this.tagName == 'INPUT' || this.tagName == 'SELECT') {
                elem.on("change", inputFieldEvent);
            }
        });
    };

    window['$'] = $;
    $['fn'] = $.fn;
    $.fn['activeChangeNotification'] = $.fn.activeChangeNotification;


}(jQuery, window, document, undefined));