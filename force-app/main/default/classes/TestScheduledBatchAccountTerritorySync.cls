/**
* @ author       : Akshay Mohan
* @ date         : 07-05-2018
* @ Description  : US-4252 Test to check ScheduledBatchAccountTerritorySync
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                  Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-05-2018                Initial version
* Akshay Mohan          09-08-2018                Modified for Account Owner updation
* Akshay Mohan          21-08-2018                DCP-10620 bug fix
* Joshith k             18-09-2019                DCP-27876 
* Nishan Shetty         09-Sept-2021              CMCP-20
* Prem Ranjan           07-02-2022                CodeScan Fix - System.assertEquals instead of System.assert
* -----------------------------------------------------------------------------------------------------------------------------------
*/
@isTest(isparallel=false)
public class TestScheduledBatchAccountTerritorySync {
    public static final String SUBREGION1 = 'SR1';
    public static final String SUBREGION2 = 'SR2';
    public static final String DISTRICT1 = 'D1';
    public static final String DISTRICT2 = 'D2';
    public static final String TERRITORY1 = 'T1';
    public static final String TERRITORY2 = 'T2';
    public static final String TERRITORY3 = 'T3';
    public static String globalterritoryname = '';
    public static final String CODEPARAMETER='Global_Territory_Name';

    /**
    *  @author 
    *  @description - Setup Method.
    **/
    @testSetup
    public static void setupData()
    {
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

        //START CMCP-20

        //Querying Territory Type
        List<Territory2Type> territoryType   = [SELECT id, DeveloperName from Territory2Type where  DeveloperName = 'Territory_Value_Added_Distributor_Channel_Partner' LIMIT 1];
        //Creating VAD Territory [CMCP-20]
        Territory2 objTerritory = new Territory2(DeveloperName = 'TestVADTerritory', Territory2ModelId=modelId, Name='TestVADTerritory',Territory_Code__c='CP_AMR11112',Territory2TypeId=territoryType[0].Id);
        insert objTerritory;

        //END CMCP-20
    }

    /*
    *  @description  : Test Method indirectTerritoryManipulation()
    */
    @isTest
    public static void indirectTerritoryManipulation()
    {
        Territory2 directTerritory =
        [SELECT Id, Name
        FROM Territory2
        WHERE Territory2Model.State = 'Active'
        AND Territory2Type.DeveloperName = :TerritoryTypesService.TYPE_TERRITORY
        LIMIT 1];

        Territory2 indirectTerritory =
        [SELECT Id, Name
        FROM Territory2
        WHERE Territory2Model.State = 'Active'
        AND Territory2Type.DeveloperName = :TerritoryTypesService.TYPE_TERRITORY_CP
        LIMIT 1];

        // this account starts with the direct T2, indirect is added
        Account accountWithBoth = TestDataAccount.getAccount('Both');
        accountWithBoth.Territory_Name__c = directTerritory.Name;
        accountWithBoth.Aligned_Territories__c = directTerritory.Id;

        // this account starts with nothing and has the indirect added
        Account accountIndirectOnly = TestDataAccount.getAccount('Indirect');

        // this account starts with both and has the indirect removed
        Account accountDirectOnly = TestDataAccount.getAccount('Direct');
        accountDirectOnly.Territory_Name__c = directTerritory.Name;
        accountDirectOnly.Aligned_Territories__c = directTerritory.Id + ',' + indirectTerritory.Id;

        insert new List<Account> { accountWithBoth, accountIndirectOnly, accountDirectOnly};

        TestDataTerritory.getNewAccountTerritoryLink(accountWithBoth, directTerritory);
        TestDataTerritory.getNewAccountTerritoryLink(accountWithBoth, indirectTerritory);
        TestDataTerritory.getNewAccountTerritoryLink(accountIndirectOnly, indirectTerritory);
        TestDataTerritory.getNewAccountTerritoryLink(accountDirectOnly, directTerritory);

        Test.startTest();
        Database.executeBatch(new ScheduledBatchAccountTerritorySync());
        Test.stopTest();

        for (Account a: [SELECT Id, Name, Territory_Name__c, Aligned_Territories__c FROM Account])
            if('Both'.equals(a.Name))
                accountWithBoth = a;
            else if('Indirect'.equals(a.Name))
                accountIndirectOnly = a;
            else if('Direct'.equals(a.Name))
                accountDirectOnly = a;

        //check account with both
        System.assertEquals(directTerritory.Name, accountWithBoth.Territory_Name__c, 'Direct Territory Name not set properly (1)');
        System.assert(accountWithBoth.Aligned_Territories__c.contains(indirectTerritory.Id), 'Indirect ID missing from assigned territories');
        System.assert(accountWithBoth.Aligned_Territories__c.contains(directTerritory.Id), 'Direct ID missing from assigned territories');

        //check account with indirect only
        System.assertEquals(null, accountIndirectOnly.Territory_Name__c, 'Territory Name not blank');
        System.assertEquals(indirectTerritory.Id, accountIndirectOnly.Aligned_Territories__c, 'Indirect only assigned territory list not correct');

        //check account with direct only
        System.assertEquals(directTerritory.Name, accountDirectOnly.Territory_Name__c, 'Direct Territory Name not set properly (2)');
        System.assertEquals(directTerritory.Id, accountDirectOnly.Aligned_Territories__c, 'Direct only assigned territory list not correct');
    }

