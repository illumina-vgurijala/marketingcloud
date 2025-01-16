/*
 *    @author Romi Taskar
 *    @date   16-06-2022
 *    @description    Test Class to cover ValidateProductServiced_WOHelper 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer              Date                    Description
 *    Romi                 15-June-2022             Initial Version
 *    ------------------------------------------------------------------------------------
 */
@IsTest
public class TestValidateProductServiced_WOHelper {

    public static final String STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT = 'Instrument';
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_PRODUCT_FAMILY_AUTOLOADER_2 = 'Autoloader - 2';
    
   /*
    * Description - Test method to cover ValidateProductServiced_WOHelper class
    */

    static testMethod void testValidateProductServiceThrowValidation() {

        Test.startTest();
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test';
        ps.Label = 'Test';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'SS_Service_Dispatch_Console'][0].Id;
        insert sea;
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;

        system.runas(new user(Id = userinfo.getUserid())) {
            List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                LIMIT 1];     
            SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
            insert serviceTeam;
            System.assertNotEquals(null, serviceTeam.Id);
            
            //FS user1
            SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technicianFAS.SVMXC__Email__c='xyz@b.com';
            insert technicianFAS;
            System.assert(technicianFAS.id != null, 'Technician not inserted');
            
            //FS user2
            SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technician.SVMXC__Email__c='abc@b.com';
            insert technician;
            System.assert(technician.id != null, 'Technician not inserted');
            
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c='Distributor';
            insert acc;

            //insert contact
            Contact con = TestDataPerson.getNewContact(acc.Id);
            System.assert(con.id != null, 'Contact not inserted');
            
            //insert case        
            Case cs = TestDataCase.initServiceRequestCase(con);
            insert cs;
    
            //Product
            Product2 objProduct2 = TestDataFieldService.createProduct('Test Product 2', STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT);
            objProduct2.Family = STRING_PRODUCT_FAMILY_AUTOLOADER_2;
            insert objProduct2;
            System.assert(objProduct2.Id != null, 'Product not inserted');

            // Product serviced
            SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c();
            objExpertise.SVMXC__Product__c = objProduct2.Id;
            objExpertise.SVMXC__Group_Member__c = technicianFAS.Id;
            objExpertise.SVMXC__Service_Group__c = serviceTeam.Id;
            objExpertise.Active_Certification__c = true;
            insert objExpertise;

            //Work Order
            List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
            SVMXC__Service_Order__c workOrder= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
            workOrder.SVMXC__Company__c=acc.id;
            workOrder.Is_Auto_Created__c = true;
            workOrder.SVMXC__Product__c = objProduct2.id;
            workOrder.SVMXC__Group_Member__c = technicianFAS.id;

            woList.add(workOrder);
            
            
            insert woList;
            System.assert(woList[0].Id != null, 'Work Order not inserted');

