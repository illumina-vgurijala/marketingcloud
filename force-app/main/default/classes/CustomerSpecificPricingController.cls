/*
* @Author: Rishab Wali
* @Date: 
* @Description :Connector class to create HTTP request - DCP-34078
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rishab Wali          16-MAR-2019                 Implemented org session cache for storing HEAD call header , Searching Logic for the 
                                                   Product Search , Callout to the SAP Web Service. 
* Saddam               27-Sep-2021                 CMCP-13 Added method CheckAccessCp() and modified method checkAcess()
* Sagar Madkaikar      30-Sep-2021                 CMCP-13/CMCP-430: Added condition to check for Distributor Account and send Distribution Channel = '02'
* Saddam                08-Nov-2021                CMCP-13 Added method checkCPProfile() to check the current user Profile is CP or not.
* Anand Palla           26-Apr-2022                CodeScan Fix-Avoid Literals in If condition
* Aman Tyagi            7th Oct 2022               Codescan Fixes
---------------------------------------------------------------------------------------------------------------------------------------                                                 
*/
public with sharing class CustomerSpecificPricingController{
    /**
     * @author Rishab Wali
     * @description HttpMethod method of enum type
     * @Param HEAD ,POST
     **/
    public enum HttpMethod {HEAD, POST}
    public final static Integer MAX_RESULTS = 5; //Maximum Results Limit on UI
    public final static String SUCCESSTRING = 'Success';
    public final static String FAILSTRING = 'Fail';
    public final static String CODEPARAMETERNAME = 'Customer_Specific_Pricing';
    public final static String INTERFACENAME  = 'Get_Customer_CSP';
    public final static String SOBJECTNAMEPRODUCT2  = 'Product2';
    public final static String CALLOUTDIRECTION  = 'InBound';
    public final static String INTERFACEPARAMETERNAME = 'Customer Specific Pricing Inbound';
    public final static String APITOKENEXPIRY = 'API_Token_Expiry';
    public static final String VALIDATEHEADER = 'ValidateHeader';
    public static final String APPLICATIONJSON = 'application/json';
    public static final String XCRSFTOKEN = 'x-csrf-token';
    private static final String LOG_TITLE = 'CustomerSpecificPricingController';//cmcp-13
    private static final String CPPROFILE = 'Channel'; //CMCP-13
    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer STATUS_CODE = 201;
    //End CodeScan Fix
    public static final string COOKIE_VARIABLE = 'cookie';

    /**
*  @author Rishab Wali
*  @description Checks whether the current user is allowed to access Component
*  @param None
*  @return Boolean
**/
    @AuraEnabled
    public static Boolean checkAccess()
    {
        List<User> lstcurrentUser = getUserList(new Set<Id>{UserInfo.getUserId()});
        String userProfile = lstcurrentUser[0].User_Profile_Name__c;   //CMCP-13
        CodeParametersSelector codeParamSelector = new CodeParametersSelector();
        List<Code_Parameter__mdt> CPRMetaData = codeParamSelector.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME}); 
        String supportedProfiles = CPRMetaData[0].Value__c;
        
        return supportedProfiles.contains(userProfile);
    }


    /**
*  @author Tapas
*  @description Returns the Product records which match the criteria
*  @param Search terms string , selected Ids of the Products List , object Name , icon Name
*  @return List<LookupSearchResultController> productList
**/
    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResultController> search(String searchTerm, List<String> selectedIds, String objectName, String iconName) {
        // Prepare query paramters
        searchTerm = '%' + searchTerm + '%';
        String query = 'select id,Name from '+ objectName + ' where id not in: selectedIds and (Name Like: searchTerm or ProductCode Like: searchTerm ) LIMIT :MAX_RESULTS';
        List<SObject> searchResults = Database.query(query);
        
        // Prepare results
        List<LookupSearchResultController> results = new List<LookupSearchResultController>();
        
        // Extract Accounts & convert them into LookupSearchResultController
        for (SObject obj : searchResults) {
            results.add(new LookupSearchResultController(obj.Id, objectName, iconName, (String)obj.get('Name')));
        }
        return results;
    }
    
    /**
*  @author Rishab Wali
*  @description Checks territory access for the current user for the specific account
*  @param Account Id
*  @return Boolean
**/
    @AuraEnabled
    public static Boolean getTerritoryAccess(Id accId)
    {
        Id currentUserProfileId = UserInfo.getProfileId();
        Set<Id> adminProfileIds = Profiles.getAllAdminProfileIds();
        if(adminProfileIds.contains(currentUserProfileId))
        {
            return true;
        }

        ObjectTerritory2AssociationsSelector objTerrAssociation = new ObjectTerritory2AssociationsSelector();
        List<ObjectTerritory2Association> objTerritories = objTerrAssociation.selectByAccountIds(new Set<Id>{accId});
        Set<Id> territoryIdSet = UtilsCollection.getSetOfIds(objTerritories, 'Territory2Id');
        Set<Id> allTerritoryIdSet = new Set<Id>();
        
        if(!territoryIdSet.isEmpty())
        {
            TerritoriesSelector terrSelector = new TerritoriesSelector();
            allTerritoryIdSet = terrSelector.getTerritoryIdsIncludingParents(territoryIdSet); 
        }
        List<UserTerritory2Association> userTerritoryAssociated = new List<UserTerritory2Association>();
        
        if(!allTerritoryIdSet.isEmpty())
        {
            UserTerritory2AssociationSelector userTerrSelector = new UserTerritory2AssociationSelector();
            userTerritoryAssociated = userTerrSelector.selectByTerritoryId(allTerritoryIdSet);
        }
        Set<Id> usersAllowedIdSet = new Set<Id>();
        
        if(!userTerritoryAssociated.isEmpty())
        {
            for(UserTerritory2Association us : userTerritoryAssociated)
            {
                usersAllowedIdSet.add(us.UserId);
            }
        }
        if(!usersAllowedIdSet.isEmpty() && usersAllowedIdSet.contains(userInfo.getUserId()))
        {
            return usersAllowedIdSet.contains(userInfo.getUserId());
        }
        return false;
    }
    
    /**
*  @author Rishab Wali
*  @description Sends the httprequest from Salesforce to SAP and sends data to the Controller(Front End)
*  @param Account Id , JSONString
*  @return String Serialized WrapperClass Variable
**/
    @AuraEnabled
    public static String getPricingData(Id accountId , String JsonString)
    {   
        Set<Id> materialIdSet = new Set<Id>();
        String salesOrg;
        String DistChannel;
        String Division;
        Map<Id,Product2> idToProduct2Map = new Map<Id,Product2>();
        
        materialIdSet = parseMaterialIds(JsonString);  //method to get material Id Set
        
        if(materialIdSet.size() > 0)
        {
            idToProduct2Map = getmapIdToProduct(materialIdSet);   //method to get material Id to material map
        }
        
        AccountsSelector accSelector = new AccountsSelector();
        List<Account> lstAcc = accSelector.selectAccounts(new Set<Id>{accountId});
        Account objAcc = lstAcc[0];
        String strAccBillingCode = objAcc.BillingCountryCode;
        SalesAreasSelector salesAreaSelctr = new SalesAreasSelector();
        List<Sales_Area__mdt> salesAreaMetaData = salesAreaSelctr.selectSalesArea(new Set<String>{strAccBillingCode});
        
        if(salesAreaMetaData.size() > 0)
        {
            salesOrg = salesAreaMetaData[0].Sales_Organization__c;
            DistChannel = objAcc.Account_Group__c=='Distributor'?'02':salesAreaMetaData[0].Distribution_Channel__c;//CMCP-13/CMCP-430: Added condition to check Distributor Account and send 02
            Division = salesAreaMetaData[0].Division__c;
        }
        
        Datetime dt = Datetime.now();
        Long timeMilliSeconds = dt.getTime();
        String dateStringStart = ''; //initialsing string for datetime format
        dateStringStart = dateStringStart.replace( '', '\\' );
        String timeMilliSecs = dateStringStart.substring(0,1) + '/Date(' + timeMilliSeconds + ')' + dateStringStart.substring(0,1) + '/';
        
        String JSONStringReq = buildJsonRequest(objAcc,idToProduct2Map,salesOrg,DistChannel,Division,timeMilliSecs);
        
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.DCPSessionVariables');
        

        HttpResponse response;
        
        //Interface Log
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(INTERFACEPARAMETERNAME,CALLOUTDIRECTION,SOBJECTNAMEPRODUCT2);
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(intDetails,JSONStringReq);
        ilib_LogInterface.addJsonToLog(log,JSONStringReq);
        Map<String, String> mapResponseHeader = new Map<String, String>(); 
        if (orgPart.contains(VALIDATEHEADER))
        {
            mapResponseHeader = (Map<String,String>)orgPart.get(VALIDATEHEADER);
        }
        else
        {
            mapResponseHeader = authenticate(orgPart);
        }
        
        Map<String, String> headerKeyToValue = new Map<String, String>{
                XCRSFTOKEN => mapResponseHeader.get('csrfToken'),
                'content-type' => APPLICATIONJSON,
                COOKIE_VARIABLE => mapResponseHeader.get(COOKIE_VARIABLE),
                'accept' => APPLICATIONJSON
                };
                    if (Test.isRunningTest())
                {
                    headerKeyToValue.put(XCRSFTOKEN,'XRTSGD');
                    headerKeyToValue.put(COOKIE_VARIABLE,'SAP_SESSIONID_GPD_100=mO8EaMo-Pau05qhnxumQ1BBwJENk4RHpgOgAUFa3Pfw%3d; path=/;sap-usercontext=sap-client=100; path=/');
                }   
        HttpRequest req = UtilsRest.createHttpRequest(INTERFACENAME, HttpMethod.POST.name(),headerKeyToValue);
        req.setBody(JSONStringReq);
        req.setTimeout(12000);
        
        response = UtilsRest.send(req);            
        ResponseWrapperFinal respFinal = new ResponseWrapperFinal();
        if(response.getStatusCode() == STATUS_CODE)
        {
            ResponseWrapperSAP sapResponse = (ResponseWrapperSAP)JSON.deserialize(response.getBody(),ResponseWrapperSAP.class);
            respFinal.customerNumber = objAcc.ERP_Customer_Id__c;
            respFinal.AccountName = objAcc.Name;
            respFinal.currencyCode = objAcc.CurrencyIsoCode;
            respFinal.salesOrg = salesOrg;
            if(sapResponse.d != null)
            {
                EXPriceWrapper arrayResponse = sapResponse.d;
                List<MaterialData> matResponse = arrayResponse.ex_prices.results;
                respFinal.resp = matResponse;
            }
            //log finalize method called (successful case)
            ilib_LogInterface.finalizeLog(log,SUCCESSTRING,response.getBody(),objAcc.Id,response);
        }
        else
        {
            //log finalize method called (failing case)
            ilib_LogInterface.finalizeLog(log,FAILSTRING,response.getBody(),objAcc.Id,response);
            return null;
        }
        
        return JSON.serialize(respFinal);
        
    }
    
    private static Map<String, String> authenticate(Cache.OrgPartition orgPart)
    {
        Map<String, String> headerKeyToValue = new Map<String, String>{
            'content-type' => APPLICATIONJSON,
                'X-CSRF-TOKEN' => 'Fetch',
                'accept' => APPLICATIONJSON
                };
                    
        HttpRequest request = UtilsRest.createHttpRequest(INTERFACENAME,HttpMethod.HEAD.name(),headerKeyToValue);
        request.setTimeout(120000);
        if (Test.isRunningTest())
        {
            MockHTTPCalloutCustomerSpecificPricing mockhttpresp = new MockHTTPCalloutCustomerSpecificPricing();
            HttpResponse httpRes =  mockhttpresp.respond(request);
            Map<String, String> mapResponseHeader = setHeaderValues(VALIDATEHEADER, httpRes, orgPart);
            return mapResponseHeader;
        }
        else
        {
            HttpResponse httpRes = UtilsRest.send(request);
            return setHeaderValues(VALIDATEHEADER, httpRes, orgPart);
        }
    }
    
    private static Map<String, String> setHeaderValues(String CallType,HttpResponse authResponse,Cache.OrgPartition orgPart)
    {
        Set<String> setCodeParameterName = new Set<String>{APITOKENEXPIRY};
            CodeParametersSelector codeParamSelector = new CodeParametersSelector();
        List<Code_Parameter__mdt> lstCodeParameter = codeParamSelector.selectCodeParameterByDeveloperName(setCodeParameterName);
        String cookie = authResponse.getHeader('set-cookie');
        Map<String, String> mapResponseHeader = new Map<String, String>();
        if (cookie !=null && cookie.indexOf(';') > -1)
        {
            mapResponseHeader.put(COOKIE_VARIABLE,cookie.substring(0, cookie.indexOf(';')));
            mapResponseHeader.put('csrfToken',authResponse.getHeader(XCRSFTOKEN));
        }
        orgPart.put(CallType,mapResponseHeader, Integer.valueOf(lstCodeParameter[0].Value__c), Cache.Visibility.ALL, true);
        return mapResponseHeader;
    }
    
    /**
*  @author Rishab Wali
*  @description Returns the current Date Time in UTC time
*  @param DateTime system.now()
*  @return DateTime in UTC
**/
    public static DateTime getUTCDateTime(DateTime dt){
        Datetime GMTDate = Datetime.newInstanceGmt(
            dt.year(),
            dt.month(),
            dt.day(),
            dt.hour(),
            dt.minute(),
            dt.second());
        return GMTDate;
    }
    
        /**
*  @author Rishab Wali
*  @description Returns the List<User>
*  @param set<Id>
*  @return List<User>
**/
    public static List<User> getUserList(Set<Id> setUserIds)
    {
        UsersSelector usrSelector = new UsersSelector();
        List<User> lstcurrentUser = usrSelector.selectByUserId(setUserIds);
        return lstcurrentUser;
    }
    
        /**
*  @author Rishab Wali
*  @description Returns the set<Id> material ids
*  @param String JSON
*  @return Set<id>
**/
    public static Set<Id> parseMaterialIds(String jsonString)
    {
        Set<Id> materialIdSet = new Set<Id>();
        JSONParser parser = JSON.createParser(JsonString);
        while (parser.nextToken() != null) {
            // Start at the array of invoices.
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if(parser.getCurrentName() == 'id' && parser.getText() != 'id') 
                    {
                        materialIdSet.add(parser.getText());
                    }
                }
            }
        }
        return materialIdSet;
    }
    
        /**
*  @author Rishab Wali
*  @description Returns the map<id,product2>
*  @param set<Id>
*  @return set<Id>
**/
    public static Map<Id,Product2> getmapIdToProduct(Set<Id> materialIdSet)
    {
        Map<Id,Product2> idToProduct2Map = new Map<Id,Product2>();
        ProductsSelector prodSelector = new ProductsSelector();
        List<Product2> materialSelected = prodSelector.selectProductsFromMaterialId(materialIdSet);
        
        for(Product2 prod : materialSelected)
        {
            idToProduct2Map.put(prod.Id,prod);
        }
        return idToProduct2Map;
    }
    
        /**
*  @author Rishab Wali
*  @description Returns the String in JSON
*  @param Account,Map<Id,Product2>,salesorg,distchannel,division,timeinmillisecond
*  @return String
**/
    public static String buildJsonRequest(Account objAcc , Map<Id,Product2> idToProduct2Map,String salesOrg,String DistChannel,String Division,String timeMilliSecs)
    {
        JSONGenerator cspRequest = JSON.createGenerator(true);    
        cspRequest.writeStartObject();
        cspRequest.writeStringField('Customer', objAcc.ERP_Customer_Id__c); 
        cspRequest.writeStringField('SalesOrg', salesOrg);
        cspRequest.writeStringField('DistiChannel', DistChannel);
        cspRequest.writeStringField('Division',Division);
        cspRequest.writeStringField('SdCurr', objAcc.CurrencyIsoCode);
        cspRequest.writeStringField('LocalCurr', objAcc.CurrencyIsoCode);
        cspRequest.writeStringField('PricingDate', timeMilliSecs);
        cspRequest.writeFieldName('im_material');
        cspRequest.writeStartArray();
        for(Product2 prod : idToProduct2Map.values())
        {
            cspRequest.writeStartObject();    
            cspRequest.writeStringField('Matnr', prod.ProductCode); 
            cspRequest.writeEndObject(); 
        }
        cspRequest.writeEndArray();
        cspRequest.writeFieldName('ex_prices');
        cspRequest.writeStartArray();
        cspRequest.writeEndArray();
        cspRequest.writeFieldName('ex_return');
        cspRequest.writeStartArray();
        cspRequest.writeEndArray();
        cspRequest.writeEndObject();
        
        String JSONStringReq = cspRequest.getAsString();
        return JSONStringReq;
    }
  /**
    * 
    *  @author Saddam
    *  @param Account Id sent from the customerSpecificPricing cmp
    *  @return Boolean
    * @description Check if current user is CP and current Account record's ID=CP user's Account ID CMCP-13
    **/
    @AuraEnabled 
    public static Boolean checkAccessCP(ID accountId) {

        ilib_LogEvent.push(LOG_TITLE + '.checkAccessCP()');
        Boolean res = false;
        try {
        ilib_LogEvent.message('accountid'+accountId);    
        List<User> currentUser =getUserList(new Set<Id>{UserInfo.getUserId()});
        String userProfileName = currentUser[0].User_Profile_Name__c;
        String strAccountId =currentUser[0].Contact.AccountId;
                if(userProfileName.contains(CPPROFILE)) {
                    if(strAccountId == accountId) {
                        res = true;
                    } else {
                        res = false;
                    }
                } else {
                    res = true;
                }   
            ilib_LogEvent.pop();
            return res;
        } catch (Exception e) {
        ApexExceptions.emit(LOG_TITLE,accountId,e);
        throw  new AuraHandledException('checkAccessCP'+ e.getMessage()) ;
        } 
        
    } 
    
  /**
    * 
    *  @author Saddam
    *  @param None
    *  @return Boolean
    * @description Check if current user is CP CMCP-13 Enhancement
    **/
    @AuraEnabled 
    public static Boolean checkCPProfile() {
        ilib_LogEvent.push(LOG_TITLE + '.checkCPProfile()');
        Boolean res = false;
        try {
        List<User> currentUser =getUserList(new Set<Id>{UserInfo.getUserId()});
        String userProfileName = currentUser[0].User_Profile_Name__c;
        if(userProfileName.contains(CPPROFILE)) {
        res =true;
        }
        ilib_LogEvent.pop();
        return res;
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            throw new AuraHandledException('checkCPProfile'+ e.getMessage()) ;
         } 
    } 
   
    /**
     * @author   
     * @description ResponseWrapperFinal wrapper class
     * @return NA 
     **/
    public class ResponseWrapperFinal{
        @AuraEnabled Public List<MaterialData> resp = new List<MaterialData>();
        @AuraEnabled public String customerNumber;
        @AuraEnabled public String salesOrg;
        @AuraEnabled public String DistChannel;
        @AuraEnabled public String Division;
        @AuraEnabled public String SdCurr;
        @AuraEnabled public Date pricingDate;
        @AuraEnabled public String AccountName;
        @AuraEnabled public String currencyCode;
    }
    /**
     * @author   
     * @description ResponseWrapperSAP wrapper class
     * @return NA 
     **/
    public class ResponseWrapperSAP{
        @AuraEnabled public EXPriceWrapper d;
    }
    /**
     * @author   
     * @description EXPriceWrapper wrapper class
     * @return NA 
     **/
    public class EXPriceWrapper{
        @AuraEnabled public ResultWrapper ex_prices;
    }
    /**
     * @author   
     * @description ResultWrapper wrapper class
     * @return NA 
     **/
    public class ResultWrapper{
        @AuraEnabled public List<MaterialData> results;
    }
    /**
     * @author   
     * @description ResponseWrapper wrapper class
     * @return NA 
     **/
    public class ResponseWrapper{
        @AuraEnabled Public List<MaterialData> results = new List<MaterialData>();
    } 
    /**
     * @author   
     * @description  Material class
     * @return NA 
     **/
    public class MaterialData{
        @AuraEnabled public String kunnr ; //customer
        @AuraEnabled public String matnr ; //mat number
        @AuraEnabled public String bismt; //Old Material No
        @AuraEnabled public String matxt; //Material desc 
        @AuraEnabled public String unitp; //Unit Price
        @AuraEnabled public String custp; //Customer Price
        @AuraEnabled public String konwa; //Rate Unit
        @AuraEnabled public String mvgr1; //Material Group
        @AuraEnabled public boolean isVisible= false; //isVisible 
    } 
    
}