    /*
    *  @description  : Test Method scheduleJob()
    */
    @isTest
    public static void scheduleJob()
    {
        ScheduledBatchAccountTerritorySync schedule = new ScheduledBatchAccountTerritorySync();
        insert TestDataAccount.getAccount('Good');

        Test.startTest();
        String strSchedule = '0 0 10 * * ?'; // every 10 am job
        String jobId = System.schedule('ScheduledBatchAccountTerritorySyncUnitTest', strSchedule, schedule);
        Test.stopTest();

        System.assert(String.isNotBlank(jobId),'Job Id not generated.');
        CronTrigger cronTrigger = [SELECT CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, TimesTriggered, NextFireTime
        FROM CronTrigger WHERE Id = :jobId];
        System.debug('cronTrigger: ' + cronTrigger);
        System.debug('cronJob: ' + cronTrigger.CronJobDetail);
        System.assertEquals('ScheduledBatchAccountTerritorySyncUnitTest',cronTrigger.CronJobDetail.Name,'Job name not proper.');
    }

    /*
    *  @description  : Test Method checkBatch()
    */
    @isTest
    public static void checkBatch()
    {
        Territory2 territory = [SELECT Id, Name, Territory_Code__c, District__c, SubRegion__c, Business_Unit__c, Territory_Region__c FROM Territory2 WHERE Name = :TERRITORY3 LIMIT 1];

        List<UserTerritory2Association> lstUsers = [SELECT UserId, LastModifiedDate
            FROM UserTerritory2Association
            WHERE RoleInTerritory2 = :ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_TAM
            AND Territory2Id = :territory.Id
            AND IsActive = true
            ORDER BY LastModifiedDate DESC];
        System.assert(!lstUsers.isEmpty(),'User setup not working');
        String strUserId = lstUsers[0].UserId;

        Account objGood = TestDataAccount.getAccount('Good'),
                objBad = TestDataAccount.getAccount('Bad'),
                objUgly = TestDataAccount.getAccount('Ugly');

        objBad.Territory_Name__c = territory.Name;
        objBad.Territory_Code__c = territory.Territory_Code__c;
        objBad.District__c = territory.District__c;
        objBad.SubRegion__c = territory.SubRegion__c;
        objBad.Business_Unit__c = territory.Business_Unit__c;
        objBad.Territory_Region__c = territory.Territory_Region__c;
        objBad.OwnerId = strUserId;
        objBad.Aligned_Territories__c = territory.Id;

        insert new List<Account> { objGood, objBad, objUgly };

        //set values to skip updation
        objBad = [SELECT LastModifiedDate FROM Account WHERE Id = :objBad.Id];
        DateTime dtLastModified = objBad.LastModifiedDate;

        List<ObjectTerritory2Association> lstAssociation = new List<ObjectTerritory2Association>();
        lstAssociation.add(TestDataObjectTerritory2Association.getObjectAssociation(territory.Id, objGood.id));
        lstAssociation.add(TestDataObjectTerritory2Association.getObjectAssociation(territory.Id, objBad.id));

        //ignoring ugly for updation
        insert lstAssociation;

        ScheduledBatchAccountTerritorySync batch = new ScheduledBatchAccountTerritorySync();

        Test.startTest();
        DataBase.executeBatch(batch);
        Test.stopTest();

        for (Account objAccount :
            [SELECT Id, Name, Territory_Name__c, Territory_Code__c, District__c, Subregion__c,
                Business_Unit__c, Territory_Region__c, LastModifiedDate, OwnerId
             FROM Account]
        ) {
            if ('Good'.equals(objAccount.Name))
                objGood = objAccount;
            else if('Bad'.equals(objAccount.Name))
                objBad = objAccount;
            else if('Ugly'.equals(objAccount.Name))
                objUgly = objAccount;
        }

        System.debug('territory'+territory);
        System.debug('objgood'+objGood);
        //check good values
        System.assertEquals(territory.Name, objGood.Territory_Name__c, 'Good\'s Territory Name not set properly ');
        System.assertEquals(territory.Territory_Code__c, objGood.Territory_Code__c, 'Good\'s Territory Code not set properly ');
        System.assertEquals(territory.District__c, objGood.District__c, 'Good\'s District not set properly ');
        System.assertEquals(territory.SubRegion__c, objGood.SubRegion__c, 'Good\'s SubRegion not set properly ');
        System.assertEquals(territory.Business_Unit__c, objGood.Business_Unit__c, 'Good\'s Business Unit not set properly ');
        System.assertEquals(territory.Territory_Region__c, objGood.Territory_Region__c, 'Good\'s Region not set properly ');

        //check bad values
        System.assertEquals(territory.Name, objBad.Territory_Name__c, 'Bad\'s Territory Name not set properly ');
        System.assertEquals(territory.Territory_Code__c, objBad.Territory_Code__c, 'Bad\'s Territory Code not set properly ');
        System.assertEquals(territory.District__c, objBad.District__c, 'Bad\'s District not set properly ');
        System.assertEquals(territory.SubRegion__c, objBad.SubRegion__c, 'Bad\'s Subregion not set properly ');
        System.assertEquals(territory.Business_Unit__c, objBad.Business_Unit__c, 'Bad\'s Business Unit not set properly ');
        System.assertEquals(territory.Territory_Region__c, objBad.Territory_Region__c, 'Bad\'s Region not set properly ');
        System.assertEquals(dtLastModified, objBad.LastModifiedDate, 'Bad got modified when it shouldn\'t');

        //check ugly values
        System.assertEquals(null,objUgly.Territory_Name__c, 'Ugly\'s Territory Name got set somehow');
        System.assertEquals(null,objUgly.Territory_Code__c, 'Ugly\'s Territory Code got set somehow');
        System.assertEquals(null,objUgly.District__c, 'Ugly\'s District got set somehow');
        System.assertEquals(null,objUgly.SubRegion__c, 'Ugly\'s sub region got set somehow');
        System.assertEquals(null,objUgly.Business_Unit__c, 'Ugly\'s business unit got set somehow');
        System.assertEquals(null,objUgly.Territory_Region__c, 'Ugly\'s region got set somehow');
    }
        
