/**
 *    @author Charket
 *    @date   29-Mar-2024
 *    @description : Assign WeChat chats to customer care users when the follower is matched with an SFDC contact.                
 **/
global without sharing class CharketCustomerCareAgentSelector implements Charket.WeChatAgentSelector {
    private static final String LOG_TITLE = 'CharketCustomerCareAgentSelector';
    private static final String TRANSFERTYPE = 'Transfer';
    private static final String TEXTTYPE = 'Text';
    private static Boolean hasRelatedContact;
    
    /**
     *  @author Charket
     *  @description Get the WeChat agent Id to assign chats
     **/
    global String getAgentId(Charket.WeChatAgentSelectorContext context) {
        ilib_LogEvent.push(LOG_TITLE + 'getAgentId');
        String agentId = null;
        String messageContent = null;
        Boolean isTransfer = context.MsgType == TRANSFERTYPE;
        Boolean isText = context.MsgType == TEXTTYPE;

        Boolean isValidMessage = (isTransfer || isText) && (CharketCustomerCareMessageHandler.isWeChatRetry == null || !CharketCustomerCareMessageHandler.isWeChatRetry);
        ilib_LogEvent.message('isValidMessage' + isValidMessage);
        Boolean isReadyToAssign = false;
        
        if(isValidMessage){
            Charket__WeChatFollower__c follower = new CharketSelector().selectWeChatFollowerByOpenId(context.FollowerOpenId);
            Boolean isValidFollower = follower != null && follower.Charket__WeChatAccount__c != null && !isChattingWithAgent(follower.Id);
            
            if(isValidFollower) {
                String endpoint = follower.Charket__WeChatAccount__r.Charket__SalesforceEndpoint__c;

                if(follower.IsContactVerified__c) {
                    isReadyToAssign = true;
                    agentId = getAgentId(follower.Charket__WeChatAccount__c, follower.Charket__Contact__r.AccountId);
                } else if(follower.IsEmailVerified__c) {
                    agentId = null;
                    messageContent = System.Label.WeChatWaitingMessage;
                } else if(follower.Charket__IndexedUnionId__c != null) {
                    agentId = getAgentIdByUnionId(follower.Charket__IndexedUnionId__c, follower);

                    if(hasRelatedContact) {
                        isReadyToAssign = true;
                    } else {
                        messageContent = CharketCustomerCareAgentSkill.getFormLink(follower.Charket__WeChatAccount__c, endpoint);
                    }
                } else {
                    agentId = null;
                    messageContent = CharketCustomerCareAgentSkill.getFormLink(follower.Charket__WeChatAccount__c, endpoint);
                }
            }
        }

        if(isText) {
            if(isReadyToAssign && agentId == null) {
                messageContent = System.Label.WeChatStartChatMessage;
            }

            if(String.isNotBlank(messageContent)) {
                sendWeChatMessage(messageContent, context.FollowerOpenId);
            }
        }

        ilib_LogEvent.message('messageContent' + messageContent);
        ilib_LogEvent.pop();
        return agentId;
    }

    /**
     *  @author Charket
     *  @description Send wechat message to followers
     **/
    @future(callout=true)
    public static void sendWeChatMessage(String messageContent, String openId) {
        ilib_LogEvent.push(LOG_TITLE + 'sendWeChatMessage');
        try{
            Charket__WeChatFollower__c follower = new CharketSelector().selectWeChatFollowerByOpenId(openId);
            if(follower != null) {
                sendWeChatTextMessage(messageContent, openId, follower.Charket__WeChatAccount__c);
                Charket__WeChatTranscript__c openTranscript = new CharketSelector().selectOpenTranscriptByFollowerId(follower.Id);
                if(openTranscript == null) {
                    openTranscript = new Charket__WeChatTranscript__c(
                        Charket__FollowerOpenId__c = openId, 
                        Charket__IsActive__c = true,
                        Charket__Status__c = 'Waiting',
                        Charket__WeChatFollower__c = follower.Id
                    );
                    upsert openTranscript Charket__WeChatTranscript__c.fields.Charket__FollowerOpenId__c;
                }

                Charket__WeChatTranscriptItem__c botItem = setBotItemFields(openTranscript.Id, openId, messageContent);
                insert botItem;
            }
        } catch(Exception ex) {
            ilib_LogEvent.info('Exception' + ex.getMessage());
        }
        ilib_LogEvent.pop();
    }

    /**
     *  @author  Charket 
     *  @description set transcript item fields
     **/
    public static Charket__WeChatTranscriptItem__c setBotItemFields(String transcriptId, String openId, String messageContent) {
        ilib_LogEvent.push(LOG_TITLE + 'setBotItemFields');
        ilib_LogEvent.pop();
        return new Charket__WeChatTranscriptItem__c(
            Charket__BotType__c = 'Auto Reply',
            Charket__Sendby__c = 'Charket Bot',
            Charket__SenderName__c = 'Charket Bot',
            Charket__WeChatTranscript__c = transcriptId,
            Charket__WeChatCreatedTime__c = Datetime.now().getTime(),
            Charket__Type__c = 'TEXT',
            Charket__MsgId__c = Datetime.now().getTime() + openId,
            Charket__Body__c = '{"IsKeyword":false,"Content":"' + messageContent.escapeJava() + '"}',
            Charket__ShortBody__c = '{"IsKeyword":false,"Content":"' + messageContent.escapeJava().left(200) + '"}',
            Charket__Content__c = messageContent,
            Charket__IsActive__c = true
        );
    }

    /**
    *  @author Charket
    *  @description check if is a valid online agent
    **/
    public static Boolean isAcceptChat(Charket__WeChatAgent__c agent) {
        return agent != null && agent.Charket__IsAcceptsChats__c && agent.Charket__LastDesktopActiveTime__c != null;
    }

    /**
     *  @author  Charket 
     *  @description Send text message to WeChat follower
     **/
    private static void sendWeChatTextMessage(String content, String openId, String wechatAccountId) {
        ilib_LogEvent.push(LOG_TITLE + 'sendWeChatTextMessage');
        if(content != null && openId != null && wechatAccountId != null) {
            Charket.WeChatApiMessage responseMessage = new Charket.WeChatApiMessage.Text(content);
            responseMessage.ToUserId = openId;
            Charket.WeChatClient client = new Charket.WeChatClient(wechatAccountId);
            client.getAgent().sendMessage(responseMessage);
        }
        ilib_LogEvent.pop();
    }

    /**
     *  @author Charket
     *  @description Check if the follower is chatting with an agent
     **/
    private static Boolean isChattingWithAgent(String followerId) {
        ilib_LogEvent.push(LOG_TITLE + 'isChattingWithAgent');
        Charket__WeChatTranscript__c transcript = new CharketSelector().selectOpenTranscriptByFollowerId(followerId);
        ilib_LogEvent.pop();
        return transcript != null && transcript.Charket__WeChatAgent__c != null;
    }

    /**
     *  @author Charket
     *  @description Get the WeChat agent Id when the follower has union id
     **/
    private static String getAgentIdByUnionId(String unionId, Charket__WeChatFollower__c follower) {
        ilib_LogEvent.push(LOG_TITLE + 'getAgentIdByUnionId');
        Charket__WeChatFollower__c unionFollower = new CharketSelector().selectVerifiedFollowerByUnionId(unionId);
        
        hasRelatedContact = unionFollower != null && unionFollower.Charket__Contact__c != null;
        ilib_LogEvent.message('hasRelatedContact' + hasRelatedContact);
        
        if(hasRelatedContact) {
            String agentId = getAgentId(follower.Charket__WeChatAccount__c, unionFollower.Charket__Contact__r.AccountId);
            
            Charket__WeChatFollower__c newFollower = new Charket__WeChatFollower__c(
                Id = follower.Id,
                Charket__Contact__c = unionFollower.Charket__Contact__c,
                IsContactVerified__c = true
            );
            update newFollower;

            ilib_LogEvent.pop();
            return agentId;
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author Charket
     *  @description Get the WeChat agent Id when the follower is matched with an SFDC contact
     **/
    private static String getAgentId(String wechatAccountId, String accountId) {
        ilib_LogEvent.push(LOG_TITLE + 'getAgentId');
        String agentId;
        if(accountId != null) {
            agentId = getAccountAgentId(wechatAccountId, accountId);
        }

        if(agentId == null) {
            ilib_LogEvent.pop();
            return getRandomOnlineAgentId(wechatAccountId);
        }
        ilib_LogEvent.pop();
        return agentId;
    }

    /**
    *  @author Charket
    *  @description Get the WeChat agent Id when the Account of the contact has a related Field Support with the "Customer care specialist" user role
    **/
    private static String getAccountAgentId(String wechatAccountId, Id accountId) {
        ilib_LogEvent.push(LOG_TITLE + 'getAccountAgentId');
        List<Account_to_Field_Support__c> accountToFieldSupports = new CharketSelector().selectAccountSpecialistById(accountId);
        
        if(accountToFieldSupports.size() > 0) {
            return getUserAgent(wechatAccountId, accountToFieldSupports[0].Salesforce_User_ID__c);
        }
        ilib_LogEvent.pop();
        return null;
    }

    /**
    *  @author Charket
    *  @description Get the WeChat agent Id by the Salesforce User Id
    **/
    private static String getUserAgent(String wechatAccountId, Id userId) {
        if(wechatAccountId != null && userId != null) {
            Charket__WeChatAgent__c agent = new CharketSelector().selectActiveCustomerCareAgentByUserId(userId, wechatAccountId);

            if (agent != null) {
                if(isAcceptChat(agent)) {
                    return agent.Id;
                } else if(agent.BackupAgent__c != null) {
                    Charket__WeChatAgent__c backupAgent = new CharketSelector().selectActiveCustomerCareAgentByUserId(agent.BackupAgent__c, wechatAccountId);
                    if(isAcceptChat(backupAgent)) {
                        return backupAgent.Id;
                    }
                }
            }
        }
        return null;
    }

    /**
    *  @author Charket
    *  @description Get a random online agent
    **/
    private static String getRandomOnlineAgentId(String wechatAccountId) {
        Charket__WeChatAgent__c agent = new CharketSelector().selectRandomCustomerCareOnlineAgent(wechatAccountId);
        if(agent != null) {
            return agent.Id;
        }
        return null;
    }
}