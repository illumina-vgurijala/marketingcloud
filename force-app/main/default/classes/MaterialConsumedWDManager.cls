/***************************************************************************************************************************************
    * NAME   : MaterialConsumedWDManager
    * DESCRIPTION  : Material Consumed Work Details Handler on Work Order Completion.
    *                    
    * @AUTHOR : Vignesh Sethuramalingam
    * @DATE   : 28-Sept-2021  
    * 
    * MODIFICATION LOG: 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * Vignesh               28-Sept-2021         Initial Version.
    *****************************************************************************************************************************************/

public with sharing class MaterialConsumedWDManager implements ilib_AdminOperationLogicInterface{

    /*******************************************************************************************************
    * @description : Method to Update Material Consumed Product's Hierarchy for NONFRU.
    * @param lstWOIds - List of WorkOrder ids.
    * @return void
    * @example
    ********************************************************************************************************/
    public static void doBusinessLogic(list<Id> lstWOIds){
        
            list<SVMXC__Installed_Product__c> lstIPsToUpdate = new list<SVMXC__Installed_Product__c> ();
            list<SVMXC__Service_Order_Line__c> lstWDToUpdate = new list<SVMXC__Service_Order_Line__c>();

            for(SVMXC__Service_Order_Line__c objWD : new WorkDetailsSelector().selectWorkDetailsByWOIdLineType(lstWOIds , new set<String>{'Material Consumed'})){
                Boolean isRelatedIPUpdated = false;
                if(objWD.SVMXC__Serial_Number__c != Null && objWD.SVMXC__Serial_Number__r.Service_Product_Type__c == 'NONFRU'  ){
                    if(objWD.SVMXC__Service_Order__r.SVMXC__Component__c != objWD.SVMXC__Serial_Number__r.SVMXC__Parent__c){
                        lstIPsToUpdate.add(new SVMXC__Installed_Product__c(Id = objWD.SVMXC__Serial_Number__c , SVMXC__Parent__c = objWD.SVMXC__Service_Order__r.SVMXC__Component__c, SVMXC__Status__c = label.InstalledProductStatusInstalled , SVMXC__Date_Installed__c = Date.today() , SVMXC__Top_Level__c = objWD.SVMXC__Service_Order__r.SVMXC__Component__c ));
                    }
                    isRelatedIPUpdated = true;
                }
                if(objWD.SVMX_PS_VS_Return_Installed_Product__c != Null ){
                    lstIPsToUpdate.add(new SVMXC__Installed_Product__c(Id = objWD.SVMX_PS_VS_Return_Installed_Product__c , SVMXC__Parent__c = Null , SVMXC__Status__c = label.InstallProductStatusDeInstalled , SVMXC__Date_Installed__c = Null, SVMXC__Top_Level__c = Null, Deinstall_Date__c = Date.today() ));
                    isRelatedIPUpdated = true;
                }

                if(isRelatedIPUpdated){
                    lstWDToUpdate.add(new SVMXC__Service_Order_Line__c(Id = objWD.Id, SVMXC__Line_Status__c = Label.WorkDetailLineStatusClosed));
                }
            }

            if(!lstWDToUpdate.isEmpty()){
                try{
                    update lstIPsToUpdate;
                    update lstWDToUpdate;              
                }catch(Exception e){
                    //catch the exception 
                    ApexExceptions.emit('MaterialConsumedWDManager', e);
                }
            }
          
    }

}
