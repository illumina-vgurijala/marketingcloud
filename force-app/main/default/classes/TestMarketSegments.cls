/**
*    @author Adyasha Satapathy
*    @date   2022-05-27
*    @description    DCP-53375 : Market Segment Test Class
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Adyasha                     27 May 2022          Market Segment test class
*           Deep Diwakar                  Jan-04-2024          CMCM-4697: Added test method for platform event change in market segments
*    --------------------------------------------------------------------------------------------------------------------------------------
**/

@isTest
public with sharing class TestMarketSegments {
   
    public static Boolean boolRunValidations = false;
    /*
	*  @author       : Adyasha Satapathy
	*  @description  : setup data method
	*  @param        : none
	*  @return       : void
	*/
    @testSetup
    public static void initializeTestData() {
         //Create Account
         Account objAccount = TestDataAccount.getCustomerAccount();
         objAccount.Market_Segment__c = null;
         insert objAccount;

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=objAccount.Id,
															Market_Sub_Segment__c='Agriculture Research;Plant Testing',Percent_Allocation__c = 30);
		Market_Segment__c objMarketSegment2 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=objAccount.Id,
															Market_Sub_Segment__c='Agriculture Research;Plant Testing',Percent_Allocation__c = 40);
		Market_Segment__c objMarketSegment3 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=objAccount.Id,
															Market_Sub_Segment__c='Agriculture Research;Plant Testing',Percent_Allocation__c = 30);
        
        boolRunValidations = true;
		insert new List<Market_Segment__c>{objMarketSegment1,objMarketSegment2,objMarketSegment3};
        boolRunValidations = false;
    }

    /*
	*  @author       : Adyasha Satapathy
	*  @description  : test method for updating market segment records where total percent allocation is less than 100
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void updateMarketSegmentwithLessPercentAllocation() {
        List<Market_Segment__c> lstMarketSegment = [SELECT Id,Market_Segment__c,Percent_Allocation__c FROM Market_Segment__c LIMIT 3];
        String strErrorMessage = '';

        Test.startTest();
        try {
            lstMarketSegment[0].Percent_Allocation__c = 20;
            lstMarketSegment[1].Percent_Allocation__c = 30;
            boolRunValidations = true;
            delete lstMarketSegment[2];
            update lstMarketSegment;
            boolRunValidations = false;
        } catch(Exception e) {
            strErrorMessage = e.getMessage();
        }
        Test.stopTest();
        System.assert(strErrorMessage.contains(Label.UI_Error_Message_Segmentation_Selection_Allocation_Total),'Incorrect Error:' + strErrorMessage);

    }

    /*
	*  @author       : Adyasha Satapathy
	*  @description  : test method for updating market segment records where percent allocation is greater than 100
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void updateMarketSegmentwithGreaterPercentAllocation() {

        Market_Segment__c objMarketSegment = [SELECT Id,Market_Segment__c,Percent_Allocation__c FROM Market_Segment__c LIMIT 1];
        String strErrorMessage = '';

        Test.startTest();
        try {
            objMarketSegment.Percent_Allocation__c = 120;
            boolRunValidations = true;
            update objMarketSegment;
            boolRunValidations = false;
        } catch(Exception e) {
            strErrorMessage = e.getMessage();
        }
        Test.stopTest();
        System.assert(strErrorMessage.contains(Label.UI_Error_Message_Segmentation_Selection_Allocation_Total),'Incorrect Error:' + strErrorMessage);

    }

    /*
	*  @author       : Adyasha Satapathy
	*  @description  : test method for inserting Market Segment Record with blank mandatory values.
	*  @param        : none
	*  @return       : void
	*/
	@isTest
	public static void insertMarketSegmentwithoutRequiredValues() {

        Account objAccount = [SELECT Id,Name FROM Account LIMIT 1];
        new MarketSegmentSelector().selectByAccountId(new List<String>{objAccount.Id});
        String strErrorMessage = '';

        Test.startTest();
        try {
            Market_Segment__c objMarketSegment = new Market_Segment__c(Market_Segment__c = '',Account__c=objAccount.Id,
                                                                Market_Sub_Segment__c='Agriculture Research;Plant Testing',Percent_Allocation__c = 100);
            boolRunValidations = true;
            insert objMarketSegment;
            boolRunValidations = false;

        } catch(Exception e) {
            strErrorMessage = e.getMessage();
        }
        Test.stopTest();
        System.assert(strErrorMessage.contains(Label.UI_Error_Message_Segmentation_Selection_Complete_Required_fields),'Incorrect Error:' + strErrorMessage);
    }

    /*
	*  @author       : Deep Diwakar
	*  @description  : test method for market segment platform event
	*  @param        : none
	*  @return       : void
	*/
    @isTest
    static void testMarketSegmentChangeEvent() {
        //Create new customer account
        Account testAccount = TestDataAccount.getCustomerAccount();
        testAccount.Name = 'Market Segment Testing';
        testAccount.Market_Segment__c = null;
        insert testAccount;

        // create new contact
        TestDataPerson.getNewContact(testAccount.Id);

        //Market_Segment__c objMarketSegment = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c = testAccount.Id,
        //Market_Sub_Segment__c='Agriculture Research;Plant Testing',Percent_Allocation__c = 30);

        Market_Segment__c objMarketSegment = new Market_Segment__c(Market_Segment__c = 'Cancer Research',Account__c=testAccount.Id,Percent_Allocation__c = 100);

        Test.startTest();
        insert objMarketSegment;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact resultCont = [Select Id, Area_Of_Work__c From Contact where AccountId =: testAccount.Id];

        Assert.areEqual('Cancer Research', resultCont.Area_Of_Work__c, 'Market segment value did not set correctly');

    }
}