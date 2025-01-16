/**
    *  @author Pankaj Singla
    *  @description Test class for MasterDataRequest PageLayout Metadata get functionality
    *  
    *  
    **/
@isTest
public class TestPartnerRequestConvertToOppcntl {
	/**
    *  @author Pankaj Singla
    *  @description Test Method for MasterDataRequest PageLayout Metadata get functionality
    *  @param None
    *  @return None
    **/
    static testmethod void testgetPageLayoutMetaData(){
        String pageLayoutName='Opportunity-Indirect Standard Layout';
        PartnerRequestConvertToOppcntl.PageLayout objPageLayout=PartnerRequestConvertToOppcntl.getPageLayoutMetadata(pageLayoutName);
        system.assert(objPageLayout!=null);
        List<Partner_Request__c> lstPartnerRequest = TestDataPartnerPortal.getNewPartnerRequest(1);
        PartnerRequestConvertToOppcntl.getOppRecordTypeId('Opportunity');
        PartnerRequestConvertToOppcntl.getPartnerAccount(lstPartnerRequest[0].id);

    }

    /**
    *  @author Pankaj Singla
    *  @description Test Method for HTTPCallout- to get assigned page layout name
    *  @param None
    *  @return None
    **/
    static testmethod void testAPIcallout(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.SetStaticResource('StaticResourceMockForMDR');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Id recordTypeIdChangeRequest = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.OpportunityRTLabelIndirectStandard).getRecordTypeId();
        String strPageLayoutName=PartnerRequestConvertToOppcntl.getPageLayoutAssignment(recordTypeIdChangeRequest);
		system.assertEquals(null,strPageLayoutName);

    }

	/**
    *  @author Saurav Bhandari
    *  @description Test Method for updateStatusonPartnerRequest functionality for DCP-32168
    *  @param None
    *  @return None
    **/
    static testmethod void testupdateStatusonPartnerRequest(){

        //Created Account
        Account objAccount = TestDataAccount.getNewAccount();

        //Created Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);

        //Query Profile
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;

        //Created User
        User objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
        insert objUser;

				// Code Scan Fix: Adding sharing to allow partner user to update contact for marketing waterfall stage.
				// Without this sharing partner user can not update contact which it hasn't created / is owner.
				ContactShare contShare = new ContactShare();
				contShare.ContactId = objContact.Id;
				contShare.UserOrGroupId = objUser.Id;
				contShare.ContactAccessLevel = 'Edit';
				insert contShare;

        test.startTest();

        system.runAs(objUser){
        //Created Partner Request
        Partner_Request__c objPR = TestDataPartnerPortal.getNewReagentRentalPartnerRequestforNewAccount(1);
        objPR.Customer_Account__c = objAccount.id;
        objPR.Ultimate_Consignee__c = objAccount.id;
        insert objPR;

        //Created Opportunity
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        objOpportunity.Type = System.Label.OpportunityTypeStandardSale;
        objOpportunity.Product_Interest__c = System.Label.OpportunityProductInterestInstrument;
        objOpportunity.Partner_Request__c = objPR.id;
        insert objOpportunity;
        System.assertEquals(objOpportunity.Type, System.Label.OpportunityTypeStandardSale);

        PartnerRequestConvertToOppcntl.updateStatusonPartnerRequest(objOpportunity.id);
        }
        test.stopTest();
    }
}
