/*@ author       : Bharath
* @ date         : 29-July-2019
* @ Description  : Test class for LocationsSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Tapas                   21-Jun-2019                                  Initial version
* 
* Dhairya                 29-Feb-2024                                  CMCM-9
*/
@isTest(seeAllData=False)
public with sharing class TestLocationsSelector {
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    testMethod static void methodToIncreaseCoverage()
    {

        // Create Location2
       /* SVMXC__Site__c loc1 = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
        insert loc1;*/
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        INSERT serviceTeam;
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
        INSERT grpMembers;
        
        //Create User removed in CMCM-9 as it was failing in test class and created the above method for users.
        /*User usr1 = TestDataFieldService.createUser(System.label.Field_Service,false);
        usr1.userName = System.now().format('yyyyMMddhhmmss') + '@testorg1.com';
        usr1.FederationIdentifier = 'Test234';
        insert new list<User> {usr1};*/
            
        //Account    
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        //acc.ERP_Customer_Id__c = 'Test1'; //cmcm - 9
        //insert acc; //cmcm-9 To add correct ERP_Customer_Id 
        acc.ERP_Customer_ID__c = '123456';
        INSERT acc;

        // Create service team1  
        /*SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;*/
        
        // Create service team2
        SVMXC__Service_Group__c serviceTeam1 = TestDataFieldService.createServiceTeam ('Test1','country1');
        insert serviceTeam1;
        
        //SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(usr1.id,'Test Technician',serviceTeam.id); //cmcm-9 removed
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(lstUsers[0].Id,'Test Technician',serviceTeam.id);//cmcm-9 added changed the User id
        //date d=system.today();
        technicianFAS.SVMXC__Email__c='bb11@b.com';
        insert technicianFAS;

        // Create Location1
         SVMXC__Site__c loc = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
         loc.SVMXC__Stocking_Location__c=true;
         loc.Type__c='Service Center';
         loc.Is_Illumina_Address__c=true;
         loc.SVMX_PS_External_ID__c ='THUGLIFE123';
         loc.SVMX_PS_Preferred_Technician__c=technicianFAS.id;
         insert loc;
        
        test.startTest();
        LocationsSelector ls= new LocationsSelector();
        
        ls.selectIlluminaAddresses(new List<String>{'USA'});
        ls.selectLocations(new List<Id>{loc.id});
        ls.selectLocationsForExternalId(new set<String>{loc.SVMX_PS_External_ID__c});
        ls.selectLocationsInventoryLocation(new set<Id>{loc.id});
		ls.selectToLocations(new set<Id>{loc.id});  
        ls.selectLocationsFromAccountIds(new set<Id>{acc.id});
        ls.selectDistributorPartnerStockLocationByAccount(new set<Id>{acc.id});
        //cmcm-9 create variable to filter location based on location Type also
        Set<String> strType = new Set<String>{'Ship To','Sold To','Ultimate Consignee'};
        //cmcm-9 added newly created method as "selectLocationsFromErpCusIds" in LocationsSelector class
        ls.selectLocationsFromErpCusIds(new set<String>{'123456'},strType); 
        list<SVMXC__Site__c> locList= new list<SVMXC__Site__c>();
        locList=ls.selectLocationByName(loc.name);
        system.assertequals(locList[0].name,loc.name);
        test.stopTest();



    }


}