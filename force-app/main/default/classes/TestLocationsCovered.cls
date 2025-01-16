/***************************************************************************************************************************************
* NAME   : TestAccountToFieldSupports
* DESCRIPTION  : TestClass for AccountToFieldSupport Trigger
*          
*    
* @AUTHOR : Debanka Chakraborty
* @DATE   : 20-June-2019 
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
*  Debanka Chakraborty.           20-June-2019             Initial Version
*************************************************************************************************************************************/

@isTest(SeeAllData = false) 

    public with sharing class TestLocationsCovered {
    //static SVMXC__Site__c loc;
    
    /**
        * DCP-17253
        *  @author : Debanka Chakraborty
        *  @description - test updates field support ids on Location
    **/
    static testMethod void testUpdateFieldSupportIdsOnLocation(){
        Account acc = TestDataAccount.getCustomerAccount();
        Account acc1 = TestDataAccount.getCustomerAccount();
        List<Account> lstAccounts = new List<Account>{acc,acc1};
        insert lstAccounts;
        System.assert(acc.Id != null);
       // Create Location1
        SVMXC__Site__c loc = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
        insert loc;

     // Create Location2
        SVMXC__Site__c loc1 = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
        insert loc1;


        User usr = TestDataFieldService.createUser(System.label.Field_Service,false);
        usr.FederationIdentifier = 'Test123';
       
        
        //Create User
        User usr1 = TestDataFieldService.createUser(System.label.Field_Service,false);
        usr1.userName = System.now().format('yyyyMMddhhmmss') + '@testorg1.com';
        usr1.FederationIdentifier = 'Test234';
        insert new list<User> {usr,usr1};
        // Create service team1  
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;	
        // Create service team2
        SVMXC__Service_Group__c serviceTeam1 = TestDataFieldService.createServiceTeam ('Test1','country1');
        insert serviceTeam1;
        
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(usr.id,'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c='b@b.com';
        
        SVMXC__Service_Group_Members__c technicianFAS1 =TestDataFieldService.createTechnician(usr1.id,'Test Technician',serviceTeam1.id);
        technicianFAS1.SVMXC__Email__c='b@b1.com';
        insert new list<SVMXC__Service_Group_Members__c> {technicianFAS,technicianFAS1};
        
                            
        Test.startTest();
        
        SVMXC__Service_Group_Site__c locCovered =TestDataFieldService.createLocationCovered(technicianFAS.id,loc.id,serviceTeam.id);
         SVMXC__Service_Group_Site__c locCovered1 =TestDataFieldService.createLocationCovered(technicianFAS1.id,loc1.id,serviceTeam1.id);
        insert new list<SVMXC__Service_Group_Site__c> {locCovered,locCovered1};
        update locCovered;
		
        loc = [SELECT Field_Support_IDs__c From SVMXC__Site__c WHERE Id = : loc.Id];
        system.assert(true,loc.Field_Support_IDs__c=='Test123test1');
        
        loc1 = [SELECT Field_Support_IDs__c From SVMXC__Site__c WHERE Id = : loc1.Id];
        system.assert(true,loc1.Field_Support_IDs__c=='Test234test1');
        loc.SVMXC__Account__c = acc1.Id;
        update loc;
		
        delete locCovered;
        
        Test.stopTest();
        
        
    }

}