    /*
    *  @description  : Test Method accountOwnerReorder()
    */
    @isTest
    public static void accountOwnerReorder()
    {   
        List<Code_Parameter__mdt> codeParameter = [SELECT Id, DeveloperName, Value__c FROM Code_Parameter__mdt WHERE DeveloperName =: CODEPARAMETER];
        if(codeParameter.size()>0){
            globalterritoryname=codeParameter[0].Value__c;
            system.debug('global territory name'+globalterritoryname);
        }
        // Query test territories
        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 territory2 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY2 LIMIT 1];
        Territory2 globalTerritory = [SELECT Id FROM Territory2 WHERE Name = :globalterritoryname  AND Territory2Model.State = 'Active' LIMIT 1];
        // TODO
        Set<String> setOwnerRoles = new Set<String>{ ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_PAM, ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_ISAM,ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_GAM};
        Set<Id> setTerritoryIds = new Set<Id>();
        setTerritoryIds.add(territory1.Id);
        setTerritoryIds.add(territory2.Id);
        setTerritoryIds.add(globalTerritory.Id);


        System.debug('setOwnerRoles: ' + setOwnerRoles);
        //Get PAM and ISAM roles to update the owner id
        List<UserTerritory2Association> lstUsers = [SELECT UserId,LastModifiedDate ,RoleInTerritory2 FROM UserTerritory2Association
        WHERE RoleInTerritory2 IN :setOwnerRoles
        AND Territory2Id IN :setTerritoryIds AND IsActive=true
        ORDER BY LastModifiedDate DESC];

