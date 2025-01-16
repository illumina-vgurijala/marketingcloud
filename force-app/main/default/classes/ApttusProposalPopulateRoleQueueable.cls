/*@ author       : Khushbu Vasani
* @ date         : 13-06-2022
* @ Description  : Populate created by role and submitted by role
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Khushbu Vasani          03-06-2022                 DCP-54390             Initial version
* 
*/
public class ApttusProposalPopulateRoleQueueable implements Queueable
{
    private static final String LOG_TITLE = 'ApttusProposalPopulateRoleQueueable';
    private static final String CHANNEL_PARTNER = 'Channel_Partner';
    List<Apttus_Proposal__Proposal__c> lstProposal=new List<Apttus_Proposal__Proposal__c>();
    Id submittedById;

    /*Parameterised Constructor */
    public ApttusProposalPopulateRoleQueueable(List<Apttus_Proposal__Proposal__c> lstProposal, Id submittedByUser) {
        this.lstProposal = lstProposal;
        this.submittedById = submittedByUser;
    }

    /*Execute*/
    public void execute(QueueableContext qc) {
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push(LOG_TITLE + '.execute');

        try {
            populateUserRole();
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
        }   
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /**
    *  @author Khushbu Vasani
    *  @description Update the Quotes with created by role nad submitted by role
    **/
    public void populateUserRole()
    {
        ilib_LogEvent.push(LOG_TITLE+'populateCreatedByUserRole()');
       
        Set<Id> setUserID = new Set<ID>();
        Set<Id> setSoldToDistributorAccountId = new Set<ID>();
        Map<Id, Id> mapQuoteCreatedById = new Map<Id,Id>();
        Map<Id, Id> mapQuoteSoldToAccountId = new Map<Id,Id>(); 
        Map<Id, Id> mapQuoteDistributorAccountId = new Map<Id,Id>(); 
        
        getDataFromProposal(setUserID, setSoldToDistributorAccountId, mapQuoteCreatedById, mapQuoteSoldToAccountId,mapQuoteDistributorAccountId);
       
        List<UserTerritory2Association> listUserTerriAssoc = new UserTerritory2AssociationSelector().selectByUserIds(setUserID);
        if(listUserTerriAssoc != null && !listUserTerriAssoc.isEmpty())
        {
            Map<Id, List<UserTerritory2Association>> mapUserTerriAssoc = getUserTerriData(listUserTerriAssoc);
          
            Map<Id, List<ObjectTerritory2Association>> mapObjectTerriAssoc = getObjectTerriAssociation(setSoldToDistributorAccountId);
           
            populateUserRoleOnProposal(mapUserTerriAssoc, mapObjectTerriAssoc);
        }    
        
        ilib_LogEvent.pop();
    }

    private  Map<Id, List<UserTerritory2Association>> getUserTerriData(List<UserTerritory2Association> listUserTerriAssoc)
    {      

        Map<Id, List<UserTerritory2Association>> mapUserTerriAssoc = new Map<Id, List<UserTerritory2Association>>();
        for(UserTerritory2Association userTerri : listUserTerriAssoc)
        {
            if(!mapUserTerriAssoc.containskey(userTerri.userId))
            {
                mapUserTerriAssoc.put(userTerri.userId,new List<UserTerritory2Association>());               
            }
            mapUserTerriAssoc.get(userTerri.userId).add(userTerri);
        }
        ilib_LogEvent.info('user to territory association' + listUserTerriAssoc);

        return mapUserTerriAssoc;
    }

    private  Map<Id, List<ObjectTerritory2Association>> getObjectTerriAssociation(set<Id> setSoldToDistributorAccountId)
    {
        List<ObjectTerritory2Association> listObjectTerriAssoc = new ObjectTerritory2AssociationsSelector().selectByAccountIdsNonGlobal(setSoldToDistributorAccountId);

        Map<Id, List<ObjectTerritory2Association>> mapObjectTerriAssoc = new Map<Id, List<ObjectTerritory2Association>>();
        
        for(ObjectTerritory2Association objTerr : listObjectTerriAssoc)
        {
            if(!mapObjectTerriAssoc.containskey(objTerr.ObjectId))
            {
                mapObjectTerriAssoc.put(objTerr.ObjectId,new List<ObjectTerritory2Association>());               
            }
            mapObjectTerriAssoc.get(objTerr.ObjectId).add(objTerr);
        }
        ilib_LogEvent.info('Object to territory association' + listObjectTerriAssoc);

        return mapObjectTerriAssoc;
    }

    private void populateUserRoleOnProposal(Map<Id, List<UserTerritory2Association>> mapUserTerriAssoc,Map<Id, List<ObjectTerritory2Association>> mapObjectTerriAssoc){
        List<Apttus_Proposal__Proposal__c> lstUpdatedRole = new List<Apttus_Proposal__Proposal__c>();
            for (Apttus_Proposal__Proposal__c prpsl : lstProposal)
            {
                List<UserTerritory2Association> userTerr;
                if(this.submittedById != null)
                {
                    userTerr = mapUserTerriAssoc.get(this.submittedById);
                }
                else{
                    userTerr = mapUserTerriAssoc.get(prpsl.CreatedByID);
                } 
                List<ObjectTerritory2Association> objTerri = mapObjectTerriAssoc.get(prpsl.Apttus_Proposal__Account__c);
                              
                string userRole;
                // For direct quote, check sold to account territory to match with user territory
                if(Opportunities.DIRECT_RECORD_TYPES.contains(prpsl.Opportunity_Record_Type__c))
                {
                    userRole = getUserRoleForDirect(objTerri, prpsl, userTerr);
                   
                }
                else{
                    if(prpsl.Direct_Sale_to_Ultimate_Consignee__c)
                    {
                        objTerri = mapObjectTerriAssoc.get(prpsl.Distributor__c);
                    }
                    userRole = getUserRoleForChannelPartner(objTerri, prpsl, userTerr);
                }
                if(!string.isBlank(userRole))
                {   Apttus_Proposal__Proposal__c updatedPrpsl = new Apttus_Proposal__Proposal__c();
                    updatedPrpsl.id= prpsl.id;
                    if(this.submittedById != null)
                    {
                        updatedPrpsl.Submitted_By_Role__c = userRole;
                    }
                    else{
                        updatedPrpsl.Created_By_Role__c = userRole;   
                    }
                    lstUpdatedRole.add(updatedPrpsl);
                }
            } 
            if(!lstUpdatedRole.isEmpty())
            {
                update lstUpdatedRole; 
            }
    }

    private void getDataFromProposal( Set<Id> setUserID,  Set<Id> setSoldToDistributorAccountId, Map<Id, Id> mapQuoteCreatedById, Map<Id, Id> mapQuoteSoldToAccountId, Map<Id, Id> mapQuoteDistributorAccountId)
    {
        for (Apttus_Proposal__Proposal__c prpsl : lstProposal)
        {
            if(this.submittedById != null)
            {
                setUserID.add(this.submittedById);
                mapQuoteCreatedById.put(prpsl.Id, this.submittedById);
            }
            else{
                setUserID.add(prpsl.CreatedByID);
                mapQuoteCreatedById.put(prpsl.Id, prpsl.CreatedByID);
            }
            setSoldToDistributorAccountId.add(prpsl.Apttus_Proposal__Account__c);           
            mapQuoteSoldToAccountId.put(prpsl.Id, prpsl.Apttus_Proposal__Account__c);
            mapQuoteDistributorAccountId.put(prpsl.Id, prpsl.Distributor__c);
            setSoldToDistributorAccountId.add(prpsl.Distributor__c);
        }
    }
    private string getUserRoleForDirect(List<ObjectTerritory2Association> objTerri,Apttus_Proposal__Proposal__c prpsl,List<UserTerritory2Association> userTerr )
    {
        for(ObjectTerritory2Association terr : objTerri)
        {
            if(terr.ObjectId == prpsl.Apttus_Proposal__Account__c)
            {
                // Check for Sales territory hierarchy for direct quotes
                if(!terr.Territory2.Territory2Type.DeveloperName.contains(CHANNEL_PARTNER))
                {
                    for(UserTerritory2Association userTerritory : userTerr)
                    {
                        if(checkTerritoryMatches(userTerritory, terr))
                        {
                            ilib_LogEvent.Info('User Role Found' + userTerritory.RoleInTerritory2);

                            return userTerritory.RoleInTerritory2;                        
                        }
                    }
                }
            }           
                
        }
        
        ilib_LogEvent.info('User Role Not Found');
        return userTerr[0].RoleInTerritory2;
    }
    

    private string getUserRoleForChannelPartner(List<ObjectTerritory2Association> objTerri,Apttus_Proposal__Proposal__c prpsl,List<UserTerritory2Association> userTerr)
    {
        Id accountId = prpsl.Apttus_Proposal__Account__c;
        if(prpsl.Direct_Sale_to_Ultimate_Consignee__c)
        {
            accountId = prpsl.Distributor__c;
            ilib_LogEvent.info('Consider disctributor account' +  prpsl.Distributor__c);
        }
        for(ObjectTerritory2Association terr : objTerri)
        {            
            if(terr.ObjectId == accountId)
            {
                 // Check for CP territory hierarchy for direct quotes
                if(terr.Territory2.Territory2Type.DeveloperName.contains(CHANNEL_PARTNER))
                {
                    for(UserTerritory2Association userTerritory : userTerr)
                    {
                        if(checkTerritoryMatches(userTerritory, terr))
                        {
                            ilib_LogEvent.message('User Role Found' + userTerritory.RoleInTerritory2);
                        
                            return userTerritory.RoleInTerritory2;                        
                        }
                    }
                }
            }           
                
        }
        
        ilib_LogEvent.info('User Role Not Found');
        return userTerr[0].RoleInTerritory2;        
    }

    private boolean checkTerritoryMatches(UserTerritory2Association userTerritory, ObjectTerritory2Association terr)
    {
        boolean match = false;
        if(userTerritory.Territory2.Name == terr.Territory2.Name ||
        userTerritory.Territory2.Name == terr.Territory2.ParentTerritory2.Name ||
        userTerritory.Territory2.Name == terr.Territory2.ParentTerritory2.ParentTerritory2.Name ||
        userTerritory.Territory2.Name == terr.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name ||
        userTerritory.Territory2.Name == terr.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name)
        {
            match = true;
        }

        return match;
    }
}