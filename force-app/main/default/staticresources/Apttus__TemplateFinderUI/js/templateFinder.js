

      // This to make sure jQuery doesn't conflict with any other JS libraries
      var j$ = jQuery.noConflict();
    
    j$(document).ready(function(){
      
      // setup namespace
      j$.APTTUS = {};
      
      // setup the text content dialog
      j$("#idTextContentPanel").dialog({
        autoOpen: false,
        draggable: false,
        modal: true,
        resizable: true,
        position: 'center'
        
      });
     
    });

    function setupDialog() {
       j$("#idTextContentPanel").dialog({
          autoOpen: false,
          draggable: false,
          modal: true,
          resizable: true,
          position: 'center'
          
        });
      }
  
     /**
     * Callback after a partial page update
     */
    function afterPageUpdate() {
      
      // delay to allow the page to be rendered 
            setTimeout(function() {
              
              // callback the object
        try {
          window.external.PageRefreshed();
        } catch(ex) {
          // object not available
        }
            }, 0);
            onAjaxStop();
            
    }
    
    // function to handle the enter key
    function noenter(ev)  {
        if (window.event && (window.event.keyCode == 13 || ev.which == 13)) {
          doSearchTemplates();
          setupDialog();
            return false;
            
         } else {
              return true;
              
         }
         
    }
    
    /**
     * Show text content panel
     */
    function showTextContent() {
      j$("#idTextContentPanel").dialog("open");
          j$("#idTextContentPanel").dialog({
              height: 350,
              width: 350,
              modal: true,
              title: "Template Information"
          });
          j$("#idTextContentPanel").dialog("option", "position", "center");
          
          return false;
          
      }
      
      /**
     * Hide the text content 
     */
      function hideTextContent() {
        // close the text content dialog
          j$("#idTextContentPanel").dialog("close");
        
      }
      
    
   