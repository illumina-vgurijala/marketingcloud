//TestCaseLinesSelector 
/*
* @ author       : Romi
* @ date         : 30-Aug-2021
* @ Description  : Test class for CaseLinesSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Romi                  30-Aug-2021                        Initial version
*Preetha                14-Mar-2022                        Added checkShowOnCaseOnAP method
*/
@isTest
public class TestCaseLinesSelector {
    public static final String STRING_WO_RECORDTYPE='Field Service';
    /**
     * @author: Romi
     * @description: test selectCaseLinesFromId method.
     */
    public testMethod static void selectCaseLinesFromIdTest(){
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        insert cs;
        System.assert(cs.Id != null);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataInstalledProduct.initInstalledProduct(acc.Id);
        insert objInstalledProduct;
        
		// DCP-51097  - Start
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c='Test';
        wo.Verification_Result__c='Test'; 
        Test.startTest();
        insert wo;
        Test.stopTest();
        System.assert(wo.Id != null);
        

        Proactive_Run_Detail__c prRec = new Proactive_Run_Detail__c();
        prRec.Work_Order__c=wo.Id;
        prRec.Case__c=cs.Id;
        prRec.Notes__c='TestNotes';
        prRec.Run_ID__c='12345';
        Insert prRec;
        Set<Id> prdSetIds = new Set<Id>();
        prdSetIds.add(prRec.Id);
		
		// DCP-51097  - End
        
        //insert Case Line
        SVMXC__Case_Line__c objCaseLine = new SVMXC__Case_Line__c();
        objCaseLine.SVMXC__Case__c = cs.Id;
        objCaseLine.Installed_Product_Upgrade_Type__c = 'IVD';
        objCaseLine.Show_On_Case__c = TRUE;//QACM-18
        objCaseLine.SVMXC__Installed_Product__c=objInstalledProduct.id;
        objCaseLine.Proactive_Run_Detail__c=prRec.Id;
        insert objCaseLine;
        System.assert(objCaseLine.Id!=null);
        
        Set<Id> setobjCaseLine = new Set<Id>();
        setobjCaseLine.add(objCaseLine.Id);
        
        
        Set<Id> csSet = new Set<Id>();
        csSet.add(cs.id);
        
        Set<Id> setobjInstalledProduct = new Set<Id>();
        setobjInstalledProduct.add(objInstalledProduct.Id);
        
        
        CaseLinesSelector selector = new CaseLinesSelector();
        List<SVMXC__Case_Line__c> lstCLIP =  selector.selectCaseLinesRelatedtoIP(setobjInstalledProduct);
        System.assert(lstCLIP.size()>0);
        List<SVMXC__Case_Line__c> lstCase =  selector.selectCaseLinesOnCases(csSet);
        System.assert(lstCase.size()>0);
        List<SVMXC__Case_Line__c> lstCaseLine =  selector.selectCaseLinesFromId(setobjCaseLine);
        System.assert(lstCaseLine.size()>0);
        List<SVMXC__Case_Line__c> lstCaseLineforPrd =  selector.fetchCaseLinesForPrd(prdSetIds);
        System.assert(!lstCaseLineforPrd.isEmpty());// DCP-51097
        //QACM-18
        List<SVMXC__Case_Line__c> lstShowOnCaseLine =  selector.selectShowOnCaseLines(csSet);
        System.assert(!lstShowOnCaseLine.isEmpty(),'List has value');
        
    }

   
    
}