//TestLocationsCoveredSelector 
/*
* @ author       : Romi
* @ date         : 30-Aug-2021
* @ Description  : Test class for LocationsCoveredSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Romi                  30-Aug-2021                        Initial version
*/
@isTest
public class TestLocationsCoveredSelector {
    /**
     * @author: Romi
     * @description: method to test selectRelatedLocationFieldSupport.
     */
    public testMethod static void selectRelatedLocationFieldSupportTest()
    {
        //Create User
        User usr1 = TestDataFieldService.createUser(System.label.Field_Service,false);
        usr1.userName = System.now().format('yyyyMMddhhmmss') + '@testorg1.com';
        usr1.FederationIdentifier = 'Test234';
        insert new list<User> {usr1};
            
         // Create service team1  
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;	
        // Create service team2
        SVMXC__Service_Group__c serviceTeam1 = TestDataFieldService.createServiceTeam ('Test1','country1');
        insert serviceTeam1;
        
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(usr1.id,'Test Technician',serviceTeam.id);
        //date d=system.today();
        technicianFAS.SVMXC__Email__c='bb11@b.com';
        technicianFAS.SVMXC__Active__c =true;
        insert technicianFAS;
        
        List<Id> setServiceMem = new List<Id>();
        setServiceMem.add(technicianFAS.Id);
        
        // Create Location1
         SVMXC__Site__c loc = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
         loc.SVMXC__Stocking_Location__c=true;
         loc.Type__c='Service Center';
         loc.Is_Illumina_Address__c=true;
         loc.SVMX_PS_External_ID__c ='THUGLIFE123';
         loc.SVMX_PS_Preferred_Technician__c=technicianFAS.id;
         insert loc;
        
        Set<Id> setLocations = new Set<Id>();
        setLocations.add(loc.Id);
       
        SVMXC__Service_Group_Site__c serviceGroup = new SVMXC__Service_Group_Site__c();
        serviceGroup.SVMXC__Technician_Equipment__c = technicianFAS.ID;
        serviceGroup.SVMXC__Site__c = loc.Id;
        serviceGroup.SVMXC__Service_Group__c=serviceTeam.id;
        insert serviceGroup;
        
        Test.startTest();
        LocationsCoveredSelector selector = new LocationsCoveredSelector();
        selector.selectRelatedLocationFieldSupport(setServiceMem);
        selector.selectLocationsCovered(setLocations);
        List<SVMXC__Service_Group_Site__c> lstServiceGroup = new LocationsCoveredSelector().selectLocationsCovered(setLocations);
        System.assert(lstServiceGroup.size()>0);
        Test.stopTest();
        
    }
    

}