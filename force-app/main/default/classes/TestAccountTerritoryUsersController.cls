/*@ author       : Akshay Mohan
* @ date         : 07-06-2018
* @ Description  : US-1565 Test class for the related list component
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-06-2018                 Initial version
* Joshith K             22-09-2018                 added test method getGlobalTerritoryUsers for Global territory logic
*/
@isTest(isparallel=false)
private class TestAccountTerritoryUsersController {
static String globalTerritoryName='';
static final String CODEPARAMETER='Global_Territory_Name';

    /*
    *  @description  : Test SetupData Method 
    */
    @testSetup
    public static void setupData()
    {
        //insert account & territory association here 
        //since operation on setup object is not permitted after you have updated a non-setup object
        Account objAccount = TestDataAccount.getAccount('Tester');
        insert objAccount;

        Account objAccountGlobal = TestDataAccount.getAccount('Tester Global');
        insert objAccountGlobal;

        List<ObjectTerritory2Association> lstAssignedTerritory =
            [SELECT Territory2Id
             FROM ObjectTerritory2Association
             WHERE ObjectId = :objAccount.Id];

        Territory2 objTerritory;
        if (lstAssignedTerritory.isEmpty())
        {
            objTerritory = getTerritory();

            ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,objAccount.id);
            insert objTerritoryAssociation;
           
        }else{
            objTerritory = new Territory2(Id = lstAssignedTerritory[0].Territory2Id);
        }
        //for global territory
         List<Code_Parameter__mdt> lstCodeParameter = [SELECT Id, DeveloperName, Value__c FROM Code_Parameter__mdt WHERE DeveloperName =: CODEPARAMETER];
        if(lstCodeParameter.size()>0){
            globalTerritoryName=lstCodeParameter[0].Value__c;
            system.debug('global territory name'+globalTerritoryName);
        }
        Territory2 globalTerritory = [SELECT Id FROM Territory2 WHERE Name = :globalTerritoryName  AND Territory2Model.State = 'Active' LIMIT 1];
       
        ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(globalTerritory.Id,objAccountGlobal.id);
        insert objTerritoryAssociation;

    }

    /*
    *  @description  : Test Method getTerritory()
    */
    public static Territory2 getTerritory()
    {
        List<Territory2Model> lstModels =
            [SELECT Id, Name, (SELECT Id, Name FROM Territory2s)
             FROM Territory2Model
             WHERE State = 'Active'];
        System.debug('lstModels: ' + lstModels);

       	System.assert(!lstModels.isEmpty(),'Territory Model needs to be set up first and activated!');

        Territory2Model objTerritoryModel = lstModels.get(0);
        System.assert(!objTerritoryModel.Territory2s.isEmpty(),'Territory needs to be set up first!');

        Territory2 objTerritory = objTerritoryModel.Territory2s.get(0);
        System.debug('objTerritory: ' + objTerritory);
        return objTerritory;
    }

    /*
    *  @description  : Test Method getUsers()
    */
    @isTest
    public static void getUsers() 
    {
        Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Tester'];

        List<ObjectTerritory2Association> lstAssignedTerritory =
            [SELECT Territory2Id
             FROM ObjectTerritory2Association
             WHERE ObjectId = :objAccount.Id];
        System.assert(!lstAssignedTerritory.isEmpty(), 'Territory assignment failed');

        Territory2 objTerritory = new Territory2(Id = lstAssignedTerritory[0].Territory2Id);

        List<UserTerritory2Association> lstUsers = new UserTerritory2AssociationSelector().selectByTerritoryId(new Set<Id> {objTerritory.Id});
        System.debug('lstUsers: '+ lstUsers); //users already assigned to territory

        Set<Id> setUserIds = new Set<Id>();
        for (UserTerritory2Association objUserAssoc : lstUsers)
            setUserIds.add(objUserAssoc.UserId);

        User objUser1,objUser2;
        if (setUserIds.isEmpty())
        {
            objUser1 = TestDataUser.findUserInProfile('Sales User');
            objUser2 = TestDataUser.findUserInProfile('System Administrator');
        }
        else
        {
            objUser1 = TestDataUser.findUserInProfile('Sales User',setUserIds);
            objUser2 = TestDataUser.findUserInProfile('System Administrator',setUserIds);
        }

        List<UserTerritory2Association> lstUserAssociations = new List<UserTerritory2Association> {
            new UserTerritory2Association(RoleInTerritory2 ='Territory Account Manager', Territory2Id = objTerritory.Id,UserId = objUser1.Id),
            new UserTerritory2Association(RoleInTerritory2 ='Field Application Scientist Manager', Territory2Id = objTerritory.Id,UserId = objUser2.Id)
        };
        insert lstUserAssociations;

        Test.startTest();
        String strJSON = AccountTerritoryUsersController.getUsers(objAccount.Id);
        Test.stopTest();

        System.debug('strJSON: ' + strJSON);
        lstUserAssociations = (List<UserTerritory2Association>)JSON.deserialize(
            UtilsObject.getJSONPart(strJSON,
            '{ "lstUserAssociations":',
            ', "labelToValue":'),
            List<UserTerritory2Association>.class);
        System.debug('lstUserAssociations: ' + lstUserAssociations);

        System.assert(!lstUserAssociations.isEmpty(),'No users retrieved');// cannot validate with exact size since territory may have some existing data which we will also retrieve here

        setUserIds = UtilsCollection.getSetOfIds(lstUserAssociations,'UserId');
        System.assert(setUserIds.contains(objUser1.Id),'Expected user not found');
        System.assert(!setUserIds.contains(objUser2.Id),'Unexpected user not found');
    }

    /*
    *  @description  : Test Method getGlobalTerritoryUsers()
    */
    @isTest
    public static void getGlobalTerritoryUsers() 
    {   
         List<Code_Parameter__mdt> lstCodeParameter = [SELECT Id, DeveloperName, Value__c FROM Code_Parameter__mdt WHERE DeveloperName =: CODEPARAMETER];
        if(lstCodeParameter.size()>0){
            globalTerritoryName=lstCodeParameter[0].Value__c;
            system.debug('global territory name'+globalTerritoryName);
        }
        Territory2 globalTerritory = [SELECT Id FROM Territory2 WHERE Name = :globalTerritoryName  AND Territory2Model.State = 'Active' LIMIT 1];
        Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'Tester Global'];
        User territoryUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP, new Set<Id>());
        UserTerritory2Association associatedUser = TestDataTerritory.initUserTerritoryLinkRole(territoryUser1.Id, globalTerritory.Id, ScheduledBatchAccountTerritorySync.TERRITORY_ROLE_GAM);
        insert associatedUser;
        List<UserTerritory2Association> lstUserAssociations  = new UserTerritory2AssociationSelector().selectByTerritoryId(new Set<Id> {globalTerritory.Id});
       
        Test.startTest();
        String strJSON = AccountTerritoryUsersController.getUsers(objAccount.Id);
        Test.stopTest();
        lstUserAssociations = (List<UserTerritory2Association>)JSON.deserialize(
            UtilsObject.getJSONPart(strJSON,
            '{ "lstUserAssociations":',
            ', "labelToValue":'),
            List<UserTerritory2Association>.class);
        
        System.assert(!lstUserAssociations.isEmpty(),'No User Associated ');
        Set<id>setUserIds = UtilsCollection.getSetOfIds(lstUserAssociations,'UserId');
        System.assert(setUserIds.contains(territoryUser1.id),'GAM user not Found');

    }

}