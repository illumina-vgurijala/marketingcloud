/***************************************************************************************************************************************
 * @AUTHOR : Vinay S Reddy
 * @DATE   : 14-October-2024
 *
 * MODIFICATION LOG:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                             DATE                DESCRIPTION
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vinay S Reddy                       14-Oct-2024              Initial Version.
 * Gerardo Garcia                      07-Nov-2024              Add quoteId and cartId fields.
 ****************************************************************************************************************************************/
global class QuoteCreationAPIRequestWrapper{
    public String sourceSystem;
    public String soldTo;
    public String ultimateConsignee;
    public String quoteCurrency;
    public String primaryContact;
    public String salesOrg;
    public String divison;
    public String distributionChannel;
    public String ecomId;
    public String shipTo;
    public String billTo;
    public String requestType;
    public String requestDate;
    public String quoteId;
    public String cartId;
    public List<QuoteLinesWrapper> quoteLines;
    
    /**
     * Description: Structure to handle the quote lines
     **/
    global class QuoteLinesWrapper{
        public String materialNumber;
        public Integer quantity;
        public String ecomLineitemId;
    }
}