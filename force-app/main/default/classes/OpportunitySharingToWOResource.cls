/**
*    @author Akshay Mohan
*    @date   2021-06-14
*    @description    DCP-38968
*    Test Class for 75% Coverage : TestDataBillableFlowQueueable,TestPopulateLastPMDateOnIP,TestPreventativeMaintenance_WOHelper,TestServiceReportEmailController,TestWorkOrderBulkUpdateController,TestWorkOrderDataSender
*    Test Class for 90% Coverage : TestDataBillableFlowQueueable,TestPopulateLastPMDateOnIP,TestPreventativeMaintenance_WOHelper,TestServiceReportEmailController,TestWorkOrderBulkUpdateController,TestWorkOrderDataSender
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                 Date                Description
*         Akshay Mohan              2021-06-14          Initial Version
*		  Anshaj Sinha              2022-08-23          CMSI-202 : Modified class with instrumentation guidelines and changed message methods to info
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class OpportunitySharingToWOResource implements Queueable{

    private final Id idWorkOrder;
    private final Boolean boolIsDelete;
    private final List<SVMXC__Work_Order_Resource__c> lstWOResources;
    public static Boolean catchException = false;
    
    public static final String LOG_TITLE = 'OpportunitySharingToWOResource';

    /**
    *   DCP-38968
	*	@author Akshay Mohan
	*	@param Id idWorkOrder,Boolean boolIsDelete, List<SVMXC__Work_Order_Resource__c> lstWOResources
	*	@return N/A
	**/
    public OpportunitySharingToWOResource(Id idWorkOrder,Boolean boolIsDelete,List<SVMXC__Work_Order_Resource__c> lstWOResources){
        this.idWorkOrder=idWorkOrder;
        this.boolIsDelete=boolIsDelete;
        this.lstWOResources=lstWOResources; 
    }
    /**
    *   DCP-38968
	*	@author Akshay Mohan
	*	@param QueueableContext
	*	@return void
	**/
    public void execute(QueueableContext objQC){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            SVMXC__Service_Order__c objWO = null ;
            List<SVMXC__Service_Order__c> objWOList =new WorkOrdersSelector().selectWorkOrders(new Set<ID>{idWorkOrder});//To address List index out of bounds Exception - INC0500761
            if(objWOList != null && !objWOList.isEmpty()){
                objWO = objWOList[0];
            }
            if(objWO != null){//To avoid null pointer exception
            if(String.isBlank(objWO.Opportunity__c)){
                ilib_LogEvent.info('No Opportunity on WO-->'+idWorkOrder);
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return;
            }
            Id idOpp=objWO.Opportunity__c;
            ilib_LogEvent.info('idOpp-->'+idOpp);
            ilib_LogEvent.info('boolIsDelete-->'+boolIsDelete);
        
            List<OpportunityShare> lstOppShares= getOpportunityShareRecordsToProcess(idOpp,getUserToResourceMap());
            if(lstOppShares.isEmpty()){
                ilib_LogEvent.info('No sharing change needed');
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return;
            }
            if(boolIsDelete){
                delete lstOppShares;
            }else{
                insert lstOppShares;
            }
            ilib_LogEvent.info('Sharing success');
            ilib_LogEvent.info('lstOppShares Ids : '+UtilsCollection.getSetOfIds(lstOppShares));
            }
             if(catchException == true){
                throw new AuraHandledException('Throwing Custom Exception');
            }
        }catch(Exception e){
            ilib_LogEvent.error('Exception-->'+e.getMessage());
            ilib_LogEvent.error('Exception Stack trace-->'+e.getStackTraceString());
            ApexExceptions.emit(LOG_TITLE,idWorkOrder,e, ilib_LogEvent.SALES);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }

        ilib_LogEvent.pop();
		ilib_LogEvent.emit();
    }

    /**
    *   DCP-38968
	*	@author Akshay Mohan
	*	@param NA
	*	@return Set<Id>
	**/
    private Set<Id> getUserToResourceMap(){
        ilib_LogEvent.push(LOG_TITLE + '.getUserToResourceMap()');
        Set<Id> setUserIds = new Set<Id>();
        Set<Id> setTechnicians= new Set<Id>();
        for(SVMXC__Work_Order_Resource__c objResource : lstWOResources){
            setTechnicians.add(objResource.SVMXC__Group_Member__c);
        }
        for(SVMXC__Service_Group_Members__c objTechnician : new TechniciansSelector().selectTechnicians(setTechnicians)){
            setUserIds.add(objTechnician.SVMXC__Salesforce_User__c);
        }
        ilib_LogEvent.info('setUserIds size-->'+setUserIds.size());
        ilib_LogEvent.info('setUserIds-->'+setUserIds);
        ilib_LogEvent.pop();
        return setUserIds;
    }

    /**
    *   DCP-38968
	*	@author Akshay Mohan
	*	@param Id idOpp,Set<Id> setUserIds
	*	@return List<OpportunityShare>
	**/
    private List<OpportunityShare> getOpportunityShareRecordsToProcess(Id idOpp,Set<Id> setUserIds){
        ilib_LogEvent.push(LOG_TITLE + '.getOpportunityShareRecordsToProcess()');
        ilib_LogEvent.info('idOpp : '+idOpp);
        List<OpportunityShare> lstOppShares = new List<OpportunityShare>();
        for(OpportunityShare objExistingShare : (List<OpportunityShare>)new TAPS_BatchImpl(new TAPS_Opportunity()).getExtantShares(new Set<Id>{idOpp})){
            if(boolIsDelete && setUserIds.contains(objExistingShare.UserorGroupId)){
                //Need to delete existing shares
                lstOppShares.add(objExistingShare);
            }else if(!boolIsDelete && setUserIds.contains(objExistingShare.UserorGroupId)){
                //Need to insert shares so remove already shared users. Any record found would have at minimum read access
                setUserIds.remove(objExistingShare.UserorGroupId);
            }
        }
        ilib_LogEvent.info('setUserIds : '+setUserIds);
        if(!boolIsDelete && !setUserIds.isEmpty()){
            ilib_LogEvent.info('Users exist for sharing');
            for(Id idUser : setUserIds){
                lstOppShares.add(new OpportunityShare(
                                                UserOrGroupId = idUser,
                                                OpportunityAccessLevel = 'Read',
                                                RowCause = Schema.OpportunityShare.RowCause.Manual,
                                                OpportunityId=idOpp));
            }
        }
        ilib_LogEvent.info('lstOppShares size-->'+lstOppShares.size());
        ilib_LogEvent.info('lstOppShares-->'+lstOppShares);
        ilib_LogEvent.pop();
        return lstOppShares;
    }
}