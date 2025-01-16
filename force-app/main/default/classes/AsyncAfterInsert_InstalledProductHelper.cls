/*****************************************************************************************************************
 * Class Name: AsyncAfterInsert_InstalledProductHelper
 * Description: Helper class for processing Installed Product on After insert asynchronusly.
 * 
 * Author: Raviteja Vakkalagadda
 * Date: 28-Mar-2022
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Raviteja Vakkalagadda      28-Mar-2022      Helper class for processing Installed Product on After insert assynchronusly
 * Sagar Madkaikar            21-Jul-2022      DCP-54367 : Added line to call IBTechnicalAttributeLRMQueueable class.
 * 
 ******************************************************************************************************************/
public class AsyncAfterInsert_InstalledProductHelper {

    public static set<Id> setInstalledProductIds = new set<Id>();
    public static final String LRM_PATCH_FEATURE ='LRM_Patch_Feature';//DCP-54367

    /**
     * Method:asynCallsOnAfterInsert
     * Description: Method to process the async calls
     * params: new records
     * return: void
     */
    public static void asynCallsOnAfterInsert(List<SVMXC__Installed_Product__c> lstInstalledProducts) {

        prepareRequiredSets(lstInstalledProducts);

        ilib_Queueablethread  queueableThread=new ilib_Queueablethread('installedProductAfterInsert');

        if(!setInstalledProductIds.isEmpty()) {
			queueableThread.logandQueue(new InstalledProductQueueable('updateInstalledProductRecordType', null, null, null,setInstalledProductIds ),'InstalledProductQueueable','updateInstalledProductRecordType');
            //DCP-54367	: calling IBTechnicalAttributeLRMQueueable for creating Technical Attribute Instance Record
            if (Feature.isOn(LRM_PATCH_FEATURE)){
                queueableThread.logandQueue(new IBTechnicalAttributeLRMQueueable('insertTAInstanceOnIPCreation',setInstalledProductIds ),'IBTechnicalAttributeLRMQueueable','insertTAInstanceOnIPCreation');	
            }
		}
        if(queueableThread!=null) {
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        }  
    }

     /**
     * Method:prepareRequiredSets
     * Description: Method to populate the set of Installed Product Ids
     * params: new records
     * return: void
     */

    public static void prepareRequiredSets(List<SVMXC__Installed_Product__c> lstInstalledProducts) {

        for (SVMXC__Installed_Product__c objInstalledProduct : lstInstalledProducts) {
            setInstalledProductIds.add(objInstalledProduct.Id);
        }
    }
}