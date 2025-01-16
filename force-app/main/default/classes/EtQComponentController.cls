/**
* @ author       : Abhinav Gupta
* @ date         : 23-Mar-2022
* @ Description  : QACM-14,15 LWC Controller for EtQ stories
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhinav             23-Mar-2022                 Initial version
* Abhinav             15-Apr-2022                 QACM-673 Check QI Record type and set RecordType as 'QI' or 'Other'
* Abhinav             15-Apr-2022                 QACM-669 Updated searchQiRecords to use contains instead of startswith in search
* Abhinav             19-Apr-2022                 QACM-670 Updated createQrjCallout to set ProblemTitle on created QI Record
* Abhinav             19-Apr-2022                 QACM-652 Enhancement - Add delinking/delete functionality for Manually Create QI Records
* Abhinav             20-Apr-2022                 QACM-692 Updated searchQiRecords to search on EtQ_Created_Date__c field
*/
public with sharing class EtQComponentController {
    
    public static final String CASE_OBJ = 'Case';
    public static final String FIELD_ACTION_NOTIFICATION_OBJ = 'Field_Action_Notification__c';
    public static final string LINK_INITIATED = 'Link Initiated';
    public static final String DELINK_INITIATED = 'Delink Initiated';
    public static final String MANUAL_LINK = 'Manual Link';
    public static final String DELINK_FAILED = 'Delink Failed';
    public static final String QUALITY_RECORD_LINKED_SUCCESSFULLY = 'Quality Record linked successfully';
    public static final String QUALITY_RECORD_ALREADY_LINKED = 'Quality Record is already linked to the Case/FAN record.';
    public static final String QUALITY_RECORD_CREATED = 'Quality Record created successfully';
    public static final String INVALID_ETQ_NUMBER = 'Invalid URL';
    private static final String LOG_TITLE = 'EtQComponentController';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
    /**
    * @author abhinav
    * @date   23-Mar-2022
    * @description  Search Quality records on SF based on the user input recieved from LWC and return the results
    */
    @AuraEnabled(cacheable=true)
    public static List<Quality_Record__c> searchQiRecords(String problemTitle, String sitesImpacted, String etqNumber, String createdDate){
        ilib_LogEvent.push(LOG_TITLE + 'searchQiRecords');
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.searchQiRecords');
        List<Quality_Record__c> qiRecords = new List<Quality_Record__c>();
        try {
            String query = 'Select Problem_Title__c, Sites_Impacted__c, EtQ_Number__c, CreatedDate,Current_Phase__c,EtQ_Created_Date__c, (select id, case__r.casenumber, Field_Action_Notification__r.name,createddate from Quality_Record_Junctions__r) from Quality_Record__c where Current_Phase__c != \'Void\' and Quality_Record_Type__c = \'QI\' and EtQ_Integration_Status__c!=\'Manual Created\'';

            if(string.isNotBlank(problemTitle)){
                query += ' and Problem_Title__c like \'%'+String.escapeSingleQuotes(problemTitle)+'%\' ';
            }
                
            if(string.isNotBlank(sitesImpacted)){
                query += ' and Sites_Impacted__c like \'%'+String.escapeSingleQuotes(sitesImpacted)+'%\' ';
            }
                
            if(string.isNotBlank(etqNumber)){
                query += ' and EtQ_Number__c like \'%'+String.escapeSingleQuotes(etqNumber)+'%\' ';
            }
                
            if(string.isNotBlank(createdDate)){
                String strCreatedDate = String.escapeSingleQuotes(createdDate)+' 00:00:00';
                Date dateApex = date.valueOf(strCreatedDate);
                String strUpperDate = String.valueOf(dateApex.addDays(1)).removeEnd(' 00:00:00');
                String strLowerDate = String.valueOf(dateApex).removeEnd(' 00:00:00');

                query += ' and EtQ_Created_Date__c > '+strLowerDate+'T00:00:00.000Z and EtQ_Created_Date__c < '+strUpperDate+'T00:00:00.000Z';
            }

            qiRecords = Database.query(query);
                
            system.debug('lwc rec: '+qiRecords);
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE + ' searchQiRecords', e, ilib_LogEvent.SERVICE);
            throw new AuraHandledException(e.getMessage());
        }
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(qiRecords.size());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return qiRecords;
        
    }


    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Create QRJ records linking Case/Fan with Quaklity Records when user clicks 'Link' button on the LWC
    */
    @AuraEnabled(cacheable=false)
    public static Quality_Record_Junction__c createQualityRecordJuntions(Id qualityRec, Id lookupIds, String objectName, String status){
        ilib_LogEvent.push(LOG_TITLE + 'createQualityRecordJuntions');
        Quality_Record_Junction__c qrj;
        try{
                qrj = new Quality_Record_Junction__c();
                if(string.isNotBlank(status)){
                    qrj.EtQ_Integration_Status__c = status;
                }
                qrj.Quality_Record__c = qualityRec;
                if(objectName==CASE_OBJ){
                    qrj.Case__c=lookupIds;
                }
                else if(objectName==FIELD_ACTION_NOTIFICATION_OBJ){
                    qrj.Field_Action_Notification__c=lookupIds;
                }
            insert qrj;
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return qrj;
        }
        catch(Exception ex){
            ApexExceptions.emit(LOG_TITLE + ' createQualityRecordJuntions', ex, ilib_LogEvent.SERVICE);
            throw new AuraHandledException(ex.getMessage());
        }
        

    }


    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  When a user clicks Link button on searched Quality record, check if the record is already linked to case/FAN and prompt user
    */
    @AuraEnabled(cacheable=false)
    public static Boolean checkIfAlreadyLinked(Id qualityRec, Id lookupIds, String objectName){
        ilib_LogEvent.push(LOG_TITLE + 'checkIfAlreadyLinked');
        List<Quality_Record_Junction__c> existingQrjList = new List<Quality_Record_Junction__c>();
        Boolean isAvailable = false;
        try{
            QualityRecordJunctionSelector qrs = new QualityRecordJunctionSelector();
            if(objectName == CASE_OBJ){
                existingQrjList = qrs.selectQRJForCase(lookupIds, qualityRec);
            }
            else if(objectName==FIELD_ACTION_NOTIFICATION_OBJ){
                existingQrjList = qrs.selectQRJForFAN(lookupIds, qualityRec);
            }
            system.debug('existing list: '+existingQrjList);
            if(!existingQrjList.isEmpty()){
                isAvailable = true;
            }
            else{
                isAvailable = false;
            }
        }
        
        catch(Exception ex){
            ApexExceptions.emit(LOG_TITLE + ' checkIfAlreadyLinked', ex, ilib_LogEvent.SERVICE);
            throw new AuraHandledException(ex.getMessage());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return isAvailable;
    }


    /**
    * @author abhinav
    * @date   25-Mar-2022
    * @description  Retrieve all the linked Quality Record Junctions linked wuth Case/FAN with Quality Record data and display on existingQiRecords LWC
    */
    @AuraEnabled(cacheable=false)
    public static List<Quality_Record_Junction__c> getLinkedQualityRecords(Id recId, String objName, String nowTime){
        ilib_LogEvent.push(LOG_TITLE + 'getLinkedQualityRecords');
        List<Quality_Record_Junction__c> qrjList = new List<Quality_Record_Junction__c>();
        try {
            QualityRecordJunctionSelector qrs = new QualityRecordJunctionSelector();
            if(objName==CASE_OBJ){
                qrjList = qrs.selectQRJForCaseLinked(recId);
            }
            else if(objName==FIELD_ACTION_NOTIFICATION_OBJ){
                qrjList = qrs.selectQRJForFANLinked(recId);
            }
        } 
        catch (Exception ex) {
            ApexExceptions.emit(LOG_TITLE + ' getLinkedQualityRecords', ex, ilib_LogEvent.SERVICE);
            throw new AuraHandledException(ex.getMessage());
            
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return qrjList;
    }

    /**
    * @author abhinav
    * @date   26-Mar-2022
    * @description  When user clicks on 'Delink' button on existing QRJ, set the status of QRJ to 'Delink Initiated'
    */
    @AuraEnabled
    public static void delinkQRJ(Id qrjId){
        ilib_LogEvent.push(LOG_TITLE + 'delinkQRJ');
        try {
            Set<Id> qrjIds = new Set<Id>();
            qrjIds.add(qrjId);
            QualityRecordJunctionSelector qrs = new QualityRecordJunctionSelector();
            List<Quality_Record_Junction__c> qrjList = qrs.selectQRJ(qrjIds);
            for(Quality_Record_Junction__c qrj: qrjList){
                qrj.EtQ_Integration_Status__c = DELINK_INITIATED;
            }
            
            update qrjList;
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE + ' delinkQRJ', e, ilib_LogEvent.SERVICE);
            throw new AuraHandledException(e.getMessage());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description  When user enters Manual URL to EtQ and tries to create QI,QRJ making apex callout to EtQ
    */
    @AuraEnabled
    public static EtQCompWrapper createQrjCallout(String etqUrl, String objApiName, String lookupId){
        ilib_LogEvent.push(LOG_TITLE + 'createQrjCallout');
        //Quality_Record_Junction__c qrj = new Quality_Record_Junction__c();
        EtQCompWrapper etqComp = new EtQCompWrapper();
        try{
            ETQResponseWrapper etqWrap;
            //make integration callout, get etq number in response
            etqWrap = EtQGetEtQNumberDataSender.fetchETQNumber(etqUrl);
            //if etqnumber field is null, throw exception
            if(etqWrap.ETQNumber==null || string.isBlank(etqWrap.ETQNumber)){
                //throw new AuraHandledException(etqWrap.Messages);
                etqComp.status = 1;
                if(etqWrap.Messages==null || string.isBlank(etqWrap.Messages)){
                    etqComp.message = INVALID_ETQ_NUMBER;
                }
                else{
                    etqComp.message = etqWrap.Messages;
                }
            }
            else{
                List<Quality_Record__c> searchQR = fetchQualityRecord(etqWrap.ETQNumber);
                if(searchQR.size()==1){
                    //means QR already exists
                    Boolean st = checkIfAlreadyLinked(searchQR[0].Id, lookupId, objApiName);
                    if(st==false){
                        Quality_Record_Junction__c qrj = createQualityRecordJuntions(searchQR[0].Id, lookupId, objApiName, MANUAL_LINK);
                        etqComp.status = 0;
                		etqComp.message = QUALITY_RECORD_LINKED_SUCCESSFULLY;
                    }
                    else if(st==true){
                        //update the problem title
                        String strProblemTitle = '';
                        Integer titleLength = 255;
                        if(etqWrap.ProblemTitle.length()>titleLength){
                            strProblemTitle = etqWrap.ProblemTitle.substring(0,titleLength);
                        }
                        else if(etqWrap.ProblemTitle.length()<=titleLength){
                            strProblemTitle = etqWrap.ProblemTitle;
                        }
                        searchQR[0].Problem_Title__c = strProblemTitle;
                        update searchQR[0];

                        etqComp.status = 1;
                		etqComp.message = QUALITY_RECORD_ALREADY_LINKED;
                    }
                }
                else if(searchQR.isEmpty()){
                    //create qr -- add problem title
                    
                    String strProblemTitle = '';
                    Integer titleLength = 255;
                    if(etqWrap.ProblemTitle.length()>titleLength){
                        strProblemTitle = etqWrap.ProblemTitle.substring(0,titleLength);
                    }
                    else if(etqWrap.ProblemTitle.length()<=titleLength){
                        strProblemTitle = etqWrap.ProblemTitle;
                    }

                    //checking record type from the EtQ URL
                    String recordType = checkQiRecordType(etqUrl);

                    Quality_Record__c qiRec = createQR(etqWrap.ETQNumber,lookupId, objApiName, '',etqUrl,'',strProblemTitle,recordType);
                    //create qrj
                    if(qiRec!=null){
                        Quality_Record_Junction__c qrj = createQualityRecordJuntions(qiRec.Id, lookupId, objApiName, MANUAL_LINK);
                        etqComp.status = 0;
                		etqComp.message = QUALITY_RECORD_CREATED;
                    }
                }
            }
        }
            
        
        catch(Exception ex){
            ApexExceptions.emit(LOG_TITLE + ' createQrjCallout', ex , ilib_LogEvent.SERVICE);
            throw new AuraHandledException(ex.getMessage());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return etqComp;
        
    }

    /**
    * @author abhinav
    * @date   4-APR-2022
    * @description  When user enters Manual URL to EtQ and tries to create QI,QRJ making apex callout to EtQ
    */
    @AuraEnabled
    public static Quality_Record__c createQR(String etqNumber,Id lookupIds, String objectName, String source, String url,String status, String problemTitle, String recordType){
        ilib_LogEvent.push(LOG_TITLE + 'createQR');
        Quality_Record__c qiRec;
        try{
            qiRec = new Quality_Record__c();
            qiRec.Quality_Record_Type__c = recordType;
            qiRec.EtQ_Integration_Status__c = status;
            qiRec.EtQ_Number__c = etqNumber;
            qiRec.Source__c = source;
            qiRec.EtQ_Created_Date__c = DateTime.now();
            qiRec.Problem_Title__c = problemTitle;
            if(objectName==CASE_OBJ){
                qiRec.Case__c=lookupIds;
            }
            else if(objectName==FIELD_ACTION_NOTIFICATION_OBJ){
                qiRec.Field_Action_Notification__c=lookupIds;
            }
            if(!string.isBlank(url)){
                qiRec.External_URL__c=url;
            }
            insert qiRec;

        }
        catch(Exception ex){
            ApexExceptions.emit(LOG_TITLE + ' createQR', ex, ilib_LogEvent.SERVICE);
            throw new AuraHandledException(ex.getMessage());
        }   
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return qiRec;     
    }

    /**
    * @author abhinav
    * @date   4-APR-2022
    * @description  WWhen user wants to delink QRJ, this method checks if the QRJ is a Manual Link record
    */
    @AuraEnabled(cacheable=false)
    public static Boolean checkIfManuallyLinked(Id qrjId){
        ilib_LogEvent.push(LOG_TITLE + 'checkIfManuallyLinked');
        Boolean isLinked=false;
        try{
            Set<Id> qrjIds = new Set<Id>();
            qrjIds.add(qrjId);
            QualityRecordJunctionSelector qrs = new QualityRecordJunctionSelector();
            List<Quality_Record_Junction__c> qrjList = qrs.selectQRJ(qrjIds);
            if(!qrjList.isEmpty()){
                for(Quality_Record_Junction__c qrRec: qrjList){
                    if(qrRec.EtQ_Integration_Status__c == MANUAL_LINK){
                        isLinked=true;
                        break;
                    }
                }
            }
        }
        catch(Exception ex){
            ApexExceptions.emit(LOG_TITLE + ' checkIfManuallyLinked', ex, ilib_LogEvent.SERVICE);
            throw new AuraHandledException(ex.getMessage());
        }   
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return isLinked;
    }

    /**
    * @author abhinav
    * @date   4-APR-2022
    * @description  Method to be used when user wants to delink Manual Link QRJ, this method deleted the QRJ record.
    */
    @AuraEnabled(cacheable=false)
    public static Boolean deleteManualQrj(Id qrjId){
        return new EtQComponentController.EtQComponentControllerWOSharing().deleteManualQrjWOSharing(qrjId);
    }


    /**
    * @author abhinav
    * @date   20-Apr-2022
    * @description  Check the recordtype to set to QUality Record in case of createqi screen and addmanuallink screen
    */
    public static String checkQiRecordType(String etqUrl){
        ilib_LogEvent.push(LOG_TITLE + 'checkQiRecordType');
        String recType = '';
        try{
            if(etqUrl.contains('ILL_QUALITY_EVENTS_1')){
                recType = 'QI';
            }
            else{
                recType = 'Other';
            }
        
        }   
        catch(Exception ex){
            ApexExceptions.emit(LOG_TITLE + ' checkQiRecordType', ex, ilib_LogEvent.SERVICE);
            throw new AuraHandledException(ex.getMessage());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return recType;
    }

        /**
    * @author abhinav
    * @date   21-Apr-2022
    * @description  Fetch Quality Record based on etq number
    */
    @AuraEnabled
    public static List<Quality_Record__c> fetchQualityRecord(String etqNum){
        ilib_LogEvent.push(LOG_TITLE + 'fetchQualityRecord');
        List<Quality_Record__c> searchQR;
        try{
            QualityRecordSelector qrs = new QualityRecordSelector();
            searchQR = qrs.selectQrForCallout(etqNum);
        }   
        catch(Exception ex){
            ApexExceptions.emit(LOG_TITLE + ' fetchQualityRecord', ex, ilib_LogEvent.SERVICE);
            throw new AuraHandledException(ex.getMessage());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return searchQR;
    }
    
     /**
    * @author abhinav
    * @date   6-APR-2022
    * @description  Inner class to return response when manual URL is entered.
    */
    public class EtQCompWrapper{
        
        @AuraEnabled
        public Integer status;
        @AuraEnabled
        public String message;
        
    }

    /**
    * @author abhinav
    * @description  EtQComponentControllerWOSharing inner class for work order sharing
    */
    public without sharing class EtQComponentControllerWOSharing {

        /**
        * @author abhinav
        * @description  deleteManualQrjWOSharing method for work order sharing
        */
        public Boolean deleteManualQrjWOSharing(Id qrjId){
            ilib_LogEvent.push(LOG_TITLE + 'deleteManualQrj');
            Boolean deleteStatus = false;
            try{
                Set<Id> qrjIds = new Set<Id>();
                qrjIds.add(qrjId);
                QualityRecordJunctionSelector qrs = new QualityRecordJunctionSelector();
                List<Quality_Record_Junction__c> qrjList = qrs.selectQRJ(qrjIds);
                if(!qrjList.isEmpty()){
                    delete qrjList;
                    deleteStatus = true;
                }
            }
            catch(Exception ex){
                ApexExceptions.emit(LOG_TITLE + ' deleteManualQrj', ex, ilib_LogEvent.SERVICE);
                throw new AuraHandledException(ex.getMessage());
            }   
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return deleteStatus;
        }
    }

}