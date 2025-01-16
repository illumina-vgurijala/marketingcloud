/**
*    @author Indra Ganesan
*    @date   2018-12-04
*    @description    DCP-12936 test class for ApttusProductSearchFilterCallback
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                       Description
*             Indra Ganesan                 12 Dec 2018            test class for ApttusProductSearchFilterCallback 
*             Satya Swain                   06-May-2019            modifications as part of TASK0370801
*/
@isTest(SeeAllData=false)
public class TestApttusProductSearchFilterCallback {

    /**
     *  @author Satya Swain 
     *  @description Test Data Setup
     **/
    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.getNewAccount();

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        List<Opportunity> lstopp = new List<Opportunity>();
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        System.debug('+++++++ Opp Type: '+opp.Type);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp);
        update lstopp;

        List<Apttus_Proposal__Proposal__c> lstProp = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        proposal.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        lstProp.add(proposal);
        insert lstProp;

        List<Product2> lstProduct = new List<Product2>();
        Product2 objProduct = TestDataMaster.createProduct(true);
        objProduct.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProduct.Product_Level_Indicator__c ='COM_PROD';
        lstProduct.add(objProduct);
        update lstProduct;

        List<Apttus_Config2__PriceListItem__c> lstPriceList = new List<Apttus_Config2__PriceListItem__c>();
        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(objProduct, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItem);
        insert lstPriceList;

        TestDataProposal.getNewConfigCustomClass();
        List<Product_Level_Indicator__c> lstProductLevelIndicator = TestDataProposal.initProductLevelIndicator();
        System.assert(!lstProductLevelIndicator.isEmpty());


    }

    /**
     *  @author Satya Swain
     *  @description Test method to check Product Filter functionality when logged in as Sales User
     **/
    static testMethod void testRunAsSalesUser()
    {
        String filterCheck = '';
        String filterCheckOption = '';

        User salesUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP);

        System.Test.startTest();

        System.runAs(salesUser){
            ApttusProductSearchFilterCallback prodFilterCallback = new ApttusProductSearchFilterCallback();
            filterCheck = prodFilterCallback.getProductFilterExpr(null);
            filterCheckOption = prodFilterCallback.getOptionFilterExpr(null);
            system.debug('filtercheck-->'+ filterCheck);
        }

        System.Test.stopTest();

        System.assert(filterCheck.length()>0);
        System.assert(filterCheckOption.length()>0);
    }

    /**
    *  @author Satya Swain
    *  @description Test method to check Product Filter functionality when logged in as Commerical Ops quoting User
    **/
    static testMethod void testRunAsCommercialOpsQuotingUser()
    {
        String filterCheck = '';
        String filterCheckOption = '';

        User salesCommercialOpsQuotingUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_COMMERCIAL_OPS_QUOTING_USER);

        System.Test.startTest();

        System.runAs(salesCommercialOpsQuotingUser){
            ApttusProductSearchFilterCallback prodFilterCallback = new ApttusProductSearchFilterCallback();
            filterCheck = prodFilterCallback.getProductFilterExpr(null);
            filterCheckOption = prodFilterCallback.getOptionFilterExpr(null);
            system.debug('filtercheck-->'+ filterCheck);
        }

        System.Test.stopTest();

        System.assert(filterCheck.length()>0);
        System.assert(filterCheckOption.length()>0);
    }

    /**
     *  @author Satya Swain
     *  @description Test method to check Product Filter functionality when logged in as System Administrator
     **/
    static testMethod void testRunAsAdmin()
    {
        String filterCheck = '';
        String filterCheckOption = '';

        User adminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN);

        System.Test.startTest();

        System.runAs(adminUser){
            ApttusProductSearchFilterCallback prodFilterCallback = new ApttusProductSearchFilterCallback();
            filterCheck = prodFilterCallback.getProductFilterExpr(null);
            filterCheckOption = prodFilterCallback.getOptionFilterExpr(null);
            system.debug('filtercheck-->'+ filterCheck);
        }

        System.Test.stopTest();

        System.assertEquals(0,filterCheck.length());
        System.assertEquals(0,filterCheckOption.length());
    }

}