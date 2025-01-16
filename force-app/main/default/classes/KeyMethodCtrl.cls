/**
*    @author: Rohit sahu
*    @date:   03-May-2024
*    @description: class for Controller class of Component keyMethod
*    Modification Log:
*    -----------------------------------------------------------------------------------
*      Developer                      Date                Description
*     Rohit sahu                   03-May-2024          CMCM-7575 UI Update to remove key methods fields from Account Plan & add component link
*    ----------------------------------------------------------------------------------------                    
*/
public with sharing class KeyMethodCtrl { 
    /**
* @description: This will load key method and Estimated annual sample volume fields record of key method object.
* @param : String recordId
* @return : kList
*/
    private static final String LOG_TITLE = 'KeyMethodCtrl';
    @AuraEnabled(Cacheable = true)
    /**
* @description: This will return key method and Estimated annual sample volume fields record of key method object.
* @param : String recordId
* @return : kList
*/
    public static List<Key_Method__c> getKeyMethod(String recordId) {
        
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.getKeyMethod()');
       
        List<Key_Method__c> kList = new List<Key_Method__c>();
        try{
            kList = [SELECT Id, Key_Method__c, Estimated_Annual_Sample_Volume__c,Account_Plan__c
                     FROM Key_Method__c
                     WHERE Account_Plan__c = :recordId limit 5];
            
            ilib_LogEvent.info('keyMethodList' +kList );
            ilib_LogEvent.pop();

        }
        catch (Exception e) {
           
            ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SALES );
            throw new AuraHandledException('Record Id Should not be blank');
            
        }
        return kList;
    }
}