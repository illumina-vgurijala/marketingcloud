//TestAgreementsSelector 
/*
* @ author       : Romi
* @ date         : 30-Aug-2021
* @ Description  : Test class for AgreementsSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Romi                  30-Aug-2021                        Initial version
*/
@IsTest
public class TestAgreementsSelector {
    /**
     * @ method selectAgreementsTest
     * @description:test selecteAgreements method.
     */
    public testMethod static void selectAgreementsTest() {
        
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != null);
        
        //insert Work Order
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        insert workOrder2;
        
        //insert Agreement
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
        agreement.Name = 'Testagreement';
        agreement.echosign_dev1__Status__c = 'Signed';   
        agreement.Work_Order__c = workOrder2.Id;
        insert agreement;  
        
        Set<Id> setagreement = new Set<Id>();
        setagreement.add(agreement.Id);
        
        Test.startTest();
        AgreementsSelector selector = new AgreementsSelector();
        selector.selectAgreements(setagreement);
        List<echosign_dev1__SIGN_Agreement__c> lstAgreement =  new AgreementsSelector().selectAgreements(setagreement);
        System.assert(lstAgreement.size()>0);
        Test.stopTest();
        
    }
    /**
     * @method:selectWOAgreementsTest
     * @description: test the selectWOAgreements method.
     */
    public testMethod static void selectWOAgreementsTest(){
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != null);
        
        //insert Work Order
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        insert workOrder2;
        
        Set<Id> setWO = new Set<Id>();
        setWO.add(workOrder2.Id);
        
        //insert Agreement
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
        agreement.Name = 'Testagreement';
        agreement.echosign_dev1__Status__c = 'Signed';   
        agreement.Work_Order__c = workOrder2.Id;
        insert agreement;  
        
        Test.startTest();
        AgreementsSelector selector = new AgreementsSelector();
        selector.selectWOAgreements(setWO);
        List<echosign_dev1__SIGN_Agreement__c> lstAgreement =  new AgreementsSelector().selectWOAgreements(setWO);
        System.assert(lstAgreement.size()>0);
        Test.stopTest();
        
    } 
    @istest(seeAllData = true)// To ensure all required managed package SVMXC Data is available
    /**
     * @method: selectPOLAgreementsTest
     * @description: test the selectPOLAgreements method.
     */
    public static void selectPOLAgreementsTest(){
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != null);
        
        //insert Work Order
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        insert workOrder2;
        
        //insert Parts Order
        SVMXC__RMA_Shipment_Order__c objPartsOrder =TestDataFieldService.createPartOrder('RMA', cs.Id, 'Open');
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='1234567890';
        objPartsOrder.SVMXC__Order_Type__c='Return';
        insert objPartsOrder;
        
        //insert Parts Order Line
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        insert objPartsOrderLine;
        
        Set<Id> setPartsOrderLine = new Set<Id>();
        setPartsOrderLine.add(objPartsOrderLine.Id);
        
        
        //insert Agreement
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
        agreement.Name = 'Testagreement';
        agreement.echosign_dev1__Status__c = 'Signed';   
        agreement.Parts_Order_Line__c=objPartsOrderLine.Id;
        insert agreement;  
        
        Test.startTest();
        AgreementsSelector selector = new AgreementsSelector();
        List<echosign_dev1__SIGN_Agreement__c> lstAgreement = selector.selectPOLAgreements(setPartsOrderLine);
        System.debug('lstAgreement-->'+lstAgreement);
        System.assert(lstAgreement.size()>0);
        Test.stopTest();
        
    } 
    
    
}