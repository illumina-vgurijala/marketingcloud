/***
*    Name -testTerritory2IdUpdateOnOpportunityBatch.
*    DESCRIPTION  : TestClass for Territory2IdUpdateOnOpportunityBatch class.
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Balakrishna                    3rd Julay 2023              CMCM-721 
*   ------------------------------------------------------------------------------------------------
*/

@isTest(isparallel=false)
public class testTerritory2IdUpdateOnOpportunityBatch{
	public static final String SUBREGION1 = 'SR1';
    public static final String SUBREGION2 = 'SR2';
    public static final String DISTRICT1 = 'D1';
    public static final String DISTRICT2 = 'D2';
    public static final String TERRITORY1 = 'T1';
    public static final String TERRITORY2 = 'T2';
    public static final String TERRITORY3 = 'T3';
    public static String globalterritoryname = '';
    public static final String CODEPARAMETER='Global_Territory_Name';
	
	@testSetup
    public static void setupData(){
        //Creating test territories to add users and test the Account owner reorder logic

        List<Territory2Model> activeModels = [SELECT Id FROM Territory2Model WHERE State = 'Active'];
        if (activeModels.size() == 0) return;
        Id modelId = activeModels.get(0).Id;

        Territory2 region = TestDataTerritory.getNewTerritory(modelId, 'R1', TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_REGION));
        Territory2 bu = TestDataTerritory.getNewTerritory(modelId, 'BU1', TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_BU), region.Id);

        Territory2 subregion1 = TestDataTerritory.initTerritory(modelId, SUBREGION1, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_SUBREGION), bu.Id);
        Territory2 subregion2 = TestDataTerritory.initTerritory(modelId, SUBREGION2, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_SUBREGION), bu.Id);
        insert new List<Territory2> { subregion1, subregion2 };

        Territory2 district1 = TestDataTerritory.initTerritory(modelId, DISTRICT1, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_DISTRICT), subregion1.Id);
        Territory2 district2 = TestDataTerritory.initTerritory(modelId, DISTRICT2, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_DISTRICT), subregion2.Id);
        insert new List<Territory2> { district1, district2 };

        Territory2 territory1 = TestDataTerritory.initTerritory(modelId, TERRITORY1, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_TERRITORY), district1.Id);
        Territory2 territory2 = TestDataTerritory.initTerritory(modelId, TERRITORY2, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_TERRITORY), district2.Id);
        Territory2 territory3 = TestDataTerritory.initTerritory(modelId, TERRITORY3, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_TERRITORY), district2.Id);

        insert new List<Territory2> { territory1, territory2, territory3};
       List<Code_Parameter__mdt> codeParameter = [SELECT Id, DeveloperName, Value__c FROM Code_Parameter__mdt WHERE DeveloperName =: CODEPARAMETER];
        if(codeParameter.size()>0){
            globalterritoryname=codeParameter[0].Value__c;
            system.debug('global territory name'+globalterritoryname);
        }
        Territory2 globalTerritory = [SELECT Id FROM Territory2 WHERE Name = :globalterritoryname  AND Territory2Model.State = 'Active' LIMIT 1];
        
        User territoryUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP, new Set<Id>());
        User territoryUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id>());
        User territoryUser3 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, new Set<Id>());
        User territoryUser4 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_CUSTOMER_SERVICE, new Set<Id>());
        Set<Id> userFound=new Set<Id>();
        userFound.add(territoryUser1.id);
        userFound.add(territoryUser2.id);
        userFound.add(territoryUser3.id);
        userFound.add(territoryUser4.id);
        User territoryUser5 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP, userFound);
        // user to territory associations
        UserTerritory2Association associatedUser1 = TestDataTerritory.initUserTerritoryLinkRole(territoryUser1.Id, territory1.Id, ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_PAM);
        UserTerritory2Association associatedUser2 = TestDataTerritory.initUserTerritoryLinkRole(territoryUser2.Id, territory1.Id, ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_SAM);
        UserTerritory2Association associatedUser3 = TestDataTerritory.initUserTerritoryLinkRole(territoryUser3.Id, territory1.Id, ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_SAM);
        UserTerritory2Association associatedUser4 = TestDataTerritory.initUserTerritoryLinkRole(territoryUser4.Id, territory2.Id, ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_ISAM);
        UserTerritory2Association associatedUser5 = TestDataTerritory.initUserTerritoryLinkRole(territoryUser4.Id, territory3.Id, ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_TAM);
        UserTerritory2Association associatedUser6 = TestDataTerritory.initUserTerritoryLinkRole(territoryUser5.Id, globalTerritory.Id, ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_GAM);

        insert new List<UserTerritory2Association> { associatedUser1, associatedUser2, associatedUser3,  associatedUser4, associatedUser5,associatedUser6};

        //Querying Territory Type
        List<Territory2Type> territoryType   = [SELECT id, DeveloperName from Territory2Type where  DeveloperName = 'Territory_Value_Added_Distributor_Channel_Partner' LIMIT 1];
        //Creating VAD Territory
        Territory2 objTerritory = new Territory2(DeveloperName = 'TestVADTerritory', Territory2ModelId=modelId, Name='TestVADTerritory',Territory_Code__c='CP_AMR11112',Territory2TypeId=territoryType[0].Id);
        insert objTerritory;

    }
    static testMethod void testBatch(){
       Territory2 territory = [SELECT Id, Name, Territory_Code__c, District__c, SubRegion__c, Business_Unit__c, Territory_Region__c FROM Territory2 WHERE Name = :TERRITORY3 LIMIT 1];

        Account objGood = TestDataAccount.getAccount('Good');              
       insert new List<Account> { objGood };
		
		List<ObjectTerritory2Association> lstAssociation = new List<ObjectTerritory2Association>();
        lstAssociation.add(TestDataObjectTerritory2Association.getObjectAssociation(territory.Id, objGood.id));
        insert lstAssociation;		
		
		Opportunity opp1 = TestDataOpportunity.initOpportunity(objGood);
        opp1.Ultimate_Consignee__c =objGood.id;
		insert new List<Opportunity> { opp1};
        
        Test.startTest();        
        Territory2IdUpdateOnOpportunityBatch job= new Territory2IdUpdateOnOpportunityBatch();
        Database.executeBatch(job);            
        Test.stopTest();
		
		System.debug('territory'+territory);
        System.debug('objgood'+objGood);
        //check good values
        System.assertEquals(opp1.Territory2Id, objGood.Aligned_Territories__c, 'Good\'s Territory Id not set properly ');
               
		
    }
}