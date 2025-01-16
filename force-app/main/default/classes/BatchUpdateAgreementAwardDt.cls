/**
*    @author: Amogh Ghodke
*    @date:   01-Dec-2023
*    @description:  Batch class to update Apttus__APTS_Agreement__c records for non compliance criteria having Date_awarded__c field as null
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Amogh Ghodke                 01 Dec 2023              Initial Build
     ------------------------------------------------------------------------------------ 
*                    
*/
global with sharing class BatchUpdateAgreementAwardDt implements Database.Batchable<sObject>, Database.Stateful{
    /*String variables are declared here to prepare errorMessage*/
    private static final String LOG_TITLE = 'BatchUpdateAgreementAwardDt';
    private String strQuery='';
    public Set<String> setNonUpdatedAgreementErrors = new Set<String>();
    public static final String CODEPARAMETERNAME = 'EmailIdsIVDR';
    @TestVisible static boolean boolEmailSent= false;
    public static Boolean boolIsTestRunning = false;
    String bullet = '~ ';
    String endLine = '\n';
    String errorMessage = '';
    public static FINAL string TENDER = 'Tender';
    public static final String STATUS_CATEGORY_IN_EFFECT_WON = 'In Effect/Won';

    
    /*Query for updating fields through batch*/
    global BatchUpdateAgreementAwardDt() {
        this.strQuery = 'SELECT Id, Date_awarded__c, Non_Compliant_Tender__c, Reason_For_Non_Compliance__c, Record_Type__c, Tenders_Status__c FROM Apttus__APTS_Agreement__c WHERE Record_Type__c =: TENDER and Date_awarded__c = null and Tenders_Status__c =: STATUS_CATEGORY_IN_EFFECT_WON';
    }
        
    /*Start method of Batch Class*/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.strQuery);
    }
    
    /*Execute method of Batch Class*/
    global void execute(Database.BatchableContext bc, list<Sobject> scope) {
    List<Apttus__APTS_Agreement__c> listUpdatedAgreements = new List<Apttus__APTS_Agreement__c>();
    ilib_LogEvent.push(LOG_TITLE +'.execute');
    ilib_LogEvent.info(LOG_TITLE +'.execute scope size is ' + scope.size() + ' records');
    System.debug('Inside execute');
    System.debug('scope >'+scope);
        for(Apttus__APTS_Agreement__c agreementVar : (List<Apttus__APTS_Agreement__c>)scope) {
            if(agreementVar.Date_awarded__c == null && agreementVar.Tenders_Status__c == STATUS_CATEGORY_IN_EFFECT_WON) {
               errorMessage += bullet + Label.UI_Label_Award_date_not_specified + endLine;
               agreementVar.Non_Compliant_Tender__c = true;
               agreementVar.Reason_for_Non_Compliance__c = errorMessage;
               listUpdatedAgreements.add(agreementVar);
            }   
        }
        ilib_LogEvent.info(LOG_TITLE +'.execute updated records ' + listUpdatedAgreements.size() + ' records');
        ilib_LogEvent.emit();
        ilib_LogEvent.pop();
        System.debug('listUpdatedAgreements >'+listUpdatedAgreements);
        if(!listUpdatedAgreements.isEmpty()){
            Database.SaveResult[] result = Database.update(listUpdatedAgreements, false);
            Integer intCount = 0;
            for (Database.SaveResult sr : result){
                if(!sr.isSuccess()){
                    for(Database.Error err : sr.getErrors()){
                        setNonUpdatedAgreementErrors.add(listUpdatedAgreements.get(intCount).id +' : '+ err.getStatusCode() + ': ' + err.getMessage()+ ': ' + err.getFields());
                    }
                }
                intCount++;
            }
        }
    }
    
    /*Finish method of the batch class*/
    global void finish(Database.BatchableContext bc){
        if(!setNonUpdatedAgreementErrors.isEmpty() || !boolIsTestRunning){
            CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
            List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> strEmailId = new List<String>();
            if(!Test.isRunningTest()){
                strEmailId.addAll(objCodeParam[0].Value__c.split(';'));
            }
            else{
                strEmailId.add('amogh.ghodke@concordusa.com');
            }
            email.setToAddresses(strEmailId);
            String subject = 'ACTION NEEDED: Apttus__APTS_Agreement__c update failed';
            email.setSubject(subject);
            String strBody = 'Following Apttus__APTS_Agreement__c were not updated : </br>';
            for(String str : setNonUpdatedAgreementErrors){
                strBody = strBody + str+'</br>';
            }
            email.setHtmlBody(strBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            boolEmailSent = true;
        }
    }

}