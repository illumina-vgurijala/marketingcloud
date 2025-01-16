/**
 * Created by igallagher on 10/13/2015.
 */
;(function ( $, window, document, undefined ) {
    // Plugin definition.
    $.fn.requiredText = function( options ) {
        var defaults = {
            'onFieldStatusChange': function() {}
        };

        var settings = $.extend( {}, defaults, options );

        // Iterate and reformat each matched element.
        return this.each(function(event) {

            var elem = $( this),
                hasValue = false;

            if(UtilWizard.isNullOrEmpty(elem.val())) {
                settings['onFieldStatusChange'](event, hasValue);
            }

            var $inputTextField = $(this),
                txtInputFieldEvent = function(event) {

                    hasValue = !UtilWizard.isNullOrEmpty($inputTextField.val());

                    // only trigger status change event if the value has changed
                    settings['onFieldStatusChange'](event, hasValue);

                };

            elem.on("keyup", txtInputFieldEvent);
            elem.on("change", txtInputFieldEvent);

            // trigger on init
            txtInputFieldEvent();

        });
    };

    window['$'] = $;
    $['fn'] = $.fn;
    $.fn['requiredText'] = $.fn.requiredText;


}(jQuery, window, document, undefined));