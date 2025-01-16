/***************************************************************************************************************************************
* NAME   : AssociatedCodesRelatedListController
* DESCRIPTION  : for AssociatedCodesRelatedList.cmp. 
* @AUTHOR : Shashank Singhal
* @DATE   : 12-July-2018  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                	DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shashank Singhal             12-July-2018         Initial Version
*****************************************************************************************************************************************/ 

public without sharing class AssociatedCodesRelatedListController {
    
    /*
*  @AUTHOR:  Shashank Singhal	
*  @DESCRIPTION:This method loads initial data required.   
*  @PARAM :  ID sworkOrderId
*  @RETURN:  JSON string with all relevant data
*/
    @AuraEnabled
    public static string getAssociatedCodes(string strWorkOrderId){
        try{
            //Query the work order record
            List<SVMXC__Service_Order__c> lstWorkOrders = new WorkOrdersSelector().selectWorkOrders(new Set<Id>{strWorkOrderId});
            string strParentCaseId = '';
            //Added as part of DCP-25588
            string strLoggedInUser='';
            Set<String> setChannelPartnerProfiles=new Set<String>{'Channel Partner Service', 'Channel Partner Sales and Service', 'Channel Partner Sales and Read Only Service', 'Channel Partner Sales and Read Only Service Login'};
                if(!lstWorkOrders.isEmpty()){
                    strParentCaseId = lstWorkOrders[0].SVMXC__Case__c;
                    //Added as part of DCP-25588
                    strLoggedInUser = lstWorkOrders[0].Logged_In_User_Profile__c;
                }
            
            //Query related associated codes related to work order and case
            List<Associated_Codes__c> lstAssociatedCodes = new AssociatedCodeSelector().selectAssociatedCodesOnWOAndCase(strWorkOrderId, strParentCaseId);
            
            //instantiate the object
            WrapObject objWrapObject = new WrapObject();
            objWrapObject.strParentCaseId = strParentCaseId;
            objWrapObject.lstAssociatedCodes = lstAssociatedCodes;
            //Added as part of DCP-25588
            objWrapObject.isChannelPartnerUser=false;
			//set boolean to true if logged in user is channel partner
            if(strLoggedInUser!='' && setChannelPartnerProfiles.contains(strLoggedInUser)){
                objWrapObject.isChannelPartnerUser=true;
            }
            
            //create JSON
            return JSON.serialize(objWrapObject);      
        }
        catch(Exception ee){
            throw new AuraHandledException('Error : '+ ee.getMessage());   
        }
    }
	
   /*
    * @Description- Wrapper Object
    */
    public class WrapObject{
        @AuraEnabled
        public string strParentCaseId;
        @AuraEnabled
        public List<Associated_Codes__c> lstAssociatedCodes;
        @AuraEnabled
        public Boolean isChannelPartnerUser;
    }
}