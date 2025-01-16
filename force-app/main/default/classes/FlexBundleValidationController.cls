/*@ author       : Akash Kumar
* @ date         : 08-08-2018
* @ Description  : FlexBundleValidationController Apex Controller
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akash Kumar        	08-08-2018                 US-4113             Initial version
* 
*/
public without sharing class FlexBundleValidationController {

    /*
*  @author       : Akash Kumar
*  @description  : To trigger outbound interface to ERP
*  @param        : String Product Id
*  @return       : NA
*/
    @AuraEnabled
    public static void submitOutboundRequest(String strProductId){
        System.debug('strProductId: ' + strProductId);
        Interface_Call__e ii = new Interface_Call__e(Name__c = 'FlexBundleDataSender',
            										Related_Record__c = strProductId);
        Product2 objProduct = new Product2(Id=strProductId,
                                          Product_Send_To_AEM_Status__c=Label.ProductSendToAEMStatus);
        update objProduct;
        // Emit the log data via Platform Events
        EventBus.publish(ii);
        System.debug('Callout done');
    }
}