/*****************************************************************************************************************
 * Class Name: AdjustSerializedPart_WorkdetailHelper
 * Description: Adjust the inventory for serialized, batch & non tracked products.
 * Author: Prashanth
 * 
 * Date: 06-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth               06-12-2021        Adjust the inventory for serialized, batch & non tracked products.
 ******************************************************************************************************************/
public with sharing class AdjustSerializedPart_WorkdetailHelper {
    /*
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process for Serialized Work Detail, update on IP
    *  @RETURN:  void
    */
    public static void adjustInstalledProductForSerializedPart(Map < Id, SVMXC__Service_Order_Line__c > serializedWorkDetailIdToWorkDetailMap, String serializedOrNonTracked) {

        Map < Id, SVMXC__Installed_Product__c > installedProductIdToUpdateIPMap = new Map < Id, SVMXC__Installed_Product__c > ();
        Map<Id, SVMXC__Service_Order_Line__c> installedProductIdToWorkDetailMap = populateIPMap(serializedWorkDetailIdToWorkDetailMap);
        if (!installedProductIdToWorkDetailMap.isEmpty()) {
            PartsConsumptionReversal_WDHelper.installedProductIdToWorkDetailFinalMap = installedProductIdToWorkDetailMap;
            Map < Id, SVMXC__Installed_Product__c > installedProductIdToIPMap = new Map < Id, SVMXC__Installed_Product__c > ([Select Id, SVMXC__Top_Level__c, SVMXC__Parent__c, SVMXC__Site__c, SVMXC__Status__c from SVMXC__Installed_Product__c where Id IN: installedProductIdToWorkDetailMap.keyset()]);
            
            for (Id installedProductId: installedProductIdToIPMap.keyset()) {

                //Return Installed product  
                if ( installedProductIdToWorkDetailMap.containsKey(installedProductId) && serializedWorkDetailIdToWorkDetailMap.get(installedProductIdToWorkDetailMap.get(installedProductId).Id).SVMX_PS_VS_Return_Installed_Product__c == installedProductId) {

                    installedProductIdToUpdateIPMap.put(installedProductId, new SVMXC__Installed_Product__c(
                        Id = installedProductId,
                        SVMXC__Top_Level__c = installedProductIdToIPMap.get(serializedWorkDetailIdToWorkDetailMap.get(installedProductIdToWorkDetailMap.get(installedProductId).Id).SVMXC__Serial_Number__c).SVMXC__Top_Level__c,
                        SVMXC__Parent__c = installedProductIdToIPMap.get(serializedWorkDetailIdToWorkDetailMap.get(installedProductIdToWorkDetailMap.get(installedProductId).Id).SVMXC__Serial_Number__c).SVMXC__Parent__c,
                        Deinstall_Date__c = null,
                        SVMX_PS_VS_Cloned_From_IP__c = null,
                        SVMXC__Status__c = 'Installed'));

                }


                //Installed product 
                if ( installedProductIdToWorkDetailMap.containsKey(installedProductId) && serializedWorkDetailIdToWorkDetailMap.get(installedProductIdToWorkDetailMap.get(installedProductId).Id).SVMXC__Serial_Number__c == installedProductId) {
                    installedProductIdToUpdateIPMap.put(installedProductId, new SVMXC__Installed_Product__c(
                        Id = installedProductId,
                        SVMXC__Top_Level__c = null,
                        SVMXC__Parent__c = null,
                        SVMX_PS_VS_Cloned_From_IP__c = null,
                        SVMXC__Date_Installed__c = null,
                        SVMXC__Status__c = 'Shipped'));
                }

            }
            
            
            system.debug('installedProductIdToUpdateIPMap ' +installedProductIdToUpdateIPMap);
            if ( !installedProductIdToUpdateIPMap.isEmpty()) {
                PartsConsumptionReversal_WDHelper.listInstalledProductFinalUpdate.addAll(installedProductIdToUpdateIPMap.values());
            }

        }

    }
    /*
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process for Serialized Work Detail, update on IP
    *  @RETURN:  void
    */
    public static Map < Id, SVMXC__Service_Order_Line__c > populateIPMap(Map < Id, SVMXC__Service_Order_Line__c > serializedWorkDetailIdToWorkDetailMap){
        Map < Id, SVMXC__Service_Order_Line__c > installedProductIdToWorkDetailMap = new Map < Id, SVMXC__Service_Order_Line__c >();
        for (Id workDetailId: serializedWorkDetailIdToWorkDetailMap.keyset()) {
            //if installed product and return installed product is not null, adjust the values.
            if (String.isNotBlank(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).SVMXC__Serial_Number__c) && String.isNotBlank(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).SVMX_PS_VS_Return_Installed_Product__c)
                || String.isNotBlank(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).SVMXC__Serial_Number__c) && String.isBlank(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).SVMX_PS_VS_Return_Installed_Product__c)
            ) {
                //Return Installed Product
                if(String.isNotBlank(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).SVMX_PS_VS_Return_Installed_Product__c)){
                installedProductIdToWorkDetailMap.put(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).SVMX_PS_VS_Return_Installed_Product__c, serializedWorkDetailIdToWorkDetailMap.get(workDetailId));    
                }
                
                //Installed Product
                installedProductIdToWorkDetailMap.put(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).SVMXC__Serial_Number__c, serializedWorkDetailIdToWorkDetailMap.get(workDetailId));
            
            }
        }
        return installedProductIdToWorkDetailMap;
    }
}