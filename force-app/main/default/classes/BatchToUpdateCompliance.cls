/*@ author       : Gopi
* @ date         : 08-01-2023
* @ Description  : Batch to Update Compliance Reason 
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                  Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Gopi           		08-01-2023                  Initial version
* Gerardo               08-15-2023                  Add updateOppsByIds method for targeting specific opportunities.
* Gerardo               11-15-2023                  Modify logic of :isComplianceReasonCloseDateInPast and Add independent data(today date and period records) for Test context.
*/
global with sharing class BatchToUpdateCompliance extends ilib_ScheduleAndBatch implements Database.Stateful {
    public String query;
    private static final String LOG_TITLE = 'BatchToUpdateCompliance';
	global override Database.QueryLocator start(Database.BatchableContext bc){
        this.query = 'SELECT Id,Compliance_Last_Modified_Date__c,StageName, Amount_USD__c,Rev_Rec_Terms__c,Product_Type__c,LastModifiedDate,CloseDate,Non_Compliance_Reason__c FROM Opportunity WHERE IsClosed = false order by createddate';
        return Database.getQueryLocator(query);
    }
    
    global override void execute(Database.BatchableContext bc, List<sObject> scope){
        ilib_LogEvent.setTitle(LOG_TITLE); 
        List<Opportunity> lstOpp = (List<Opportunity>)scope;
        List<Opportunity> updateList = new List<Opportunity>();
        ilib_LogEvent.message('userName:' + UserInfo.getName());

        try{
            List<String> lstOfLastModStages = Code_Parameter__mdt.getInstance('Opp_Last_Mod_Noncompliance_Stages').Value__c.split(';');
            List<String> lstOfNoRevRecTermStages = Code_Parameter__mdt.getInstance('Opp_No_RevRec_Noncompliance_Stages').Value__c.split(';');
            List<Period> periodRecs = getPeriodRecs();
            ilib_LogEvent.message('periodRecs:' + periodRecs);
            for(Opportunity opp :lstOpp){

                Opportunity res = fillComplianceInOpportunity(lstOfLastModStages, lstOfNoRevRecTermStages, periodRecs, opp);
                if(res != null)
                    updateList.add(opp);
            }

            if(!updateList.isEmpty()) {
                List<Database.SaveResult> res = Database.update(updateList, false);
                ilib_LogEvent.info('Updated num opp:' + updateList.size() + ' List:' + updateList);
                if(!res.isEmpty() ){
                    ApexExceptions.emitSaveErrors(res,LOG_TITLE);
                }
            }
            ilib_LogEvent.emit();
        }
        catch(Exception e){
			ilib_LogEvent.info('Exception Message: ' +e.getMessage());
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.emit();
		}
    }

    /*
    * @Author: Gerardo Garcia
    * @Description: Update Opportunities with compliance data.
    * @param : List<Id> ids from target opportunities.
    * @return: List<Opportunity> results.
    */
    public static List<Opportunity> updateOppsByIds(List<String> ids) {
        List<Opportunity> res = new List<Opportunity>();
        if(ids?.size() > 0) {
            try {
                List<String> lstOfLastModStages = Code_Parameter__mdt.getInstance('Opp_Last_Mod_Noncompliance_Stages').Value__c.split(';');
                List<String> lstOfNoRevRecTermStages = Code_Parameter__mdt.getInstance('Opp_No_RevRec_Noncompliance_Stages').Value__c.split(';');
                List<Period> periodRecs = getPeriodRecs();


                for(Opportunity opp : [SELECT Id,Compliance_Last_Modified_Date__c,StageName, Amount_USD__c,Rev_Rec_Terms__c,
                                        Product_Type__c,LastModifiedDate,CloseDate,Non_Compliance_Reason__c 
                                        FROM Opportunity WHERE Id In :ids]) {
                    Opportunity result = fillComplianceInOpportunity(lstOfLastModStages, lstOfNoRevRecTermStages, periodRecs, opp);
                    if(result != null)
                        res.add(result);
                }

                update res;

            }
            catch(Exception e){
                ilib_LogEvent.info('Exception Message: ' +e.getMessage());
                ApexExceptions.emit(LOG_TITLE,e);
                ilib_LogEvent.emit();
            }
        }
        
        return res;
        
    }

    @TestVisible
    private static Opportunity fillComplianceInOpportunity(List<String> lstOfLastModStages, List<String> lstOfNoRevRecTermStages, List<Period> periodRecs, Opportunity opp) {
        ilib_LogEvent.message('Opportunity ID: ' + opp.Id);
        String oldComplianceReason = opp.Non_Compliance_Reason__c;
        Datetime lstModDate;
        Boolean hasDefaultedCLMD = false;
        if(opp.Compliance_Last_Modified_Date__c == null){
            hasDefaultedCLMD = true;
            lstModDate = opp.LastModifiedDate;
            opp.Compliance_Last_Modified_Date__c = opp.LastModifiedDate;
        } else {
            lstModDate = opp.Compliance_Last_Modified_Date__c;
        }
        
        List<String> nonCompliances = new List<String>();
        ilib_LogEvent.message('updateNonComplianceReason: stageName ' + opp.StageName + ' opp.Amount_USD__c ' + opp.Amount_USD__c + ' opp.Rev_Rec_Terms__c ' + opp.Rev_Rec_Terms__c);
        ilib_LogEvent.message('updateNonComplianceReason: opp.Product_Type__c ' + opp.Product_Type__c + ' lstModDate ' + lstModDate + ' opp.CloseDate ' + opp.CloseDate);

        if(!periodRecs.isEmpty()){
            if(isComplianceReasonLastModDate(opp, lstModDate, lstOfLastModStages, periodRecs)){
                nonCompliances.add(System.Label.ComplianceReasonLastModDate);
            }

            if(isComplianceReasonCloseDateInPast(opp, periodRecs[0])){
                nonCompliances.add(System.Label.ComplianceReasonCloseDateInPast);
            }
        }

        if(isComplianceReasonNoRevRecTerms(opp, lstOfNoRevRecTermStages)){
            nonCompliances.add(System.Label.ComplianceReasonNoRevRecTerms);
        }

        String nonComplianceReason = String.join(nonCompliances, ';');
        ilib_LogEvent.message('newNonComplianceReason: ' + nonComplianceReason);
        ilib_LogEvent.message('OldNonComplianceReason: ' + oldComplianceReason);
        
        opp.Non_Compliance_Reason__c = nonComplianceReason;
        
        if(hasDefaultedCLMD || hasChangedComplianceReason(oldComplianceReason, nonComplianceReason)) {
            ilib_LogEvent.message('Update Opportunity ID: ' + opp.Id);
            return opp;
        } else {
            ilib_LogEvent.message('No update required Opportunity ID: ' + opp.Id);
            return null;
        }

    }

    private static Boolean hasChangedComplianceReason(String oldComplianceReason, String nonComplianceReason) {
        return !(String.isBlank(oldComplianceReason) && String.isBlank(nonComplianceReason)) && (oldComplianceReason != nonComplianceReason);
    }

    private static Boolean isComplianceReasonLastModDate(Opportunity opp, Datetime lstModDate, List<String> lstOfLastModStages, List<Period> periodRecs) {
        if(periodRecs.size() > 2){
        
            Integer firsThreshold = Integer.valueOf(System.Label.Opp14DaysDue);
            Integer secondThreshold = Integer.valueOf(System.Label.Opp30DaysDue);
            Integer thirdThreshold = Integer.valueOf(System.Label.Opp45DaysDue);
            
            return ((lstOfLastModStages.contains(opp.StageName))
            && (hasAboveComplianceAmount(opp) || hasInstrument(opp)) 
            && (hasReachComplianceDate(opp, lstModDate, periodRecs[0], firsThreshold)
                ||  hasReachComplianceDate(opp, lstModDate, periodRecs[1], secondThreshold)
                ||  hasReachComplianceDate(opp, lstModDate, periodRecs[2], thirdThreshold)
            ));
        }
        return false;
    }

    private static Boolean isComplianceReasonCloseDateInPast(Opportunity opp, Period period ) {
        return !opp.StageName.contains(System.Label.CaseStatusClosed) 
        &&  
        ( opp.CloseDate < period.StartDate ||  
            ( 
                (isOppInRangePeriod(opp, period) && opp.CloseDate < getToday()) 
                    && (hasAboveComplianceAmount(opp) || hasInstrument(opp))
            )
        );
    }

    private static Boolean isComplianceReasonNoRevRecTerms(Opportunity opp, List<String> lstOfNoRevRecTermStages) {
        return hasInstrument(opp) 
        && (lstOfNoRevRecTermStages.contains(opp.StageName)) && String.isBlank(opp.Rev_Rec_Terms__c);
    }

    private static Boolean hasInstrument(Opportunity opp) {
        return  !String.isBlank(opp.Product_Type__c) && opp.Product_Type__c.contains(System.Label.OpportunityProdTypeInstrument);
    }

    private static Boolean hasAboveComplianceAmount(Opportunity opp) {
        return opp.Amount_USD__c > Integer.valueOf(System.Label.ComplianceAmountUSD);
    }

    private static Boolean hasReachComplianceDate(Opportunity opp, Datetime lstModDate, Period period, Integer thresholdDays) {
        return lstModDate <= getToday().addDays(-1 * thresholdDays) && isOppInRangePeriod(opp, period);
    }

    private static Boolean isOppInRangePeriod(Opportunity opp, Period period){
        return opp.CloseDate > period.StartDate && opp.CloseDate <= period.EndDate;
    }

    private static List<Period> getPeriodRecs() {
        return Test.isRunningTest() ? TestBatchToUpdateCompliance.periodRecs : [SELECT FullyQualifiedLabel, StartDate, EndDate FROM Period where Type = 'Quarter' AND EndDate >=: Date.today() order by EndDate limit 3];
    }

    private static Date getToday() {
        return Test.isRunningTest() ? TestBatchToUpdateCompliance.today : Date.today();
    }

    global override void finish(Database.BatchableContext bc){}
}