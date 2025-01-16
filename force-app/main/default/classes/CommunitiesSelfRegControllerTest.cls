/**
 * An apex page controller that supports self registration of users in communities that allow self registration
 */
@IsTest public with sharing class CommunitiesSelfRegControllerTest {
    /**Method - Test method for CommunitiesSelfRegController */
    @IsTest(SeeAllData=true) 
    public static void testCommunitiesSelfRegController() {
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        CommunitiesSelfRegController controller2 = new CommunitiesSelfRegController();
        controller.firstName = 'FirstName';
        controller.lastName = 'LastName';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';
        
        controller2.firstName = '';
        controller2.lastName = '';
        controller2.email = '';
        controller2.communityNickname = '';
        
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assertEquals(null,controller.registerUser());    
        System.assertEquals(null,controller2.registerUser());
        
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        
        controller2.password = 'null';
        controller2.confirmPassword = '';
        
        System.assertEquals(null,controller.registerUser());  
        System.assertEquals(null,controller2.registerUser());  
    }    
}