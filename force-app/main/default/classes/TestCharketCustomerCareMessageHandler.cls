/**
 *  @author Charket
 *  @date   01-April-2024
 *  @description Test class for CharketCustomerCareMessageHandler
 **/
@isTest
public class TestCharketCustomerCareMessageHandler {
    /** @DESCRIPTION - test handler **/
    @isTest
    static void testHandler() {
        Charket.WeChatApiMessage.Text message = new Charket.WeChatApiMessage.Text('hello');
        message.FromUserId = 'abcdefg123456';
        message.ToUserId = 'gh_e8c4857297b0';
        message.Content = 'hello';
        message.CreateTime =  Datetime.now().addSeconds(-10);

        CharketCustomerCareMessageHandler handler = new CharketCustomerCareMessageHandler();
        handler.onTextMessageReceived(message);
        system.assert(CharketCustomerCareMessageHandler.IsWeChatRetry);
    }
}