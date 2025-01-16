/**
 *   @author: Deep Diwakar
*    @date:   Dec-04-2023
*    @description: Test class for ilib_SObjectDecorator class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Dec-04-2023        CMCM-4856: Initial version
*    --------------------------------------------------------------------------------------------------
 */

@IsTest
private class ilib_SObjectDecoratorTest {

    @IsTest
    static void testVirtualMethods() {

        Lead lead = TestDataMarketing.createLeadForMarketable('Aow', 'Testaow', 'aow_test@testing.com', 'USA', 'Aow Test Inc');
        lead.Area_Of_Interest__c = 'Animal Testing';

        List<Lead> records = new List<Lead>{lead};
        Map<Id, Lead> mapRecords = new Map<Id, Lead>{lead.Id => lead};

        Test.startTest();
        ilib_SObjectDecorator objectDecorator = new ilib_SObjectDecorator(records);
        objectDecorator.decorate();
        objectDecorator.decorate(mapRecords);
        Test.stopTest();

        List<Lead> updateLeads = new List<Lead>();
        updateLeads = (List<Lead>) objectDecorator.lstRecords;

        Assert.isTrue(updateLeads.contains(lead), 'Virtual class variable did not set correctly');
    }

}