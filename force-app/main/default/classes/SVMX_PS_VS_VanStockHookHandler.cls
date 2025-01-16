/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockHookHandler 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
public with sharing class SVMX_PS_VS_VanStockHookHandler {
    /*****************************************************************************************************************************************
    *  Method Name : hookForReturnedIPUpdate
    *  Parameter   : SVMXC__Installed_Product__c returnedIP - Installed Product which is now being De-Installed and now needs updation
    *  Returns     : SVMXC__Installed_Product__c - The Updated Installed Product
    *  Description : This method is a part of Part Out Process
    *                This method gives a Installed Product which is now being De-Installed
    *                By OOB, the status field of Installed Product is set to "De-Installed"
    *                If any other changes need to be done, use this method
    *                Please do not commit any changes.
    *                Instead, use the IP object sent as parameter and return it again
    *                Part Out process will save it in database
    *                Following fields will be sent :-
    *                 Id, Name, SVMXC__Company__c, SVMXC__City__c, SVMXC__Country__c,
    *                 SVMXC__Site__c, SVMXC__Product__c, SVMXC__Serial_Lot_Number__c,
    *                 SVMXC__State__c, SVMXC__Status__c, SVMXC__Street__c, SVMXC__Zip__c 
    *                In case, if more fields needed, we can use SOQL query to get the fields and update it.  
    *                But this would consume many SOQL queries in a transaction
    *                Please use another method "hookForReturnedIPListUpdate" if needed to query
    *                Null Check is applied --> if returned null, then ip with "De-Installed" status will be updated to db
    *                -----------------------------------------------------------------------------------------------------------
    *                     //ADD HERE DESCRIPTION FOR CODE WRITTEN 
    *                -----------------------------------------------------------------------------------------------------------  
    *******************************************************************************************************************************************/  
    public static SVMXC__Installed_Product__c hookForReturnedIPUpdate(SVMXC__Installed_Product__c returnedIP){
        //-----------------------------------------------------------------------------------------------------------
        //ADD CODE HERE IN BETWEEN LINES 
        //-----------------------------------------------------------------------------------------------------------  
        return returnedIP;
    }

    /*****************************************************************************************************************************************
    *  Method Name : hookForReturnedIPListUpdate
    *  Parameter   : List<SVMXC__Installed_Product__c> returnedIPList - List of Installed Product which is now being De-Installed
    *  Returns     : List<SVMXC__Installed_Product__c> - The List of updated Installed Product
    *  Description : This method is a part of Part Out Process
    *                This method gives a List of Installed Product which is now being De-Installed
    *                By OOB, the status field of all Installed Product is set to "De-Installed"
    *                If any other changes need to be done, use this method
    *                Please do not commit any changes.
    *                Instead, use the List of IP object sent as parameter and return it again
    *                Part Out process will save it in database
    *                Following fields will be sent :-
    *                 Id, Name, SVMXC__Company__c, SVMXC__City__c, SVMXC__Country__c,
    *                 SVMXC__Site__c, SVMXC__Product__c, SVMXC__Serial_Lot_Number__c,
    *                 SVMXC__State__c, SVMXC__Status__c, SVMXC__Street__c, SVMXC__Zip__c 
    *                Null Check is applied --> if returned null, then ip with "De-Installed" status will be updated to db 
    *                -----------------------------------------------------------------------------------------------------------
    *                     //ADD HERE DESCRIPTION FOR CODE WRITTEN 
    *                -----------------------------------------------------------------------------------------------------------  
    *******************************************************************************************************************************************/  
    public static List<SVMXC__Installed_Product__c> hookForReturnedIPListUpdate(List<SVMXC__Installed_Product__c> returnedIPList){
        //-----------------------------------------------------------------------------------------------------------
        //ADD CODE HERE IN BETWEEN LINES 
        //-----------------------------------------------------------------------------------------------------------  
        return returnedIPList;
    }
}