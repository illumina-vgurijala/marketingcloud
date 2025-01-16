/*@ author       : Gopesh Banker
* @ date         : 04 Oct 2018
* @ Description  : display action callback class to enable/disable actions on cart
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Gopesh Banker          04 Oct 2018                      Initial version
*/
global with sharing class ApttusDisplayActionCallback implements Apttus_Config2.CustomClass.IDisplayActionCallback{
    
    private List<Apttus_Config2.DisplayActionInfo> lstDisplayActions;
    @TestVisible private Apttus_Config2__ProductConfiguration__c objProductConfig;
    private static final String FINALIZE = 'Finalize';
    private static final String CARTLINEITEIM = 'Cart Line Item';
    private static final string SUGGESTED_SALES = 'Apply_Remove';

    /**
    * @owner Gopesh Banker
    * @description start method of the interface
    * @param cart the cart object to validate, lstDisplayActions - list of actions
    * @return void
    **/
    global void start(Apttus_Config2.ProductConfiguration cart, List<Apttus_Config2.DisplayActionInfo>lstDisplayActions){
        this.lstDisplayActions = lstDisplayActions;
        if(!Test.isRunningTest())
        {
            this.objProductConfig = cart.getConfigSO();
        }
    }

    /**
    * @owner Gopesh Banker
    * @description actual show/hide enable/disable logic to be implemented
    * @param actionParam all actions of the page
    * @return void
    **/
    global void setActionProperties(Apttus_Config2.CustomClass.ActionParams actionParam){
                
            Boolean boolGTChecked = objProductConfig.GT_Check_Pending_Count__c == 0;
            if(!boolGTChecked){
                for(Apttus_Config2.DisplayActionInfo objAction : this.lstDisplayActions)
                {
                    if(objAction.ActionSO.Apttus_Config2__DisplayType__c.equalsIgnoreCase(CARTLINEITEIM) && objAction.ActionSO.Apttus_Config2__ActionLabelName__c.contains(FINALIZE)){
                        objAction.isEnabled = false;
                    }
                }
            }

        Boolean boolCatalystEnabled = FeatureManagement.checkPermission('Check_Catalyst_Discount');

        if(!boolCatalystEnabled){
            for(Apttus_Config2.DisplayActionInfo objAction : this.lstDisplayActions)
            {
                if(objAction.ActionSO.Apttus_Config2__DisplayType__c.equalsIgnoreCase(CARTLINEITEIM) && objAction.ActionSO.Apttus_Config2__ActionLabelName__c.contains(SUGGESTED_SALES)){
                        objAction.isEnabled = false;
                }
            }
        }
    }
}