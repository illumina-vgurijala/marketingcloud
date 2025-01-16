/**
*    @author Roopal Verma
*    Created date 2019-05-21
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*         Adyasha Satapathy              11-Jan-2023         Codescan Fix for Removing Unused Methods
*    ---------------------------------------------------------------------------------------------------------------------------
**/	

@isTest
private class TestTAPS_PartnerRequest {

    public final static String TERRITORY1 = 'T1';

    // NOTE: TestTAPS covers scenarios like new user, new territory, territory move 
    // this is just to make sure we have coverage of the specific object trigger

    @testSetup static void setupEtmData()
    {
        setupTerritoryData();        
    }
    static void setupTerritoryData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryData();
        }
    }

    // these methods do most of the object-specific work, modify all of them

    private static TAPS_ComposedBase mshareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mshareClass == null) mshareClass = new TAPS_PartnerRequest();
        return mshareClass;
    }

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Account a1;
        a1 = TestDataAccount.initAmrAccount();
        a1.Name = 'Test Account 1';
        insert a1;
        TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);

        Contact con =TestDataContact.getNewContact(a1);

        // parent records
        //List<Id> indirectUserIds = TestTAPS.getAssociatedPartnerUserIds();
        //User indirectUser = new User(Id = indirectUserIds.get(0));

        Id profileId = [select id from profile where name='Channel Partner Sales and Service'].id;
        string orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;          
        User user = new User(alias = uniqueName.substring(18, 23), email=uniqueName + '@test' + orgId + '.org',
                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                    localesidkey='en_US', profileid = profileId , country='USA',IsActive =true,PortalRole = 'Manager',
                    ContactId = con.Id,
                    timezonesidkey='America/Los_Angeles', username=uniqueName + '@test' + orgId + '.org');
       
        insert user;

        // add record
        Partner_Request__c rec1;
        Test.startTest();
        {
            System.runAs(user)
            {
                rec1 = TestDataPartnerPortal.getNewPartnerRequest(1).get(0);
                insert rec1;
            
            }
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, TestTAPS.getAssociatedUserIds()));
        // also check record id conversion method
        Set<Id> recordIds = getShareClass().getRecordIdsFromAccountIdsCustom(new Set<Id>{a1.id});
        System.assert(recordIds.contains(rec1.Id), 'idsFromAccountIds: Did not successfully convert from account IDs to record IDs');
    }
}