/*
 * 
 * 
 * @Description : TestPartnerRequestUpdateRecord
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
@IsTest(SeeAllData=false)
global with sharing class  TestPartnerRequestUpdateRecord{
    
    static testMethod  void testPartnerRequestRecord (){
         List<Partner_Request__c> lstPartnerReq=TestDataPartnerPortal.getNewPartnerRequest(1);
         insert lstPartnerReq;

        
        //perform the test
        Test.startTest();      
            PartnerRequestUpdateRecord.updatePartnerRequestRecord(lstPartnerReq[0].Id);
             Partner_Request__c pobj=[select id , Status__c from Partner_Request__c where id=:lstPartnerReq[0].Id];
            System.assertEquals('Rejected',pobj.Status__c);
        Test.stopTest();
 
    }
}