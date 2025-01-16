//TestAssociatedProductSelector 
/*
* @ author       : Abhishek
* @ date         : 12-Sept-2023
* @ Description  : Test class for AssociatedProductSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhishek                  12-Sept-2021                        Initial version
* Dhairya Shah			    15-Feb-2023	.                       CMCM-3591
* Pritam Yadav              18-Mar-2024                         cmcm-6411
*/
@isTest
public class TestAssociatedProductSelector {
        public static final String STRING_WO_RECORDTYPE = 'Field Service';

    /**
* @author: Abhishek
* @description: test selectAssociatedProductFromId method.
*/
    public testMethod static void selectAssociatedProductFromIdTest() {

        //TO AVOID SOQL 101 FOR WORK ORDER TRIGGER
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
           Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'
        );
        insert apexSettings;

        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null,'Account got created');
        
        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact got created');
        
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        insert cs;
        System.assert(cs.Id != null, 'Case got created');
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataInstalledProduct.initInstalledProduct(acc.Id);
        insert objInstalledProduct;
        
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test'; 
        Test.startTest();
        insert wo;
        Test.stopTest();
        System.assert(wo.Id != null, 'Work order got created');
        
        
        Proactive_Run_Detail__c prRec = new Proactive_Run_Detail__c();
        prRec.Work_Order__c = wo.Id;
        prRec.Case__c = cs.Id;
        prRec.Notes__c = 'TestNotes';
        prRec.Run_ID__c = '12345';
        Insert prRec;
        Set<Id> prdSetIds = new Set<Id>();
        prdSetIds.add(prRec.Id);
        
        //insert Associated product
        Associated_product__c associatedProd = new Associated_product__c();
        associatedProd.Case__c = cs.Id;
        associatedProd.work_order__c = wo.Id;
        associatedProd.Installed_Product_Upgrade_Type__c = 'IVD';
        associatedProd.Is_Primary__c = TRUE;
        associatedProd.Installed_Product__c = objInstalledProduct.id;
        associatedProd.Proactive_Run_Detail__c  =prRec.Id;
        insert associatedProd;
        System.assert(associatedProd.Id != null, 'Associated Product got created');
        
        AssociatedProductSelector selector = new AssociatedProductSelector();
        List<Associated_product__c> lstCLIP =  selector.associatedProductRecords(prdSetIds);
        List<Id> apRecIds = new List<Id>();
        apRecIds.add(associatedProd.Id);
        Assert.isTrue(!lstCLIP.isEmpty(),'lstCLIP is empty');
        List<Associated_product__c> associatedProdCase =  selector.selectAssocProdsWithCase(associatedProd.Case__c);
        Assert.isTrue(!associatedProdCase.isEmpty(),'associatedProdCase is empty');
        List<Associated_product__c> associatedProdWorkOrder =  selector.selectAssocProdsWithWorkOrder(associatedProd.Work_Order__c);
        Assert.isTrue(!associatedProdWorkOrder.isEmpty(),'associatedProdWorkOrder is empty');
        List<Associated_Product__c> caseAPList = selector.selectAPwithCase(new Set<Id>{associatedProd.Case__c});
        Assert.isTrue(!caseAPList.isEmpty(), 'caseAPList is empty');
        List<Associated_Product__c> workOrderAPList = selector.selectAPwithWorkOrder(new Set<Id>{associatedProd.Work_Order__c});
        Assert.isTrue(!workOrderAPList.isEmpty(), 'associated Product reult is empty');
        List<Associated_Product__c> woRelatedAP = selector.selectPrimaryProductwithWorkOrder(new Set<Id>{associatedProd.Work_Order__c});
        Assert.isTrue(!woRelatedAP.isEmpty(), 'associated Product result is empty'); 
        List<Associated_Product__c> caseRelatedAP = selector.selectPrimaryProductwithCase(new Set<Id>{associatedProd.Case__c});
        Assert.isTrue(!caseRelatedAP.isEmpty(), 'caseRelatedAP result is empty');
        List<Associated_Product__c> listAPRecs = selector.selectAssocProdsWithAPId(apRecIds);
        Assert.isTrue(!listAPRecs.isEmpty(), 'listAPRecs result is not empty');
        List<Associated_Product__c> apProdsDelete = selector.selectAssocProdsforDelete(apRecIds);
        Assert.isTrue(apProdsDelete.isEmpty(), 'apProdsDelete result is empty');
        List<Associated_Product__c> apRecordList = selector.selectAPwithIds(new Set<Id> {associatedProd.Id});
        Assert.isTrue(!apRecordList.isEmpty(), 'apRecordList result is empty');
        List<Associated_Product__c> apRelatedCaseWOList = selector.selectAPwithCaseWOIds(new Set<Id> {cs.Id} , new Set<Id> {wo.Id});
        Assert.isTrue(!apRelatedCaseWOList.isEmpty(), 'apRelatedCaseWOList result is empty');
        //CMCM-6411 - START
        List<Associated_Product__c> apRelatedIPList = selector.selectAPwithIP(new Set<Id> {associatedProd.Id});
        Assert.isTrue(!apRelatedIPList.isEmpty(), 'apRelatedIPList result is empty');
		//CMCM-6411 - END
        List<Associated_Product__c> ipRelatedAP = selector.selectAPwithInstallProduct(new Set<Id> {objInstalledProduct.id});
        Assert.isTrue(!ipRelatedAP.isEmpty(), 'apRelatedIPList result is empty');
        
           }
}