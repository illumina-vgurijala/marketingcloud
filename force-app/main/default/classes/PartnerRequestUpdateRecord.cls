/*@ author       : Prakhar Kumar
* @ date         : 14-10-2018
* @ Description  : Fetches respective carousel on the basis of Logged in user's region information
*
* Modification Log:
* ---------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------
* Prakhar Kumar          25-09-2018                                    Initial version
* Aman Tyagi             31-Mar-2022                                   CodeScan Fixes
* Aman Tyagi             12-Dec-2022                                   CodeScan Fixes
*/

public with sharing class PartnerRequestUpdateRecord {
    
    /*
*  @author       : Prakhar Kumar
*  @description  : Fetch the corresponding Slides based on the region
*  @param        : NA
*  @return       : void
*/   
    
    //Update the Status field with Rejected value on Partner Request Object    
    
    /*
*  @author       : Prakhar Kumar
*  @description  : this method has logic to update partner record based on Id of record
*  @param        : String idRecord
*  @return       : void
*/
    @AuraEnabled
    public static string updatePartnerRequestRecord(String idRecord){
        Final String StatusRejected='Rejected';
        List <Partner_Request__c>lstPartnerRequest;
        try{
            PartnerRequestsSelector obj =new PartnerRequestsSelector();
            lstPartnerRequest = obj.selectPartnerRequestRecord(idRecord);
            lstPartnerRequest[0].Status__c = StatusRejected ;
            update lstPartnerRequest[0];
            return 'success';
        }
        catch(Exception e){
            System.debug('Exception in Updating Partner REQUEST RECORD====>'+lstPartnerRequest[0]);
            return 'error';
        }
    }
}