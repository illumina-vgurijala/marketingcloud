/**
*   Class - BatchUpdateAOIData
*   @description:  Batch class to update AOI field values                     
*/
public class BatchUpdateAOIData extends ilib_ScheduleAndBatch{
    
    /**Start method of Batch Class */
    public override Database.QueryLocator start(Database.BatchableContext bC){
         String strSoql ='select id,Area_Of_Interest__c,AOI_Agriculture_Research__c,AOI_Animal_Testing__c,AOI_Applied_Microbiology__c, '+
             				' AOI_Autoimmune_Disease_Research__c,AOI_Cancer_Research__c,AOI_Cardiovascular_Disease_Research__c,AOI_Cell_And_Molecular_Biology_Research__c,AOI_Clinical_Oncology__c, '+
             				' AOI_Consumer_Genomics__c,AOI_Genetic_And_Complex_Disease_Research__c,AOI_Genetic_Health__c,AOI_Healthy_Screening__c,AOI_Metabolic_Disease_Research__c,AOI_Microbiology_Virology_Research__c,AOI_Neuroscience_Research__c,AOI_NIPT__c,AOI_Pharmacogenomics_PGx__c, '+
             				' AOI_Plant_Testing__c,AOI_Preconception_And_Fertility__c,AOI_Public_Health__c,AOI_Rare_And_Inherited_Disease__c '+
             				' from Lead where Area_Of_Interest__c!=null';
         return Database.getQueryLocator(strSoql);
    } 
    
    /**Execute method of Batch Class */
    public override void execute(Database.BatchableContext bC, List<sObject> lstLead){
        List<Lead> lstLeads=new List<Lead>();
        for(Lead objLead:(List<Lead>) lstLead){
            Lead objLeadUpdate=new Lead(id=objLead.Id);
            
           	String strAOIPickVal = objLead.Area_Of_Interest__c;
           	list<String> aoilst=strAOIPickVal.split(';');
            for(String aoiVal:aoilst){
                if(aoiVal=='Agriculture Research'){
                    objLeadUpdate.AOI_Agriculture_Research__c=true;
                }
                else if(aoiVAL=='Animal Testing'){
                    objLeadUpdate.AOI_Animal_Testing__c=true;
                }
                else if(aoiVAL=='Applied Microbiology'){
                    objLeadUpdate.AOI_Applied_Microbiology__c=true;
                }
                
                else if(aoiVAL=='Autoimmune Disease Research'){
                    objLeadUpdate.AOI_Autoimmune_Disease_Research__c=true;
                }
                
                else if(aoiVAL=='Cancer Research'){
                    objLeadUpdate.AOI_Cancer_Research__c=true;
                }
                
                else if(aoiVAL=='Cardiovascular Disease Research'){
                    objLeadUpdate.AOI_Cardiovascular_Disease_Research__c=true;
                }
                
                else if(aoiVAL=='Cell And Molecular Biology Research'){
                    objLeadUpdate.AOI_Cell_And_Molecular_Biology_Research__c=true;
                }
                
                else if(aoiVAL=='Clinical Oncology'){
                    objLeadUpdate.AOI_Clinical_Oncology__c=true;
                }
                
                else if(aoiVAL=='Consumer Genomics'){
                    objLeadUpdate.AOI_Consumer_Genomics__c=true;
                }
                
                else if(aoiVAL=='Genetic And Complex Disease Research'){
                    objLeadUpdate.AOI_Genetic_And_Complex_Disease_Research__c=true;
                }
                
                else if(aoiVAL=='Genetic Health'){
                    objLeadUpdate.AOI_Genetic_Health__c=true;
                }
                
                else if(aoiVAL=='Metabolic Disease Research'){
                    objLeadUpdate.AOI_Metabolic_Disease_Research__c=true;
                }
                
                else if(aoiVAL=='Microbiology/Virology research'){
                    objLeadUpdate.AOI_Microbiology_Virology_Research__c=true;
                }
                
                else if(aoiVAL=='Neuroscience Research'){
                    objLeadUpdate.AOI_Neuroscience_Research__c=true;
                }
                else if(aoiVAL=='NIPT'){
                    objLeadUpdate.AOI_NIPT__c=true;
                }
                else if(aoiVAL=='Pharmacogenomics PGx'){
                    objLeadUpdate.AOI_Pharmacogenomics_PGx__c=true;
                }
                else if(aoiVAL=='Healthy Screening'){
                    objLeadUpdate.AOI_Healthy_Screening__c=true;
                }
                else if(aoiVAL=='Plant Testing'){
                    objLeadUpdate.AOI_Plant_Testing__c=true;
                }
                else if(aoiVAL=='Preconception And Fertility'){
                    objLeadUpdate.AOI_Preconception_And_Fertility__c=true;
                }
                else if(aoiVAL=='Public Health'){
                    objLeadUpdate.AOI_Public_Health__c=true;
                }
                
                else if(aoiVAL=='Rare and Inherited Disease'){
                    objLeadUpdate.AOI_Rare_And_Inherited_Disease__c=true;
                }
            }
            lstLeads.add(objLeadUpdate);
        }
        
        if (lstLead.size() > 0)
        {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(p.Id);
            cs.Bypass_All_Validations__c = true;
            cs.Bypass_All_Triggers__c=true;
            upsert cs cs_Apex_Settings__c.Id;

            Database.update(lstLead, false);
			//update lstLead;
            
            cs.Bypass_All_Validations__c = false;
            cs.Bypass_All_Triggers__c=false;
            upsert cs cs_Apex_Settings__c.Id;
        }
    }
    
    /**Finish method of Batch class */
    public override void finish(Database.BatchableContext bc){
        system.debug('I am finish');
    }
}