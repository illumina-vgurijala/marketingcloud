/**
 *    @author Koustubh M
 *    @date   16-May-2022
 *    @description : TASK0748834 : Test class for TAPS_ChannelPartnerQuotas
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer                    Date                      Description
 *    Koustubh M                16-May-2022                Initial Version
 *    -----------------------------------------------------------------------------------------------        
 */
@isTest
private class TestTAPS_ChannelPartnerQuotas {
    
    public static FINAL string USD = 'USD';
    
    @testSetup static void setupEtmData()
    {
        setupTerritoryData();    
    }
    
    private static TAPS_ComposedBase mShareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mShareClass == null) mShareClass = new TAPS_ChannelPartnerQuotas();
        return mShareClass;
    }
    
    static void setupTerritoryData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryData();
        }
    }
    @isTest static void createObject(){
        
        List<Id> accountIds = TestTAPS.createParentAccounts();
        
        test.startTest();
        
		//Creating Channel Parter Quota Record
        Channel_Partner_Quota__c objChannelPartnerQuotaRec=new Channel_Partner_Quota__c();
        objChannelPartnerQuotaRec.CurrencyIsoCode=USD;
        objChannelPartnerQuotaRec.Account_Name__c=accountIds.get(0);
        objChannelPartnerQuotaRec.Name=String.valueOf(System.today().year());
        objChannelPartnerQuotaRec.Year__c=String.valueOf(System.today().year());
        objChannelPartnerQuotaRec.Quarter_1__c=0;
        objChannelPartnerQuotaRec.Quarter_2__c=0;
        objChannelPartnerQuotaRec.Quarter_3__c=0;
        objChannelPartnerQuotaRec.Quarter_4__c=0;
        insert objChannelPartnerQuotaRec;
        
        TestTAPS.objectBeingTested = getShareClass().getObjectType();
        Test.getEventBus().deliver();
        test.stopTest();
        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), objChannelPartnerQuotaRec.Id),'Number of share records do not match');
    }

    
}