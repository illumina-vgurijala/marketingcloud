/**
 *  @author Charket
 *  @date   29-Mar-2024
 *  @description Trigger on WeChat Agent object.
 *  Used to transfer open WeChat chats to a backup agent when the agent status changes to 'Out of Office'
 **/
public without sharing class CharketCustomerCareAgents extends ilib_SObjectDomain {
    private static final String LOG_TITLE = 'CharketCustomerCareAgents';
    private static final String STANDARD_USER_TYPE = 'Standard';
    /**
     *  @author  Charket 
     *  @description Constructor method
     **/
    public CharketCustomerCareAgents(List<Charket__WeChatAgent__c> sObjectList) {
        super(sObjectList);
        if(FeatureManagement.checkPermission('Bypass_Person_Object_Permission')){
            Configuration.disableTriggerCRUDSecurity();
            ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
        }
    }
    
    /**
     *  @author  Charket 
     *  @description Param - List<sObject>
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*Method Param - List<sObject> */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new CharketCustomerCareAgents(sObjectList);
        }
    }

    /**
     *  @author  Charket 
     *  @description Runs on afterUpdate event of trigger
     **/
    public override void onAfterUpdate(Map<Id, SObject> idToAgent) {
        ilib_LogEvent.push(LOG_TITLE + 'onAfterUpdate');
        Boolean isStandardUser = UserInfo.getUserType() == STANDARD_USER_TYPE;
        if(idToAgent.size() > 1 || !isStandardUser) {
            return;
        }
        Charket__WeChatAgent__c newAgent = (Charket__WeChatAgent__c)Trigger.new.get(0);
        Charket__WeChatAgent__c oldAgent = (Charket__WeChatAgent__c)idToAgent.get(newAgent.Id);
        
        if(isStatusUpdatedToOutOfOffice(newAgent, oldAgent)){
            ilib_LogEvent.message('isStatusUpdatedToOutOfOffice=true');
            transferChats(newAgent);
        }
        ilib_LogEvent.pop();
    }

    /**
     *  @author  Charket 
     *  @description Transfer open chats to backup agent.
     **/
    public void transferChats(Charket__WeChatAgent__c agent){
        ilib_LogEvent.push(LOG_TITLE + 'transferChats');
        String wechatAccountId = agent.Charket__WeChatAccount__c;
        Charket__WeChatAgent__c backupAgent = new CharketSelector().selectActiveCustomerCareAgentByUserId(agent.BackupAgent__c, wechatAccountId);
        
        Boolean isBackupAcceptChat = CharketCustomerCareAgentSelector.isAcceptChat(backupAgent);
        if(!isBackupAcceptChat) return;
        ilib_LogEvent.message('backupAgent' + backupAgent);

        List<Charket__WeChatTranscript__c> transcriptsToUpdate = new List<Charket__WeChatTranscript__c>();
        List<Charket__WeChatTranscriptItem__c> lockItems = new List<Charket__WeChatTranscriptItem__c>();
        
        List<Charket__WeChatTranscript__c> openTranscripts = new CharketSelector().selectOpenTranscriptsByAgentId(agent.Id);
        ilib_LogEvent.message('openTranscriptsSize' + openTranscripts.size());
        
        for(Charket__WeChatTranscript__c openTranscript: openTranscripts){
            Charket__WeChatTranscriptItem__c lockItem = setLockItemFields(agent.Id, backupAgent, openTranscript.Id);
            lockItems.add(lockItem);

            openTranscript.Charket__WeChatAgent__c = backupAgent.Id;
            openTranscript.Charket__AgentAssignedTime__c = Datetime.now();
            transcriptsToUpdate.add(openTranscript);
        }
        ilib_LogEvent.message('transcriptsToUpdateSize' + transcriptsToUpdate.size());
        if(transcriptsToUpdate.size() > 0){
            insert lockItems;

            List<Charket__WeChatTranscriptItem__c> transferItems = new List<Charket__WeChatTranscriptItem__c>();
            for(Charket__WeChatTranscriptItem__c transferItem : lockItems){
                transferItem = setTransferItemFields(agent, backupAgent, transferItem);
                transferItems.add(transferItem);
            }

            update transferItems;

            update transcriptsToUpdate;
        }
        ilib_LogEvent.pop();
    }

    /**
     *  @author  Charket 
     *  @description check agent status.
     **/
    private Boolean isStatusUpdatedToOutOfOffice(Charket__WeChatAgent__c newAgent, Charket__WeChatAgent__c oldAgent) {
        return oldAgent.Charket__WeChatAgentStatus__c != newAgent.Charket__WeChatAgentStatus__c && 
            newAgent.Charket__CurrentStatus__c == 'Out of Office' && 
            newAgent.BackupAgent__c != null && 
            newAgent.Charket__IsActive__c && 
            newAgent.Charket__User__c != null;
    }

    /**
     *  @author  Charket 
     *  @description set transcript item fields.
     **/
    private Charket__WeChatTranscriptItem__c setLockItemFields(String agentId, Charket__WeChatAgent__c backupAgent, String transcriptId) {
        return new Charket__WeChatTranscriptItem__c(
            Charket__Type__c = 'Lock',
            Charket__IsActive__c = true,
            Charket__SendBy__c = 'System',
            Charket__SenderName__c = 'System',
            Charket__Body__c = '{"To":{"Id":"' + backupAgent.Id + '", "Name":"' + backupAgent.Name+ '"}}',
            Charket__WeChatTranscript__c = transcriptId,
            Charket__AgentId__c = agentId,
            Charket__WeChatCreatedTime__c = Datetime.now().getTime(),
            Charket__MsgId__c = String.valueOf(backupAgent.Id) + Datetime.now().getTime()
        );
    }

    /**
     *  @author  Charket 
     *  @description set transcript item fields.
     **/
    private Charket__WeChatTranscriptItem__c setTransferItemFields(Charket__WeChatAgent__c agent, Charket__WeChatAgent__c backupAgent, Charket__WeChatTranscriptItem__c transferItem) {
        transferItem.Charket__Body__c = '{"Comment":"", "To":{"Name":"' + backupAgent.Name +'","Id":"' + backupAgent.Id + '"},"From":{"Name":' + '"' + agent.Name +'"' + ',"Id":"' + agent.Id + '"}}';
        transferItem.Charket__Type__c = 'Transfer';
        transferItem.Charket__AgentId__c = backupAgent.Id;
        return transferItem;
    }
}