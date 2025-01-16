/***************************************************************************************************************************************
 * NAME   : LightningLoginFormControllerTest
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Rishab                   17-Jan-2022         CodeScan Fixes
 * Sheikh Shahnawaz         28-sep-2022         Code Coverage Enhancement
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
@IsTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

 @IsTest
 static void lightningLoginFormControllerInstantiation() {
  LightningLoginFormController controller = new LightningLoginFormController();
  System.assertNotEquals(null,controller);
 }

 @IsTest
 static void testIsUsernamePasswordEnabled() {
  System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
 }

 @IsTest
 static void testIsSelfRegistrationEnabled() {
  System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
 }

 @IsTest
 static void testGetSelfRegistrationURL() {
  System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
 }

 @IsTest
 static void testAuthConfig() {
  Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
  System.assertNotEquals(null, authConfig);
  
 }
  
 @IsTest
 static void testSetExperienceId() {
 String returnType = LightningLoginFormController.setExperienceId('TestExId');
 LightningLoginFormController.getForgotPasswordUrl();
 LightningLoginFormController.login('username',  'password',  'startUrl');
 System.assertNotEquals(null, returnType);
 } 
}