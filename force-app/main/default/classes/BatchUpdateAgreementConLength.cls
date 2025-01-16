/**
*    @author: Amogh Ghodke
*    @date:   01-Dec-2023
*    @description:  Batch class to update Apttus__APTS_Agreement__c records for non compliance criteria for having Total_contract_length_with_extension__c field as null
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Amogh Ghodke                 01 Dec 2023              Initial Build
     ------------------------------------------------------------------------------------ 
*                    
*/
global with sharing class BatchUpdateAgreementConLength implements Database.Batchable<sObject>, Database.Stateful{
    /*String variables are declared here to prepare errorMessage*/
    private static final String LOG_TITLE = 'BatchUpdateAgreementConLength';
    private String strQuery='';
    public Set<String> setNonUpdatedAgreementErrors = new Set<String>();
    public static final String CODEPARAMETERNAME = 'EmailIdsIVDR';
    @TestVisible static boolean boolEmailSent= false;
    public static Boolean boolIsTestRunning = false;
    String bullet = '~ ';
    String endLine = '\n';
    String errorMessage = '';
    public static FINAL string TENDER = 'Tender';
    public static final String AGREEMENT_SUBTYPE_TERMED =  'Termed';
    public static final String AGREEMENT_SUBTYPE_ONE_TIME_SALE_AND_TERMED =  'One Time Sale & Termed';
    public static final Set<String> SET_OF_SUBTYPE = new Set<String> { AGREEMENT_SUBTYPE_TERMED, AGREEMENT_SUBTYPE_ONE_TIME_SALE_AND_TERMED };
    private String subType ='\'%' + AGREEMENT_SUBTYPE_TERMED  + '%\'';
  
    /*Query for updating fields through batch*/
    global BatchUpdateAgreementConLength() {
        this.strQuery = 'SELECT Id, Non_Compliant_Tender__c, Total_contract_length_with_extension__c, Apttus__Subtype__c, Reason_for_Non_Compliance__c FROM Apttus__APTS_Agreement__c WHERE Record_Type__c =: TENDER and Total_contract_length_with_extension__c = null and Apttus__Subtype__c like '+subType ;
    }
        
    /*Start method of Batch Class*/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.strQuery);
    }
    
    /*Execute method of Batch Class*/
    global void execute(Database.BatchableContext bc, list<Sobject> scope) {
    List<Apttus__APTS_Agreement__c> listUpdatedAgreements = new List<Apttus__APTS_Agreement__c>();
    ilib_LogEvent.push(LOG_TITLE +'.execute');
    System.debug('Inside execute');
    System.debug('scope >'+scope);
    ilib_LogEvent.info(LOG_TITLE +'.execute scope size is ' + scope.size() + ' records');
        for(Apttus__APTS_Agreement__c agreementVar : (List<Apttus__APTS_Agreement__c>)scope) {
            if(agreementVar.Total_contract_length_with_extension__c == null && SET_OF_SUBTYPE.contains(agreementVar.Apttus__Subtype__c)) {
               errorMessage += bullet + Label.UI_Label_Total_contract_length_blank + endLine;
               agreementVar.Non_Compliant_Tender__c = true;
               agreementVar.Reason_for_Non_Compliance__c = errorMessage;
               listUpdatedAgreements.add(agreementVar);
            }   
        }
        System.debug('listUpdatedAgreements >'+listUpdatedAgreements);
        ilib_LogEvent.info(LOG_TITLE +'.execute updated records ' + listUpdatedAgreements.size() + ' records');
        ilib_LogEvent.emit();
        ilib_LogEvent.pop();
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