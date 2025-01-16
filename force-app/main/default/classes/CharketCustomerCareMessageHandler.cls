/**
 *    @author Charket
 *    @date   01-April-2024
 *    @description : This class is executed when a follower sends a message from WeChat.                
 **/
global without sharing class CharketCustomerCareMessageHandler extends Charket.CharketMessageHandler {
    public static Boolean isWeChatRetry { get; set; }
    /**
     *  @author Charket
     *  @description Execute when receive a text message
     **/
    global override Charket.WeChatApiMessage onTextMessageReceived(Charket.WeChatApiMessage.Text message) {
        isWeChatRetry = message.CreateTime.addSeconds(5) <= Datetime.now();
        return null;
    }
}