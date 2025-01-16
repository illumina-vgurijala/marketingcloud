/***************************************************************************************************************************************
 * NAME   : AccountsServiceSalesEmails
 * DESCRIPTION  : Return list of user email addresses associated to the passed-in account with the passed-in list of territory roles
 *
 * @AUTHOR : Vishnu Priya Duggineni
 * @DATE   : 24-October-2018
 *
 * MODIFICATION LOG:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                             DATE                DESCRIPTION
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vishnu Priya Duggineni                24-October-2018        Initial Version.
 * Kushagra Desai                        15-Nov-2019            Return list of user email addresses associated to the passed-in account except for global territory
 * Nesar Mohan                           01-April-2022          Codescan Fix
 * Aman Tyagi                            12-Dec-2022            Codescan Fixes
 ****************************************************************************************************************************************/
@RestResource(urlMapping='/AccountSalesUsers/*')
global class AccountsServiceSalesEmails {

    // Inputs
    private static String strCustomerId;
    private static List<String> lstEtmRoles;
    private static String strEtmRoles;

    public static final String ERROR_NO_CUSTOMER = 'No Customer Id';
    public static final String ERROR_NO_ROLES = 'No roles received';
    public static final String ERROR_CUSTOMER_NOT_FOUND = 'Customer ID not found ';

    /*
    *  @Author      : Vishnu Priya Duggineni
    *  @Description : Method to retrieve the sales users 
    *  @Param       : None
    *  @Return      : void
    */

    @HttpGet
    global static void getSalesUsers()
    {
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails('AccountSalesUsers', 'Outbound', 'User');
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(intDetails, RestContext.request);

        Id primaryRecordId;
        Boolean isSuccess = false;
        String errorMessage = '';

        try
        {
            errorMessage = validateInputs();

            if (!String.isBlank(errorMessage))
            {
                ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_FAIL, errorMessage, primaryRecordId);
                return;
            }

            List<Account> lstAccountDetails = new AccountsSelector().getAccountsforCustomerId(strCustomerId);
            isSuccess = lstAccountDetails.size() > 0;

            if (isSuccess)
            {
                primaryRecordId = lstAccountDetails.get(0).Id;
                getSalesUsersImpl(primaryRecordId);
            }
            else
            {
                errorMessage = ERROR_CUSTOMER_NOT_FOUND + strCustomerId;
                buildErrorResponse(errorMessage);
                return;
            }
        }
        catch (Exception e)
        {
            errorMessage = 'Exception: ' + e.getMessage();
            buildErrorResponse(e.getMessage());

            throw new ilib_LogInterface.InterfaceException(e);
        }

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : errorMessage),
            primaryRecordId
        );
    }
    
    /* @author      : Vishnu Priya Duggineni
     * @Description : Valdiate Inputs for the request
     * @return      : String
     */
    private static String validateInputs()
    {
        if (String.isBlank(RestContext.request.params.get('roles')))
        {
            buildErrorResponse(ERROR_NO_ROLES);
            return ERROR_NO_ROLES;
        }
        strEtmRoles = RestContext.request.params.get('roles');
        lstEtmRoles = RestContext.request.params.get('roles').split(',');

        if (String.isBlank(RestContext.request.params.get('customerId')))
        {
            buildErrorResponse(ERROR_NO_CUSTOMER);
            return ERROR_NO_CUSTOMER;
        }
        strCustomerId = RestContext.request.params.get('customerId');

        return '';
    }
    
    /* @author      : Vishnu Priya Duggineni
     * @Description : Get emails and roles for all terriroty levels for erp customer account.
     * @param       : account Id
     * @return      : list with emails and roles
     */
    private static void getSalesUsersImpl(Id accountId)
    {
        // query for territories associated with the account
        Set<Id> setAccountIds = new Set<Id> { accountId };
        List<ObjectTerritory2Association> lstAccountAssociations = new ObjectTerritory2AssociationsSelector().selectByAccountIdsNonGlobal(setAccountIds);
        Set<Id> setTerritoryIds = UtilsCollection.getSetOfIds(lstAccountAssociations, 'Territory2Id');

        TerritoriesSelector ts = new TerritoriesSelector();

        // include all parents of leaf territories
        Map<Id, Set<Id>> leafIdToParentIds = ts.selectTerritoriesInHierarchy(setTerritoryIds);
        Set<Id> setAllTerritoryIds = new Set<Id>();
        for (Id leafId : leafIdToParentIds.keySet())
        {
            setAllTerritoryIds.add(leafId);
            setAllTerritoryIds.addAll(leafIdToParentIds.get(leafId));
        }
        System.debug('setAllTerritoryIds' + setAllTerritoryIds);

        // query for users associated with the territory IDs from all levels
        List<AccountSalesUser> lstSalesUsers = new List<AccountSalesUser>();
        List<UserTerritory2Association> lstUserAssociations = new UserTerritory2AssociationSelector().selectUsersByTerritoriesAndRoles(setAllTerritoryIds, lstEtmRoles);

        // build output object
        for (UserTerritory2Association a : lstUserAssociations)
            lstSalesUsers.add(new AccountSalesUser(a.User.Name, a.User.Email));

        buildSuccessResponse(lstSalesUsers);
    }

    /* @author      : Vishnu Priya Duggineni
     * @Description : error response for callout
     * @param       : String
     * @return      : Void
     */
    private static void buildErrorResponse(String message)
    {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('Result', 'Error');
        gen.writeStringField('ErrorDetail', message);

        RestContext.response.statusCode = 400;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(gen.getAsString());
        System.debug('AccountSalesUsers REST exception occurred ' + message);
    }
    
    /* @author      : Vishnu Priya Duggineni
     * @Description : Success Json response to the callout
     * @param       : List of users
     * @return      : void
     */
    private static void buildSuccessResponse(List<AccountSalesUser> salesUsers)
    {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('users');
        gen.writeObject(salesUsers);
        gen.writeEndObject();

        String json = gen.getAsString();

        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(json);
        System.debug('AccountSalesUsers REST success ' + json);
    }

    /* @author:Vishnu Priya Duggineni
     * @Description: Wrapper class for roles and email.
     */
    public class AccountSalesUser
    {
        /**
        * 
        *
        * @desc AccounSalesUser Constructor [CodeScan Fix]
        */ 
        public AccountSalesUser(String strName, String strEmail)
        {
            this.strName = strName;
            this.strEmail = strEmail;
        }

        public String strName;
        public String strEmail;
    }

}