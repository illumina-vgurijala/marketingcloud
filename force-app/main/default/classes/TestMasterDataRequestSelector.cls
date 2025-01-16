/**
*    @author Pankaj Singla
*    @date   2019-10-08
*    @description    Test class for MasterDataRequestSelector
*    Modification Log:
*    ---------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                08 Aug 2019           Initial Build   
*             Satya Swain                  23 Aug 2019           DCP-30062: Sonar Qube Issue Fix 
//SonarQube Issue Fix 10/12/2019        
*             Satya Swain                  09 Dec 2022           Added Codescan fix for Variable Naming Convention
*    --------------------------------------------------------------------------------------------- 
*                    
*/

@isTest
public class TestMasterDataRequestSelector{
     
     static testmethod void testMDGSelector(){
     
        Account objAcc=TestDataMarketing.getAccount('TestAccount');
        objAcc.Territory_Region__c='AMR';
        update objAcc;
        Id recordTypeIdChangeRequest = Schema.SObjectType.Master_Data_Request__c.getRecordTypeInfosByName().get('Other Change Request').getRecordTypeId();
        Master_Data_Request__c objMDR=new Master_Data_Request__c();
        objMDR.RecordTypeId=recordTypeIdChangeRequest;
        objMDR.Account_Name__c=objAcc.id;
        objMDR.Comments__c='Test';
        insert objMDR;
        List<Id> lst12=new List<Id>();
        lst12.add(objMDR.id);
        MasterDataRequestSelector obj=new MasterDataRequestSelector();
        List<Master_Data_Request__c> testList=obj.selectByMDRId(objMDR.id);
        List<Master_Data_Request__c> testList2=obj.selectByListMDR(lst12);

        System.assert(testList.size()>0);
        System.assert(testList2.size()>0);
     
     }

}