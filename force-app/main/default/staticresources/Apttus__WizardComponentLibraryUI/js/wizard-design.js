	function invokeUniqueDesignCheck() {            
            performUniqueWizardDesignCheck();     
        };		
        
        $( document ).ready(function() {             
            $("#wizardDesignModal").dialog({
              	autoOpen: false,
                modal:true,
                resizable: false,
              show: {
                effect: "fade",
                duration: 500
              },
              hide: {
                effect: "fade",
                duration: 10
              }
            });
    	});

		function openWizardDesignModal(wizardDesignId) {               
            $.unblockUI();
            $('[id$=designId]').val('');
            $('[id$=wid1]').val('');
            $("#wizardDesignModal" ).dialog( "open" );
            $('#wizardDesignModal').css('width','428px'); 
            cleanWizardDesignModalPopup(wizardDesignId);            
		}
    
		function closeWizardDesignModal(){
       	 	$("#wizardDesignModal").dialog('close');
            $('[id$=designId]').val('');
            $('[id$=wid1]').val('');
        }
    
    	function captureValue(){            
            $('[id*=designId]').val($('[id*=wid1]').val());
        }
                
        /*$(document).on("keyup", ".popupWizardDesignText", function() {
        	$('[id$=txtCloneBtnDefault]').show();
            $('[id$=lnkCloneBtn]').hide();
            $('[id$=txtCloneBtn]').hide();
            wait(function(){				
                captureValue();                
                invokeUniqueDesignCheck();
            }, 1000 );
        });*/
        	
    	/*$(document).on("focus", ".popupWizardDesignText", function() {           
            $('[id$=txtCloneBtnDefault]').show();
            $('[id$=lnkCloneBtn]').hide();
            $('[id$=txtCloneBtn]').hide();            
        });*/
        
        function onComplete() {           
            var length =  $(".popupWizardDesignText").val().length;                           
            $(".popupWizardDesignText")[0].setSelectionRange(length, length);           
            $(".popupWizardDesignText").focus();
        }