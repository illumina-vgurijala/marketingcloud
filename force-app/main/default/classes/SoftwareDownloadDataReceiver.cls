/***************************************************************************************************************************************
* NAME         : SoftwareDownloadDataReceiver
* DESCRIPTION  : SoftwareDownload Synchronization to SFDC
* @AUTHOR      : Joshith K
* @DATE        : 19-Aug-2019
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Joshith K             19-AUG-2019        for DCP-27213, Initial Version
  Nesar Mohan           04-Apr-2022        Codescan Fix
****************************************************************************************************************************************/
@RestResource(urlMapping = '/SoftwareDownloadSyncInterface/*')
global with sharing class SoftwareDownloadDataReceiver extends ilib_RestReceiver {
    global static final Integer REST_ERROR = 412;
    global static Boolean boolCustomError=false;
    private static List<SoftwareDownloadDataReceiverWrapper> wrapSfwDownloads;
   
    /*
    *  @Author      : Joshith k
    *  @Description : Post Method to upsert the incoming values
    *  @Param       : None
    *  @Return      : void
    */

@HttpPost
    global static void upsertIncomingValues(){
        // get the (non-static context) details
        
        
        SoftwareDownloadDataReceiver instantiated = new SoftwareDownloadDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);
        String strRestError = null;
        Id primaryRecordId;
        String erpCustomerId;

        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

       try
       {
            //if there is no body found, throw an error.
        if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, wrapSfwDownloads);

             insertIncomingValuesImpl();
          
             }
        catch (Exception e)
        {
            //strRestError = UtilsRest.handleCustomRestError(e);
            strRestError =handleCustomSoftwareRestError(e);
        }

        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );
     
        if (!isSuccess)
        {
            
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
            /*
            ilib_LogEvent.quickEmit(
                interfaceDetails.name + ' failed',
                new Map<String, String> { 'Error Description' => strRestError }
            );*/
        }
        
        ilib_LogEvent.emit();

    }

    /*
    *  @Author      : Joshith k
    *  @Description : Method to deserialize the json input
    *  @Param       : String
    *  @Return      : void
    */

    private static void deserializeInputs(String jsonInput)
    {
        
        wrapSfwDownloads = (List < SoftwareDownloadDataReceiverWrapper> ) System.JSON.deserialize(jsonInput, List<SoftwareDownloadDataReceiverWrapper>.class);
        
    }

    /*
    *  @Author      : Joshith k
    *  @Description : Method to insert incoming values
    *  @Param       : None
    *  @Return      : void
    */

    private static void  insertIncomingValuesImpl(){
        Set<String>setEmailIds= new Set<String>();
       
        Map<String,SObject> mapParentIdsForSftwDownload=new Map<String,SObject>();// Map of sobject  having Software Download childs size>0
        
        Schema.SObjectType contactType = Schema.Contact.getSObjectType();
        List<Software_Download__c>lstSwDownload=new List<Software_Download__c>();
      
        for (SoftwareDownloadDataReceiverWrapper objWrapper : wrapSfwDownloads) {
            
            if(String.isNotBlank(objWrapper.Email_Address)){
                setEmailIds.add(objWrapper.Email_Address);
               // setEmailIdsNotInContact.add(objWrapper.Email_Address.toLowerCase());
                objWrapper.Email_Address=objWrapper.Email_Address.toLowerCase();
                //setEmailIdsNotInContact.add(objWrapper.Email_Address);
            }
            
        }

        for(Contact objCon:new ContactsSelector().selectContactsWithSftwDwnldByEmail(setEmailIds)){
            string contactkey=objCon.Email.toLowerCase();
            if(!mapParentIdsForSftwDownload.containsKey(contactkey)){
                mapParentIdsForSftwDownload.put(contactkey,objCon);
            }else if(!objCon.Software_Downloads__r.isEmpty()){
                mapParentIdsForSftwDownload.put(contactkey, objCon);
            }
             
                    
                
        }
         
        // remove emails existing in Contact Maps from Master Email Set to find Email Ids Without Contact
        setEmailIds.removeAll(mapParentIdsForSftwDownload.keySet());
        
      
        // Search in Leads for email which is not available in contact
        for(Lead objLead:new LeadsSelector().selectLeadsWithSftwDwnldByEmail(setEmailIds)){
            string leadkey=objLead.Email.toLowerCase();
            if(!mapParentIdsForSftwDownload.containsKey(leadkey)){
                mapParentIdsForSftwDownload.put(leadkey, objLead);
            }else if(!objLead.Software_Downloads__r.isEmpty()){
                mapParentIdsForSftwDownload.put(leadkey, objLead);
            }        
            
        }
       
        // insert software download records finding the Best Lead/Contact form the Above Maps
        //mapParentIdsForSftwDownload,mapIdsLatestModified,mapLeadWithSftwDownload,mapLeadWithEmailIds
     
        for (SoftwareDownloadDataReceiverWrapper objWrapper : wrapSfwDownloads) {
         
          Software_Download__c objSoftwareDownload = new Software_Download__c();
            
            if(String.isNotBlank(objWrapper.Email_Address)){
              if(mapParentIdsForSftwDownload.containsKey(objWrapper.Email_Address)){
                    Sobject parent= mapParentIdsForSftwDownload.get(objWrapper.Email_Address);
                    objSoftwareDownload.First_Name__c=(String)parent.get('FirstName');
                    objSoftwareDownload.Last_Name__c=(String)parent.get('LastName');
                    if(mapParentIdsForSftwDownload.get(objWrapper.Email_Address).getSObjectType()==contactType){
                        objSoftwareDownload.Contact_Full_Name__c=(Id)parent.get('Id');
                        if(String.isNotEmpty((String)parent.get('MailingCountry'))){
                            objSoftwareDownload.Country__C=(String)parent.get('MailingCountry');
                                    
                        }else{
                            objSoftwareDownload.Country__C=(String)parent.get('Country_Local__c');
                        }

                    }else{
                        objSoftwareDownload.Lead_full_name__c=(Id)parent.get('Id');
                        if(String.isNotEmpty((String)parent.get('Country'))){
                            objSoftwareDownload.Country__C=(String)parent.get('Country');
                                            
                        }else{
                            objSoftwareDownload.Country__C=(String)parent.get('Country_Local__c');
                        }
                    }
                }else{
                    objSoftwareDownload.Country__C=objWrapper.Country;
                    objSoftwareDownload.First_Name__c=objWrapper.First_Name;
                    objSoftwareDownload.Last_Name__c=objWrapper.Last_Name;
                }
            }
               
            objSoftwareDownload.Software_Name__c=objWrapper.Software_Name;
            objSoftwareDownload.Email_Address__c=objWrapper.Email_Address;
            objSoftwareDownload.Platform_GUID__c=objWrapper.Platform_GUID;
            objSoftwareDownload.Software_File_URL__c=objWrapper.Software_File_URL;
            objSoftwareDownload.Software_Category__c=objWrapper.Software_Category;
            objSoftwareDownload.Software_Version__c=objWrapper.Software_Version;
            objSoftwareDownload.EULA_Version_Accepted__c=objWrapper.EULA_Version_Accepted;
            objSoftwareDownload.Software_Download_External_Id__c=objWrapper.Software_Download_ID;
            if (String.isNotBlank(objWrapper.EULA_Acceptance_Date)) {
                objSoftwareDownload.EULA_Acceptance_Date__c=dateTime.valueOf(objWrapper.EULA_Acceptance_Date.replace('T',' '));
                //objSoftwareDownload.EULA_Acceptance_Date__c=date.parse(date.valueOf(objWrapper.EULA_Acceptance_Date).format());
            }

            if (String.isNotBlank(objWrapper.Download_Date)) {
                objSoftwareDownload.Download_Date__c=dateTime.valueOf(objWrapper.Download_Date.replace('T',' '));
               // objSoftwareDownload.Download_Date__c=date.parse(date.valueOf(objWrapper.Download_Date).format());
        
            }
            
            lstSwDownload.add(objSoftwareDownload);
           // objSoftwareWork.registerUpsert(objSoftwareDownload);

        }
        
        Database.SaveResult[] srList=Database.insert(lstSwDownload,false);
      //objUnitOfWork.commitWork();
      
        List < Error_Details > listErrorDetails=new List <Error_Details>();
        integer i=0;
        for (Database.SaveResult sr : srList) {

            if (!sr.isSuccess()) {
  
            // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    Error_Details objErrors=new Error_Details();
                    
                    objErrors.Error_Message=err.getMessage();
                    objErrors.Error_Data=lstSwDownload[i].Software_Download_External_Id__c;
                    listErrorDetails.add(objErrors);
                    //strErrors=strErrors+err.getMessage();
                }
            }
            i++;
        }
        if(!listErrorDetails.isEmpty()){
            string strErrors=JSON.serialize(listErrorDetails);
            boolCustomError=TRUE;
           throw new UtilsRest.InterfaceException(strErrors);
        }
        
    }

    /*
    *  @Author      : Joshith k
    *  @Description : Method to handle the rest error
    *  @Param       : Exception
    *  @Return      : String
    */

     public static String handleCustomSoftwareRestError(Exception e)
    {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('Result', 'Error');
        if(boolCustomError){
            List <Error_Details > listErrorDetails=(List < Error_Details > ) System.JSON.deserialize(e.getMessage(), List<Error_Details>.class);
            gen.writeObjectField('ErrorDetail', listErrorDetails);
            
        }else {
            gen.writeStringField('ErrorDetail', e.getMessage());
           
        }
        
        gen.writeEndObject();
        
        RestContext.response.statusCode = REST_ERROR;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(gen.getAsString());
        String errMsg = e.getMessage() + '\n' + e.getStackTraceString();
       
        return errMsg;
    
    }


    /*
    *  @Author      : Joshith k
    *  @Description : Wrapper class
    */

    public class SoftwareDownloadDataReceiverWrapper {
        public String First_Name;
        public String Last_Name;
        public String Country;
        public String Software_Name;
        public String Platform_GUID;
        public String Email_Address;
        public String Software_File_URL;
        public String Software_Category;
        public String Software_Version;
        public String EULA_Acceptance_Date;
        public String EULA_Version_Accepted;
        public String Download_Date;
        public String Software_Download_ID;
        
   }
   
    /*
    *  @Author      : Joshith k
    *  @Description : Wrapper class
    */
    
   public class Error_Details{
     public String Error_Message; 
     public String Error_Data;
    }


