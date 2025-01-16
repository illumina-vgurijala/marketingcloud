/**
*    @author Saswati Prusty
*    @date   2019-06-04
*    @description   Add Product Flows
*    Test class for 75%+ Coverage : TestApttusAddProduct
*    Test class for 90%+ Coverage : TestApttusAddProduct
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                    Description
*       Saswati Prusty                 04-06-2019        DCP-25191: Moving the Flow logic to Controller for Add Products
*       Saswati Prusty                 27-06-2019        DCP-25322: New Flow added
*       Satya Swain                    10-Dec-2019       DCP-30062: Sonar Qube Issue Fix
*       Khushbu Vasani                 24-Nov-2021       TASK0672536 : price override based on new custom permission and for ops quoting user
*       Nesar Mohan                    01-Apr-2022       Codescan Fix
*       Saddam                         08-Dec-2022     Codescan Fix , Varaible naming convention. 
*       Satya                          20-Feb-2022       TASK0862791: refactor addProducts() to reduce NPath Complexity
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ApttusAddProductsController
{
    public static Apttus_Proposal__Proposal__c sobjProposal;
    public static String strQuoteid { get; set; }
    public static String strContractnumber { get; set; }
    private static final String SL_APTTUS_ALLOW_PRICE_OVERRIDE = 'SL_Apttus_Allow_Price_Override';
    
    /*
    *  @Author: Saswati Prusty
    *  @Description: Constructor for the class ApttusAddProductsController to get parameters from the URL
    *  @Param: None
    */

    public ApttusAddProductsController() {
        // Added by Satya to fix SonarQube issue
        strQuoteID = ApexPages.CurrentPage().getParameters().get('id').escapeHtml4();
        System.debug('Quote Id constructor--' + strQuoteID);
        strContractnumber = ApexPages.CurrentPage().getParameters().get('ContractNumber');
        System.debug('Quote Id constructor--' + strContractnumber);
    }

    /*
    *  @Author: Saswati Prusty
    *  @Description: Method to return the pageReference concatinated with flow and strContractnumber
    *  @Param: None
    *  @Return: PageReference
    */
    public static PageReference addProducts() {
        Apttus_Proposal__Proposal__c objProposal = [
            SELECT Id, Invalid_Quote__c, Direct_Sale_to_Ultimate_Consignee__c, Apttus_QPConfig__PriceListId__c, Apttus_Proposal__Approval_Stage__c,
                Quote_Sub_Type__c, Apttus_Proposal__Opportunity__r.RecordType.Name
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :strQuoteID
        ];

        String strOpportunityRTName = objProposal.Apttus_Proposal__Opportunity__r.RecordType.Name;

        String strRedirectURL = '/apex/Apttus_Lightning_Page_Redirect?id=' + strQuoteID;
        PageReference objPageReference = null;
        if (objProposal.Id == null) { return null;}

        updateLineItems(strQuoteID);
            
        Boolean boolUserIsCommercialOps = checkQuotingUserOrHasPriceOveridePermission(UserInfo.getProfileId());
        objPageReference = fetchURLForConsortiumFlow(objProposal,strOpportunityRTName,strRedirectURL);
        if(objPageReference != null) { return objPageReference;}
        objPageReference = fetchURLForDirectFlow(strOpportunityRTName,strRedirectURL,boolUserIsCommercialOps);
        if(objPageReference != null) { return objPageReference;}
        objPageReference = fetchURLForIndirectFlow(objProposal,strOpportunityRTName,strRedirectURL,boolUserIsCommercialOps);
        if(objPageReference != null) { return objPageReference;}

        return null;
    }

    /*
    *  @Author: Lovel Panchal
    *  @Description: Method to update line items and trigger DiscountGuidancePopulatorForCPQ
    *  @Param: String quoteId
    *  @Return: void
    */
    private static void updateLineItems(String quoteId) {
        List<Apttus_Config2__LineItem__c> lineItems = [
            SELECT Id, Name, Apttus_Config2__ConfigurationId__c,Discount_Grid_Group__c,Product_Code__c,Material_Group_1__c,
            Open_Offer_Product_Category__c,Customer_Historical_Discount__c, Median_Discount_Guidance__c,
            Max_Discount_Guidance__c, Sales_Approval_Threshold__c, Approval_Matrix_Custom__c
            FROM Apttus_Config2__LineItem__c
            WHERE Apttus_Config2__ConfigurationId__c IN (
                SELECT Id
                FROM Apttus_Config2__ProductConfiguration__c
                WHERE Apttus_QPConfig__Proposald__c = :quoteId
            )
        ];

        if (!lineItems.isEmpty()) {
            // Trigger the DiscountGuidancePopulatorForCPQ for the filtered line items
            DiscountGuidancePopulatorForCPQ discountPopulator = new DiscountGuidancePopulatorForCPQ();
            discountPopulator.deriveFieldValuesForDiscountGuidance(lineItems);

            // Update line items in the database
            update lineItems;
        }
    }
    
    /*
    *  @Author: Satya Swain
    *  @Description: TASK0862791 : add new method for Consortium Flow
    *  @Param: Apttus_Proposal__Proposal__c sobjProposal,String opportunityRTName, String redirectURL
    *  @Return: PageReference
    */
    private static PageReference fetchURLForConsortiumFlow(Apttus_Proposal__Proposal__c sobjProposal,String opportunityRTName, String redirectURL) {
        if (sobjProposal.Quote_Sub_Type__c == Label.OpportunityTypeConsortium || sobjProposal.Quote_Sub_Type__c == Label.OpportunityTypeReorderConsortiumConsumable) {
            if (sobjProposal.Direct_Sale_to_Ultimate_Consignee__c) { //check added as part of DCP-25322 for the new flow
                // TASK0672536 : price override based on new custom permission and for ops quoting user
                if (opportunityRTName.contains(Label.DistributionChannelIndirect) && checkQuotingUserOrHasPriceOveridePermission(UserInfo.getprofileId())) {
                    return new PageReference(redirectURL + '&flow=RegionalSalesOpsIndirectConsortiaFlow&cntrNbr_1=' + strContractnumber);
                } else {
                    return new PageReference(redirectURL + '&flow=DirectSaleToUCConsortia&cntrNbr_1=' + strContractnumber);
                }
            } else {
                return new PageReference(redirectURL + '&flow=ConsortiaOppFlow&cntrNbr_1=' + strContractnumber);
            }
        }
        return null;
    }

    /*
    *  @Author: Satya Swain
    *  @Description: TASK0862791 : add new method for Direct Flow
    *  @Param: String opportunityRTName, String redirectURL, Boolean boolUserIsCommercialOps
    *  @Return: PageReference
    */
    private static PageReference fetchURLForDirectFlow(String opportunityRTName, String redirectURL, Boolean boolUserIsCommercialOps) {
        // TASK0672536 : price override based on new custom permission and for ops quoting user        
        if (opportunityRTName.contains(Label.DistributionChannelDirect)) {
            if (boolUserIsCommercialOps) {
                return new PageReference(redirectURL + '&flow=RegionalSalesOpsNGDefault&cntrNbr_1=' + strContractnumber);
            } else {
                return new PageReference(redirectURL + '&flow=NGDefault&cntrNbr_1=' + strContractnumber);  
            }
        }
        return null;
    }

    /*
    *  @Author: Satya Swain
    *  @Description: TASK0862791 : add new method for Indirect Flow
    *  @Param: Apttus_Proposal__Proposal__c objProposal, String strOpportunityRTName, String strRedirectURL, Boolean boolUserIsCommercialOps
    *  @Return: PageReference
    */
    private static PageReference fetchURLForIndirectFlow(Apttus_Proposal__Proposal__c objProposal, String strOpportunityRTName, String strRedirectURL, Boolean boolUserIsCommercialOps) {
        if (strOpportunityRTName.contains(Label.DistributionChannelIndirect) && objProposal.Direct_Sale_to_Ultimate_Consignee__c) {
            if (boolUserIsCommercialOps) {
                return new PageReference(strRedirectURL + '&flow=RegionalSalesOpsIndirectOppFlow&cntrNbr_1=' + strContractnumber); 
            } else {
                return new PageReference(strRedirectURL + '&flow=IndirectOppFlow&cntrNbr_1=' + strContractnumber); 
            }
        }

        if (strOpportunityRTName.contains(Label.DistributionChannelIndirect) && !objProposal.Direct_Sale_to_Ultimate_Consignee__c) {
            if (boolUserIsCommercialOps) {
                return new PageReference(strRedirectURL + '&flow=RegionalSalesOpsIndirectUCFalseOppFlow&cntrNbr_1=' + strContractnumber); 
            } else {
                return new PageReference(strRedirectURL + '&flow=IndirectUCFalseOppFlow&cntrNbr_1=' + strContractnumber); 
            }
        }
        return null;
    }


    /*
    *  @Author: Saswati Prusty
    *  @Description: TASK0672536 : price override based on new custom permission and for ops quoting user
    *  @Param: Id
    *  @Return: Boolean
    */
    private static Boolean checkQuotingUserOrHasPriceOveridePermission(Id currentUserProfileId) {
        return Profiles.getCommercialOpsQuotingUserProfileId().contains(currentUserProfileId) || FeatureManagement.checkPermission(SL_APTTUS_ALLOW_PRICE_OVERRIDE);
    }
}