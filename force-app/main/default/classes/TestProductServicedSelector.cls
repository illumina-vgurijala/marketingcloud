/*
 *    @author Romi Taskar
 *    @date   16-06-2022
 *    @description    Class to cover Product Serviced Selector Class
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer              Date                    Description
 *    Romi                 15-June-2022             Initial Version
 *    ------------------------------------------------------------------------------------
 */
@IsTest
public class TestProductServicedSelector {

    public static final String STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT = 'Instrument';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_PRODUCT_FAMILY_AUTOLOADER_2 = 'Autoloader - 2';
    
    /*
    * Description - Test method to cover Product Serviced Selector Class
    */
    static testMethod void testProductServiced(){

        Test.startTest();
        //Service Team
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        //FS user
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c objTechnician = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert objTechnician;
        
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
        System.assert(objProduct2.Id != null, 'product not inserted');

        // Product serviced
        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct2.Id,
        SVMXC__Group_Member__c = objTechnician.Id,
        SVMXC__Service_Group__c = serviceTeam.Id,
        Active_Certification__c = true);
        insert objExpertise;

        //Work Order
        SVMXC__Service_Order__c workOrder= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Company__c=acc.id;
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Product__c = objProduct2.id;
        workOrder.SVMXC__Group_Member__c = objTechnician.id;
        insert workOrder;
        
        Set<Id> technicianIds = new Set<Id>{objTechnician.Id};
        Set<Id> productIds = new Set<Id>{objProduct2.Id};
        
        Test.stopTest();

        ProductServicedSelector selector = new ProductServicedSelector();
        List<SVMXC__Service_Group_Product__c> lstPOL1 = selector.selectProductServicedRecs(technicianIds, productIds);
        List<SVMXC__Service_Group_Product__c> lstPOL2 = selector.getCertifiedTechnicianProducts(technicianIds);
        System.assertEquals(1, lstPOL1.size(), 'Products Serviced Record not found');
        System.assertEquals(1, lstPOL2.size(), 'Products Serviced Record not found');
        for(SVMXC__Service_Group_Product__c pss : lstPOL2){
            System.assertEquals(true, pss.Active_Certification__c, 'Checking for active certification');
        }

    }
}