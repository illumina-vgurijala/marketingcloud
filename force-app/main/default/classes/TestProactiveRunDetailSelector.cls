/*@ author       : Raviteja Vakkalagadda
* @ date         : 24-Nov-2021
* @ Description  : Test class for ProactiveRunDetailSelector class
*
* Modification Log::
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* -----------------------------------------------------------------------------------------------------------------------------------------
* Raviteja Vakkalagadda                   24-Nov-2021                                  Initial version
* 
*/
@isTest
public with sharing class TestProactiveRunDetailSelector 
{   
    static Case cs;
    public static final String STRING_ACCOUNT='Test Acc';
    public static final String STRING_WO_RECORDTYPE='Field Service';
    public static final String STRING_WO_ORDER_TYPE='Service Activities';


     testMethod static void proactiveSelectorCoverage()
     {
         Account acc=TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        Contact conRec=TestDataPerson.getNewContact(acc.Id);
        System.assert(conRec.id !=null);

        Product2 objProduct=TestDataFieldService.createProduct('TestProduct', 'Instrument');
        objProduct.Product_Category__c='MiSeq';
        objProduct.ProductCode='TestProduct';
        insert objProduct;

        SVMXC__Installed_Product__c objInstalledProduct=TestDataFieldService.createInstalledProduct('TestIP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c=acc.Id;
        INSERT objInstalledProduct;

        cs=TestDataCase.initServiceRequestCase(conRec);
        cs.SVMXC__Component__c=objInstalledProduct.Id;
        insert cs;

        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
          wo.Evaluation__c='Test';
          wo.SVMXC__Work_Performed__c='Test';
          wo.Verification_Result__c='Test'; 
          insert wo;
          System.assert(wo.Id != null);
          wo.SVMXC__Order_Status__c = 'Completed';
          wo.No_Calibrated_Tools_Used__c = true;
          wo.Is_Service_Report_Generated__c = true;
          wo.PO_Number__c='12';
          wo.No_Calibrated_Tools_Used__c = true;
          Test.startTest();
          update wo;
          Test.stopTest();

        Proactive_Run_Detail__c prRec = new Proactive_Run_Detail__c();
        prRec.Work_Order__c=wo.Id;
        prRec.Case__c=cs.Id;
        prRec.Notes__c='TestNotes';
        prRec.Run_ID__c='12345';
        Insert prRec;
         
         ProactiveRunDetailSelector prdSelector = new ProactiveRunDetailSelector();
         
         System.assertNotEquals(null, prdSelector.selectPRDRec(prRec.Id));
         System.assertNotEquals(null, prdSelector.selectPRDRecFromRunId(prRec.Run_ID__c));
         
         
     }
}