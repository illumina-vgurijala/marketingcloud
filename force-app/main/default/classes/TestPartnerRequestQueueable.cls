/***************************************************************************************************************************************
* NAME         : TestPartnerRequestQueueable
* DESCRIPTION  : Test Class for PartnerRequestQueueable.
*                    
* @AUTHOR : Anish
* @DATE   : 15-Mar-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Anish                 15-Mar-2021          DCP-43258.Initial Version. 
* Gerardo Garcia        09-Sep-2024          CMCM-10190 Partner Request PB to Flow conversion.
****************************************************************************************************************************************/

@isTest
public class TestPartnerRequestQueueable {
    private static final String TEST_EMAIL= 'test@email.com';
    private static final String TEST_ACCOUNT= 'MainAccount';
    private static final String TEST_DIST_ACCOUNT= 'DistAccount';

    @TestSetup
    static void makeData(){
        //Created Account
        Account objAccount = TestDataAccount.initAccount();
        objAccount.Name = TEST_ACCOUNT; 
        Account objAccount2 = TestDataAccount.initAccount();
        objAccount2.Name = TEST_DIST_ACCOUNT; 
        objAccount2.Account_Group__c = 'Distributor';
        insert new List<Account> {objAccount, objAccount2};

        //Created Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);

        //Query Profile
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;

        //Created User
        User objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
        objUser.Email = TEST_EMAIL;
        insert objUser;
    }

    /**
    *  @author Anish
    *  @description Test Method for PartnerRequestQueueable (DCP-43258). Channel Partner user Insert Partner_Request__c record type as "Reagent Rental Request"
    *  @param None
    *  @return None
    **/ 
    @IsTest
    private static void testUpdateStatusonPartnerRequest(){

        User testUser = getUser();
        Account mainAccount = getAccount(TEST_ACCOUNT);
        Account distribuitorAccount = getAccount(TEST_DIST_ACCOUNT);

        Test.startTest();

        Partner_Request__c objPR = TestDataPartnerPortal.getNewReagentRentalPartnerRequestforNewAccount(1);
        objPR.Customer_Account__c = mainAccount.id;
        objPR.Ultimate_Consignee__c = mainAccount.id;
        objPR.Status__c = Label.PartnerRequestStatusPending;
        System.runAs(testUser){
            //Created Partner Request
            insert objPR;
        }

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(mainAccount, Opportunities.RT_STANDARD_INDIRECT);
        objOpportunity.Type = System.Label.OpportunityTypeStandardSale;
        objOpportunity.Product_Interest__c = System.Label.OpportunityProductInterestInstrument;
        objOpportunity.Partner_Request__c = objPR.id;
        objOpportunity.Distributor__c = distribuitorAccount.id;
        insert objOpportunity;
        Test.stopTest();

        Partner_Request__c resPReq = [SELECT Id, Customer_Account__c, Recipient_Email__c, RecordType.Name, CreatedDate FROM Partner_Request__c WHERE id =: objPR.id];
        System.debug('Partner Request: ' + JSON.serializePretty(resPReq));

        Assert.areEqual(resPReq.Recipient_Email__c, testUser.Contact.Account.Owner.Email, 'Flow Partner before Insert should set Recipient_Email__c as User.Contact.Account.Owner.Email');
        Assert.areEqual(resPReq.Customer_Account__c, testUser.Contact.Account.id, 'Flow Partner before Insert should set Customer_Account__c as User.Contact.Account.Id');
        Assert.areEqual(objOpportunity.Type, System.Label.OpportunityTypeStandardSale);
    }

    /**
     * @author Gerardo Garcia
     * @description Partner_Request__c : Before Insert flow Prepopulation fields. Channel Partner user Insert Partner_Request__c record type as "New Account Request"
     */
    @isTest
    private static void testNewAccountRequestBeforeInsert() {
        User testUser = getUser();
        Partner_Request__c objPR = TestDataPartnerPortal.getNewPartnerRequestforNewAccount(1).get(0);

        Test.startTest();
        System.runAs(testUser) {
            insert objPR;
        }
        Test.stopTest();

        Partner_Request__c resPReq = [SELECT Id, Status__c, Recipient_Email__c, RecordType.Name, CreatedDate FROM Partner_Request__c WHERE id =: objPR.id];
        System.debug('Partner Request: ' + JSON.serializePretty(resPReq));

        Assert.areEqual(resPReq.Recipient_Email__c, testUser.Contact.Account.Owner.Email, 'Flow Partner before Insert should set Recipient_Email__c as User.Contact.Account.Owner.Email');
        Assert.areEqual(resPReq.Status__c, Label.PartnerRequestStatusPending, 'Flow Partner before Insert should set Status__c as Pending');
    } 

    private static User getUser() {
        User users1 = [SELECT Id, Contact.Account.id, Contact.Account.Owner.Email FROM User WHERE Email = :TEST_EMAIL];
        System.debug('users1: ' + JSON.serializePretty(users1));
        return users1;
    }

    private static Account getAccount(String name) {
        return [SELECT id FROM Account WHERE Name = :name LIMIT 1];
    }
}