        String strPamUserId=lstUsers[0].UserId;
        String strIsamUserId=lstUsers[1].UserId;
        String strGamUserId;
        system.debug('strIsamUserId'+lstUsers[1].UserId);
        for(UserTerritory2Association obj:lstUsers){
            if(obj.RoleInTerritory2==ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_GAM){
                system.debug('GAM User found '+obj);
                strGamUserId=obj.UserId;
            }
        }
        system.debug('strIGamUserId'+strGamUserId);
        Account a1;
        Account a2;
        Account a3;
        a1 = TestDataAccount.initAmrAccount();
        a1.Name = 'Test Account 1';
        a1.ownerid = strPamUserId;
        a2 = TestDataAccount.initAmrAccount();
        a2.Name = 'Test Account 2';
        a2.ownerid = strIsamUserId;
        a3 = TestDataAccount.initAmrAccount();
        a3.Name = 'Test Account 3';
        a3.ownerid = strIsamUserId;
        insert new List<Account>{ a1, a2,a3 };
        system.debug('Account a3 owner id'+ a3.ownerid);
        TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
        TestDataTerritory.getNewAccountTerritoryLink(a2, territory2);
        TestDataTerritory.getNewAccountTerritoryLink(a2, globalTerritory);
        TestDataTerritory.getNewAccountTerritoryLink(a3, globalTerritory);

        ScheduledBatchAccountTerritorySync batch = new ScheduledBatchAccountTerritorySync();

        Test.startTest();
        DataBase.executeBatch(batch);
        Test.stopTest();
        system.debug('Account a3 owner id'+ a3.ownerid);
        a3=[select id,ownerid from Account where id=:a3.id limit 1];
        system.debug('Account a3 owner id'+ a3.ownerid);
        //Asserts to test the PAM, SAM, ISAM
        System.assertEquals(strPamUserId, a1.OwnerId,'a1\'s owner not set properly');
        System.assertEquals(strIsamUserId, a2.OwnerId,'a2\'s owner not set properly');
        System.assertEquals(strGamUserId, a3.OwnerId,'a3\'s owner not set properly');
    }


    /**
    *  @author Nishan Shetty
    *  @description - Method to check if VAD Territory Code on Account is updated if current field is blank.
    **/
    @isTest
    public static void testAssignVADTerritoryCodeToAccount() {  
       //Created Account
        Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount1.Account_Group__c='Distributor';
        insert objAccount1; 

       //Querying Territory
       Territory2 objVADTerritory = [SELECT Id, Name, Territory_Code__c, District__c, SubRegion__c, Business_Unit__c, Territory_Region__c FROM Territory2 WHERE Name ='TestVADTerritory' LIMIT 1];
        
        //Associating Territory with Account2
        ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(objVADTerritory.Id,objAccount1.id);
        insert objTerritoryAssociation;

        ScheduledBatchAccountTerritorySync batch = new ScheduledBatchAccountTerritorySync();
        Test.startTest();
        DataBase.executeBatch(batch);
        Test.stopTest();

        Account accUpdated=[select id,VAD_Channel_Partner_Territory__c from Account where id=:objAccount1.id limit 1];
        System.assertEquals('CP_AMR11112',accUpdated.VAD_Channel_Partner_Territory__c,'VAD Territory not Assigned');

    }   
    
    /**
    *  @author Nishan Shetty
    *  @description - Method to check if VAD Territory Code on Account is updated if current field contains values.
    **/
    @isTest
    public static void testAssignVADTerritoryCodeToAccountWithExistingCode() {  
       //Created Account
        Account objAccount1 = TestDataAccount.getAccount('Test Acc23', 'USD');
        objAccount1.Account_Group__c='Distributor';
        objAccount1.VAD_Channel_Partner_Territory__c='CP_AMR11112';
        insert objAccount1; 
       

       //Querying Territory
       Territory2 objVADTerritory = [SELECT Id, Name, Territory_Code__c, District__c, SubRegion__c, Business_Unit__c, Territory_Region__c FROM Territory2 WHERE Name ='TestVADTerritory' LIMIT 1];
        
        //Associating Territory with Account2
        ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(objVADTerritory.Id,objAccount1.id);
        insert objTerritoryAssociation;

        ScheduledBatchAccountTerritorySync batch = new ScheduledBatchAccountTerritorySync();
        Test.startTest();
        DataBase.executeBatch(batch);
        Test.stopTest();

        Account accUpdated=[select id,VAD_Channel_Partner_Territory__c from Account where id=:objAccount1.id limit 1];
        System.assertEquals('CP_AMR11112',accUpdated.VAD_Channel_Partner_Territory__c,'VAD Territory not Assigned');

    }    

}