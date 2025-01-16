/**
* Opportunity and associated records
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey                26 May 2018            getNewOpportunitywithRole(account)
*                                                                initOpportunityContRole()
*                                                                getContactRecord()
*                                                                getAccountRecord()
*                                                                getOpportunityContactRoleRecord()
*                                         13 July 2018           getNewIndReOrderOpportunity()
*                                                                initIndReOrderOpportunity()
*             Roopal Verma                26 July 2018           Removed Method__c from initOpportunity()
*             Rahul Sharma                26 sep 2018            Added initOpportunity(Account a,String strDeveloperName)
*             Pradeep Patil               19 Oct 2018            Removed Lab Type from initOpportunity method call
*			  Saurabh Brahmankar		  27 Feb 2024			 Added 'Competitor Presence' field 
*    ------------------------------------------------------------------------------------
**/
public with sharing class TestDataOpportunity {

    /**
    * 
    *
    * @desc getNewOpportunity [CodeScan Fix]
    */
    public static Opportunity getNewOpportunity(Account a)
    {
        Opportunity o = initOpportunity(a);
        insert o;
        return o;
    }

    /**
    * 
    *
    * @desc initOpportunity [CodeScan Fix]
    */
    public static Opportunity initOpportunity(Account a)
    {
        return initOpportunity(a, Opportunities.RT_STANDARD_DIRECT);
    }

    /**
    * 
    *
    * @desc initOpportunity [CodeScan Fix]
    */
    public static Opportunity initOpportunity(Account a,String strDeveloperName)
    {
        return initOpportunity(a,Opportunities.RECORD_TYPE_MAP.get(strDeveloperName).getRecordTypeId(),'Create','Standard Sale','Consumables');
    }

    /**
    * 
    *
    * @desc initOpportunity [CodeScan Fix]
    */
    public static Opportunity initOpportunity(Account a,ID idRecordTypeId,String strStage,String strType,String strProductInterest)
    {
        return initOpportunity(a,strStage,Date.today() + 30,10000,idRecordTypeId,10,'Clinical','Description Test','Applied Lab','Forensics',strProductInterest,strType,'$10,000 - $25,000','Internal Budget: In Process','Poor Data Quality','0-3 Months',true);
    }

    /**
    * 
    *
    * @desc initOpportunity [CodeScan Fix]
    */
    public static Opportunity initOpportunity(Account a,string strStage,Date dtCloseDate,Integer intAmount,Id idRecordType,Integer intProbability,String strClinicalType, String strDescription, String strLabType,String strPrimaryMarket,String strProductInterest,String strType,String strBudgetRange, String strBudget, String strPain,String strPurchaseTimeline, Boolean booDirectSaletoUltimateConsignee)
    {
        String rand = TestData.getRandom();

        Opportunity o = new Opportunity(
            Name = rand,
            StageName = strStage,
            CloseDate = dtCloseDate,
            AccountId = a.Id,
            Ultimate_Consignee__c = a.Id,
            Amount = intAmount,
            RecordTypeId = idRecordType,
            Probability = intProbability,
            Clinical_Type__c = strClinicalType,
            Description = strDescription,
            Market_Segment__c = strPrimaryMarket,
            Product_Interest__c = strProductInterest,
            Type = strType,
            Projected_Budget_Range__c = strBudgetRange,
            Budget__c = strBudget,
            Pain__c = strPain,
            Purchase_Timeline__c = strPurchaseTimeline,
            Direct_Sale_to_Ultimate_Consignee__c = booDirectSaletoUltimateConsignee,
            Rev_Rec_Terms__c = 'SHI: Shipment ',
            Abandoned_Reason_Details__c = 'Error',
            Competitor_Presence__c = 'No Competitor' //Competitor_Name__c = 'No Competitor' Added by SB
        );

        return o;
    }

    /**
    * 
    *
    * @desc getNewOpportunity2 [CodeScan Fix]
    */
    public static Opportunity getNewOpportunity2(Id accountId)
    {
        Opportunity rec = initOpportunity2(accountId);
        insert rec;
        return rec;
    }
    /**
    * 
    *
    * @desc initOpportunity2 [CodeScan Fix]
    */
    public static Opportunity initOpportunity2(Id accountId)
    {
        String rand = TestData.getRandom();
        Id idRecordType = Opportunities.RECORD_TYPE_MAP.get(Opportunities.RT_STANDARD_DIRECT).getRecordTypeId();
        return new Opportunity(
                Name = rand,
                StageName = 'Create',
                CloseDate = Date.today() + 30,
                AccountId = accountId,
                Ultimate_Consignee__c = accountId,
                Amount = Decimal.valueOf(TestData.getRandomNumeric()),
                RecordTypeId = idRecordType,
                Probability = 50,
                Clinical_Type__c = 'Clinical',
                Description = TestData.getRandom(),
                Market_Segment__c = 'Forensics',
                Product_Interest__c = 'Services',
                Type = 'Standard Sale',
                Projected_Budget_Range__c = '$10,000 - $25,000',
                Budget__c = 'Internal Budget: In Process',
                Pain__c = 'Poor Data Quality',
                Purchase_Timeline__c = '0-3 Months',
                Direct_Sale_to_Ultimate_Consignee__c = true,
                Rev_Rec_Terms__c='SHI: Shipment ',
                Competitor_Presence__c = 'No Competitor' //Competitor_Name__c = 'No Competitor' Added by SB
        );
    }

    /**
    * 
    *
    * @desc initOpportunity [CodeScan Fix]
    */
    public static Opportunity initOpportunity(Account a,string strStage,Date dtCloseDate,Integer intAmount,String strDeveloperName,Integer intProbability,String strClinicalType, String strDescription, String strLabType,String strPrimaryMarket,String strProductInterest,String strType,String strBudgetRange, String strBudget, String strPain,String strPurchaseTimeline, Boolean booDirectSaletoUltimateConsignee)
    {
        String rand = TestData.getRandom();
        Id idRecordType = Opportunities.RECORD_TYPE_MAP.get(strDeveloperName).getRecordTypeId();
        Opportunity o = new Opportunity(
            Name = rand,
            StageName = strStage,
            CloseDate = dtCloseDate,
            AccountId = a.Id,
            Ultimate_Consignee__c = a.Id,
            Amount = intAmount,
            RecordTypeId = idRecordType,
            Probability = intProbability,
            Clinical_Type__c = strClinicalType,
            Description = strDescription,
            Market_Segment__c = strPrimaryMarket,
            Product_Interest__c = strProductInterest,
            Type = strType,
            Projected_Budget_Range__c = strBudgetRange,
            Budget__c = strBudget,
            Pain__c = strPain,
            Purchase_Timeline__c = strPurchaseTimeline,
            Direct_Sale_to_Ultimate_Consignee__c = booDirectSaletoUltimateConsignee,
            Rev_Rec_Terms__c='SHI: Shipment ',
            Competitor_Presence__c = 'No Competitor' //Competitor_Name__c = 'No Competitor' Added by SB
        );
        return o;
    }

    /**
    * 
    *
    * @desc getNewOpportunityLineItem [CodeScan Fix]
    */
    public static OpportunityLineItem getNewOpportunityLineItem(Id oppId, Id pbeId, Double quantity, Double price)
    {
        OpportunityLineItem oli = initOpportunityLineItem(oppId, pbeId, quantity, price);
        insert oli;
        return oli;
    }

    /**
    * 
    *
    * @desc initOpportunityLineItem [CodeScan Fix]
    */
    public static OpportunityLineItem initOpportunityLineItem(Id oppId, Id pbeId, Double quantity, Double price)
    {
        OpportunityLineItem oli = new OpportunityLineItem(
            PricebookEntryId = pbeId,
            Quantity = quantity,
            OpportunityId = oppId,
            Shipping_In_Close_Quarter__c = 1,
            UnitPrice = price
        );

        return oli;
    }

    /**
    *  @author  Indra Ganesan
    *  @description to Set Opportunity Primary Contact Role
    **/
   public static OpportunityContactRole getNewOpportunityPrimaryContactRole(String role, Id contactId, Id opportunityId, boolean val)
   {
       OpportunityContactRole ocr = new OpportunityContactRole(
           Role = role,
           ContactId = contactId,
           OpportunityId = opportunityId,
           isPrimary = true
       );
       return ocr;
   }

    /**
     *  @author  Govind Dubey
     *  @description to Set Opportunity Contact Role
     **/
    public static OpportunityContactRole getNewOpportunityContactRole(String role, Id contactId, Id opportunityId)
    {
        OpportunityContactRole ocr = new OpportunityContactRole(
            Role = role,
            ContactId = contactId,
            OpportunityId = opportunityId
        );
       return ocr;
    }

    /**
    * 
    *
    * @desc getNewCrf [CodeScan Fix]
    */
    public static Customer_Readiness_Form__c getNewCrf(Id accountId, Id opportunityId)
    {
        Customer_Readiness_Form__c rec = initCrf(accountId, opportunityId);
        insert rec;
        return rec;
    }
    /**
    * 
    *
    * @desc initCrf [CodeScan Fix]
    */
    public static Customer_Readiness_Form__c initCrf(Id accountId, Id opportunityId)
    {
        Customer_Readiness_Form__c rec = new Customer_Readiness_Form__c(
                SFT_Account__c = accountId,
                Opportunity_Name__c = opportunityId
        );
        return rec;
    }

    /**
     *  @author Rohan Chandarana
     *  @description Get the standard price book
     *  @return Pricebook2
     **/
    public static Pricebook2 getStandardPriceBook()
    {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        return standardPricebook;
    }

}