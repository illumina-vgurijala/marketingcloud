/***************************************************************************************************************************************
* NAME   : TestAddAssociatedCodesController
* DESCRIPTION  : TestClass for AddAssociatedCodesController
*                  
*    
* @AUTHOR : Bharath
* @DATE   : 21-May-2019
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Bharath                  21-May-2019        initial Development
* KD                       20-May-2020         Add data set up method
* --------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/ 


@isTest(SeeAllData = false)
public class TestAddAssociatedCodesController{
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    //DCP-47684
    public static final string STRING_PRODUCT_INSTRUMENT = 'Instrument';
    public static final string CASE_ORIGIN_PHONECP  = 'Phone-CP';
    public static final string PRODUCT_REGULATORYTYPE_IUO = 'IUO';
    public static final string PRODUCT_SERIALNUMBER = 'IL02';
    public static final string CASE_SUBTYPE_ORDER = 'Order';

    @testSetup
    static void setupData(){
        User usr1 = TestDataFieldService.createUser(System.label.Profile_Quality_Assurance,false);
        usr1.alias = 'TestUser';
        usr1.userName = System.now().format('yyyyMMddhhmmss') + '@testorg1.com';
        usr1.FederationIdentifier = 'Test234';
        insert new list<User> {usr1};
        List<Code_Library__c> lstCodeLib = new List<Code_Library__c>();
        Code_Library__c objCLParent = new Code_Library__c(Name='Test Hazard Code Parent',
        Code_type__c = 'Hazard', Case_Type__c = STRING_CASE_RECORDTYPENAME);
        insert objCLParent;
        Code_Library__c objCL = new Code_Library__c(Name='Test Hazard Code',
        Code_type__c = 'Hazard', Case_Type__c = STRING_CASE_RECORDTYPENAME,Parent_Code__c =objCLParent.id );
        lstCodeLib.add(objCL);
        Code_Library__c objCL1 = new Code_Library__c(Name='Additional Code',
        Code_type__c = 'Hazard', Case_Type__c =STRING_CASE_RECORDTYPENAME);
        lstCodeLib.add(objCL1);
        insert lstCodeLib;
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        cs.Date_of_Issue_Awareness__c = Date.Today();
        cs.Hazard_Codes__c = 'Test Hazard Code';
        cs.status = Label.CaseStatusInitiated;
        insert cs;
    }

    /*
    *@author: Kushagra Desai
    *@Desc: Test Hazard code related funtionality
    */

    @isTest
    static void testSearchCode(){
        User usr = [Select id from User where alias = 'TestUser'];
        Test.startTest();
        System.runAs(usr){
            List<Case> lstCase = [select id from Case];
            String strResponse = AddAssociatedCodesController.getSearchCodeList('Test Hazard','Hazard',lstCase[0].id,null,null);
            String strHazardName = (String)JSON.deserialize(UtilsObject.getJSONPart(strResponse, ',"Name":', ',"OwnerId":'), 
                                                       String.class);
            System.assertEquals(true,strHazardName.equals('Test Hazard Code'),'Incorrect Code returned');
            String strResponse1 = AddAssociatedCodesController.getAssociatedCodes(lstCase[0].id,null,null);
            Boolean boolQAUser = (Boolean)JSON.deserialize(UtilsObject.getJSONPart(strResponse1, ',"boolQAUser":', ',"bLockCodes":'), 
                                                       Boolean.class);
            System.assertEquals(true,boolQAUser,'Incorrect User check');
        }
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
        system.assertEquals(2,aclst.size());
        
        test.stopTest();
        
    }
    
    static testmethod void getAssociatedCodesTest2() {//passing workorder
         //Create channel partner profile   
        Id profileId = [select id from profile where name=: Label.Channel_Partner_Profile_Name].id;
        Account acc =TestDataAccount.initAccount();
        acc.Territory_Region__c='AMR';
        acc.Account_Group__c = 'Sold To';
        insert acc;
        //Create account
        
        Account acc1 = [Select id,Account_Group__c From Account WHERE id=:acc.id][0];
        System.debug('before contact'+acc1);
        //Create Contact
        Contact con =TestDataContact.getNewContact(acc);
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;   
        //Create user of Channel Partner user
        User u = new User(alias = uniqueName.substring(18, 23), email=uniqueName + '@test' + orgId + '.org',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profileId , country='USA',IsActive =true,PortalRole = 'Manager',
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username=uniqueName + '@test' + orgId + '.org');
       
        insert u;
        Account acc5 = [Select id,Account_Group__c From Account WHERE id=:acc.id][0];
        System.debug('before case'+acc5);
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
        cs.Sub_Type__c = Label.CaseSubTypeComplaint;
        cs.Category__c = Label.CaseCategoryInstall;
        //cs.Category__c = 'Question'; 
        cs.Status = 'In Progress';
        cs.Subject = 'test' ;
        cs.Description= 'test';
        cs.Origin = 'Phone-CP';
        cs.Date_of_Issue_Awareness__c=System.today() -2;
        cs.Awareness_Date_Difference_Reason__c = 'Automatic case creation during off hours';
        cs.ContactId = con.Id;
        test.startTest();
        insert cs;
        SVMXC__Service_Order__c objWorkOrder  = [Select id,OwnerID from SVMXC__Service_Order__c where SVMXC__Case__c=: cs.Id];
        
        objWorkOrder.OwnerID = u.id;
        update objWorkOrder;
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',
                                                  Service_Product_Type__c = 'Tool');
        insert dcl;
        list<Associated_Codes__c> aclst= new list<Associated_Codes__c>();
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dcl.Id;
        ac.Case__c = cs.Id;
        ac.Work_Order__c = objWorkOrder.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Inquiry';
        
        Associated_Codes__c ac2 = new Associated_Codes__c();
        ac2.Code_Title__c = dcl.Id;
        ac2.Case__c = cs.Id;
        ac2.Work_Order__c = objWorkOrder.Id;
        ac2.Code_Type__c='Subject';
        ac2.Case_Type__c='Inquiry';
        
        aclst.add(ac);
        aclst.add(ac2);
        
        insert aclst;
    
        AddAssociatedCodesController.getAssociatedCodes(objWorkOrder.Id,null,null);
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
        system.assertEquals(2,aclst.size());
        //Run as a Channel Partner user
        system.runAs(u){
        try{
            AssociatedCodesRelatedListController.getAssociatedCodes(objWorkOrder.Id);
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
        }
        
        test.stopTest();
        
    }
}

  static testmethod void getcodesTest() {
       
      string obj = '';
        try {
                obj=AssociatedCodesRelatedListController.getAssociatedCodes('Test');
             } 
            catch(AuraHandledException  e) {
            system.assert(e.getMessage().length()>0);
        } 
        
      }
    
    
    
    
    static testmethod void getSearchCodeListTest() {
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'General';
        cs.Category__c = 'Question'; 
        cs.Status = 'In Progress';
        test.startTest();
        
        insert cs;
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool');
        insert dcl;
        Code_Library__c dcl1 = new Code_Library__c(Name='INQ CS Inquiry Verification code', Code_type__c = 'Verification', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool');
        insert dcl1;
        //system.runAs(serviceUser){
        list<Associated_Codes__c> aclst= new list<Associated_Codes__c>();
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dcl.Id;
        ac.Case__c = cs.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Inquiry';
        aclst.add(ac);
        Associated_Codes__c ac1 = new Associated_Codes__c();
        ac1.Code_Title__c = dcl1.Id;
        ac1.Case__c = cs.Id;
        ac1.Code_Type__c='Verification';
        ac1.Case_Type__c='Inquiry';
        aclst.add(ac1);
        
        insert aclst;
        
        AddAssociatedCodesController.getSearchCodeList(dcl.name,'All',cs.Id,null,null);
        AddAssociatedCodesController.getSearchCodeList(dcl.name,'Subject',cs.Id,null,null);
        system.assertEquals('Subject',aclst[0].Code_Type__c);
        AddAssociatedCodesController.getSearchCodeList(dcl1.name,'Verification',cs.Id,null,null);
        system.assertEquals('Verification',aclst[1].Code_Type__c);
        AddAssociatedCodesController.getSearchCodeList(null,'All',cs.Id,null,null);
        AddAssociatedCodesController.WrapObject wrapObj= new AddAssociatedCodesController.WrapObject();
        wrapObj.lstAssociatedCodes=aclst;
        JSON.serialize(wrapObj);
        test.stopTest();
        
    }
    
    static testmethod void getSearchCodeListTest2() {//passing workorder
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
        cs.Sub_Type__c = Label.CaseSubTypeComplaint;
        cs.Category__c = Label.CaseCategoryInstall; 
        cs.Status = 'In Progress';
        cs.Subject = 'test' ;
        cs.Description= 'test';
        cs.Origin = 'Phone-CP';
        cs.Date_of_Issue_Awareness__c=System.today() -2;
        cs.Awareness_Date_Difference_Reason__c = 'Automatic case creation during off hours';
        cs.ContactId = con.Id;
        test.startTest();
        
        insert cs;
        SVMXC__Service_Order__c objWorkOrder  = [Select id from SVMXC__Service_Order__c where SVMXC__Case__c=: cs.Id];
        
        
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool');
        insert dcl;
        //system.runAs(serviceUser){
        list<Associated_Codes__c> aclst= new list<Associated_Codes__c>();
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dcl.Id;
        ac.Case__c = cs.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Inquiry';
        aclst.add(ac);
        
        insert aclst;
        
        AddAssociatedCodesController.getSearchCodeList(dcl.name,'All',objWorkOrder.Id,null,null);
        AddAssociatedCodesController.getSearchCodeList(dcl.name,'Subject',objWorkOrder.Id,null,null);
        AddAssociatedCodesController.getSearchCodeList(dcl.name,'Verification',objWorkOrder.Id,null,null);
        AddAssociatedCodesController.WrapObject wrapObj= new AddAssociatedCodesController.WrapObject();
        wrapObj.lstAssociatedCodes=aclst;
        JSON.serialize(wrapObj);
        system.assertEquals(1,aclst.size());
        test.stopTest();
        
    }
    
    static testmethod void addAssociatedCodesTest() {
        
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'General';
        cs.Category__c = 'Question'; 
        cs.Status = 'In Progress';
        test.startTest();
        
        insert cs;
        list<Code_Library__c> codeLibLst = new list<Code_Library__c>();
        Code_Library__c dclparent = new Code_Library__c(Name='INQ CS Inquiry Subject parent code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool');
        codeLibLst.add(dclparent);
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool', Parent_Code__c =dclparent.id);
        codeLibLst.add(dcl);
        insert codeLibLst;
        //system.runAs(serviceUser){
        /*list<Associated_Codes__c> aclst= new list<Associated_Codes__c>();
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dcl.Id;
        ac.Case__c = cs.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Inquiry';
        ac.Parent_Code__c=dcl.id;
        aclst.add(ac);
        Associated_Codes__c ac2 = new Associated_Codes__c();
        ac2.Code_Title__c = dcl.Id;
        ac2.Case__c = cs.Id;
        ac2.Code_Type__c='Subject';
        ac2.Case_Type__c='Inquiry';
        aclst.add(ac2);
        
        insert aclst;*/
        
        AddAssociatedCodesController.addAssociatedCodes(cs.id,dcl.id);
       system.assertEquals('INQ CS Inquiry Subject code',dcl.name);
       //JSON.serialize(wrapObj);
        test.stopTest();
        
        
    }
    
    static testmethod void addAssociatedCodesTest2(){
        
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
        cs.Sub_Type__c = Label.CaseSubTypeComplaint;
        cs.Category__c = Label.CaseCategoryInstall; 
        cs.Status = 'In Progress';
        cs.Date_of_Issue_Awareness__c=System.today() -2;
        cs.Awareness_Date_Difference_Reason__c = 'Automatic case creation during off hours';
        
        test.startTest();
        insert cs; 
        SVMXC__Service_Order__c wo = [select id, SVMXC__Case__c from SVMXC__Service_Order__c where SVMXC__Case__c=:cs.id][0];
        //insert wo;
        
        Code_Library__c dclparent = new Code_Library__c(Name='INQ CS Inquiry Subject parent code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool');
        insert dclparent;
        Code_Library__c dcl = new Code_Library__c(Name='INQ CS Inquiry Subject code', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',Service_Product_Type__c = 'Tool', Parent_Code__c =dclparent.id);
        insert dcl;
        //system.runAs(serviceUser){
        list<Associated_Codes__c> aclst= new list<Associated_Codes__c>();
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dcl.Id;
        ac.Case__c = cs.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Inquiry';
        ac.Parent_Code__c=dcl.id;
        aclst.add(ac);
        Associated_Codes__c ac2 = new Associated_Codes__c();
        ac2.Code_Title__c = dcl.Id;
        ac2.Case__c = cs.Id;
        ac2.Code_Type__c='Subject';
        ac2.Case_Type__c='Inquiry';
        aclst.add(ac2);
        
        insert aclst;
        
        AddAssociatedCodesController.addAssociatedCodes(wo.id,dcl.id);
        system.assertEquals(2,aclst.size());
        //JSON.serialize(wrapObj);
        test.stopTest();
        
        
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
    
    /*******************************************************************************************************
    * @description DCP-47684 test coverage for Highlighting codes functionality
    */
    static testmethod void getValidationsMapTest() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Product2',
            Bypass_Triggers_By_Object_2__c = 'Contact'
        );
        insert apexSettings;
        
        Map<String, Boolean> codesValidationMap = new Map<String, Boolean>();
        List<Case> lstCases = new List<Case>();

        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Label.CaseRecordTypeBusinessIssue).getRecordTypeId();
        cs.Sub_Type__c = Label.CaseSubTypeComplaint;
        cs.Category__c = Label.CaseCategoryInstall;
        cs.Status = Label.CaseStatusInProgress;
        cs.Subject = 'test' ;
        cs.Description= 'test';
        cs.Origin = CASE_ORIGIN_PHONECP;
        cs.Date_of_Issue_Awareness__c=System.today() -2;
        cs.Awareness_Date_Difference_Reason__c = 'Automatic case creation during off hours';
        cs.ContactId = con.Id;
        insert cs;

        System.assert(cs.Id != null, 'Case not created successfully');

        Contact conLog = new Contact(FirstName = 'testlogisticfirstname', LastName = 'testlogisticlastname');
        Case csLog = TestDataCase.initServiceRequestCase(conLog);
        csLog.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Label.CaseRecordTypeBusinessIssue).getRecordTypeId();
        csLog.Sub_Type__c = Label.CaseSubTypeGeneralIssue;
        csLog.Category__c = Label.CaseCategoryLogistics;
        csLog.Status = Label.CaseStatusInProgress;
        csLog.Subject = 'test_1653' ;
        csLog.Description= 'test_1653';
        csLog.Origin = CASE_ORIGIN_PHONECP;
        csLog.Date_of_Issue_Awareness__c=System.today() -2;
        csLog.Awareness_Date_Difference_Reason__c = 'Logistical Delay';
        csLog.ContactId = conLog.Id;
        insert csLog;

        System.assert(csLog.Id != null, 'Case not created successfully');
        Case xyz =new Case();
        xyz=[Select RecordType.Name,Category__c From Case where Id= :csLog.Id];

        System.assertEquals('Business Issue',xyz.RecordType.Name);
        System.assertEquals('Logistics / Supply Chain',xyz.Category__c);

        Product2 objProduct1=TestDataFieldService.createProduct('Test Product',STRING_PRODUCT_INSTRUMENT);
        objProduct1.Regulatory_Type__c = PRODUCT_REGULATORYTYPE_IUO;
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_INSTRUMENT;
        objProduct1.Serial_Number_Profile__c = PRODUCT_SERIALNUMBER;
        insert objProduct1;
        Test.startTest();
        System.assert(objProduct1.Id != null, 'Product not created successfully');
        
        SVMXC__Service_Order__c objWorkOrder  = [Select id from SVMXC__Service_Order__c where SVMXC__Case__c=: cs.Id];
        objWorkOrder.SVMXC__Order_Type__c = Label.WorkOrderTypeServiceActivities;
        objWorkOrder.RecordTypeId =  Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(Label.WorkOrderRecordTypeServiceSupport).getRecordTypeId();
        objWorkOrder.SVMXC__Product__c = objProduct1.Id;
        update objWorkOrder;

        Case cs1 = TestDataCase.initServiceRequestCase(con);
        cs1.Sub_Type__c = Label.CaseSubTypeServiceSupport;
        cs1.Category__c = 'Microarray';
        cs1.ContactId = con.Id;
        lstCases.add(cs1);
        cs1 = TestDataCase.initServiceRequestCase(con);
        cs1.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Label.CaseRecordTypeInquiry).getRecordTypeId();
        cs1.ContactId = con.Id;
        lstCases.add(cs1);
        insert lstCases;
        Test.stopTest();

        AddAssociatedCodesController.getValidationsMap(objWorkOrder.Id);
        AddAssociatedCodesController.getValidationsMap(cs.Id);
        AddAssociatedCodesController.getValidationsMap(lstCases[0].Id);
        AddAssociatedCodesController.getValidationsMap(csLog.Id);
        String jsonActualOutput = AddAssociatedCodesController.getValidationsMap(lstCases[1].Id);

        codesValidationMap.put(Label.AssociatedCodeTypeAnalysis, true);
        codesValidationMap.put(Label.AssociatedCodeTypeResolution, true);
        codesValidationMap.put(Label.AssociatedCodeTypeVerification, true);
        codesValidationMap.put(Label.AssociatedCodeTypeSubject, true);

        System.assertEquals(jsonActualOutput, JSON.serialize(codesValidationMap), 'getValidationsMap method failed');
    }

}