/*
SAMPLE INPUT RECIEVED
[
  { 
    "First_Name":"sample first name",
    "Last_Name":"sample last name",
    "Country":"sample Country",
    "Software_Name": "Sample Software name1",
    "Platform_GUID": "Sample GUID 1",
    "Email_Address": "xyz@abc.com",
    "Software_File_URL": "https://jira.illumina.com/browse/DCP-27215",
    "Software_Category": "Example Category 1",
    "Software_Version": "Example Version 1",
    "EULA_Acceptance_Date": "2019-08-06 05:06:17",
    "EULA_Version_Accepted": "Example EULA Version 1",
    "Download_Date": "2019-08-06 05:06:17",
    
  },
  { 
    "First_Name":"sample first name",
    "Last_Name":"sample last name",
    "Country":"sample Country",
    "Software_Name": "Sample Software name2",
    "Platform_GUID": "Sample GUID 2",
    "Email_Address": "xffyz@abc.com",
    "Software_File_URL": "https://jira.illumina.com/browse/DCP-27216",
    "Software_Category": "Example Category 2",
    "Software_Version": "Example Version 2",
    "EULA_Acceptance_Date": "2019-08-06 05:06:17",
    "EULA_Version_Accepted": "Example EULA Version 2",
    "Download_Date": "2019-08-06 05:06:17",
    
    

  },
  {
    "First_Name":"sample first name",
    "Last_Name":"sample last name",
    "Country":"sample Country",
    "Software_Name": "Sample Software name3",
    "Platform_GUID": "Sample GUID 3",
    "Email_Address": "xyz@abc.com",
    "Software_File_URL": "https://jira.illumina.com/browse/DCP-27715",
    "Software_Category": "Example Category 3",
    "Software_Version": "Example Version 3",
    "EULA_Acceptance_Date": "2019-08-06 05:06:17",
    "EULA_Version_Accepted": "Example EULA Version 3",
    "Download_Date ": "2019-08-06 05:06:17",
    
  }
]

*/
}