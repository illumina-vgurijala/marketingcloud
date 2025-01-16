/***************************************************************************************************************************************
* NAME         : TestServiceUtilityCollection
* DESCRIPTION  : Test class forServiceUtilityCollection
* @AUTHOR      : 
* @DATE        : 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
 * Abhishek Yadav       4th March 2024         CMCM-273 product on cases Functionality
****************************************************************************************************************************************/

@isTest(SeeAllData = false)
public with sharing class TestServiceUtilityCollection {
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
    public static final string STRING_PRODUCT_TYPE = 'Consumable';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumables';
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    static Case cs;
    static Account objAcc;
    static SVMXC__Service_Order__c workOrder;
    static SVMXC__Service_Group__c objGrp;
    static SVMXC__Service_Group_Members__c objGrpMember;
		/*Test Data*/
 public static void initializeTestData() {
        
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        
        objAcc = TestDataAccount.getAccount('TestAccount','USD');
        
        insert objAcc;
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAcc.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        
        
        objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;
        
        objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        insert objGrpMember;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAcc.id;
        workOrder.SVMXC__Group_Member__c= objGrpMember.id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
        /*Account_to_Field_Support__c objAccountTechnicianRole = new Account_to_Field_Support__c();
objAccountTechnicianRole.Account__c = objAcc.id;
objAccountTechnicianRole.User_Role__c = 'Field Service Manager';
objAccountTechnicianRole.User__c = objGrpMember.id;
insert objAccountTechnicianRole; 
*/
    }
		/*Test Data*/
    static testmethod void coverTestCoverage(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c'
        );
        insert apexSettings;
        String strLocationObjPrefix = ServiceUtilityCollection.getObjectPrefix('SVMXC__Site__c');
        system.assertEquals('a2K',strLocationObjPrefix);
        Id recId = ServiceUtilityCollection.getRecordTypeId('SVMXC__Service_Order__c', 'Field Service');
        List<SVMXC__Service_Order__c> lstWO = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(RecordTypeId = recId,SVMXC__Order_Status__c = 'Initiated',SVMXC__Order_Type__c = 'Field Service');
        lstWO.add(workOrder);
        Test.startTest();
        insert lstWO;
        Test.stopTest();
        Map<Id, SVMXC__Service_Order__c> mapWOIdToWorkOrder = ServiceUtilityCollection.getWorkOrderMap(lstWO);
        system.assertEquals(lstWO[0].id, mapWOIdToWorkOrder.get(lstWO[0].id).id);
        
        String strObj = ServiceUtilityCollection.getAPIName(lstWO[0].id);
        system.assertEquals('SVMXC__Service_Order__c', strObj);
        //Added by Shruti 
        ServiceUtilityCollection.getAPIName('8003F000005PMj6');
        ServiceUtilityCollection.fetchBusinessHoursMetadata();
        /*List<String> lstRecordTypeNames=new List<String>();
        lstRecordTypeNames.add('Field Service');        
        List<RecordType> lstRecType = ServiceUtilityCollection.getSelectedRecordTypes('SVMXC__Service_Order__c',lstRecordTypeNames);*/
        
        
    }
    
		/*Test Data*/
    static testmethod void coverTestCoverage2() {
        Feature.setMockFeatureFlag('MissingProductNotificationsToGFSL', true);
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Account',
            Bypass_Triggers_By_Object_4__c = 'Product2'
        );
        insert apexSettings;
        Set<String> setFSEROLES = new Set<String>{'Partner Primary Field Service Engineer','Partner Secondary Field Service Engineer','Primary Field Service Engineer', 'Secondary Field Service Engineer', 'Field Service Manager','Primary Field Application Scientist', 'Secondary Field Application Scientist'};        
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        system.assertNotEquals(null,acc.id);
        
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        system.assertNotEquals(null,serviceTeam.id);
        
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(UserInfo.getUserId(),'Test Technician',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        insert technician;
        system.assertNotEquals(null,technician.id);
        
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(UserInfo.getUserId(),'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c='b@b.com';
        insert technicianFAS;
        system.assertNotEquals(null,technicianFAS.id);

        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Service Engineer',technician.id);
        insert accToFieldSupport;
        system.assertNotEquals(null,accToFieldSupport.id);
        
        Account_to_Field_Support__c accToFieldSupportFSM =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Application Scientist',technicianFAS.id);
        insert accToFieldSupportFSM;
        system.assertNotEquals(null,accToFieldSupportFSM.id); 

        //insert event
        Event objEvent = new Event(subject = 'unavailable');
        objEvent.StartDateTime = System.now().addDays(-1);
        objEvent.EndDateTime = System.now().addDays(1);
        insert objEvent;
        System.assert(objEvent.Id != null);
        
        //insert product
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        System.assert(objProduct.Id != null);
        
        //insert User
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        System.assert(u.Id != null);
        
        //insert expertise (Service group product)
        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = technician.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;
        System.assert(objExpertise.id != null);
        
        //insert contact
        Contact objContact = TestDataContact.getNewContact(acc);
        System.assert(objContact != null);
        
        //insert product
        Product2 product1 = TestDataMaster.createProduct(true);
        
        //insert serviceBOM
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        System.assert(serviceBOM.Id != null);
        
        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        System.assert(objInstalledProduct.Id != null);
        
        //insert case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        System.assert(objCase.Id != null);
        //insert workorder
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        
        workOrder.SVMXC__Company__c = acc.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        workOrder.Partner_Installation_WO__c = true;
        insert workorder;
        System.assert(workOrder.Id != null);
        //map of workorder to case ids
        Map<Id,Id> mapCaseWO = new Map<Id,Id>{workorder.Id => UserInfo.getUserId()};

        //test FieldSupportFromUser method 
        ServiceUtilityCollection.FieldSupportFromUser(new Set<Id>{UserInfo.getUserId()});
        //test addBussinessDays method
        ServiceUtilityCollection.addBussinessDays(System.now(), 7);
        //test fetchAccountRoles method
        Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(new Set<String>{acc.Id}, setFSEROLES);
        System.assert(accountIdToFSERoles != null);
        
        //test checkTechniciansCalendar
        ServiceUtilityCollection.ServiceSystemUtilityCollection objSysUtility = new ServiceUtilityCollection.ServiceSystemUtilityCollection();
        Set<Id> setUnavailableTechnician = objSysUtility.checkTechniciansCalendar(accountIdToFSERoles);
        System.assert(setUnavailableTechnician != null);

        Test.startTest();
        Id recId = ServiceUtilityCollection.getRecordTypeId('SVMXC__Service_Order__c', 'Field Service');
        List<SVMXC__Service_Order__c> lstWO = new List<SVMXC__Service_Order__c>();
        workOrder = new SVMXC__Service_Order__c(SVMXC__Company__c = acc.id,RecordTypeId = recId,SVMXC__Order_Status__c = 'Initiated',SVMXC__Order_Type__c = 'Field Service');
        lstWO.add(workOrder);
        insert lstWO;
        List<SVMXC__Service_Order__c> lstWO1 = ServiceUtilityCollection.fetchNextAvailableEngineer(lstWO[0], null, null, null,null,null);
        accToFieldSupport.User_Role__c = 'Secondary Field Service Engineer';
        update accToFieldSupport;
        lstWO1 = ServiceUtilityCollection.fetchNextAvailableEngineer(lstWO[0], null, null, null,null,null);
        lstWO[0].Partner_Installation_WO__c = true;
        update lstWO;
        Map<Id,Map<String,Account_to_Field_Support__c>> mapAccFS=ServiceUtilityCollection.fetchAccountRoles(new Set<String>{acc.id},setFSEROLES);
        system.assertNotEquals(0,mapAccFS.size());
        lstWO1 = ServiceUtilityCollection.fetchNextAvailableEngineer(lstWO[0], null, null, null,null,null);
        ServiceUtilityCollection.checkTechniciansExpertise(mapAccFS);
        set<Id> setuserid = new set<Id>();
        setuserid.add(UserInfo.getUserId());
        ServiceUtilityCollection.FieldSupportFromUser(setuserid);
        ServiceUtilityCollection.ServiceSystemUtilityCollection sv = new ServiceUtilityCollection.ServiceSystemUtilityCollection();
         setuserid = sv.checkTechniciansCalendar(mapAccFS);
        String timeZoneId = 'America/Los_Angeles';
         ServiceUtilityCollection.setAutoRejectionDates(lstWO[0],ServiceUtilityCollection.fetchBusinessHoursMetadata(), timeZoneId);
         

        //test checkTechniciansExpertise 
        Map<Id,Set<Id>> technicianToExertise = ServiceUtilityCollection.checkTechniciansExpertise(accountIdToFSERoles);
        System.assert(technicianToExertise != null);
        
        //test fetchBusinessHoursMetadata
        List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata = ServiceUtilityCollection.fetchBusinessHoursMetadata();
        System.assertNotEquals(null, accountIdToFSERoles);
        set<string> productExtIds= new set<string>();
        productExtIds.add('20006797X370693,15032930,20015886,15023353,15009571,20031595,20037376,20040234,20039246,20042337,20034630,20006797X371625,20014309,15069618X365016,20045494,20039147');
        ServiceUtilityCollection.sendEmailToGFSLAndStoreProdExtId(productExtIds);
        Integer totalMin=ServiceUtilityCollection.convertHoursToMinutes('1:00');
        System.assertEquals(60,totalMin,'Total minuts');
        String totalHour=ServiceUtilityCollection.convertMinutesToHours(60);
        System.assertEquals('1',totalHour,'Total hours');
        //test fetchNextAvailableEngineer
        if(accountIdToFSERoles.containsKey(workOrder.SVMXC__Company__c)){
            ServiceUtilityCollection.fetchNextAvailableEngineer(workOrder,accountIdToFSERoles.get(workOrder.SVMXC__Company__c),new Set<Id>{u.Id},mapCaseWO,technicianToExertise,lstBusinessHoursMetadata);
        }
        Test.stopTest();
    }
    
		/*Test Data*/
    static testmethod void coverTestCoverage3(){
        
        EmailTemplate eTemplate = new EmailTemplate (DeveloperName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', Subject = 'Test email'); 
        insert eTemplate;
        
        Id idEmailTemplate = ServiceUtilityCollection.getEmailTemplate(eTemplate.DeveloperName);
        system.assertEquals(eTemplate.id, idEmailTemplate);
        ServiceUtilityCollection.getEmailTemplate('Test2');
        ServiceUtilityCollection.fetchBusinessHoursMetadata();
        
        ServiceUtilityCollection.addBussinessDays(System.now() , 2);
    }
		/*Test Data*/
    
    static testmethod void coverTestCoverage4(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Account',
            Bypass_Triggers_By_Object_4__c = 'Product2'
        );
        insert apexSettings;
        test.startTest();
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount .Account_Group__c='Distributor';
        insert objAccount ;
        //Account objAccount = TestDataAccount.getAccount('Test');
        //insert objAccount;
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        SVMXC__Installed_Product__c ip1 = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip1;
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Parts Only';
        sp.Item_Number__c = '1111';
        insert sp;
        Product2 prod = new Product2(Name='TestProd',
                                     //Auto_Create_Install_Work_Order__c=true,
                                     Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case',
                                     Service_Product_Type__c='Instrument',
                                     Regulatory_Type__c='DX',
                                     IsActive=true,
                                     ProductCode='43535',
                                     Material_Number__c = '1111',
                                     Service_Level__c = 'GOLD'
                                    );        
        insert prod;
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
	    objServiceContract.Consumables_Included__c = true;
        objServiceContract.Parts_Included__c = true;
        objServiceContract.Labor_Included__c =true;
        insert objServiceContract;
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert cp;
        cp.SVMXC__Installed_Product__c = ip1.Id;
        update cp;
        set<SVMXC__Installed_Product__c > setInstalledProductIds = new set<SVMXC__Installed_Product__c >();
        setInstalledProductIds .add(ip1);
        Id recId = ServiceUtilityCollection.getRecordTypeId('SVMXC__Service_Order__c', 'Field Service');
        List<SVMXC__Service_Order__c> lstWO = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(SVMXC__Company__c = objAccount.id,RecordTypeId = recId,SVMXC__Order_Status__c = 'Initiated',SVMXC__Order_Type__c = 'Field Service');
        lstWO.add(workOrder);
        insert lstWO;
		
		
		Applied_Contract__c appContObj = new Applied_Contract__c();
        appContObj.Service_Contract__c = objServiceContract.Id;
        appContObj.Work_Order__c = workOrder.id;
        insert appContObj;

       
        Group gp = new Group ();
        gp.name='grpName';
        gp.Type = 'Queue';
        gp.DeveloperName = 'TestName';
        insert gp;
        Set<String> setQueueDeveloperNames = new Set<String>();
        setQueueDeveloperNames.add('TestName');
        ServiceUtilityCollection.getQueueFromName(setQueueDeveloperNames);
        
        List<Applied_Contract__c> lstEntitlement = new List<Applied_Contract__c>();
        List<String> lstFieldAPINames = new List<String>();
        lstFieldAPINames.add('SVMXC__Component__c');
		lstEntitlement.add(appContObj);
		system.assert(!lstEntitlement.isEmpty(), 'lstEntitlement is empty');
       // lstEntitlement = ServiceUtilityCollection.insertEntitlement(lstWO, setInstalledProductIds, null,lstFieldAPINames );
	   ServiceUtilityCollection.classifyEntitlementsByLineTypesIncluded(lstEntitlement);
        test.stopTest();
    
    }
		/*Test Data*/
    static testMethod void validateToolProductFromFRUListForNonIVD(){
        initializeTestData();
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Product2'
        );
        insert apexSettings;
        Product2 workOrderProduct = TestDataMaster.initProduct('Test');
        workOrderProduct.Source_System__c = 'SAP';
        insert workOrderProduct;

        Product2 toolProduct = TestDataMaster.initProduct('Test Product','Tools');
		//updated to Standard Tool since service product type values got updated (This functionality is no more dependent on Service product Type)
        toolProduct.GFSL_FC_Hierarchy__c = 'Standard Tool';
        toolProduct.Service_Product_Type__c = 'Standard Tool';
        toolProduct.Source_System__c = 'SAP';
        insert toolProduct;
        
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(workOrderProduct.Id);
        
        TestDataFieldService.createToolFRU(serviceBOM.Id, toolProduct.Id);

        SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(workOrderProduct.Id);
        workOrderIP.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert workOrderIP;

        
        workOrder.SVMXC__Component__c=workOrderIP.Id;
        workOrder.SVMXC__Product__c = workOrderProduct.Id;
        workOrder.Warning_Message__c = 'Warning for part Test on the Work Order.\r\nWarning for part Test on the Work Order.';
        update workOrder;
        SVMXC__Service_Order_Line__c objWorkDetail= TestDataFieldService.createToolTypeWorkDetail(workOrder.Id,toolProduct.Id);
        
        Test.startTest();
        
        insert objWorkDetail;
        List<SVMXC__Service_Order_Line__c> workDetailInserted = [Select Id from SVMXC__Service_Order_Line__c where Id = : objWorkDetail.Id];
        System.assertEquals(true,!workDetailInserted.isEmpty());

        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        insert toolProduct2;

        objWorkDetail.SVMXC__Product__c = toolProduct2.Id;
        update objWorkDetail;         

        workDetailInserted = [Select Id, Warning_Message__c from SVMXC__Service_Order_Line__c where Id = : objWorkDetail.Id];
        System.assertEquals(workDetailInserted[0].Warning_Message__c, System.label.FRU_List_Trigger_Error_Message_Non_IVD);

        delete objWorkDetail;
        Test.stopTest();
    }
		/*Test Data*/
     static testmethod void testAutoDispatchPFSE() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Account',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Group__c',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Group_Members__c'
        );
        insert apexSettings;
        initializeTestData();
         User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
             
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        List<Account_to_Field_Support__c> lstAccountRoles = new List<Account_to_Field_Support__c>();
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Service Engineer'
        );
        lstAccountRoles.add(accTechRole1);
        Account_to_Field_Support__c accTechRole2 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Secondary Field Service Engineer'
        );
        lstAccountRoles.add(accTechRole2);
        Account_to_Field_Support__c accTechRole3 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Field Service Manager'
        );
        lstAccountRoles.add(accTechRole3);
        insert lstAccountRoles;

        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = grpMembers.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        system.assert(workOrder.id!=null, 'workOrder id is null');
        workOrder.Is_Auto_Dispatch__c = true;
        update workOrder;
    }
		/*Test Data*/

    static testmethod void testAutoDispatchSFSE(){
        initializeTestData();
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'User',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Product2',
            Bypass_Triggers_By_Object_4__c = 'Account'
        );
        insert apexSettings;
         User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
             
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        Test.startTest();
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        List<Account_to_Field_Support__c> lstAccountRoles = new List<Account_to_Field_Support__c>();
        Account_to_Field_Support__c accTechRole2 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Secondary Field Service Engineer'
        );
        lstAccountRoles.add(accTechRole2);
        Account_to_Field_Support__c accTechRole3 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Field Service Manager'
        );
        lstAccountRoles.add(accTechRole3);
        insert lstAccountRoles;

        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = grpMembers.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        system.assert(workOrder.id!=null, 'workOrder id is null');
        workOrder.Is_Auto_Dispatch__c = true;
        
        update workOrder;
        workOrder.Is_Auto_Dispatch__c = false;
        
        update workOrder;
        workOrder.Is_Auto_Dispatch__c = true;
        workOrder.Partner_Installation_WO__c = true;
        update workOrder;
        Test.stopTest();

    }

     	/*Test Data*/
    static testmethod void testAutoDispatchFSM() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'User',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Product2'
        );
        insert apexSettings;
        initializeTestData();
         User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
             
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        List<Account_to_Field_Support__c> lstAccountRoles = new List<Account_to_Field_Support__c>();
        Account_to_Field_Support__c accTechRole3 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Field Service Manager'
        );
        lstAccountRoles.add(accTechRole3);
        insert lstAccountRoles;

        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = grpMembers.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        system.assert(workOrder.id!=null, 'workOrder id is null');
        workOrder.Is_Auto_Dispatch__c = true;
        update workOrder;

    }

    /**
    *  @author prashanth
    *  @description - test the ServiceUtilityCollection
    **/
    static testmethod void serviceUtilityCollectionTest(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_4__c = 'Account',
            Bypass_Triggers_By_Object_5__c = 'SVMXC__Service_Order_Line__c'
        );
        insert apexSettings;
        initializeTestData();
        //insert account
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
                objAccount.Account_Group__c='Distributor';
                insert objAccount;       
        System.assert(objAccount.Id != null);
        
        //insert product
        Product2 product1 = TestDataMaster.initProduct('Test Product','Tools');
        product1.GFSL_FC_Hierarchy__c = 'Tools';
        product1.Service_Product_Type__c = 'Spare';
        product1.Source_System__c = 'SAP';
        insert product1;
        System.assert(product1.Id != null);
        
        //insert serviceBOM
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        serviceBOM.Default__c = true;
        update serviceBOM;
        System.assert(serviceBOM.Id != null);
        
        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        System.assert(objInstalledProduct.Id != null);
        
        //insert contact
        Contact objContact = TestDataContact.getNewContact(objAccount);
        System.assert(objContact.Id != null);
        Test.startTest();
        //insert case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        objCase.SVMXC__Product__c = product1.Id;
        insert objCase;
        System.assert(objCase.Id != null);
        //insert objLocation
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location', 'Test Street', 'Ireland', '123456', 'USD');
            insert objLocation;
        System.assert(objLocation.Id != null);
        //insert workOrder
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.SVMXC__Site__c = objLocation.Id;
        workOrder.Is_Auto_Created__c=true;
        workorder.SVMXC__Product__c = product1.Id;
        insert workorder;
        System.assert(workOrder.Id != null);
        
        //insert objOrderDetail
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Product__c = product1.Id;
        insert objOrderDetail;
        System.assert(objOrderDetail.Id != null);
        
        //insert objServiceContract
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        insert objServiceContract;
        system.assert(objServiceContract.Id != null);
        //Test.startTest();
        //insert objCoveredProduct
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        system.assert(objCoveredProduct.Id != null);
        Test.stopTest();
        //insert coveredLocation
        SVMXC__Service_Contract_Sites__c coveredLocation = new SVMXC__Service_Contract_Sites__c(
            SVMXC__Site__c = objLocation.Id,SVMXC__Service_Contract__c = objServiceContract.Id
        );
        insert coveredLocation;
        system.assert(objCoveredProduct.Id != null);
        
        //creating FRU List
        FRU_List__c objFRUList = TestDataFieldService.createToolFRU(serviceBOM.Id,product1.Id);
        system.assert(objFRUList.Id != null);
        
       
        //set of products
        Set<Id> setProductsIdsSelected = new Set<Id>{objOrderDetail.SVMXC__Product__c};
        Map < Id, SVMXC__Service_Order__c > idToWorkOrderMap = new Map < Id, SVMXC__Service_Order__c > ();
        idToWorkOrderMap.put(workOrder.id,workOrder);
        //test checkCompatibleProductsInFRUList
        ServiceUtilityCollection.checkCompatibleProductsInFRUList(new List<SVMXC__Service_Order_Line__c>{objOrderDetail}, idToWorkOrderMap, null, 'SVMXC__Service_Order__c', setProductsIdsSelected, new set<String>{'Tool'});
        //test insertEntitlement
        ServiceUtilityCollection.insertEntitlement(new List<sObject> {workOrder}, new Set<Id>{objInstalledProduct.Id}, new Set<Id>{objLocation.Id}, new List<String>{'SVMXC__Component__c','SVMXC__Site__c'});
        //test updateLatestExpiringContractOnIP
        ServiceUtilityCollection.updateLatestExpiringContractOnIP(new Set<Id>{objInstalledProduct.Id});
        ServiceUtilityCollection.pMPlanCreation(new List<SVMXC__Service_Contract__c>{objServiceContract} , new Set<Id>{objCoveredProduct.Id});
    }
    
    /**
    *  @author prashanth
    *  @description - test ServiceUtilityCollection Class.
    **/
    static testmethod void updateCurrentActiveContractOnIPTest(){
        //insert account
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
                objAccount.Account_Group__c='Distributor';
                insert objAccount;
        System.assert(objAccount.Id != null);
        
        //insert product
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Service_Level__c = 'BASIC';
        insert product1;
        Product2 product = [Select Id,Material_Number__c from Product2 where Id =:product1.Id];
        System.assert(product.Material_Number__c != null);
        
        //insert serviceBOM
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        System.assert(serviceBOM.Id != null);
        
        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        System.assert(objInstalledProduct.Id != null);

        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct('Test IP2 VM', 'USD', 'New');
        objInstalledProduct1.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct1.Service_Bill_Of_Materials__c = serviceBOM.Id;
        objInstalledProduct1.Currently_Active_Service_Contract__c = null;
        insert objInstalledProduct1;
        System.assert(objInstalledProduct1.Id != null);
        
        //insert SVMXC__Service_Plan__c
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = product.Material_Number__c;
        insert sp;
        System.assert(sp.Id != null);
        
        //insert SVMXC__Service_Contract__c
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
        objServiceContract.ERP_Contract_Type__c = 'Software (ZWS)';
        objServiceContract.SVMXC__Company__c = objAccount.Id;
        insert objServiceContract;
        system.assert(objServiceContract.Id != null);
        
        //insert covered product
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        system.assert(objCoveredProduct.Id != null);

        Map<Id,Case> caseIdBYCaseDetails = new Map<Id,Case>();
        
        Contact objContact = TestDataContact.getNewContact(objAccount);
        Set<Id> subIds = new Set<Id>();
        subIds.add(ObjServiceContract.Id);
        Case objCase1 = TestDataCase.initServiceRequestCase(objContact);
        objCase1.Subscription__c = ObjServiceContract.Id;
        insert objCase1;
        caseIdBYCaseDetails.put(objCase1.Id,objCase1);

		objCase1.SVMXC__Component__c = objInstalledProduct1.Id;
        update objCase1;
        
        Test.startTest();
        //test updateCurrentActiveContractOnIP
        ServiceUtilityCollection.insertEntitlementForSubscription(subIds,caseIdBYCaseDetails );
        ServiceUtilityCollection.updateCurrentActiveContractOnIP(new Set<Id>{objInstalledProduct.Id});
        Test.stopTest();
    }
    /**
    *  @author prashanth
    *  @description - test ServiceUtilityCollection Class.
    **/
    static testmethod void fetchNextAvailableEngineerTest() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
        Bypass_Triggers_By_Object_1__c = 'Account',
        Bypass_Triggers_By_Object_2__c = 'SVMXC__Installed_Product__c',
        Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Group_Members__c',
        Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Order__c',
        Bypass_Triggers_By_Object_5__c = 'Contact'
        );
        insert apexSettings;
        Set<String> setFSEROLES = new Set<String>{'Partner Primary Field Service Engineer','Partner Secondary Field Service Engineer','Primary Field Service Engineer', 'Secondary Field Service Engineer', 'Field Service Manager','Primary Field Application Scientist', 'Secondary Field Application Scientist'};
        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        system.assertNotEquals(null,acc.id);
        
        //insert contact
        Contact objContact = TestDataContact.getNewContact(acc);
        system.assertNotEquals(null,objContact.id);
        
        //insert product
        Product2 product1 = TestDataMaster.createProduct(true);
        system.assertNotEquals(null,product1.id);
        
        //insert serviceBOM
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        system.assertNotEquals(null,serviceBOM.id);
        
        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,serviceBOM.id);
        
        //insert case
        Case objCase1 = TestDataCase.initServiceRequestCase(objContact);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase1;
        system.assertNotEquals(null,serviceBOM.id);
        
        //insert workOrder1
        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder('Field Service', objCase1.Id, 'Initiated');
        workOrder1.SVMXC__Company__c = acc.id;
        workOrder1.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder1.SVMXC__Order_Type__c='Installation';
        workOrder1.Is_Auto_Created__c=true;
        workOrder1.Partner_Installation_WO__c = true;
        workOrder1.Field_Support_User_Role__c = 'Partner Primary Field Service Engineer';
        insert workOrder1;
        system.assertNotEquals(null,workOrder1.id);
        
        //insert user
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        system.assertNotEquals(null,u.id);
        
        Map<Id,Id> mapCaseWO = new Map<Id,Id>{workorder1.Id => UserInfo.getUserId()};
        //insert serviceTeam
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        system.assertNotEquals(null,serviceTeam.id);
        
        //insert technician
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(UserInfo.getUserId(),'Test Technician',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        insert technician;
        system.assertNotEquals(null,technician.id);
        
        //insert Account_to_Field_Support__c
        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Partner Secondary Field Service Engineer',technician.id);
        insert accToFieldSupport;
        system.assertNotEquals(null,accToFieldSupport.id);
        
        Test.startTest();
        //test fetchAccountRoles
        Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(new Set<String>{acc.Id}, setFSEROLES);
        System.assert(accountIdToFSERoles != null);
        //test checkTechniciansExpertise
        Map<Id,Set<Id>> technicianToExertise = ServiceUtilityCollection.checkTechniciansExpertise(accountIdToFSERoles);
        System.assert(technicianToExertise != null);
        //test fetchBusinessHoursMetadata
        List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata = ServiceUtilityCollection.fetchBusinessHoursMetadata();
        System.assert(lstBusinessHoursMetadata != null);
        //test fetchNextAvailableEngineer
        if(accountIdToFSERoles.containsKey(workOrder1.SVMXC__Company__c)){
            ServiceUtilityCollection.fetchNextAvailableEngineer(workOrder1,accountIdToFSERoles.get(workOrder1.SVMXC__Company__c),new Set<Id>{u.Id},mapCaseWO,technicianToExertise,lstBusinessHoursMetadata);
        }
        Test.stopTest();
    }
    /**
    *  @author prashanth
    *  @description - test ServiceUtilityCollection Class.
    **/
    static testmethod void fetchNextAvailableEngineerTest1() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
        Bypass_Triggers_By_Object_1__c = 'Account',
        Bypass_Triggers_By_Object_2__c = 'SVMXC__Installed_Product__c',
        Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Group_Members__c',
        Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Order__c',
        Bypass_Triggers_By_Object_5__c = 'Contact'
        );
        insert apexSettings;
        Set<String> setFSEROLES = new Set<String>{'Partner Secondary Field Service Engineer','Primary Field Service Engineer', 'Secondary Field Service Engineer', 'Field Service Manager','Primary Field Application Scientist', 'Secondary Field Application Scientist'};
        //insert acc
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        system.assertNotEquals(null,acc.id);
        
        //insert contact
        Contact objContact = TestDataContact.getNewContact(acc);
        system.assertNotEquals(null,objContact.id);
        
        //insert product1
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Source_System__c = 'SAP';
        insert product1;
        system.assertNotEquals(null,product1.id);
        
        //insert serviceBOM
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        system.assertNotEquals(null,serviceBOM.id);
        
        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        //insert case
        Case objCase1 = TestDataCase.initServiceRequestCase(objContact);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase1;
        system.assertNotEquals(null,objCase1.id);
        
        //insert workOrder
        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder('Field Service', objCase1.Id, 'Initiated');
        workOrder1.SVMXC__Company__c = acc.id;
        workOrder1.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder1.SVMXC__Order_Type__c='Installation';
        workOrder1.Is_Auto_Created__c=true;
        workOrder1.Field_Support_User_Role__c = 'Primary Field Service Engineer';
        workOrder1.SVMXC__Product__c = product1.Id;
        insert workOrder1;
        system.assertNotEquals(null,workOrder1.id);
        
        //insert user
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        system.assertNotEquals(null,u.id);
        
        Map<Id,Id> mapCaseWO = new Map<Id,Id>{workorder1.Id => UserInfo.getUserId()};
        //insert serviceTeam
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        system.assertNotEquals(null,serviceTeam.id);
        
        //insert technician
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(UserInfo.getUserId(),'Test Technician',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        insert technician;
        system.assertNotEquals(null,technician.id);
        
        //insert accToFieldSupport
        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Secondary Field Service Engineer',technician.id);
        insert accToFieldSupport;
        system.assertNotEquals(null,accToFieldSupport.id);
        
        //insert objExpertise
        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = product1.Id,
                                                                                        SVMXC__Group_Member__c = technician.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;
        
        Test.startTest();
        //test fetchAccountRoles
        Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(new Set<String>{acc.Id}, setFSEROLES);
        System.assert(accountIdToFSERoles != null);
        //test checkTechniciansExpertise
        Map<Id,Set<Id>> technicianToExertise = ServiceUtilityCollection.checkTechniciansExpertise(accountIdToFSERoles);
        System.assert(technicianToExertise != null);
        //test fetchBusinessHoursMetadata
        List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata = ServiceUtilityCollection.fetchBusinessHoursMetadata();
        System.assert(lstBusinessHoursMetadata != null);
        //test fetchNextAvailableEngineer
        if(accountIdToFSERoles.containsKey(workOrder1.SVMXC__Company__c)){
            ServiceUtilityCollection.fetchNextAvailableEngineer(workOrder1,accountIdToFSERoles.get(workOrder1.SVMXC__Company__c),new Set<Id>{u.Id},mapCaseWO,technicianToExertise,lstBusinessHoursMetadata);
        }
        Test.stopTest();
    }
    /**
    *  @author prashanth
    *  @description - test ServiceUtilityCollection Class.
    **/
    static testmethod void fetchNextAvailableEngineerTest2() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
        Bypass_Triggers_By_Object_1__c = 'Account',
        Bypass_Triggers_By_Object_2__c = 'SVMXC__Installed_Product__c',
        Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Group_Members__c',
        Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Order__c',
        Bypass_Triggers_By_Object_5__c = 'Contact'
        );
        insert apexSettings;
        Set<String> setFSEROLES = new Set<String>{'Partner Secondary Field Service Engineer','Primary Field Service Engineer', 'Secondary Field Service Engineer', 'Field Service Manager','Primary Field Application Scientist', 'Secondary Field Application Scientist'};
        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        system.assertNotEquals(null,acc.id);
        
        //insert contact
        Contact objContact = TestDataContact.getNewContact(acc);
        system.assertNotEquals(null,objContact.id);
        
        //insert product
        Product2 product1 = TestDataMaster.createProduct(true);
        system.assertNotEquals(null,product1.id);
        
        //insert serviceBOM
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        system.assertNotEquals(null,serviceBOM.id);
        
        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        //insert case
        Case objCase1 = TestDataCase.initServiceRequestCase(objContact);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase1;
        system.assertNotEquals(null,objCase1.id);
        
        //insert workorder
        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder('Field Service', objCase1.Id, 'Initiated');
        workOrder1.SVMXC__Company__c = acc.id;
        workOrder1.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder1.SVMXC__Order_Type__c='Installation';
        workOrder1.Is_Auto_Created__c=true;
        workOrder1.Field_Support_User_Role__c = 'Secondary Field Service Engineer';
        insert workOrder1;
        system.assertNotEquals(null,workOrder1.id);
        
        //insert user
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        system.assertNotEquals(null,workOrder1.id);
        
        Map<Id,Id> mapCaseWO = new Map<Id,Id>{workorder1.Id => UserInfo.getUserId()};
        
        //insert serviceTeam
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        system.assertNotEquals(null,serviceTeam.id);
        
        //insert technician
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(UserInfo.getUserId(),'Test Technician',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        insert technician;
        system.assertNotEquals(null,technician.id);
        
        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Field Service Manager',technician.id);
        insert accToFieldSupport;
        system.assertNotEquals(null,accToFieldSupport.id);
        
        Test.startTest();
        //test fetchAccountRoles
        Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(new Set<String>{acc.Id}, setFSEROLES);
        System.assert(accountIdToFSERoles != null);
        //test checkTechniciansExpertise
        Map<Id,Set<Id>> technicianToExertise = ServiceUtilityCollection.checkTechniciansExpertise(accountIdToFSERoles);
        System.assert(technicianToExertise != null);
        //test fetchBusinessHoursMetadata
        List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata = ServiceUtilityCollection.fetchBusinessHoursMetadata();
        System.assert(lstBusinessHoursMetadata != null);
        //test fetchNextAvailableEngineer
        if(accountIdToFSERoles.containsKey(workOrder1.SVMXC__Company__c)){
            ServiceUtilityCollection.fetchNextAvailableEngineer(workOrder1,accountIdToFSERoles.get(workOrder1.SVMXC__Company__c),new Set<Id>{u.Id},mapCaseWO,technicianToExertise,lstBusinessHoursMetadata);
        }
        Test.stopTest();
    }
    /**
    *  @author prashanth
    *  @description - test ServiceUtilityCollection Class.
    **/
    static testmethod void fetchNextAvailableEngineerTest3() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
        Bypass_Triggers_By_Object_1__c = 'Account',
        Bypass_Triggers_By_Object_2__c = 'SVMXC__Installed_Product__c',
        Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Group_Members__c',
        Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Order__c',
        Bypass_Triggers_By_Object_5__c = 'Contact'
        );
        insert apexSettings;
        Set<String> setFSEROLES = new Set<String>{'Partner Secondary Field Service Engineer','Primary Field Service Engineer', 'Secondary Field Service Engineer', 'Field Service Manager','Primary Field Application Scientist', 'Secondary Field Application Scientist'};
        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        system.assertNotEquals(null,acc.id);
        
        //insert contact
        Contact objContact = TestDataContact.getNewContact(acc);
        system.assertNotEquals(null,objContact.id);
        
        //insert product
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Source_System__c = 'SAP';
        insert product1;
        system.assertNotEquals(null,product1.id);
        
        //insert serviceBOM
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        system.assertNotEquals(null,serviceBOM.id);
        
        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        //insert case
        Case objCase1 = TestDataCase.initServiceRequestCase(objContact);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase1;
        system.assertNotEquals(null,objCase1.id);
        
        //insert workorder
        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder('Field Service', objCase1.Id, 'Initiated');
        workOrder1.SVMXC__Company__c = acc.id;
        workOrder1.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder1.SVMXC__Order_Type__c='Installation';
        workOrder1.Is_Auto_Created__c=true;
        workOrder1.SVMXC__Product__c = product1.Id;
        insert workOrder1;
        system.assertNotEquals(null,workOrder1.id);
        
        //insert user
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        system.assertNotEquals(null,u.id);
        
        Map<Id,Id> mapCaseWO = new Map<Id,Id>{workorder1.Id => UserInfo.getUserId()};
        
        //insert serviceTeam
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        system.assertNotEquals(null,serviceTeam.id);
        
        //insert technician
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(UserInfo.getUserId(),'Test Technician',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        insert technician;
        system.assertNotEquals(null,technician.id);
        
        //insert accToFieldSupport
        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Service Engineer',technician.id);
        insert accToFieldSupport;
        system.assertNotEquals(null,accToFieldSupport.id);
        
        //insert objExpertise
        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = product1.Id,
                                                                                        SVMXC__Group_Member__c = technician.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;
        
        Test.startTest();
        //test fetchAccountRoles
        Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(new Set<String>{acc.Id}, setFSEROLES);
        System.assert(accountIdToFSERoles != null);
        //test checkTechniciansExpertise
        Map<Id,Set<Id>> technicianToExertise = ServiceUtilityCollection.checkTechniciansExpertise(accountIdToFSERoles);
        System.assert(technicianToExertise != null);
        //test fetchBusinessHoursMetadata
        List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata = ServiceUtilityCollection.fetchBusinessHoursMetadata();
        System.assert(lstBusinessHoursMetadata != null);
        //test fetchNextAvailableEngineer
        if(accountIdToFSERoles.containsKey(workOrder1.SVMXC__Company__c)){
            ServiceUtilityCollection.fetchNextAvailableEngineer(workOrder1,accountIdToFSERoles.get(workOrder1.SVMXC__Company__c),new Set<Id>{u.Id},mapCaseWO,technicianToExertise,lstBusinessHoursMetadata);
        }
        Test.stopTest();
    }
    /**
    *  @author prashanth
    *  @description - test ServiceUtilityCollection Class.
    **/
    static testmethod void fetchNextAvailableEngineerTest4() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
        Bypass_Triggers_By_Object_1__c = 'Account',
        Bypass_Triggers_By_Object_2__c = 'SVMXC__Installed_Product__c',
        Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Group_Members__c',
        Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Order__c',
        Bypass_Triggers_By_Object_5__c = 'Contact'
        );
        insert apexSettings;
        Set<String> setFSEROLES = new Set<String>{'Partner Secondary Field Service Engineer','Primary Field Service Engineer', 'Secondary Field Service Engineer', 'Field Service Manager','Primary Field Application Scientist', 'Secondary Field Application Scientist'};
        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        system.assertNotEquals(null,acc.id);
        
        //insert contact
        Contact objContact = TestDataContact.getNewContact(acc);
        system.assertNotEquals(null,objContact.id);
        
        //insert product
        Product2 product1 = TestDataMaster.createProduct(true);
        system.assertNotEquals(null,objContact.id);
        
        //insert serviceBOM
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        system.assertNotEquals(null,objContact.id);
        
        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        //insert case
        Case objCase1 = TestDataCase.initServiceRequestCase(objContact);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase1;
        system.assertNotEquals(null,objCase1.id);
        
        //insert workOrder1
        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder('Field Service', objCase1.Id, 'Initiated');
        workOrder1.SVMXC__Company__c = acc.id;
        workOrder1.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder1.SVMXC__Order_Type__c='Installation';
        workOrder1.Is_Auto_Created__c=true;
		DateTime myDateTime = DateTime.newInstance(2020, 4, 10, 10, 3, 3);
		workOrder1.Date_Time_Assigned__c = myDateTime;
        workOrder1.Field_Support_User_Role__c = 'Field Service Manager';
        workOrder1.Original_Owner__c = UserInfo.getUserId();
        insert workOrder1;
        system.assertNotEquals(null,workOrder1.id);
        
        //insert user
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        system.assertNotEquals(null,u.id);
        
        Map<Id,Id> mapCaseWO = new Map<Id,Id>{workorder1.Id => UserInfo.getUserId()};
        //insert serviceTeam
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        system.assertNotEquals(null,serviceTeam.id);
        
        //insert technician
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(UserInfo.getUserId(),'Test Technician',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        insert technician;
        system.assertNotEquals(null,technician.id);
        
        //insert accToFieldSupport
        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Field Service Manager',technician.id);
        insert accToFieldSupport;
        system.assertNotEquals(null,accToFieldSupport.id);
        
        Test.startTest();
        //test fetchAccountRoles
        Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(new Set<String>{acc.Id}, setFSEROLES);
        System.assert(accountIdToFSERoles != null);
        //test checkTechniciansExpertise
        Map<Id,Set<Id>> technicianToExertise = ServiceUtilityCollection.checkTechniciansExpertise(accountIdToFSERoles);
        System.assert(technicianToExertise != null);
        //test fetchBusinessHoursMetadata
        List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata = ServiceUtilityCollection.fetchBusinessHoursMetadata();
        System.assert(lstBusinessHoursMetadata != null);
        //test fetchNextAvailableEngineer
        if(accountIdToFSERoles.containsKey(workOrder1.SVMXC__Company__c)){
            ServiceUtilityCollection.fetchNextAvailableEngineer(workOrder1,accountIdToFSERoles.get(workOrder1.SVMXC__Company__c),new Set<Id>{u.Id},mapCaseWO,technicianToExertise,lstBusinessHoursMetadata);
            ServiceUtilityCollection.fetchNextAvailableEngineer(workOrder1,accountIdToFSERoles.get(workOrder1.SVMXC__Company__c),new Set<Id>{u.Id},null,technicianToExertise,lstBusinessHoursMetadata);
			workOrder1.Field_Support_User_Role__c = null;
			accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Partner Primary Field Service Engineer',technician.id);
			 upsert accToFieldSupport;
			 accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(new Set<String>{acc.Id}, setFSEROLES);
			 ServiceUtilityCollection.ServiceSystemUtilityCollection objSysUtility = new ServiceUtilityCollection.ServiceSystemUtilityCollection();
			 Set<Id> setUnavailableTechnician = objSysUtility.checkTechniciansCalendar(accountIdToFSERoles);
			 System.assert(setUnavailableTechnician != null);
			 ServiceUtilityCollection.fetchNextAvailableEngineer(workOrder1,accountIdToFSERoles.get(workOrder1.SVMXC__Company__c),new Set<Id>{u.Id},null,technicianToExertise,lstBusinessHoursMetadata);
			 DateTime myDateTimeEndDate = DateTime.newInstance(2020, 4, 11, 10, 3, 3);
             ServiceUtilityCollection.checkNextAvailableSLATime(workOrder1,workOrder1.Date_Time_Assigned__c,myDateTimeEndDate,4,'Rejection_DateTime_for_SLA_Next_Day__c','America/Los_Angeles');
        }
        Test.stopTest();
    }

     /**
    *  @author Digvijay
    *  @description - test ServiceUtilityCollection Class.
    **/
    static testmethod void testmethod1(){
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        Attachment objAttachment = TestDataFieldService.createAttachment(cs.id,'Letter_of_Acceptance_001');
        objAttachment.ownerId=userinfo.getUserId();
        insert objAttachment;
      Test.startTest();
        ServiceUtilityCollection.createFilesFromAttachment(objAttachment);

        ContentVersion objcv=[Select id from ContentVersion where Title=:objAttachment.Name];
        System.assert(objcv.id!=null);
     Test.stopTest();

    }


    @isTest
		/*Test Data*/
    public static void testStockedSerialSelectorMethod()
    {
        Product2 objProduct = TestDataMaster.initProduct('1241527');
        objProduct.Service_Product_Type__c = 'Core';
        insert objProduct;
        
        SVMXC__Product_Stock__c objProductStock = new SVMXC__Product_Stock__c();
        objProductStock.SVMXC__Product__c = objProduct.Id;
        objProductStock.SVMXC__Quantity2__c=2; 
        insert objProductStock;
        
        SVMXC__Product_Serial__c objStockedSerial = new SVMXC__Product_Serial__c();
        objStockedSerial.SVMXC__Product__c = objProduct.Id;
        objStockedSerial.SVMXC__Product_Stock__c = objProductStock.Id;
        insert objStockedSerial;
        SVMXC__Stock_History__c objstkhis=ServiceUtilityCollection.createTransationHistoryRecord('Increase',objProductStock,objStockedSerial,'Available','Shipment',12.3);
        System.assert(objstkhis!=null);

        List<String> lstdummy = new List<String>();
        lstdummy.add('String 1');
        lstdummy.add('String 2');
        lstdummy.add('String 3');
        lstdummy.add('String 4');
       
        List<List<String>> result = new List<List<String>>();
        //call splitlist method to split the list into smaller chunks of size 50.
        ServiceUtilityCollection.splitList(lstdummy, 2, result);
    }
	
    static testmethod void updateTimeInState() {
       
        Case objCase = TestDataCase.initNewCase('Business Issue', 'Initiated', 'Phone - CS');
		objCase.Date_of_Issue_Awareness__c = Date.Today();        
        try{
                 
            insert objCase;            
            objCase.Description= 'For Test class';
            objCase.ownerId = (TestDataUser.findUserInProfile('Customer Service')).Id;
            Cases.runTimeInStateCreationOnInsert = true;
            Cases.runTimeInStateUpdateStatusOnce = true;
            update objCase;
            Set<Id> setObjIds = new Set<Id>();
            setObjIds.add(objCase.id);
            Time_In_State__c objTimeInState = new Time_In_State__c(
                        Case__c = objCase.Id,
                        Field__c = 'Case Status',
            			Start_Date_Time__c = System.Now(),
                        Value__c = objCase.Status );                 
            insert objTimeInState;
          Time_In_State__c objTimeInState1 = new Time_In_State__c(
                        Case__c = objCase.Id,
                        Field__c = 'Case Owner',
            			Start_Date_Time__c = System.Now(),
                        Value__c = objCase.Status );                 
            insert objTimeInState1;            
         }
        Catch(Exception ex){
            System.debug('The following exception has occurred: ' + ex.getMessage());
        }
	}
    /**
    *  @author Abhishek
    *  @description - CMCM-269.
    **/
    static testmethod void testInsertConsumableWarrantyContract() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Product2'
        );
        insert apexSettings;
        initializeTestData();
        Product2 objProduct = new Product2(Name = STRING_PRODUCT_NAME, Service_Product_Type__c = STRING_PRODUCT_TYPE, Material_Class__c = STRING_PRODUCT_MATERIAL_CLASS, Source_System__c ='SAP');
		insert objProduct;
        Case cs = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1]; 
        Associated_Product__c apc = new Associated_Product__c();
        apc.Case__c = cs.Id;
        apc.Work_Order__c = wo.Id;
        apc.Product__c = objProduct.Id;
        apc.Is_Primary__c = false;
        apc.Product_Lot_Number__c = '7563833';
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = false;
        Test.startTest();
        INSERT apc;
        new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertConsumableWarrantyContract(new set<Id> {apc.Id});
        List<Applied_Contract__c> aclIist = [SELECT Id FROM Applied_Contract__c WHERE Case_Number__c = :cs.Id];
        Assert.areEqual(aclIist.size() , 1 , 'applied contract is empty');
        Test.stopTest();
     }
    /**
    *  @author Abhishek
    *  @description - CMCM-269.
    **/
    static testmethod void testUpdateConsumableWarrantyContract() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Product2'
        );
        insert apexSettings;
        initializeTestData();
        Product2 objProduct = new Product2(Name = STRING_PRODUCT_NAME, Service_Product_Type__c = STRING_PRODUCT_TYPE, Material_Class__c = STRING_PRODUCT_MATERIAL_CLASS, Source_System__c ='SAP');
		insert objProduct;
        Case cs = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1]; 
        Associated_Product__c apc = new Associated_Product__c();
        apc.Case__c = cs.Id;
        apc.Work_Order__c = wo.Id;
        apc.Product__c = objProduct.Id;
        apc.Is_Primary__c = false;
        apc.Product_Lot_Number__c = '7563833';
        apc.Expired_Date__c = System.Today();
        INSERT apc;
        Test.startTest();
        apc.Is_Expired__c = false;
		UPDATE apc;
        new ServiceUtilityCollection.ServiceSystemUtilityCollection().updateConsumableWarrantyContract(new set<Id>{cs.Id} , new set<Id>{wo.Id});
        List<Applied_Contract__c> aclIist = [SELECT Id FROM Applied_Contract__c WHERE Case_Number__c = :cs.Id];
        Assert.areEqual(aclIist.size() , 1 , 'aclIist list is empty');
        Test.stopTest();
     }
    /**
    *  @author Abhishek
    *  @description - CMCM-269.
    **/
    static testmethod void testDeleteConsumableWarrantyContract() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Product2'
        );
        insert apexSettings;
        initializeTestData();
        Case cs = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1]; 
        Account objAccount = [SELECT Id FROM Account LIMIT 1];
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        insert objServiceContract;
        system.assert(objServiceContract.Id != null , 'contract is empty');
        Applied_Contract__c appContObj = new Applied_Contract__c();
        appContObj.Service_Contract__c = objServiceContract.Id;
        appContObj.Work_Order__c = wo.id;
        insert appContObj;
        Associated_Product__c apc = new Associated_Product__c();
        apc.Case__c = cs.Id;
        apc.Work_Order__c = wo.Id;
        apc.Is_Primary__c = false;
        apc.Product_Lot_Number__c = '7563833';
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = false;
        Test.startTest();
        INSERT apc;
        new ServiceUtilityCollection.ServiceSystemUtilityCollection().deleteConsumableWarrantyContract(new set<Id>() , new set<Id>{cs.Id} , new set<Id>{wo.Id});
        List<Applied_Contract__c> aclIist = [SELECT Id FROM Applied_Contract__c WHERE Case_Number__c = :cs.Id];
        Assert.areEqual(aclIist.size() , 0 , 'aclIist is empty');
        Test.stopTest();
     }
     /**
    *  @author Abhishek
    *  @description - CMCM-269.
    **/
     static testmethod void testCoverMissingMethod() {
        Test.startTest();
        //insert account
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
                objAccount.Account_Group__c='Distributor';
                insert objAccount;
        System.assert(objAccount.Id != null , 'Account is null');
        // insert install product
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Parts Only';
        sp.Item_Number__c = '1111';
        insert sp;
        Product2 prod = new Product2(Name='TestProd',
                                     Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case',
                                     Service_Product_Type__c='Instrument',
                                     Regulatory_Type__c='DX',
                                     IsActive=true,
                                     ProductCode='43535',
                                     Source_System__c = 'SAP',
                                     Material_Number__c = '1111',
                                     Service_Level__c = 'GOLD'
                                    );        
        insert prod;
        // work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Product__c = prod.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = objAccount.Id;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
	    objServiceContract.Consumables_Included__c = true;
        objServiceContract.Parts_Included__c = true;
        objServiceContract.Labor_Included__c =true;
        insert objServiceContract;
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert cp;
        ServiceUtilityCollection.createPMPlansFromPMOfferings(new Set<Id> {objServiceContract.id});
        ServiceUtilityCollection.pMPlanCreation(new List<SVMXC__Service_Contract__c>{objServiceContract} , new Set<Id> {objServiceContract.Id});
        Set<Id> setObjIds = new Set<Id>();
        setObjIds.add(workOrder.id);
     }
    /**
    *  @author Abhishek
    *  @description - CMCM-273. fixed this method which was failing while fixing CMCM-9 bug
    **/
    static testmethod void testinsertUpdateAppliedContract() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Product2'
        );
        insert apexSettings;
        initializeTestData();
        Case cs = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1]; 
        Account objAccount = TestDataAccount.getAccount('Test');
        insert objAccount;
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = '1111';
        insert sp;
        Product2 prod = new Product2(Name='TestProd',
                                     Auto_Create_Installation_Workflow__c='Auto Create Install Work Order and Service Request Case',
                                     Service_Product_Type__c='Instrument',
                                     Regulatory_Type__c='DX',
                                     IsActive=true,
                                     ProductCode='43535',
                                     Material_Number__c = '1111',
                                     Service_Level__c = 'GOLD'
                                    );        
        insert prod;
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
        insert objServiceContract;
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert cp;
        Associated_Product__c apc = new Associated_Product__c();
        apc.Case__c = cs.Id;
        apc.Work_Order__c = wo.Id;
        apc.Installed_Product__c = ip.Id;
        apc.Subscription__c = objServiceContract.id;
        apc.Is_Primary__c = false;
        apc.Product_Lot_Number__c = '7563833';
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = false;
        insert apc;

        Test.startTest();
        if(apc.isDeleted == false){
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertAppliedContractEntitlement(new Set<Id>{apc.Id});
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().updateAppliedContractEntitlement(new Set<Id>{apc.Id});
        }
        List<Applied_Contract__c> aclIist = [SELECT Id FROM Applied_Contract__c WHERE Service_Contract__c = :objServiceContract.Id];
        Assert.areEqual(2 , aclIist.size() , 'aclIist list is empty'); //CMCM-9 Bug (6517) reverting back to 2
        Test.stopTest();
    }
    /**
    *  @author Abhishek
    *  @description - CMCM-273.
    **/
    static testmethod void testDeleteAppliedContract() {
        Account objAccount = TestDataAccount.getAccount('Test');
        insert objAccount;
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = '1111';
        insert sp;
        Product2 prod = new Product2(Name='TestProd',
                                     Auto_Create_Installation_Workflow__c='Auto Create Install Work Order and Service Request Case',
                                     Service_Product_Type__c='Instrument',
                                     Regulatory_Type__c='DX',
                                     IsActive=true,
                                     ProductCode='43535',
                                     Material_Number__c = '1111',
                                     Service_Level__c = 'GOLD'
                                    );        
        insert prod;
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
        insert objServiceContract;
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert cp;
        Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.Service_Contract__c = objServiceContract.Id;
        insert objEntitlement; 
        Test.startTest();
        new ServiceUtilityCollection.ServiceSystemUtilityCollection().deleteAppliedContractEntitlement(new Set<Id>{objEntitlement.Id});
         List<Applied_Contract__c> aclIist = [SELECT Id FROM Applied_Contract__c WHERE Id = :objServiceContract.Id];
        Assert.areEqual(0 , aclIist.size() , 'aclIist list is empty');
        Test.stopTest(); 
    }
}