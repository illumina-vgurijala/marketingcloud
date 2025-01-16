/***************************************************************************************************************************************
    * NAME   : ApttusAgreementTerminateService
    * DESCRIPTION  : Logic for updating Agreement to terminate from platform event
    *                    
    * @AUTHOR : Rishi Sharma
    * @DATE   : 19-Sept-2022 
    * 
    * MODIFICATION LOG: 
    * -----------------------------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * ------------------------------------------------------------------------------------------------------------------------------------------------------------
    * Rishi Sharma             19-Sept-2022        DCP-56529 - Agreements getting stuck with "Terminate In progress" for BatchAutoTerminateAgreements
    * Test Class for 90% Coverage: TestBatchAutoTerminateAgreements
    * Test Class for 75% Coverage: TestBatchAutoTerminateAgreements
******************************************************************************************************************************************************************/
public with sharing class ApttusAgreementTerminateService implements ilib_AdminOperationLogicInterface{
    private static final String LOG_TITLE = 'ApttusAgreementTerminateService';
    public static final String TERMINATE = 'Terminate';
    /**
     *  @author       : Rishi Sharma
     *  @description  : Logic for updating Agreement to terminate from platform event
     *  @return       : void
     */
    public static void doBusinessLogic(List<Id> lstAgreementIds){
        ilib_LogEvent.rootTitle = LOG_TITLE;  
        ilib_LogEvent.push(LOG_TITLE + '.doBusinessLogic()');
        
        try{
            for(id aggId : lstAgreementIds){
                ApttusAgreementActionService.sendBatchTerminateRequestToSAP(TERMINATE, aggId);
            }
                
        }catch(Exception e){ApexExceptions.emit(LOG_TITLE,lstAgreementIds.get(0), e);}
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}