/**
*    @author Vishnu Priya Duggineni
*    @date   
*    @description 
*    Test class for 90% coverage: 
*    Test class for 75% coverage: TestScheduledBatchSailPointUserSync (As of Sep 08, 22 - 87%) 
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Vishnu Priya Duggineni                             Initial Version
*           Satya Swain                  18-Feb-2021           INC0307308: Adding fixes for nullpointer exceptions for User data
*           Joshith K                    11-March-2021         TASK0573387: Added Unique_Id__c mapping.
*           Nishan Shetty                24-May-2022           Ilib Batch Deferrable Implementation.
*           Rucha Dalvi                  05-July-2022          Codescan Fix : Duplicate literals
*           Atit Kar                     08-Sep-2022           INC0419648 - Adding super keyword in no-arg constructor for best practice.
*           Prem Ranjan                  16-12-1022            POL-268 Sailpoint Integration Update
*           Nishan Shetty                24-Jan-2023           POL-862 - Truncate Title Exceeding 80 Charaters.
--------------------------------------------------------------------------------------------------------------------------------------------
**/
global with sharing class ScheduledBatchSailPointUserSync extends ilib_BatchDeferrable implements Database.AllowsCallouts {

    private final static String SOURCE = 'ScheduledBatchSailPointUserSync';
    public static final String STRING_LABEL_SAILPOINT = 'SailPoint_UserUpdate';
    public static final String STRUSERTYPE = 'Standard';
    public static final String STRING_LABEL_DECIMAL = 'Decimal';
    public static final String STRING_LABEL_GREATER_CHINA = 'GC';
    public static final String STRING_LABEL_TITLE ='Title';//POL-862.
    public static final Integer INTEGER_EIGHTY = 80;//POL-862.

    
    //Codescan Fix - Duplicate literals
    public static final String STRING_LABEL_STRING = 'String';

    private static List<UserWrapper.UserFieldUpdates> wrapUserList;
    private static Map<String, User> fedIdToUser;

    public Boolean isUserCreated = false;
    private Set<Id> userIds;

    global Integer recordsProcessed = 0;
    global Map<String, List<String>> fedIdToEmailHtml = new Map<String, List<String>>();
    
    //DCP-50962
    private Inputs inputs;
    
   /*
    *  @Author      : Nishan Shetty DCP-50962
    *  @Description : Parameter wrapper for easy serialization
    */
    public class Inputs {
        public Set<Id> setUserIds;
        
        /**
        * @author illumina
        * @description 
        */
        public Inputs(Set<Id> userIds) {
            this.setUserIds = userIds;
            
        }
    }

    /**
    *   @description: constructor
    **/
    global ScheduledBatchSailPointUserSync() {
        super();    //INC0419648
     }
    /**
    *   @description: constructor
    **/
    global ScheduledBatchSailPointUserSync(Set<Id> userIds) { 
       super();
       this.isUserCreated = true;
       this.inputs = new Inputs(userIds);
       this.userIds = inputs.setUserIds;
    }

    /**
    *   @description: start method for Batch class
    **/
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        String strSoql = 'SELECT Id, Name, FirstName, LastName, Email, Title, Department, EmployeeNumber, Division, Functional_Area__c, '
            + ' Cost_Center__c, FederationIdentifier, ManagerId, Region__c,AD_UserName__c,Manager_Name__c, Manager_Email__c, CreatedDate, Phone,Unique_Id__c FROM user WHERE IsActive = true and userType = :STRUSERTYPE';
        
        if (isUserCreated) {
            strSoql += ' AND Id IN :userIds';
        }
            
        if(Test.isRunningTest()) {
            strSoql += ' LIMIT 50';
        }
           
        return Database.getQueryLocator(strSoql);
    }
    /**
    *   @description: execute method for Batch class
    **/
    global override void execute(Database.BatchableContext bc, List<Sobject> records) {
        ilib_LogEvent.setBatchTitle(SOURCE, transactionId);
        ilib_LogEvent.push(SOURCE+'.execute');        
        //String strRestError = null;
        fedIdToUser = getFedIdToUser(records);
        ilib_LogEvent.message('@@@@ inside execute method, value of fedIdToUser:'+fedIdToUser);
        List<String> lstFedIds = new List<String>(fedIdToUser.keySet());

        Http sailpointHttp = new Http();
        Map<String, String> strTostrconfig = UtilsRest.getIntegrationEndpoint(STRING_LABEL_SAILPOINT);
        String sailpointURL = strTostrconfig.get('Endpoint') +'\'' +string.join(lstFedIds, '\',\'')+'\'';
        ilib_LogEvent.message('sailpointURL IN :'+sailpointURL);

        HttpResponse sailpointResponse;
        if(!Test.isRunningTest())
        {
        sailpointResponse = sailpointHttp.send(UtilsRest.createHttpRequest(sailpointURL, strTostrconfig.get('ApiKey'), '', strTostrconfig.get('Header Token'), 'GET'));
        }
        else {
            sailpointResponse = new MockSailPointConnector().respond(new HTTPRequest());
        }
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails('ScheduledBatchSailPointUserSync', 'Outbound', 'User');
        ilib_LogInterface.LogDetails log;

        if (sailpointResponse.getStatusCode() == UtilsRest.REST_SUCCESS) {
            String strJsonInput = sailpointResponse.getBody();
            ilib_LogEvent.message('JSON Res'+strJsonInput);
            log = ilib_LogInterface.initiateLog(intDetails, JSON.serializePretty(JSON.deserializeUntyped(strJsonInput)));
            try {
                if (String.isBlank(strJsonInput))
                    throw new UtilsRest.InterfaceException('Input JSON is missing');

                deserializeInputs(strJsonInput);
                upsertIncomingValuesImpl();
            }catch (Exception e) {
                ilib_LogEvent.message('@@@ Exception happened, details here:'+strJsonInput);
                ApexExceptions.emit('ScheduledBatchSailPointUserSync', e);
                ilib_LogEvent.message('Rest Error:'+e);
            }
        } else {
            log = ilib_LogInterface.initiateLog(intDetails, JSON.serializePretty(JSON.deserializeUntyped(sailpointResponse.getBody())));
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *   @description: finish method for Batch class
    **/
    global override void finish(Database.BatchableContext bc)
    {  
        ilib_LogEvent.setBatchTitle(SOURCE, transactionId);
        ilib_LogEvent.push(SOURCE+'.finish');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String strEmailCondition = 'Sailpoint_Update_Distibution_List';

        Send_Email_Setting__mdt objSendEmailSetting = [Select To_Address_Fields__c, Additional_To_Addresses__c from Send_Email_Setting__mdt Where DeveloperName = :strEmailCondition];
        
        List<String> toAddresses = new List<String>();
        toAddresses.add(objSendEmailSetting.To_Address_Fields__c);
        toAddresses.add(objSendEmailSetting.Additional_To_Addresses__c);

        mail.setToAddresses(toAddresses);
        mail.setSubject('Sail Point User Sync ' + job.Status);
        mail.setHtmlBody(getTableBody(fedIdToEmailHtml));
        if(!Test.isRunningTest())
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { mail });
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *   @description: execute method for Schedulable class
    **/
    public override void execute(SchedulableContext sc) {
        ilib_BatchManager.executeBatch(new ScheduledBatchSailPointUserSync(),80); //DCP-50962
    }   
    /**
    *  @description get Map of Federation Id to User records
    **/
    global static Map<String, User> getFedIdToUser(List<User> scope) {
        //Boolean isActive = true;
        fedIdToUser = new Map<String, User>();

        for (User activeUser : scope)
            if (activeUser.FederationIdentifier != null)
                fedIdToUser.put(activeUser.FederationIdentifier, activeUser);

        return fedIdToUser;
    }
    

    /**
    *  @description method to parse the response received from SailPoint
    **/
    global static void deserializeInputs(String jsonInput)
    {
        wrapUserList = UserWrapper.parse(jsonInput).Table;
    }
    /**
    *  @description method to check if any user attribute has changed or not
    **/
    global Boolean userAttributeChanged(User orgUser, String sailPointValue, String userField)
    {
        return (!String.isBlank(sailPointValue) && !sailPointValue.equals(String.valueOf(orgUser.get(userField))));
    }
    /**
    *  @description method to set values to user fields
    **/
    global void setUserAttribute(User upadateUser, String sailPointValue, String userField, String dataType)
    {
        if(String.isNotBlank(dataType) && STRING_LABEL_DECIMAL.equals(dataType)) {
            upadateUser.put(userField, Decimal.valueOf(sailPointValue));
        }else if(sailPointValue!=null && sailPointValue.length()>INTEGER_EIGHTY && userField == STRING_LABEL_TITLE) { //Start POL-862
            upadateUser.put(userField,sailPointValue.substring(0,INTEGER_EIGHTY));
        } else {//END POL-862
           upadateUser.put(userField, sailPointValue);
        }
    }
    /**
    *  @description method to process user atrributes
    **/
    public Boolean processUserAttribute(User upadateUser, User orgUser, String sailPointValue, String userField, List<String> emailHtmlBody, String dataType)
    {

        if(String.isNotBlank(sailPointValue) && STRING_LABEL_GREATER_CHINA.equals(sailPointValue))
            sailPointValue = 'China';
        if (!(userAttributeChanged(orgUser, sailPointValue, userField))) return false;

        setUserAttribute(upadateUser, sailPointValue, userField, dataType);
        addToOutputMap(orgUser, sailPointValue, userField, emailHtmlBody);
        return true;
    }
    /**
    *  @description method to prepare HTML body of outgoing email
    **/
    global void addToOutputMap(User orgUser, String sailPointValue, String userField, List<String> emailHtmlBody)
    {
        emailHtmlBody.add('<td> <a href="'+ URL.getSalesforceBaseUrl().toExternalForm() + '/'+ orgUser.Id + '">' + orgUser.Name + '</a></td>');
        emailHtmlBody.add('<td>' + userField + '</td>');
        emailHtmlBody.add('<td>' + String.valueOf(orgUser.get(userField)) + '</td>');
        emailHtmlBody.add('<td>' + sailPointValue + '</td></tr>');
    }
    /**
    *  @description method to process cost center value
    **/
    public String processCostcenterValue(String strCostCenterSailPoint){
        String maskZeros = '00000';
        for (integer i=4; i>0; i--){
            maskZeros= maskZeros.removeend('0');
            if(strCostCenterSailPoint.right(i) == maskZeros)
                strCostCenterSailPoint= strCostCenterSailPoint.removeEnd(maskZeros);
        }
        return strCostCenterSailPoint;
    }
    /**
    *  @description method to upsert user data
    **/
    global void upsertIncomingValuesImpl()
    {   ilib_LogEvent.push(SOURCE+'upsertIncomingValuesImpl');
        List<User> lstUpdatedUser= new List<User>();
        Boolean isSandbox = runningInASandbox();   
        string phoneSailpoint = '';     

        if (wrapUserList== null) return;
        ilib_LogEvent.message('@@@@ wrapUserList-> :'+wrapUserList);
        ilib_LogEvent.message('@@@@ fedIdToUser -> :'+fedIdToUser);
        for (UserWrapper.UserFieldUpdates wrpuser : wrapUserList) 
        {
            Boolean isChanged = false;
            List<String> emailHtmlBody = new List<String>();
            if(!fedIdToUser.containsKey(wrpuser.EMPLOYEEIDORIGINAL)) continue;
            User upadateUser = new User();
            User orgUser = fedIdToUser.get(wrpuser.EMPLOYEEIDORIGINAL);
            ilib_LogEvent.message('@@@ inside for loop, value of orgUser: '+orgUser);
            ilib_LogEvent.message('@@@ inside for loop, value of wrpuser: '+wrpuser);
            upadateUser.Id = orgUser.Id;

            upadateUser.FederationIdentifier = orgUser.FederationIdentifier;
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.PREFERRED_FIRST_NAME, 'FirstName', emailHtmlBody, STRING_LABEL_STRING) || isChanged;
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.PREFERRED_LAST_NAME, 'LastName', emailHtmlBody, STRING_LABEL_STRING) || isChanged;
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.JOB_TITLE,STRING_LABEL_TITLE, emailHtmlBody, STRING_LABEL_STRING) || isChanged;//POL-862
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.DEPARTMENT_NAME, 'Department', emailHtmlBody, STRING_LABEL_STRING) || isChanged;
            if(!isSandbox && !wrpuser.EMAIL.equalsIgnoreCase('noreply@illumina.com'))
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.EMAIL.toLowerCase(), 'Email', emailHtmlBody, STRING_LABEL_STRING) || isChanged;
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.COSTCENTER_NAME, 'Division', emailHtmlBody, STRING_LABEL_STRING) || isChanged;
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.EMP_ID, 'EmployeeNumber', emailHtmlBody, STRING_LABEL_STRING) || isChanged;
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.WD_USER_NAME, 'AD_UserName__c', emailHtmlBody, STRING_LABEL_STRING) || isChanged;
            isChanged = processUserAttribute(upadateUser, orgUser, processCostcenterValue(wrpuser.COSTCENTER_NUMBER), 'Cost_Center__c', emailHtmlBody, STRING_LABEL_DECIMAL) || isChanged;
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.FUNCTIONAL_AREA, 'Functional_Area__c', emailHtmlBody, STRING_LABEL_STRING) || isChanged;
            isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.REGION, 'Region__c', emailHtmlBody, 'Picklist') || isChanged;
            

            if(isUserCreated) //Update Phone only on create
            {
                if(!string.isBlank(wrpuser.DESK_COUNTRY_CODE) && !string.isBlank(wrpuser.DESK_AREA_CODE))
                    phoneSailpoint = '+' +wrpuser.DESK_COUNTRY_CODE+ ' (' +wrpuser.DESK_AREA_CODE+ ') ' +wrpuser.DESK_PHONE_ONLY;
                isChanged = processUserAttribute(upadateUser, orgUser, phoneSailpoint, 'Phone', emailHtmlBody, 'Phone') || isChanged;
            }
            
            //logic to update manager Id
            // null check added if manager email is NULL
            if(String.isBlank(wrpuser.MANAGER_EMAIL))
            {
                if(String.isNotBlank(orgUser.Manager_Email__c))
                {
                    isChanged = true;
                    upadateUser.ManagerId = NULL;
                    addToOutputMap(orgUser, '', 'Manager_Name__c', emailHtmlBody);
                }
            }
            else
            {
                if(userAttributeChanged(orgUser, isSandbox ? wrpuser.MANAGER_EMAIL.toLowerCase()+'.invalid'  : wrpuser.MANAGER_EMAIL.toLowerCase(), 'Manager_Email__c'))
                {
                    List<User> managerId = new UsersSelector().getManagerId(wrpuser.MANAGER_OID, isSandbox ? wrpuser.MANAGER_EMAIL+'.invalid' : wrpuser.MANAGER_EMAIL);
                    ilib_LogEvent.message('@@@ managerId '+managerId);
                    if(!managerId.IsEmpty())
                    {
                        isChanged = true;
                        upadateUser.ManagerId = managerId[0].Id;
                        addToOutputMap(orgUser, wrpuser.MANAGER, 'Manager_Name__c', emailHtmlBody);
                    }
                }
            }
            // check for null value in response
            if(String.isBlank(wrpuser.UNIQUE_ID))
            {
                if(String.isNotBlank(orgUser.Unique_Id__c))
                {
                    isChanged = true;
                    upadateUser.Unique_Id__c = NULL;
                    addToOutputMap(orgUser, '', 'Unique_Id__c', emailHtmlBody);
                }
            }else {
                isChanged = processUserAttribute(upadateUser, orgUser, wrpuser.UNIQUE_ID, 'Unique_Id__c', emailHtmlBody, STRING_LABEL_STRING) || isChanged; 
            }

            if (isChanged)
            {
                lstUpdatedUser.add(upadateUser);  
            }
            fedIdToEmailHtml.put(upadateUser.FederationIdentifier, emailHtmlBody);
            recordsProcessed = recordsProcessed + 1;
        }
        ilib_LogEvent.message('@@@@ lstUpdatedUser: '+lstUpdatedUser);

        if (!lstUpdatedUser.isEmpty())
            update lstUpdatedUser;

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *  @description method to check if org is a sandbox
    **/
    public static Boolean runningInASandbox() {
        return !Organizations.isProductionUsingConstant();
    }
    /**
    *  @description method to prepare HTML table in outgoing email
    **/
    public static string getTableBody(Map<String, List<String>> changedValuesUser)
    {
        String htmlBody = '<table border="1" style="border-collapse: collapse">'
            + '<caption><b>User Field Updates</b></caption><br/><br/>'
            + '<tr><th>Record Id</th><th>Changed Field</th><th>Before Value</th><th>After Value</th></tr>';

        if(changedValuesUser.isEmpty()) return 'No Updates from Sailpoint';
        for (String idValue : changedValuesUser.keyset())
        {
            htmlBody += '<tr>';            
            for (String str : changedValuesUser.get(idValue))
            {
                htmlBody +=  str;
            }
            htmlBody += '</tr>';
        }
        htmlBody += '</table>';

        return htmlBody;    
    }
    
    //DCP-50962
     // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************
    
    /*
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs()
    {
        return JSON.serialize(inputs);
    }

    /*
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs)
    {
        this.inputs = (ScheduledBatchSailPointUserSync.Inputs)JSON.deserialize(serializedInputs, ScheduledBatchSailPointUserSync.Inputs.class);
    }

}