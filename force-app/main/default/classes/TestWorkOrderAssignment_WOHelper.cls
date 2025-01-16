/**
* @author Shivani Jain
* @date 13th June 2022
*
* @description DCP-54018 Test class for WorkOrderAssignment_WOHelper
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Pooja                 22-Dec-2022            DCP-57153 : To validate the Updatation of Work Order fields for Installation/Preventive maintenance order type
*/
@IsTest
public with sharing class TestWorkOrderAssignment_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';

    /**
    *  @description - initialize test data
    **/
    @testSetup
    public static void initializeTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

     /*******************************************************************************************************
     * Decription - DCP-46058 Method to check Field Support Field
     */
    static testmethod void newBICaseCreationToPopulateFS() {
        List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;        
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'TestUser',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        technician.Preferred_Service_Report_Language__c='Japanese';
        insert technician;
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        User serviceUser=TestDataUser.findUserInProfile('Field Service');        
        system.runAs(serviceUser){
            Case cs = TestDataCase.initServiceRequestCase(con);
            cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
            cs.Date_of_Issue_Awareness__c = Date.Today();
            test.startTest();
            insert cs;
            //Case Insertion
            system.assertNotEquals(null,cs.id);
            Code_Library__c dcl = new Code_Library__c(Name='Code Disassociated', Code_type__c = 'Subject', Service_Product_Type__c = 'Tool');
            insert dcl;
            system.assertNotEquals(null,dcl.id);

            Code_Library__c pcl = new Code_Library__c(Name='Did the issue involve a death or serious',
            Code_type__c = 'Subject', Service_Product_Type__c = 'Tool');
            insert pcl;
            system.assertNotEquals(null,pcl.id);

            SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Assignment Accepted');
            wo.SVMXC__Order_Type__c='Service Activities';
            wo.SVMXC__Group_Member__c=technician.id;

            Code_Library__c cl = new Code_Library__c(Name='Test2', Code_type__c = 'Subject', Parent_Code__c=pcl.Id, Service_Product_Type__c = 'Tool');
            insert cl;
            system.assertNotEquals(null,cl.id);

            Associated_Codes__c ac = new Associated_Codes__c();
            ac.Code_Title__c = cl.Id;
            ac.Case__c = cs.Id;
            ac.Work_Order__c = wo.Id;
            //insert ac;

            cs.Question_1__c = 'Did the issue involve a death or serious injury to either the patient or the operator?';
            cs.Question_2__c = 'Could the issue cause a death or serious injury if it were to recur?';
            cs.Answer_1__c = 'No';
            cs.Answer_2__c = 'No';

            update cs;
            test.stopTest();
        }    
    }

    /**
    * @description : To validate te functionality of DCP-57153
    * @return testMethod 
    **/
    public static testMethod void woOwnerUpdate(){
        List<User> lstUsers = [SELECT Id 
                            FROM User 
                            WHERE Profile.Name =: System.label.Field_Service 
                            LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        List<Account> lstacc = new List<Account>();
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.ERP_Customer_Id__c='ERPCustomer1';
        acc.Account_Group__c='Distributor';
        lstacc.add(acc);
        Account  acc2=acc.clone();
        acc2.ERP_Customer_Id__c='ERPCustomer2';
        acc2.Account_Group__c='Distributor';
        lstacc.add(acc2);
        insert lstacc;

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
        objLocation.SVMXC__Account__c = acc.Id;
        insert objLocation;
                                                                            
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Primary Field Service Engineer',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        technician.SVMXC__Inventory_Location__c=objLocation.Id;
        technician.SVMXC__Active__c=true;
        insert technician;

        Account_to_Field_Support__c afs1 = new Account_to_Field_Support__c(User__c = technician.Id,
        Account__c = acc.Id,User_Role__c = 'Primary Field Service Engineer');
        Account_to_Field_Support__c afs2 = new Account_to_Field_Support__c(User__c = technician.Id,
        Account__c = acc2.Id,User_Role__c = 'Partner Primary Field Service Engineer');
        list<Account_to_Field_Support__c> lstAccFS = new list<Account_to_Field_Support__c>();
        lstAccFS.add(afs1);    
        lstAccFS.add(afs2);
        insert lstAccFS; 

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Is_Auto_Created__c=true;
        workOrder.Partner_Work_Order__c =true;
        workOrder.Distributor_Account__c = acc.ERP_Customer_Id__c;
        workOrder.SVMXC__Company__c=acc.id;

        SVMXC__Service_Order__c workOrder2=workOrder.clone();
        workOrder2.SVMXC__Company__c=acc2.id;
        workOrder.Distributor_Account__c = acc2.ERP_Customer_Id__c;
        List<SVMXC__Service_Order__c> lstWO= new List<SVMXC__Service_Order__c>();
        lstWO.add(workOrder2);
        lstWO.add(workOrder);
        test.startTest();
        insert lstWO;
        workOrder.PO_Number__c='8976';	
        update workOrder;
        test.stopTest();

        List<SVMXC__Service_Order__c> wolst= [select id, ownerId,Distributor_Account__c from SVMXC__Service_Order__c where id =:workOrder.id];
        system.assertEquals(wolst[0].OwnerId,lstUsers[0].Id,'Assign FS as owner to WO');
    }

    /**
* @description : testUpdatePONumber 
* @return testMethod 
**/
public static testMethod void testUpdatePONumberUpdate(){
    List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name ='Field Service' and IsActive =true LIMIT 1];
    
       //Account objAccount = TestDataAccount.initAccount();//TestDataAccount.getAccount('Test Account', 'USD');
        Account objAccount = [SELECT id FROM Account LIMIT 1];
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        //insert objAccount;
        update objAccount;
        
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
       insert serviceTeam;
           
        List<SVMXC__Service_Group_Members__c> techlist = new List<SVMXC__Service_Group_Members__c>();
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Primary Field Application Scientists',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        //insert technician;
        techlist.add(technician);
        SVMXC__Service_Group_Members__c technician1 =TestDataFieldService.createTechnician(lstUsers[0].id,'Primary Field Application Scientists',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        //insert technician1;
        techlist.add(technician1);
        insert techlist;
        
       List<Account_to_Field_Support__c> lstAFS=new List<Account_to_Field_Support__c>();
        Account_to_Field_Support__c accTechRole = new Account_to_Field_Support__c(
           Account__c = objAccount.Id,
           User__c = technician.Id,
           User_Role__c = 'Primary Field Service Engineer'
       );
       lstAFS.add(accTechRole);
        Account_to_Field_Support__c accTechRole2 = new Account_to_Field_Support__c(
           Account__c = objAccount.Id,
           User__c = technician1.Id,
           User_Role__c = 'Partner Primary Field Service Engineer'
       );
       
       lstAFS.add(accTechRole2);
       
       insert lstAFS;
       List<SVMXC__Installed_Product__c> lstIp = new List<SVMXC__Installed_Product__c>();
       SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
       objInstalledProduct.SVMXC__Company__c=objAccount.Id;
       lstIp.add(objInstalledProduct);
       SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
       objInstalledProduct1.SVMXC__Company__c=objAccount.Id;
       lstIp.add(objInstalledProduct1);
       insert lstIp;
       BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
       SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
       objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
       insert objServiceLevel;
       SVMXC__Service_Contract__c objServiceContract= TestDataFieldService.createServiceContract(objAccount.Id);
       objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        objServiceContract.Parts_Included__c=true;
       insert objServiceContract;
       SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(lstIp[0].Id );
       objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
       insert objCoveredProduct;
       SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
       insert objLoc; 
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
       toolProduct2.SVMXC__Product_Type__c = 'Spare';
       insert toolProduct2; 
       
       SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
       nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
       nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
       nonSerializedProdStock.SVMXC__Status__c = 'Available';
       nonSerializedProdStock.SVMXC__Quantity2__c = 10;
       insert nonSerializedProdStock;
       
       Case objCase = [SELECT id, AccountId FROM Case WHERE RecordType.Name = 'Service Request' LIMIT 1];
       SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
       objWorkOrder.SVMXC__Component__c = lstIp[1].Id;
       objWorkOrder.SVMXC__Order_Type__c='Service Activities';
       objWorkOrder.SVMXC__Case__c = objCase.Id;
       objWorkOrder.Record_Created_from_SFM__c=true;
       objWorkOrder.PO_Number__c='6789';
       objWorkOrder.SVMXC__Company__c=objAccount.id;
       objWorkOrder.SVMXC__Billing_Type__c='Billable';
       
       insert objWorkOrder;

       test.startTest();
       SVMXC__Service_Order__c wo =[select id,SVMXC__Billing_Type__c,SVMXC__Component__c from SVMXC__Service_Order__c where id= : objWorkOrder.id];
        
       SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
       workDetail1.SVMXC__Service_Order__c = objWorkOrder.id;
       workDetail1.SVMXC__Line_Type__c='Parts';
       workDetail1.SVMXC__Product__c = toolProduct2.Id;
       workDetail1.SVMXC__Is_Billable__c = true;
       workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467          

       insert workDetail1; 
       objWorkOrder.PO_Number__c='8976';
       objWorkOrder.Send_Pricing_Request_to_SAP__c=true;
       
       update  objWorkOrder;
       test.stoptest();
       
        SVMXC__Service_Order__c wo1 =[select id,SVMXC__Billing_Type__c ,PO_Number__c from SVMXC__Service_Order__c where id= : wo.id];
       System.assertEquals('8976',wo1.PO_Number__c,'PO number not equal');
      
   }
}