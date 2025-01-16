/***************************************************************************************************************************************
 * @AUTHOR : Arquimidez Mora
 * @DATE   : 11-November-2024
 *
 * MODIFICATION LOG:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                             DATE                DESCRIPTION
 * --------------------------------------------------------------------------------------------------------------------------------------
 *   Arquimidez Mora                 14-Oct-2024           Initial Version.
 ****************************************************************************************************************************************/
global class QuoteCreationAPIOppCartWrapper {
    public String strJsonPayload;
    public String strOpportunityId;
    public QuoteCreationAPIErrorHandler objErrorHandler;
    public QuoteCreationAPIRequestWrapper objRequestWrapper;
    public List<Apttus_Proposal__Proposal_Line_Item__c> lstQuoteLineItems;
    public List<UtilsCart.LineItemWrapper> lstCartLineItems;
    public List<String> lstSuccessesSteps;
}