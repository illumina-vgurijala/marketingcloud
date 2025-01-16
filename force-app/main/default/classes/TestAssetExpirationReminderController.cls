/**
* @author      : Indra Ganesan
* @date        : 2018-10-28
* @description : Test Class For Apex Controller - AssetExpirationReminderController
* Modification Log 
* --------------------------------------------------------------------------------------------- 
*       Developer            Date               Description
*       Indra Ganesan        2018-10-31         Original Version
*       Ashwin Kumar         2021-08-23         Test method updates for TASK0587523 modification
* ---------------------------------------------------------------------------------------------   
*/

@isTest
public class TestAssetExpirationReminderController {
    
	/**
    *  @author Indra Ganesan
    *  @description test data setup
    *  @return void
    **/    
    @testSetup
    static void setupData()
    {
        Id activeTerritoryModel = [SELECT Id FROM Territory2Model WHERE State = 'Active']?.Id;
        if (activeTerritoryModel == null) { return; }

        Territory2 territoryRegion = TestDataTerritory.getNewTerritory(activeTerritoryModel, 'R1', TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_REGION));
        User territoryUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP, new Set<Id>());
        UserTerritory2Association associatedUser = TestDataTerritory.initUserTerritoryLinkRole(territoryUser.Id, territoryRegion.Id, 'Inside Sales Representative - Service Contract Specialists');
        insert associatedUser;
    }
   
    /**
    *  @author Ashwin Kumar
    *  @description test method to send email from batch apex
    *  @return void
    **/ 
    @isTest
    public static void testSendEmailFromBatch()
    {
        Territory2 territoryRegion = [SELECT Id, Name, Territory_Code__c, District__c, SubRegion__c, Business_Unit__c, Territory_Region__c FROM Territory2 WHERE Name = 'R1' LIMIT 1];

        List<UserTerritory2Association> lstUsers = [SELECT UserId, LastModifiedDate
                                                    FROM UserTerritory2Association
                                                    WHERE RoleInTerritory2 = 'Inside Sales Representative - Service Contract Specialists'
                                                    AND Territory2Id = :territoryRegion.Id
                                                    AND IsActive = true
                                                    ORDER BY LastModifiedDate DESC];
        String strUserId = lstUsers[0].UserId;

        Account objAccount = TestDataAccount.getAccount('AccWithAsset');
        objAccount.Territory_Name__c = territoryRegion.Name;
        objAccount.Territory_Code__c = territoryRegion.Territory_Code__c;
        objAccount.District__c = territoryRegion.District__c;
        objAccount.SubRegion__c = territoryRegion.SubRegion__c;
        objAccount.Business_Unit__c = territoryRegion.Business_Unit__c;
        objAccount.Territory_Region__c = territoryRegion.Territory_Region__c;
        objAccount.OwnerId = strUserId;
        objAccount.Aligned_Territories__c = territoryRegion.Id;
        insert objAccount;
        
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceList;

        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
      
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = objPriceList.Name;
        update objOpportunity;
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
        
        Product2 objProduct = TestDataMaster.createProduct(true);
        objProduct.Material_Class__c = 'Instrument';
        update objProduct;

        Apttus_Config2__AssetLineItem__c objAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem.Apttus_Config2__AccountId__c = objAccount.Id;
        objAssetLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objAssetLineItem.Serial_Number__c = '123123';
        objAssetLineItem.Contract_Number__c = '453523413';
        objAssetLineItem.Contract_Type__c = 'test Contract Type';
        objAssetLineItem.Apttus_QPConfig__ProposalId__c = objProposal.Id;
        objAssetLineItem.Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Status__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Apttus_Config2__EndDate__c = Date.today()+120;
        objAssetLineItem.Apttus_Config2__StartDate__c = Date.today();
        objAssetLineItem.Apttus_Config2__OriginalStartDate__c = Date.today();
        insert objAssetLineItem;
        
        ObjectTerritory2Association objTerr2Assoc = TestDataObjectTerritory2Association.getObjectAssociation(territoryRegion.Id, objAccount.id);
        insert objTerr2Assoc;

        Test.startTest();
        ScheduleBatchAssetLineExpirationReminder scheduled = new ScheduleBatchAssetLineExpirationReminder();
        scheduled.execute(null);
        Test.stopTest();
        System.assert(AssetExpirationReminderController.boolIsEmailSentFromTest, 'Email Sent');
    }
}