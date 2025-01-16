/***************************************************************************************************************************************
 * NAME   : TestAssociatedCodeSelector
 * DESCRIPTION  : TestClass for AssociatedCodeSelector
 * @AUTHOR : Naomi
 * @DATE   : 24-June-2019 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Naomi              22-May-2018             Initial Version
 ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)
public class TestAssociatedCodeSelector {
 
    static case cs;
	/**
      *  @author Prashanth
      *  @description - initialize test data
    **/

    @testSetup
    public static void initializeTestData()
    {
        Contact con = TestDataPerson.getNewContact(null);
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }
    
    
    static testmethod void removeAssociatedCodesTest(){
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'General';
        cs.Category__c = 'Question'; 
        cs.Status = 'In Progress';
        
        
        test.startTest();
        
        insert cs;
        
        Case cs2 = TestDataCase.initServiceRequestCase(con);
        cs2.Status = 'In Progress';
        insert cs2;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs2.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
        list<Code_Library__c> codeLibLst = new list<Code_Library__c>();
        Code_Library__c dclparent = new Code_Library__c(Name='INQ CS Inquiry Subject parent code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool');
        codeLibLst.add(dclparent);
        Code_Library__c disCl = new Code_Library__c(Name='Code Disassociated', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool');
        codeLibLst.add(disCl);
        insert codeLibLst;
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool',
                                                  Parent_Code__c=dclparent.Id);
        insert dcl;
        //system.runAs(serviceUser){
        list<Associated_Codes__c> aclst= new list<Associated_Codes__c>();
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dcl.Id;
        ac.Case__c = cs.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Inquiry';
        aclst.add(ac);
        Associated_Codes__c ac2 = new Associated_Codes__c();
        ac2.Code_Title__c = dclparent.Id;
        ac2.Case__c = cs.Id;
        ac2.Code_Type__c='Subject';
        ac2.Case_Type__c='Inquiry';
        aclst.add(ac2);
        Associated_Codes__c ac3 = new Associated_Codes__c();
        ac3.Code_Title__c = dcl.Id;
        ac3.Work_Order__c = workOrder.Id;
        ac3.Case__c = cs2.Id;
        ac3.Code_Type__c='Subject';
        ac3.Case_Type__c='Inquiry';
        aclst.add(ac3);
        
        
        insert aclst;
        System.debug('The acLst');
        AddAssociatedCodesController.removeAssociatedCodes(cs.id,ac.id);
        //system.assertEquals(dcl.name,'INQ CS Inquiry Subject code');
        system.assertEquals(2,[select id from Associated_Codes__c where case__c=: cs.Id and Code_Title__c=: disCl.Id].size());
        AddAssociatedCodesController.removeAssociatedCodes(workOrder.Id,ac3.id);
        system.assertEquals(1,[select id from Associated_Codes__c where Work_Order__c =: workOrder.Id and Code_Title__c=: disCl.Id].size());
        //JSON.serialize(wrapObj);
        test.stopTest();
    }
    
    static testmethod void getAssociatedCodesTest() {
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'General';
        cs.Category__c = 'Question'; 
        cs.Status = 'In Progress';
        test.startTest();
        
        insert cs;
        System.assert(cs.Id != null);
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',
                                                  Service_Product_Type__c = 'Tool');
        insert dcl;
        //system.runAs(serviceUser){
        list<Associated_Codes__c> aclst= new list<Associated_Codes__c>();
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dcl.Id;
        ac.Case__c = cs.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Inquiry';
        
        Associated_Codes__c ac2 = new Associated_Codes__c();
        ac2.Code_Title__c = dcl.Id;
        ac2.Case__c = cs.Id;
        ac2.Code_Type__c='Subject';
        ac2.Case_Type__c='Inquiry';
        
        aclst.add(ac);
        aclst.add(ac2);
        
        insert aclst;
        
        AddAssociatedCodesController.getAssociatedCodes(cs.Id,null,null);
        // All,Subject,Analysis,Resolution,Verification,Product
        AddAssociatedCodesController.WrapObject wrapObj= new AddAssociatedCodesController.WrapObject();
        wrapObj.lstAssociatedCodes=aclst;
        wrapObj.lstCodeLibrary= new List<Code_Library__c>{dcl};
            wrapObj.lSearchOptions= new List<String>{'All'};
                wrapObj.objInsertedCode= ac;
        wrapObj.objDeletedCode= ac2;
        wrapObj.CodeName='testcode';
        wrapObj.CodeId='SUB-123323';
        wrapObj.parentCodeName='INQ CS Inquiry Subject code'; 
        //new Associated_Codes__c(ac.Code_Title__c = dcl.Id, ac.Case__c = cs.Id,ac.Code_Type__c='Subject',ac.Case_Type__c='Inquiry')
        JSON.serialize(wrapObj);
        
        test.stopTest();
        
    }
    /**
     * @description: Test Associated code creation on Inquiry case.
     */
    static testmethod void newAssociatedCodeCreationOnInquiryCase() {
    
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'Order';
        cs.Category__c = 'New Order'; 
        cs.Status = 'In Progress';
        cs.Closed_with_Associated_Codes__c = false;
        test.startTest();
        
        User serviceUser=TestDataUser.findUserInProfile('Customer Service');
       system.runAs(serviceUser){
            insert cs;
            Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',
                                                      Service_Product_Type__c = 'Tool');
            insert dcl;
        //system.runAs(serviceUser){
            Associated_Codes__c ac = new Associated_Codes__c();
            ac.Code_Title__c = dcl.Id;
            ac.Case__c = cs.Id;
            ac.Code_Type__c='Subject';
            ac.Case_Type__c='Inquiry';
            insert ac;
            
            cs.status='Closed';
            cs.Record_Updated_from_SFM__c=true;
            cs.ASOP_Order__c = 'O-12345';
            update cs;

            System.assertEquals(1, [select id from Associated_Codes__c where Code_Title__c =: dcl.Id and case__c =: cs.Id].size());
        
        }
        test.stopTest();
    }
    
    
    static testmethod void testselectAssociatedCodesOnWOAndCase(){
    
       initializeTestData();
    
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Service Activities';
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        
        Set<Id> setWOId=new Set<Id>();
        setWOId.add(workOrder.id);
        Set<Id> setCaseId=new Set<Id>();
        setCaseId.add(cs.id);
        setCaseId.add(workOrder.id);
        
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',
                                                      Service_Product_Type__c = 'Tool');
            insert dcl;
        Code_Library__c dcl1 = new Code_Library__c(Name='Code Disassociated', Code_type__c = 'Subject');
        insert dcl1;
        //system.runAs(serviceUser){
            Associated_Codes__c ac = new Associated_Codes__c();
            ac.Code_Title__c = dcl.Id;
            ac.Case__c = cs.Id;
            ac.Code_Type__c='Subject';
            ac.Case_Type__c='Inquiry';
            ac.Work_Order__c=workOrder.id;
            insert ac;
            
            List<Associated_Codes__c> lstAsscode=new AssociatedCodeSelector().selectAssociatedCodesOnWOAndCase(workOrder.id,cs.id);
            lstAsscode=new AssociatedCodeSelector().selectAssociatedCodesOnWorkOrders(setWOId);
            System.assert(lstAsscode.size()>0);
            lstAsscode=new AssociatedCodeSelector().selectAssociatedCodesOnCaseWithCodeTitle(setCaseId,new Set<String>{dcl.Name}, 'Subject');
            System.assert(lstAsscode.size()>0);
            //dcl.Name='Code Disassociated';
            dcl.Logistics_Supply_Chain_code__c=true;
            update dcl;
            
            lstAsscode=new AssociatedCodeSelector().selectNotDisAssociatedCodesOnCase(setCaseId);
            lstAsscode=new AssociatedCodeSelector().selectLogisticsAssociatedCodes(new Set<id>{ac.id});
            System.assert(lstAsscode.size()>0);
            lstAsscode=new AssociatedCodeSelector().selectActiveAssociatedCodesOnCase(setCaseId,'Code_Type__c','ASC');
            lstAsscode=new AssociatedCodeSelector().selectActiveAssociatedCodesOnCase(setCaseId,'Code_Type__c','DESC');
            lstAsscode=new AssociatedCodeSelector().selectAssociatedCodesOnCaseWithCodeIds(setCaseId,new Set<id>{dcl.id});
            System.assert(lstAsscode.size()>0);
            lstAsscode=new AssociatedCodeSelector().selectActiveAssociatedCodesOnWOs(setWOId,setCaseId,'Code_Type__c','ASC');
            lstAsscode=new AssociatedCodeSelector().selectActiveAssociatedCodesOnWOs(setWOId,setCaseId,'Code_Type__c','DESC');
            System.assert(lstAsscode.size()>0);
            lstAsscode=new AssociatedCodeSelector().selectAssociatedCodesForWOAndCase(string.valueof(workOrder.Id),String.valueOf(cs.Id) );
            System.assertNotEquals(0,lstAsscode.size(), 'List is Empty');
    }

    /**
     * @description: Test method for getAssociatedCodesOnCase()
     */
    static testmethod void testGetAssociatedCodesOnCase() {
        initializeTestData();
    
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Service Activities';
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        
        Set<Id> setWOId=new Set<Id>();
        setWOId.add(workOrder.id);
        Set<Id> setCaseId=new Set<Id>();
        setCaseId.add(cs.id);
        setCaseId.add(workOrder.id);
        
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',
                                                      Service_Product_Type__c = 'Tool');
            insert dcl;
        Code_Library__c dcl1 = new Code_Library__c(Name='Code Disassociated', Code_type__c = 'Subject');
        insert dcl1;
         
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dcl.Id;
        ac.Case__c = cs.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Inquiry';
        ac.Work_Order__c=workOrder.id;
        insert ac;

        test.startTest();  
        List<Associated_Codes__c> acs = new AssociatedCodeSelector().getAssociatedCodesOnCase(cs.Id);
        System.assertEquals(1, acs.size(),'testGetAssociatedCodesOnCase');
        test.stopTest();
    }

     /**
     * @description: Test method for getAssociatedCodesFromWorkOrderOrCase()
     */
    static testmethod void testGetAssociatedCodesFromWorkOrderOrCase() {
        initializeTestData();
    
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Service Activities';
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        System.assert(workOrder.Id != null,'testGetAssociatedCodesFromWorkOrderOrCase');
        
        Set<Id> setWOId=new Set<Id>();
        setWOId.add(workOrder.id);
        Set<Id> setCaseId=new Set<Id>();
        setCaseId.add(cs.id);
        setCaseId.add(workOrder.id);
        
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',
                                                      Service_Product_Type__c = 'Tool');
            insert dcl;
        Code_Library__c dcl1 = new Code_Library__c(Name='Code Test', Code_type__c = 'Subject');
        insert dcl1;
         
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dcl.Id;
        ac.Case__c = cs.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Inquiry';
        ac.Work_Order__c=workOrder.id;
        insert ac;

        test.startTest();  
        new AssociatedCodeSelector().getAssociatedCodesFromWorkOrderOrCase(cs.Id,workOrder.Id);
        test.stopTest();
    }

}