/***************************************************************************************************************************************
* NAME   : QuoteCreationAPIPESubscriberService 
* DESCRIPTION  : Service class for QuoteCreationAPIPlatformEvents object.
*                    
* @AUTHOR : Arquimidez Mora
* @DATE   : 29-10-2024  
* Modification Log:
*  ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*          Arquimidez Mora               29 Oct 2024           Initial version
*          Gerardo Garcia                04 Nov 2024           CMCM-2891 Quote and Cart Creation.
*          Arquimidez Mora               20 Nov 2024           CMCM-9914 Add Products to Cart.
*  ------------------------------------------------------------------------------------     
*/
public with sharing class QuoteCreationAPIPESubscriberService {
    
    /**Steps for platform events */
    public enum Step {
        STEP1_QUOTATION_CREATION,
        STEP2_ADD_PRODUCTS_TO_CART,
        STEP3_VALIDATE_CART,
        STEP4_SUBMIT_FOR_APPROVAL
    }
    /**
    * @description 
    * @params List<Quote_Creation_API__e> lstQuoteCreation
    * @return void
    **/ 
    public static void requestHandler( List<Quote_Creation_API__e> lstQuoteCreation ) {
        List<String> lstPlatformEventPayloads = new List<String>();
        List<String> lstCartLinePayloads = new List<String>();
        List<String> lstCartValidate = new List<String>();
        List<String> lstCartSubmitForApproval = new List<String>();
        for(Quote_Creation_API__e eventQuoteCreation: lstQuoteCreation) {
            Step type = Step.valueOf(eventQuoteCreation.Process_Type__c);
            switch on type{
                when STEP1_QUOTATION_CREATION {
                    lstPlatformEventPayloads.add( eventQuoteCreation.JSON_Payload__c );
                }
                
                when STEP2_ADD_PRODUCTS_TO_CART {
                    lstCartLinePayloads.add(eventQuoteCreation.JSON_Payload__c);
                }

                when STEP3_VALIDATE_CART {
                    lstCartValidate.add(eventQuoteCreation.JSON_Payload__c);
                }
                when STEP4_SUBMIT_FOR_APPROVAL {
                    lstCartSubmitForApproval.add(eventQuoteCreation.JSON_Payload__c);
                }
            }
        }
        
        if( !lstPlatformEventPayloads.isEmpty() ){
            WebGeneratedQuoteOpportunityCreation.handlePayload( lstPlatformEventPayloads );
        }
        if( !lstCartLinePayloads.isEmpty() ){
            WebGeneratedQuoteOpportunityCreation.handleCartLinePayload( lstCartLinePayloads );
        }
        if(!lstCartValidate.isEmpty() ){
            //WebGeneratedQuoteOpportunityCreation.handleCartValidate(lstCartValidate);
            System.enqueueJob(new GenerateQueueDocument(lstCartValidate,GenerateQueueDocument.QueueStep.STEP1_VALIDATE_CART), 10);
        }
        if( !lstCartSubmitForApproval.isEmpty() ){
            WebGeneratedQuoteOpportunityCreation.handleSubmitForApprovalPayloads(lstCartSubmitForApproval);
        }
    } 
}