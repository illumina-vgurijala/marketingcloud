/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for IlluminaAddress_WOHelper
* Modification Log:
* ---------------------------------------------------------------------------------------------------------------------
* Developer                      Date                Description
* Romi Taskar                1-Sep-2022              DCP-52923: Changes list location records to map location records
* ---------------------------------------------------------------------------------------------------------------------
*/
@IsTest
private class TestIlluminaAddress_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';

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

    /**
     * DCP-610
    *  @author : Sandeep Ram Ch.
    *  @description - test the work order Illumina address field on when a work order is Updated/inserted 
    **/
    static testMethod void workOrderUpdateIlluminaAddress() {
        Case cs = [SELECT id FROM Case LIMIT 1];
        
        Test.startTest();
        
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
        insert objLocation;
        
        SVMXC__Site__c objLocationOne = TestDataFieldService.createLocation('testlocation','teststreet','nocountry','53434343','USD');
        insert objLocationOne;
        
        SVMXC__Site__c objIlluminaLocation = TestDataFieldService.createLocation('testIlluminalocation','teststreet','testcountry','53434343','USD');
        objIlluminaLocation.Is_Illumina_Address__c=true;
        objIlluminaLocation.Is_Primary_Illumina_Address__c=true;
        insert objIlluminaLocation;
        
        SVMXC__Site__c objIlluminaLocationOne = TestDataFieldService.createLocation('testIlluminalocation','teststreet','nocountry','53434343','USD');
        objIlluminaLocationOne.Is_Illumina_Address__c=true;
        objIlluminaLocationOne.Is_Primary_Illumina_Address__c=true;
        insert objIlluminaLocationOne;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
        workOrder.SVMXC__Site__c=objLocation.id;
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        SVMXC__Service_Order__c wo =[select id,Illumina_Address__c from SVMXC__Service_Order__c where id= : workOrder.id];
        System.assertEquals(wo.Illumina_Address__c, objIlluminaLocation.id, 'Illumina Address not updated');
        
        WorkOrders.mapLocationrecords.clear(); // DCP: 52923
        WorkOrders.lstLocationrecordsbyCountries.clear();
        workOrder.SVMXC__Site__c=objLocationOne.id;
        WorkOrders.mapLocationrecords.clear();  // DCP: 52923
        WorkOrders.lstLocationrecordsbyCountries = null;
        update workOrder;
        SVMXC__Service_Order__c woUpdate =[select id,Illumina_Address__c from SVMXC__Service_Order__c where id= : workOrder.id];
        System.assertEquals(woUpdate.Illumina_Address__c, objIlluminaLocationOne.id, 'Illumina Address not updated');
        
        Test.stopTest();
        
    }
}