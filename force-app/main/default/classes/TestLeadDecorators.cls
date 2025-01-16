/**
 *   @author: Deep Diwakar
*    @date:   Dec-04-2023
*    @description: Test class for LeadDecorator class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Dec-04-2023        CMCM-4510: Initial version
*    --------------------------------------------------------------------------------------------------
 */

@IsTest
private class TestLeadDecorators {

    @IsTest
    static void testVirtualMethods() {

        Lead lead = TestDataMarketing.createLeadForMarketable('Aow', 'Testaow', 'aow_test@testing.com', 'USA', 'Aow Test Inc');
        lead.Area_Of_Interest__c = 'Animal Testing';

        List<Lead> records = new List<Lead>{lead};
        Map<Id, Lead> mapRecords = new Map<Id, Lead>{lead.Id => lead};

        Test.startTest();
        LeadDecorator leadDecorator = new LeadDecorator(records);
        leadDecorator.decorateLeadBeforeInsert();
        leadDecorator.decorateLeadAfterInsert();
        leadDecorator.decorateLeadBeforeUpdate(mapRecords);
        leadDecorator.decorateLeadAfterUpdate(mapRecords);
        Test.stopTest();

        List<Lead> updateLeads = new List<Lead>();
        updateLeads = leadDecorator.lstLead;

        Assert.isTrue(updateLeads.contains(lead), 'Virtual class variable did not set correctly');

    }

}