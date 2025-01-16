/**
*   Class - BatchUpdateAOIData
*   @description:  Batch class to update AOI field values on Contact                    
*/
public class BatchUpdateAOIDataContact extends ilib_ScheduleAndBatch{

    /**Start method of Batch Class */
    public override Database.QueryLocator start(Database.BatchableContext bC){
         String strSoql ='select id,Area_Of_Interest__c,AOI_Agriculture_Research__c,AOI_Animal_Testing__c,AOI_Applied_Microbiology__c, '+
             				' AOI_Autoimmune_Disease_Research__c,AOI_Cancer_Research__c,AOI_Cardiovascular_Disease_Research__c,AOI_Cell_And_Molecular_Biology_Research__c,AOI_Clinical_Oncology__c, '+
             				' AOI_Consumer_Genomics__c,AOI_Genetic_And_Complex_Disease_Research__c,AOI_Genetic_Health__c,AOI_Healthy_Screening__c,AOI_Metabolic_Disease_Research__c,AOI_Microbiology_Virology_Research__c,AOI_Neuroscience_Research__c,AOI_NIPT__c,AOI_Pharmacogenomics_PGx__c, '+
             				' AOI_Plant_Testing__c,AOI_Preconception_And_Fertility__c,AOI_Public_Health__c,AOI_Rare_And_Inherited_Disease__c '+
             				' from Contact where Area_Of_Interest__c!=null';
        return Database.getQueryLocator(strSoql);
    }
    /**Execute method of Batch Class */
    public override void execute(Database.BatchableContext bC, List<sObject> lstContact){
         List<Contact> lstContacts=new List<Contact>();
        for(Contact objCon:(List<Contact>) lstContact){
            Contact objConUpdate=new Contact(id=objCon.Id);
            String strAOIPickVal = objCon.Area_Of_Interest__c;
            list<String> aoilst=strAOIPickVal.split(';');
            for(String aoiVal:aoilst){
                if(aoiVal=='Agriculture Research'){
                    objConUpdate.AOI_Agriculture_Research__c=true;
                }
                else if(aoiVAL=='Animal Testing'){
                    objConUpdate.AOI_Animal_Testing__c=true;
                }
                else if(aoiVAL=='Applied Microbiology'){
                    objConUpdate.AOI_Applied_Microbiology__c=true;
                }
                
                else if(aoiVAL=='Autoimmune Disease Research'){
                    objConUpdate.AOI_Autoimmune_Disease_Research__c=true;
                }
                
                else if(aoiVAL=='Cancer Research'){
                    objConUpdate.AOI_Cancer_Research__c=true;
                }
                
                else if(aoiVAL=='Cardiovascular Disease Research'){
                    objConUpdate.AOI_Cardiovascular_Disease_Research__c=true;
                }
                
                else if(aoiVAL=='Cell And Molecular Biology Research'){
                    objConUpdate.AOI_Cell_And_Molecular_Biology_Research__c=true;
                }
                
                else if(aoiVAL=='Clinical Oncology'){
                    objConUpdate.AOI_Clinical_Oncology__c=true;
                }
                
                else if(aoiVAL=='Consumer Genomics'){
                    objConUpdate.AOI_Consumer_Genomics__c=true;
                }
                
                else if(aoiVAL=='Genetic And Complex Disease Research'){
                    objConUpdate.AOI_Genetic_And_Complex_Disease_Research__c=true;
                }
                
                else if(aoiVAL=='Genetic Health'){
                    objConUpdate.AOI_Genetic_Health__c=true;
                }
                
                else if(aoiVAL=='Metabolic Disease Research'){
                    objConUpdate.AOI_Metabolic_Disease_Research__c=true;
                }
                
                else if(aoiVAL=='Microbiology/Virology research'){
                    objConUpdate.AOI_Microbiology_Virology_Research__c=true;
                }
                
                else if(aoiVAL=='Neuroscience Research'){
                    objConUpdate.AOI_Neuroscience_Research__c=true;
                }
                else if(aoiVAL=='NIPT'){
                    objConUpdate.AOI_NIPT__c=true;
                }
                else if(aoiVAL=='Pharmacogenomics PGx'){
                    objConUpdate.AOI_Pharmacogenomics_PGx__c=true;
                }
                else if(aoiVAL=='Healthy Screening'){
                    objConUpdate.AOI_Healthy_Screening__c=true;
                }
                else if(aoiVAL=='Plant Testing'){
                    objConUpdate.AOI_Plant_Testing__c=true;
                }
                else if(aoiVAL=='Preconception And Fertility'){
                    objConUpdate.AOI_Preconception_And_Fertility__c=true;
                }
                else if(aoiVAL=='Public Health'){
                    objConUpdate.AOI_Public_Health__c=true;
                }
                
                else if(aoiVAL=='Rare and Inherited Disease'){
                    objConUpdate.AOI_Rare_And_Inherited_Disease__c=true;
                }
            }
            lstContacts.add(objConUpdate);
        }
        if(!lstContacts.isEmpty()){
           Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(p.Id);
            cs.Bypass_All_Validations__c = true;
            cs.Bypass_All_Triggers__c=true;
            upsert cs cs_Apex_Settings__c.Id;

            Database.update(lstContacts, false);
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