/*****************************************************************************************************************
* Class Name: AsyncBeforeUpdate_InstalledProductHelper
* Description: Helper class for processing Installed Product on Before Update asynchronusly.
* 
* Author: Raviteja Vakkalagadda
* Date: 28-Mar-2022
* 
* Notification Log:
* -------------------------------------------------------------------------------------------------------------
* Developer                  Date                              Description
* -------------------------------------------------------------------------------------------------------------
* Raviteja Vakkalagadda      28-Mar-2022      Helper class for processing Installed Product on Before Update asynchronusly.
* 
******************************************************************************************************************/
public with sharing class AsyncBeforeUpdate_InstalledProductHelper {
    
/*
* @description: Method to update the Technical Attributes asynchronously 
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: void
*/
    
    public static void checkFieldSetValuesChangedOnIP(Map<Id, SVMXC__Installed_Product__c> idToRecordWithAttributesUpdated) {
        if (!idToRecordWithAttributesUpdated.isEmpty()) {
            createTechnicalAttributes(idToRecordWithAttributesUpdated);
        }
    }

/*
* @description: create / update technical attributes set from IQ/OQ form
* @author: Ritika M
* @date: 03/28/2022
* @returns: void
*/

    @TestVisible
    private static void createTechnicalAttributes(Map<Id, SVMXC__Installed_Product__c> idToRecordWithAttributesUpdated) {
        ilib_Queueablethread  queueableThread=new ilib_Queueablethread('createTechnicalAttributes');
        queueableThread.logandQueue(new IBTechinalAttributeCreationQueuable(idToRecordWithAttributesUpdated ),'IBTechinalAttributeCreationQueuable','createTechnicalAttributes');			
        if(queueableThread!=null)
        ilib_QueueableManager.enqueueJob(queueableThread);
        
    }
}