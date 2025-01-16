/**
 * Created by igallagher on 10/6/2015.
 */
;(function ( $, window, document, undefined ) {
    function Util () {}

    // Store the functions in a global property to keep closure compiler from renaming
    window['UtilWizard'] = Util;

    /**
     * Escape SFDC style Id
     * @return escaped id
     */
    Util.escSfId = function( sfid ) {
        return sfid.replace( /(:|\.|\[|\])/g, "\\$1" );
    };
    Util['escSfId'] = Util.escSfId;

    /**
     * Escape SFDC style Id and return as jquery selector
     * @return escaped SFDC id as jquery selector
     */
    Util.sfIdSelector = function( sfid ) {
        return "#" + sfid.replace( /(:|\.|\[|\])/g, "\\$1" );
    };
    Util['sfIdSelector'] = Util.sfIdSelector;

    /**
     * Returns true if value is null or empty string
     * @return boolean value true or false
     */
    Util.isNullOrEmpty = function( value ) {
        return (value == null || !value.trim())
    };
    Util['isNullOrEmpty'] = Util.isNullOrEmpty;

    /**
     * disables anchor element
     */
    Util.disableLink = function( $link ) {
        $link.addClass("disabled");
        $link[0].onclick = function() { return false; }; // remove on click event
    };
    Util['disableLink'] = Util.disableLink;

    /**
     * disables anchor element
     */
    Util.enableLink = function( $link, clickEvent ) {
        $link.removeClass("disabled");
        $link[0].onclick = clickEvent;
    };
    Util['enableLink'] = Util.enableLink;

}(jQuery, window, document, undefined));

