/**************************************************************************************************************************************
 * NAME   : CasesHelper
 * DESCRIPTION  : Helper class for Case trigger class.                   
 * @AUTHOR : Susmitha Mogidi 
 * MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
*
* Susmitha              13-09-2022           QACM-108 Method to clear case field values on Record type change
**/
public without sharing class CaseQueueableHelper {
    private static final String LOG_TITLE = 'CaseQueueableHelper';
    /*
     *@DESCRIPTION = QACM-108 Whenever case record type chnages form BI to Sr, the code tite on associated code should be changed to code dis associated
    *  @PARAM :  Map<Id, Case>
    *  @RETURN: void
    *  @AUTHOR - Susmitha Mogidi
    */
    public static void updateCodeTitleonRTChange(Map<id,Case> casesRecord){
        ilib_LogEvent.push(Cases.LOG_TITLE + '.updateCodeTitleonRTChange()');
        try{ 
            List<Associated_Codes__c> lAssocodes =  new List<Associated_Codes__c>(); 
            ilib_LogEvent.info('lAssocodes: '+lAssocodes); 
            if(!casesRecord.IsEmpty() && casesRecord != null) {
                List<Code_Library__c> lstDisassociatedCode= new CodeLibrarySelector().selectDisassocaiatedCodeLibrary();
                for(id caseId :casesRecord.keySet()) {
                    for(Associated_Codes__c objRemoveACode: new AssociatedCodeSelector().selectAssociatedCodesForWOAndCase(casesRecord.get(caseId).Work_Order__c,caseId)) {
                        objRemoveACode.Code_Title__c=lstDisassociatedCode[0].id;
                        lAssocodes.add(objRemoveACode);
                    }
                }
                if(!lAssocodes.isEmpty()) {
                    Update lAssocodes;
                }
            }
            ilib_LogEvent.pop();
        } 
        catch(Exception e){
        ApexExceptions.emit('updateCodeTitleonRTChange',e);
        }      
    }
    /*
     *@DESCRIPTION = QACM-108 Whenever case record type chnages form BI to Sr, Update the case fields 
    *  @PARAM :  Map<Id, Case>
    *  @RETURN: void
    *  @AUTHOR - Susmitha Mogidi
    */
    public static void updateCase(map<id,Case> mapOfoCaseRecords){
        List<Case> updateCaseList =  new List<Case>();
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            System.debug('List of update cases'+mapOfoCaseRecords);
            if(!mapOfoCaseRecords.IsEmpty() && mapOfoCaseRecords != null){
				for(Case oldCase:mapOfoCaseRecords.Values()){
                    oldCase.QA_Review__c = '';
                    oldCase.Predicted_QA_Product_Family__c = '';
                    oldCase.Predicted_QA_Sub_Product_Family__c = '';
                    oldCase.QA_Product_Family__c = '';
                    oldCase.QA_Sub_Product_Family__c = '';
                    oldCase.Investigation_Summary_Comments__c = '';
                    oldCase.Potentially_Reportable__c = '';
                    oldCase.pAE_pFA_Awareness_Date__c = NULL;
                    oldCase.PAE_PFA_Evaluation_Required__c = '';
                    oldCase.Answer_1__c = '';
                    oldCase.Answer_2__c = '';
                    oldCase.Answer_3__c = '';
                    oldCase.Answer_4__c = '';
                    oldCase.Answer_5__c = '';
                   updateCaseList.add(oldCase);
                }
            }
            if(!updateCaseList.isEmpty()){
                update updateCaseList;
            }
            ilib_LogEvent.pop();
        }
        Catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage());
        }
    }
}    