            try {
                workOrder.SVMXC__Group_Member__c = technician.id;
                workOrder.SVMXC__Locked_By_DC__c = true;
                update woList;
            }
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('The Field Service assignee is not trained on the product. Please review the event and assign the Work Order to a trained FS employee.') ? true : false;
                System.assert(expectedExceptionThrown, 'Expected Validation from Confirm Assignee Functionality not thrown');
            }    
        }               

        Test.stopTest();
    }

    
    static testMethod void testValidateProductServiceNoValidation() {

        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test';
        ps.Label = 'Test';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'SS_Service_Dispatch_Console'][0].Id;
        insert sea;
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;

        system.runas(new user(Id = userinfo.getUserid())) {
            List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                LIMIT 1];     
            SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
            insert serviceTeam;
            System.assertNotEquals(null, serviceTeam.Id);
            
            //FS user1
            SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technicianFAS.SVMXC__Email__c='xyz@b.com';
            insert technicianFAS;
            System.assert(technicianFAS.id != null, 'Technician not inserted');
            
            //FS user2
            SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technician.SVMXC__Email__c='abc@b.com';
            insert technician;
            System.assert(technician.id != null, 'Technician not inserted');
            
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c='Distributor';
            insert acc;

            //insert contact
            Contact con = TestDataPerson.getNewContact(acc.Id);
            System.assert(con.id != null, 'Contact not inserted');
            
            //insert case        
            Case cs = TestDataCase.initServiceRequestCase(con);
            insert cs;
    
            //Product
            Product2 objProduct2 = TestDataFieldService.createProduct('Test Product 2', STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT);
            objProduct2.Family = STRING_PRODUCT_FAMILY_AUTOLOADER_2;
            insert objProduct2;
            System.assert(objProduct2.Id != null, 'Product not inserted');

            // Product serviced
            SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c();
            objExpertise.SVMXC__Product__c = objProduct2.Id;
            objExpertise.SVMXC__Group_Member__c = technicianFAS.Id;
            objExpertise.SVMXC__Service_Group__c = serviceTeam.Id;
            objExpertise.Active_Certification__c = true;
            insert objExpertise;

            Test.startTest();
            //Work Order
            List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
            SVMXC__Service_Order__c workOrder= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
            workOrder.SVMXC__Company__c=acc.id;
            workOrder.Is_Auto_Created__c = true;
            workOrder.SVMXC__Product__c = objProduct2.id;
            workOrder.Confirm_Assignee__c = true;
            workOrder.SVMXC__Group_Member__c = technicianFAS.id;
            woList.add(workOrder);
        
            insert woList;
            System.assert(woList[0].Id != null, 'Work Order not inserted');
            Test.stopTest();

            workOrder.SVMXC__Group_Member__c = technician.id;
            update woList;
            
        }

        List<SVMXC__Service_Order__c> updatedWO =  [SELECT id, Confirm_Assignee__c FROM SVMXC__Service_Order__c LIMIT 1];
        System.assert(!updatedWO[0].Confirm_Assignee__c, 'Confirm Assignee set to false logic failed!');
    }

    static testMethod void testValidateProductServiceThrowValidationForQueue() {
        Test.startTest();
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test';
        ps.Label = 'Test';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'SS_Service_Dispatch_Console'][0].Id;
        insert sea;
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;

        Group testGroup = new Group(Name='test group', Type='Queue');
        insert testGroup;
       

        system.runas(new user(Id = userinfo.getUserid())) {
            List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                LIMIT 1];     
            SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
            insert serviceTeam;
            System.assertNotEquals(null, serviceTeam.Id);
            
            //FS user1
            SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technicianFAS.SVMXC__Email__c='xyz@b.com';
            insert technicianFAS;
            System.assert(technicianFAS.id != null, 'Technician not inserted');
            
            //FS user2
            SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technician.SVMXC__Email__c='abc@b.com';
            insert technician;
            System.assert(technician.id != null, 'Technician not inserted');
            
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c='Distributor';
            insert acc;

            //insert contact
            Contact con = TestDataPerson.getNewContact(acc.Id);
            System.assert(con.id != null, 'Contact not inserted');
            
            //insert case        
            Case cs = TestDataCase.initServiceRequestCase(con);
            insert cs;
    
            //Product
            Product2 objProduct2 = TestDataFieldService.createProduct('Test Product 2', STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT);
            objProduct2.Family = STRING_PRODUCT_FAMILY_AUTOLOADER_2;
            insert objProduct2;
            System.assert(objProduct2.Id != null, 'Product not inserted');

            // Product serviced
            SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c();
            objExpertise.SVMXC__Product__c = objProduct2.Id;
            objExpertise.SVMXC__Group_Member__c = technicianFAS.Id;
            objExpertise.SVMXC__Service_Group__c = serviceTeam.Id;
            objExpertise.Active_Certification__c = true;
            insert objExpertise;

            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
 
            //Work Order
            List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
            SVMXC__Service_Order__c workOrder= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
            workOrder.SVMXC__Company__c=acc.id;
            workOrder.Is_Auto_Created__c = true;
            workOrder.SVMXC__Product__c = objProduct2.id;
            workOrder.SVMXC__Group_Member__c = technicianFAS.id;
            workOrder.OwnerId = testGroup.id;

            woList.add(workOrder);
            
            
            insert woList;
            System.assert(woList[0].Id != null, 'Work Order not inserted');

            try {
                workOrder.SVMXC__Group_Member__c = technician.id;
                workOrder.SVMXC__Locked_By_DC__c = true;
                update woList;
            }
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('The Field Service assignee is not trained on the product. Please review the event and assign the Work Order to a trained FS employee.') ? true : false;
                System.assert(expectedExceptionThrown, 'Expected Validation from Confirm Assignee Functionality not thrown');
            }    
        }               

        Test.stopTest();


    }
}