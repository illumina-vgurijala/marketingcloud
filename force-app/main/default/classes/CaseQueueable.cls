/***************************************************************************************************************************************
* NAME         : CaseQueueable
* DESCRIPTION  :  CaseQueueable.
*                    
* @AUTHOR : Akash Lahoti
* @DATE   : 30-July-2020 
* @testclasses : TestCases
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Akash            30-July-2020           Initial Version. 
*Nishan Shetty     15-Sept-2021           CMCP-22 Request GTS Relocations Work Order.
* Rohan            23-Mar-2022            DCP-49682 Remove updateWOWithElevatedCase and SendEmailsForElevationCases
  Nitin            7 june 2022            CMSI-36 try catch in execute method
  Susmitha         26-Aug-2022            QACM-108 Disassociate codes and update code title on Associated codes on RT chnage
*Sagar             02-Sep-2022            DCP-51201: To Send Case information to medical Affairs(Veeva)    
****************************************************************************************************************************************/

public class CaseQueueable implements Queueable,Database.AllowsCallouts {
    
    String strMethodtoExecute;
    Set<Id> setRecordIds=new set<Id>();
    String caseInsertUpdate;
    Map<Id, Case> idToCaseRecords;
	Map<Id, Set<String>> caseIdToChange;
    public static Boolean catchException = false;
    
    //Constructor to Initialize Class parameters  
    	
   /*
    * Constructor
    */
    public CaseQueueable(String strMethodtoExecute , Set<Id> setRecordIds, string caseInsertUpdate, Map<Id, Case> idToCaseRecords, Map<Id, Set<String>> caseIdToChange){
        this.strMethodtoExecute=strMethodtoExecute;
        this.setRecordIds=setRecordIds;
        this.idToCaseRecords = idToCaseRecords;
        this.caseIdToChange = caseIdToChange;   
    }
    
    /**
    *  @author Akash
    *  @description -Holds methods that need to be Run in Queuable context from Cases Class
    *                 
    **/
    public void execute(QueueableContext qc) { 
        try{
        /*if(strMethodtoExecute=='uncheckClosedWithAssociatedCodes' && !setRecordIds.IsEmpty() && (caseInsertUpdate==null || caseInsertUpdate=='')){
            RefactoredCases.uncheckClosedWithAssociatedCodes(setRecordIds);
            
        }*/
        if(strMethodtoExecute=='updateCaseFields' && idToCaseRecords != null && !idToCaseRecords.keyset().isEmpty()){
            Cases.updateCaseFields(idToCaseRecords);   
        }     
        //DCP-46141
        if(strMethodtoExecute=='doCalloutToQualtrics' && !setRecordIds.IsEmpty() && setRecordIds != null){
            Cases.doCalloutToQualtrics(setRecordIds);          
        }
        
        
        //START CMCP-22
        if(strMethodtoExecute=='sendGTSCaseToSAP' && setRecordIds != null && !setRecordIds.IsEmpty()){
            Cases.sendGTSCaseToSAP(setRecordIds);          
        }
        //END CMCP-22

        //DCP-51201:Start
        if(strMethodtoExecute=='sendCaseDetailsToVeeva' && setRecordIds != null && !setRecordIds.IsEmpty())
        {
            cases.sendCaseDetailsToVeeva(setRecordIds);
        }
        //DCP-51201:End
        if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }
    }
    catch(Exception e){
        ApexExceptions.emit('CaseQueueable', e, ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
    }  
    }
    
}