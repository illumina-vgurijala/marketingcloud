/*
*    @author Sagar Madkaikar 
*    @date   2021-09-27
*    @description  Controller class for ProactiveDynamicComponent component.
*    90% Code Coverage: TestProactiveDynamicComponentController
*    75% Code Coverage: TestProactiveDynamicComponentController
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------
*             Developer               Date                Description
*            Sagar Madkaikar       27 Sep 2021           CMCP-81:Initial Version  
*            Sibin P Kuriakose     31 Aug 2022           [CMSI-219]: Instrumentation of the Class      		
*    --------------------------------------------------------------------------------------------------------
*                    
*/
public without sharing class ProactiveDynamicComponentController {
    private static final String LOG_TITLE = 'ProactiveDynamicComponentController';
    private static final String OBJ_INSTALLED_PRODUCT = 'Installed Products';
    /*
     *  @author Sagar Madkaikar
     *  @description Get current record ID details from recordID and Object Name passed.
     *  @param - recordId Id of current record.
     *  @param objectName - Object Name of current record.
     *  @return String - field value depending on the object name. This value will be used to form iFrame URL
     */
    @AuraEnabled
    public static String getCurrentRecordDetails(Id recordId,String objectName)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE); //CMSI-219
        ilib_LogEvent.push(LOG_TITLE + '.getCurrentRecordDetails');
        String returnValue;
        
        try {
            ilib_LogEvent.info('recordId'+recordId); //CMSI-219
            ilib_LogEvent.info('objectName'+objectName); //CMSI-219      
            if(objectName==OBJ_INSTALLED_PRODUCT) {
                InstalledProductsSelector ipSelector = new InstalledProductsSelector();
                List<SVMXC__Installed_Product__c> ipList = ipSelector.selectRelatedInstalledProducts(new Set<Id>{recordId});
                //return SVMXC__Serial_Lot_Number__c for IP object to form iFrame URL
                if(!ipList.isEmpty()){
                    returnValue = ipList[0].SVMXC__Serial_Lot_Number__c; 
                }
            }
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,recordId,e,ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop(); //CMSI-219
            ilib_LogEvent.emit(); //CMSI-219
            throw  new AuraHandledException('getCurrentRecordDetails'+ e.getMessage()) ;
        }
        ilib_LogEvent.info('Value of Field' + returnvalue); //CMSI-219
        ilib_LogEvent.pop(); //CMSI-219
        ilib_LogEvent.emit(); //CMSI-219
        return returnValue;
    }
}