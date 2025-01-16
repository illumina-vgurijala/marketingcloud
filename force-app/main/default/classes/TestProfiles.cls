/**
* @actor illumina
* @description
*/
@isTest
private class TestProfiles {

    // this class makes it easy to get coverage for Profiles class

    // NOTE ************************************************************************************
    // did you change the profiles returned by an existing method?
    // please make sure you did a global search to see what is affected
    // END NOTE ********************************************************************************

    @isTest
    static void admin()
    {
        Set<Id> ids = Profiles.getAdminProfileId();
        System.assertEquals(1, ids.size());
    }

    @isTest
    static void adminAndPseudoAdmin()
    {
        Set<Id> ids = Profiles.getAllAdminProfileIds();
        System.assertEquals(3, ids.size());
    }

    @isTest

    static void salesIntegration()
    {
        Set<Id> ids = Profiles.getSalesIntegrationProfileIds();
        System.assertEquals(2, ids.size());
    }

    @isTest
    static void sales()
    {
        Set<Id> ids = Profiles.getAllSalesProfileIds();
        System.assertEquals(5, ids.size());
    }

    @isTest
    static void commercialOpsQuotingUser()
    {
        Set<Id> ids = Profiles.getCommercialOpsQuotingUserProfileId();
        System.assertEquals(1, ids.size());
    }

    @isTest
    static void commercialRevenueOperations()
    {
        Set<Id> ids = Profiles.getCommercialRevenueOperationsProfileId();
        System.assertEquals(1, ids.size());
    }

}