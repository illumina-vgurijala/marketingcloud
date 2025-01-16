/**
 *    @author Charket
 *    @date   29-Mar-2024
 *    @description : Automatically send a message when a WeChat follower clicks on the "Contact Us" menu.              
 **/
global without sharing class CharketCustomerCareAgentSkill implements Charket.CharketSkillHandler {
    private static final String LOG_TITLE = 'CharketCustomerCareAgents';
    private static final String PAGE_NAME = '/CharketCustomerCare?wid=';
    
    /**
     *  @author Charket
     *  @description Send a message when clicking on the wechat menu
     **/
    global Charket.SkillResponse execute(Charket.SkillContext context, Charket.SkillSession session) {
        ilib_LogEvent.push(LOG_TITLE + 'execute');
        try{
            String openId = context.WeChatEvent != null ? context.WeChatEvent.FromUserId : context.WeChatMessage.FromUserId;
            String originId = context.WeChatEvent != null ? context.WeChatEvent.ToUserId : context.WeChatMessage.ToUserId;
            String messageContent;
        
            Charket__WeChatFollower__c follower = new CharketSelector().selectWeChatFollowerByOpenId(openId);
            if(follower == null || follower.Charket__WeChatAccount__c == null){
                Charket__WeChatAccount__c wechatAccount = new CharketSelector().selectWeChatAccountByOriginId(originId);
                if(wechatAccount != null){
                    String endpoint = wechatAccount.Charket__SalesforceEndpoint__c;
                    messageContent = getFormLink(wechatAccount.Id, endpoint);
                }
            } else {
                if(follower.IsContactVerified__c){
                    messageContent = System.Label.WeChatStartChatMessage;
                } else if(follower.IsEmailVerified__c) {
                    messageContent = System.Label.WeChatWaitingMessage;
                } else {
                    String endpoint = follower.Charket__WeChatAccount__r.Charket__SalesforceEndpoint__c;
                    String formMessage = getFormLink(follower.Charket__WeChatAccount__c, endpoint);

                    if(follower.Charket__IndexedUnionId__c != null){
                        Charket__WeChatFollower__c unionFollower = new CharketSelector().selectVerifiedFollowerByUnionId(follower.Charket__IndexedUnionId__c);
                        if(unionFollower != null && unionFollower.Charket__Contact__c != null){
                            follower.Charket__Contact__c = unionFollower.Charket__Contact__c;
                            follower.IsContactVerified__c = true;
                            update follower;
        
                            messageContent = System.Label.WeChatStartChatMessage;
                        } else {
                            messageContent = formMessage;
                        }
                    } else {
                        messageContent = formMessage;
                    }
                }
            }
            ilib_LogEvent.message('messageContent' + messageContent);
            if(String.isNotBlank(messageContent)){
                session.ShouldEndSession = true;
                return new Charket.SkillResponse(new Charket.WeChatApiMessage.Text(messageContent)); 
            }
        } catch(Exception ex) {
            ilib_LogEvent.info('Exception' + ex.getMessage());
        }    
        
        session.ShouldEndSession = true; 
        ilib_LogEvent.pop();
        return null;
    }

    /**
     *  @author Charket
     *  @description Get the link of page
     **/
    public static String getFormLink(String wechatAccountId, String endpoint){
        if(endpoint != null){
            String formLink = endpoint + PAGE_NAME + wechatAccountId;
            return System.Label.WeChatFormLinkMessage.replace('{0}', formLink);
        }

        return null;
    }
}