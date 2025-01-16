/**
 *    @author Vaibhav
 *    @date   2 May 2021
 *    @description   DCP-46141 - Class to Qualtrics Integration From Case.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                         Date                     Description
 *    Vaibhav                       2 May 2021              Initial Version - DCP-46141 : Qualtrics Integration.
 *    Shivani                       10 June 2022            DCP-49913 Enhance sending the same survey link via both Email and WeChat
 * ---------------------------------------------------------------------------------------
 */
public with sharing class QualtricsAPISurveyLinkReader extends ilib_RestReceiver {

    public static final String INTERFACE_NAME = 'Qualtrics_Inbound';
    public static final String APPLICATION_JSON = 'application/json';
    public static final String HTTP_METHOD_POST = 'POST';
    public static final String HTTP_METHOD_GET = 'GET';
    public static final String STRING_NA = 'N/A';
    public static final String STRING_AUTH   = 'Auth';
    public static string qualtricsBaseEndpointUrl;
    public static string qualtricsAPIKey;
    public static ilib_LogInterface.LogDetails log;
    public static Case caseObjInstance = new Case();
    public static string contactQualtricsId;
    public static string distributionLinkQualtricsId;
    public static string surveyLinkQualtricsId;
    public static string qualtricsAccessToken = 'N/A';
    public static List < Interface_Log__c > lstInterfaceLog = new List < Interface_Log__c > ();
    public static List < Case > lstCaseToUpdateWithSurveyLink = new List < Case > ();
	public static final String QUALTRICSMIDENDPOINGSTR = '/API/v3/distributions/';
	public static final String QUALTRICS_INBOUND = 'Qualtrics Inbound';
	public static final String QUALTRICS_OUTBOUND = 'Qualtrics Outbound';
	public static final String INBOUND = 'Inbound';
	public static final String OUTBOUND = 'Outbound';
	public static final String ACCESS_TOKEN_IDENTIFIER = 'Qualtrics - Get Access Token callout.';
	public static final String QUALTRICS_CREATE_CONTACT_INBOUND = 'Qualtrics - Create Contact API Inbound';
	public static final String QUALTRICS_CREATE_CONTACT_OUTBOUND = 'Qualtrics - Create Contact API Outbound';
	public static final String QUALTRICS_CREATE_DISTRIBUTION_INBOUND = 'Qualtrics - Create Distribution API Inbound';
	public static final String QUALTRICS_CREATE_DISTRIBUTION_OUTBOUND = 'Qualtrics - Create Distribution API Outbound';
	public static final String QUALTRICS_GET_SURVEY_LINK_OUTBOUND = 'Qualtrics - Get Survey Link API Outbound';
	public static final String HTTP_STATUS_CODE_OKAY = '200 - OK';
    public static final Integer HTTP_STATUS_CODE = 200;

    public static string oAuthClientId;
    public static string oAuthClientSecret;

    public static Boolean nextPage = false;
	

    /**                     GENERIC METHODS - START                         **/

    /** @DESCRIPTION - start qualtrics api **/
    public static void initiateQualtricsCallout(Case caseObj) {

        caseObjInstance = caseObj;

        //get custom metadata information.
        getQualtricsMetadataInformation();

        //get access token first
        oAuthAuthentication();

        //if we got an access token, make callouts ahead
        if (qualtricsAccessToken != STRING_NA) {
            //1st callout
            createContactInQualtrics();

            //2nd callout
            if (String.isNotBlank(contactQualtricsId))
                createDistributionLinksInQualtrics();

            //3rd callout
            if (String.isNotBlank(distributionLinkQualtricsId))
                getSurveyLinksFromQualtrics(null);

            //update survey link to a field in Case
            if (String.isNotBlank(surveyLinkQualtricsId)) {
                Case caseObjRec = new Case(Id = caseObjInstance.Id, Qualtrics_Survey_Link__c = surveyLinkQualtricsId);
                lstCaseToUpdateWithSurveyLink.add(caseObjRec);

                if (lstCaseToUpdateWithSurveyLink != null && !lstCaseToUpdateWithSurveyLink.isEmpty())
                    update lstCaseToUpdateWithSurveyLink;
					
                //send weChat message if follower is not blank
                if (String.isNotBlank(caseObjInstance.WeChatFollower__c) && !surveyLinkQualtricsId.contains('Error'))
                    sendWeChatMessageToContact();

            }

        }

        //insert interface logs
        if (lstInterfaceLog != null && !lstInterfaceLog.isEmpty())
            insert lstInterfaceLog;

    }

    /** @DESCRIPTION - Constructor to setup initial variables like endpoint using custom metadata. **/
    public static void getQualtricsMetadataInformation() {
        Map < String, String > mapInterfaceDetails = getBaseEnpointUrlFromCustomMetadata();
        qualtricsBaseEndpointUrl = mapInterfaceDetails.get('Endpoint');
        qualtricsAPIKey = mapInterfaceDetails.get('ApiKey');
        String clientIdAndClientSecret =   mapInterfaceDetails.get('Header Token');
        oAuthClientId = clientIdAndClientSecret.subStringBefore('||');
        oAuthClientSecret = clientIdAndClientSecret.subStringAfter('||');
    }

    /** @DESCRIPTION - Get Interface Parameter custom metadata information. **/
    public static Map < String, String > getBaseEnpointUrlFromCustomMetadata() {
        return UtilsRest.getIntegrationEndpoint(INTERFACE_NAME);
    }

    /** @DESCRIPTION - Oauth 2 authentication. **/
    public static void oAuthAuthentication() {

        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Content-Type' => 'application/x-www-form-urlencoded'
        };

        String clientId = oAuthClientId;
        String clientSecret = oAuthClientSecret;
        String accessTokenBody = 'grant_type=client_credentials' + '&client_id=' + clientId + '&client_secret=' + clientSecret + '&scope=manage:all';

        HttpRequest request = createHttpRequest(HTTP_METHOD_POST, headerKeyToValue, accessTokenBody, '/oauth2/token');

        HTTPResponse response = !Test.isRunningTest() ? UtilsRest.send(request) : MockHTTPCalloutQualtricsAccessTokenAPI.respondMock(STRING_AUTH);

        if (response.getStatusCode() == HTTP_STATUS_CODE) {
            QualtricsAPIAccessTokenResponse qualtricsAccessTokenResponse = QualtricsAPIAccessTokenResponse.parse(response.getBody());
            qualtricsAccessToken = qualtricsAccessTokenResponse.access_token;
        } else {
            ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(QUALTRICS_INBOUND, INBOUND, ACCESS_TOKEN_IDENTIFIER);
            log = ilib_LogInterface.initiateLog(intDetails, JSON.serializePretty(JSON.deserializeUntyped(response.getBody())));
            lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_FAIL, accessTokenBody, caseObjInstance.Id, response));
        }

    }

    /** @DESCRIPTION - Create HTTP Request. **/
    public static HttpRequest createHttpRequest(String strMethod, Map < String, String > headerKeyToValue, String strJSON, String strResourceURL) {
        HttpRequest request = new HttpRequest();
		
        request.setEndpoint(qualtricsBaseEndpointUrl + strResourceURL);
        request.setMethod(strMethod);

        //request.setHeader('apikey', strAPIKey);
        if (headerKeyToValue != null && !headerKeyToValue.isEmpty())
            for (String headerKey: headerKeyToValue.keySet()) {
                request.setHeader(headerKey, headerKeyToValue.get(headerKey));
            }

        if (String.isNotBlank(strJSON))
            request.setBody(strJSON);

        request.setTimeout(120000);
        return request;
    }


    /**                     GENERIC METHODS - END                           **/

    /**                     CALLOUT 1 - CREATE CONTACT API - START          **/

    /** @DESCRIPTION - 1st callout - create raw json body to create contact in qualtrics directory.**/
    public static void createContactInQualtrics() {

        HttpResponse response;

        //map to send api key in header
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer ' + qualtricsAccessToken,
            'Content-Type' => APPLICATION_JSON,
            'Content-Length' => '512'
        };

        //prepare post body to create contact in qualtrics.
        string createContactJSONBody = createJSONForContactCreationInQualtrics();

        //register create contact api inbound interface log
        ilib_RestInterface.InterfaceDetails intDetailsInbound = new ilib_RestInterface.InterfaceDetails(QUALTRICS_INBOUND, INBOUND, QUALTRICS_CREATE_CONTACT_INBOUND);

        //make create contact api callout
        HttpRequest request = createHttpRequest(HTTP_METHOD_POST, headerKeyToValue, createContactJSONBody, '/API/v3/directories/' + Label.Qualtrics_Directory_ID + '/mailinglists/' + Label.Qualtrics_MailingList_ID + '/contacts');

        //store create contact api salesforce json.
        log = ilib_LogInterface.initiateLog(intDetailsInbound, JSON.serializePretty(JSON.deserializeUntyped(createContactJSONBody)));

        response = !Test.isRunningTest() ? UtilsRest.send(request) : MockHTTPCalloutQualtricsAPI.respondMock(STRING_AUTH);
        //response = UtilsRest.send(request);

        lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_SUCCESS, createContactJSONBody, caseObjInstance.Id, response));
        //insert create contact api interface log record.
        //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, createContactJSONBody, caseObjInstance.Id);

        //register create contact api outbound interface log
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(QUALTRICS_OUTBOUND, OUTBOUND, QUALTRICS_CREATE_CONTACT_OUTBOUND);

        //if create contact api returned success, store the qualtrics contact id.
        if (response.getStatusCode() == UtilsRest.REST_SUCCESS) {
            String strJsonInput = response.getBody();

            system.debug('JSON Res' + strJsonInput);
            log = ilib_LogInterface.initiateLog(intDetails, JSON.serializePretty(JSON.deserializeUntyped(strJsonInput)));
            try {
                if (String.isBlank(strJsonInput))
                    throw new UtilsRest.InterfaceException('Input JSON is missing');

                //store create contact api outbound response.
                lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_SUCCESS, strJsonInput + response.getStatusCode(), caseObjInstance.Id, response));
                //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, strJsonInput + response.getStatusCode(), caseObjInstance.Id);

                deserializeCreateContactAPIResponse(strJsonInput);

            } catch (Exception e) {
                System.debug('@@@ Exception happened, details here: ' + e);
                ApexExceptions.emit('QualtricsAPISurveyLinkReader create contact api ', e);
                system.debug('Rest Error: ' + e);
                lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_FAIL, strJsonInput + response.getStatusCode(), caseObjInstance.Id, response));
                //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_Fail, strJsonInput + response.getStatusCode(), caseObjInstance.Id);
            }
        } else {

            log = ilib_LogInterface.initiateLog(intDetails, JSON.serializePretty(JSON.deserializeUntyped(response.getBody())));
            lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), caseObjInstance.Id, response));
            //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, response.getBody() + response.getStatusCode(), caseObjInstance.Id);

        }


    }

    /** @DESCRIPTION - 1st callout - create raw json body to create contact in qualtrics directory. **/
    public static String createJSONForContactCreationInQualtrics() {

        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();

        if (caseObjInstance.Contact != null && String.isNotBlank(caseObjInstance.Contact.FirstName)) {
            gen.writeStringField('firstName', caseObjInstance.Contact.FirstName);
        }

        if (caseObjInstance.Contact != null && String.isNotBlank(caseObjInstance.Contact.LastName)) {
            gen.writeStringField('lastName', caseObjInstance.Contact.LastName);
        }

        if (caseObjInstance.Contact != null && String.isNotBlank(caseObjInstance.Contact.Email)) {
            gen.writeStringField('email', caseObjInstance.Contact.Email);
        }
        if (caseObjInstance.Contact != null && String.isNotBlank(caseObjInstance.Contact.Phone)) {
            gen.writeStringField('phone', caseObjInstance.Contact.Phone);
        }
        if (String.isNotBlank(caseObjInstance.Id)) {
            gen.writeStringField('extRef', caseObjInstance.Id);
        }

        gen.writeStringField('language', 'en/US');
        gen.writeStringField('unsubscribed', 'false');

        gen.writeFieldName('embeddedData');
        gen.writeStartObject();

        if (String.isNotBlank(caseObjInstance.casenumber)) {
            gen.writeStringField('casenumber', caseObjInstance.casenumber);
        }
        if (String.isNotBlank(caseObjInstance.case_owner_name__c)) {
            gen.writeStringField('case_owner_name__c', caseObjInstance.case_owner_name__c);
        }
        if (String.isNotBlank(String.valueOf(caseObjInstance.date_time_completed__c))) {
            gen.writeStringField('date_time_completed__c', String.valueOf(caseObjInstance.date_time_completed__c));
        }
        if (String.isNotBlank(caseObjInstance.subject)) {
            gen.writeStringField('subject', caseObjInstance.subject);
        }
        if (String.isNotBlank(caseObjInstance.country__c)) {
            gen.writeStringField('country__c', caseObjInstance.country__c);
        }
        if (String.isNotBlank(caseObjInstance.region__c)) {
            gen.writeStringField('region__c', caseObjInstance.region__c);
        }
        if (String.isNotBlank(caseObjInstance.category__c)) {
            gen.writeStringField('category__c', caseObjInstance.category__c);
        }
        if (String.isNotBlank(caseObjInstance.district__c)) {
            gen.writeStringField('district__c', caseObjInstance.district__c);
        }
        if (String.isNotBlank(caseObjInstance.case_owner_role__c)) {
            gen.writeStringField('case_owner_role__c', caseObjInstance.case_owner_role__c);
        }
        if (String.isNotBlank(caseObjInstance.accountid)) {
            gen.writeStringField('accountid', caseObjInstance.accountid);
        }
        if (String.isNotBlank(caseObjInstance.contactid)) {
            gen.writeStringField('contactid', caseObjInstance.contactid);
        }
        if (String.isNotBlank(caseObjInstance.svmxc__component__c)) {
            gen.writeStringField('svmxc__component__c', caseObjInstance.svmxc__component__c);
        }
        if (String.isNotBlank(caseObjInstance.svmxc__product__c)) {
            gen.writeStringField('svmxc__product__c', caseObjInstance.svmxc__product__c);
        }
        if (String.isNotBlank(caseObjInstance.case_owner_s_manager_email__c)) {
            gen.writeStringField('case_owner_s_manager_email__c', caseObjInstance.case_owner_s_manager_email__c);
        }
        if (String.isNotBlank(String.valueOf(caseObjInstance.ivd_product_identifier__c))) {
            gen.writeStringField('ivd_product_identifier__c', String.valueOf(caseObjInstance.ivd_product_identifier__c));
        }
        if (String.isNotBlank(String.valueOf(caseObjInstance.ivd_product_identifier_additional_prod__c))) {
            gen.writeStringField('ivd_product_identifier_additional_prod__c', String.valueOf(caseObjInstance.ivd_product_identifier_additional_prod__c));
        }
        if (String.isNotBlank(caseObjInstance.case_owner_manager__c)) {
            gen.writeStringField('case_owner_manager__c', caseObjInstance.case_owner_manager__c);
        }
        if (String.isNotBlank(caseObjInstance.contact.phone)) {
            gen.writeStringField('contactphone', caseObjInstance.contact.phone);
        }
        if (String.isNotBlank(caseObjInstance.id)) {
            gen.writeStringField('id', caseObjInstance.id);
        }
        if (String.isNotBlank(caseObjInstance.product_group__c)) {
            gen.writeStringField('product_group__c', caseObjInstance.product_group__c);
        }
        if (String.isNotBlank(caseObjInstance.ownerid)) {
            gen.writeStringField('ownerid', caseObjInstance.ownerid);
        }
        gen.writeEndObject();

        gen.writeEndObject();

        String strJson = gen.getAsString();
        System.debug(LoggingLevel.INFO, 'JSON Output:\n' + strJson);
        return strJson;

    }

    /** @DESCRIPTION - deserializeCreateContactAPIResponse **/
    public static void deserializeCreateContactAPIResponse(string createContactJSONResponse) {
        QualtricsAPICreateContactResponse qualtricsCreateContactResponse = QualtricsAPICreateContactResponse.parse(createContactJSONResponse);
        system.debug('qualtricsCreateContactResponse.Result.id == ' + qualtricsCreateContactResponse.Result.id);
        contactQualtricsId = qualtricsCreateContactResponse.meta.httpStatus == HTTP_STATUS_CODE_OKAY ? qualtricsCreateContactResponse.result.id : 'Error fetching Contact Id from Qualtrics.';
    }



    /**                     CALLOUT 1 - CREATE CONTACT API - END            **/


    /**                     CALLOUT 2 - CREATE DISTRIBUTION API - START          **/

    /** @DESCRIPTION - 2nd callout - make 2nd callout to create distribution id in qualtrics.**/
    public static void createDistributionLinksInQualtrics() {

        HttpResponse response;

        //map to send api key in header
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer ' + qualtricsAccessToken,
            'Content-Type' => APPLICATION_JSON,
            'Content-Length' => '512'
        };

        //prepare post body to create DISTRIBUTION in qualtrics.
        string createDistributionJSONBody = createJSONForDistributionInQualtrics();

        //register create DISTRIBUTION api inbound interface log
        ilib_RestInterface.InterfaceDetails intDetailsInbound = new ilib_RestInterface.InterfaceDetails(QUALTRICS_INBOUND, INBOUND, QUALTRICS_CREATE_DISTRIBUTION_INBOUND);

        //make create DISTRIBUTION api callout
        HttpRequest request = createHttpRequest(HTTP_METHOD_POST, headerKeyToValue, createDistributionJSONBody, QUALTRICSMIDENDPOINGSTR);

        //store create DISTRIBUTION api salesforce json.
        log = ilib_LogInterface.initiateLog(intDetailsInbound, JSON.serializePretty(JSON.deserializeUntyped(createDistributionJSONBody)));

        response = !Test.isRunningTest() ? UtilsRest.send(request) : MockHTTPCalloutQualtricsAPI.respondMock(STRING_AUTH);
        //response = UtilsRest.send(request);

        //insert create DISTRIBUTION api interface log record.
        lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_SUCCESS, createDistributionJSONBody, caseObjInstance.Id, response));
        //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, createDistributionJSONBody, caseObjInstance.Id);

        //register create DISTRIBUTION api outbound interface log
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(QUALTRICS_OUTBOUND, OUTBOUND, QUALTRICS_CREATE_DISTRIBUTION_OUTBOUND);

        //if create DISTRIBUTION api returned success, store the qualtrics DISTRIBUTION id.
        if (response.getStatusCode() == UtilsRest.REST_SUCCESS) {
            String strJsonInput = response.getBody();

            system.debug('JSON Res' + strJsonInput);
            log = ilib_LogInterface.initiateLog(intDetails, JSON.serializePretty(JSON.deserializeUntyped(strJsonInput)));
            try {
                if (String.isBlank(strJsonInput))
                    throw new UtilsRest.InterfaceException('Input JSON is missing');

                //store create DISTRIBUTION api outbound response.    
                lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_SUCCESS, strJsonInput + response.getStatusCode(), caseObjInstance.Id, response));
                //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, strJsonInput + response.getStatusCode(), caseObjInstance.Id);

                deserializeDistributionAPIResponse(strJsonInput);

            } catch (Exception e) {
                System.debug('@@@ Exception happened, details here: ' + e);
                ApexExceptions.emit('QualtricsAPISurveyLinkReader distribution api ', e);
                system.debug('Rest Error: ' + e);
                //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_Fail, strJsonInput + response.getStatusCode(), caseObjInstance.Id);
                lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_FAIL, strJsonInput + response.getStatusCode(), caseObjInstance.Id, response));
            }
        } else {

            log = ilib_LogInterface.initiateLog(intDetails, JSON.serializePretty(JSON.deserializeUntyped(response.getBody())));
            //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, response.getBody() + response.getStatusCode(), caseObjInstance.Id);
            lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), caseObjInstance.Id, response));

        }


    }

    /** @DESCRIPTION - 2nd callout - create raw json body to create distribution id in qualtrics. **/
    public static String createJSONForDistributionInQualtrics() {

        QualtricsAPISurveyLinkReader.CreateDistributionInQualtricsWrapper createDistributionInQualtricsWrap = new QualtricsAPISurveyLinkReader.CreateDistributionInQualtricsWrapper();

        String strJson = JSON.serializePretty(createDistributionInQualtricsWrap);
        System.debug(LoggingLevel.INFO, 'Distribution JSON Output:\n' + strJson);
        return strJson;

    }

    /** @DESCRIPTION - 2nd callout - deserialize response to extract distribution Id. **/
    public static void deserializeDistributionAPIResponse(string createContactJSONResponse) {
        //response is same as createContact api response json.
        QualtricsAPICreateContactResponse qualtricsCreateContactResponse = QualtricsAPICreateContactResponse.parse(createContactJSONResponse);
        system.debug('distributionLinkQualtricsId == ' + qualtricsCreateContactResponse.Result.id);
        distributionLinkQualtricsId = qualtricsCreateContactResponse.meta.httpStatus == HTTP_STATUS_CODE_OKAY ? qualtricsCreateContactResponse.result.id : 'Error fetching Distribution Id from Qualtrics.';
    }

    /** @DESCRIPTION - Wrapper class for 2nd callout - create raw json body to create distribution in qualtrics directory. **/
    public class CreateDistributionInQualtricsWrapper {
        public string surveyId = Label.Qualtrics_Survey_ID;
        public string linkType = 'Individual';
        public string description = 'distribution ' + Date.today();
        public string action = 'CreateDistribution';
        public string expirationDate = String.valueOf(Date.today().addMonths(6)) + ' 00:00:00';
        public string mailingListId = Label.Qualtrics_MailingList_ID;

    }

    /**                     CALLOUT 2 - CREATE DISTRIBUTION API - END            **/


    /**                     CALLOUT 3 - GET SURVEY LINK API - START          **/

    /** @DESCRIPTION - 3rd callout - get survey link from qualtrics. **/
    public static void getSurveyLinksFromQualtrics(String nextPageURL) {

        HttpResponse response;
        HttpRequest request;
        System.debug('qualtricsAccessToken ' + qualtricsAccessToken);
        //map to send api key in header
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'authorization' => 'bearer ' + qualtricsAccessToken
        };

        //make get survey link api callout-if contact found in first page
        if(nextPage == false){
            request = createHttpRequest(HTTP_METHOD_GET, headerKeyToValue, '', QUALTRICSMIDENDPOINGSTR + distributionLinkQualtricsId + '/links?surveyId=' + Label.Qualtrics_Survey_ID);
        }
        else{
            request = createHttpRequest(HTTP_METHOD_GET, headerKeyToValue, '', nextPageURL);
        }
        

        response = UtilsRest.send(request);

        //register get survey link api outbound interface log
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(QUALTRICS_OUTBOUND, OUTBOUND, QUALTRICS_GET_SURVEY_LINK_OUTBOUND);

        //if survey link api returned success, store the qualtrics survey link id.
        if (response.getStatusCode() == UtilsRest.REST_SUCCESS) {
            String strJsonInput = response.getBody();

            system.debug('JSON Res' + strJsonInput);
            log = ilib_LogInterface.initiateLog(intDetails, JSON.serializePretty(JSON.deserializeUntyped(strJsonInput)));
            try {
                if (String.isBlank(strJsonInput))
                    throw new UtilsRest.InterfaceException('Input JSON is missing');

                //store survey link api  outbound response.
                //INC0500807
                Interface_Log__c objInterfaceLog = ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_SUCCESS, strJsonInput + response.getStatusCode(), caseObjInstance.Id, response);
                lstInterfaceLog.add(objInterfaceLog);
                //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, strJsonInput + response.getStatusCode(), caseObjInstance.Id);

                deserializeSurveyLinkAPIResponse(strJsonInput, objInterfaceLog.Id);

            } catch (Exception e) {
                System.debug('@@@ Exception happened, details here: ' + e);
                ApexExceptions.emit('QualtricsAPISurveyLinkReader survey link api ', e);
                system.debug('Rest Error: ' + e);
                //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_Fail, strJsonInput + response.getStatusCode(), caseObjInstance.Id);
                lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_FAIL, strJsonInput + response.getStatusCode(), caseObjInstance.Id, response));
            }
        } else {
            system.debug('Error fetching survey link == ' + response.getBody());
            log = ilib_LogInterface.initiateLog(intDetails, JSON.serializePretty(response.getBody()));
            lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log, ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), caseObjInstance.Id, response));
            //ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, response.getBody() + response.getStatusCode(), caseObjInstance.Id);

        }


    }


    /** @DESCRIPTION - 3rd callout - deserialize response to extract survey link. **/
    public static void deserializeSurveyLinkAPIResponse(string createContactJSONResponse, Id interfaceLogId) {
        //response is same as survey link api response json.
        QualtricsAPISurveyLinkResponse qualtricsSurveyLinkResponse = QualtricsAPISurveyLinkResponse.parse(createContactJSONResponse);
        Map < String, String > contactIdToSurveyLinkMap = new Map < String, String > ();
        String nextPageLink = '';
        //get the list of elements 
        if (qualtricsSurveyLinkResponse.meta.httpStatus == HTTP_STATUS_CODE_OKAY) {
            if (qualtricsSurveyLinkResponse.result.elements != null && !qualtricsSurveyLinkResponse.result.elements.isEmpty()) {
                nextPageLink = qualtricsSurveyLinkResponse.result.nextPage;
                for (QualtricsAPISurveyLinkResponse.Elements qualtricsResp: qualtricsSurveyLinkResponse.result.elements) {
                    contactIdToSurveyLinkMap.put(qualtricsResp.contactId, qualtricsResp.link);
                }
            }
        }

        //INC0500807
        //get survey link for contacts
        if(contactIdToSurveyLinkMap.containsKey(contactQualtricsId)){
            surveyLinkQualtricsId = contactIdToSurveyLinkMap.get(contactQualtricsId);
        }
        //if not found, check on next page by making a callout to the enpoint received in 'nextpage' attribute
        else{
            if(nextPageLink != null){
                nextPage = true;
                nextPageLink = nextPageLink.replace(qualtricsBaseEndpointUrl,'');
                getSurveyLinksFromQualtrics(nextPageLink);
                nextPage = false;
            }
            else{
                //no contact found error, store Exception log
                ApexExceptions.emit('QualtricsAPISurveyLinkReader survey link api ', interfaceLogId ,'Error fetching Survey Link from Qualtrics. Link not found. ', 'Service');
            }
        }
        system.debug('surveyLinkQualtricsId ' + surveyLinkQualtricsId);
    }



    /**                     CALLOUT 3 - GET SURVEY LINK API - END            **/

    /**                     SEND WECHAT MESSAGE - START                      **/

    /** @DESCRIPTION - Send survey link as a weChat message. **/
    public static void sendWeChatMessageToContact() {

        List < Charket.CharketSendWeChatNotificationAction.SendTemplateNotificationRequest > requests = new List < Charket.CharketSendWeChatNotificationAction.SendTemplateNotificationRequest > ();

        Charket.CharketSendWeChatNotificationAction.SendTemplateNotificationRequest request = new Charket.CharketSendWeChatNotificationAction.SendTemplateNotificationRequest();

        request.templateId = Label.WeChat_Notification_Template_ID; //[Select Id from EmailTemplate where name = 'Charket - WeChat Message With Survey Link'].Id; // templateId refers to the WeChat Notification Template ID to be used

        request.whoId = caseObjInstance.WeChatFollower__c; // Use the Lead or Contact ID that is related to the WeChat Follower

        request.objectId = caseObjInstance.Id; // use the record ID where the merge fields reside in

        requests.add(request);

        Charket.CharketSendWeChatNotificationAction.sendTemplateNotification(requests);

        //DCP-49913 Enhance sending the same survey link via both Email and WeChat
        List<Case> caseListForEmail = new List<Case> {caseObjInstance};
        SendEmailWithSurveyLink_CaseHelper.sendEmailWithSurveyLink(caseListForEmail);

    }

}