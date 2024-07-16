@isTest
public class LeaveApplicationTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        
        List<User> Users = new List<User>();
        User u = new user();
        u.FirstName = 'Employee 1';
        u.LastName = 'Test';
        u.Email = 'hello111@vx.com';
        u.Username = 'hello111@vx.com';
        u.Alias = 'test';
        u.Vacation_Balance__c = 30;
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        u.LanguageLocaleKey = 'en_US';
        Users.add(u);
        
        User u1 = new user();
        u1.FirstName = 'Manager 1';
        u1.LastName = 'Test';
        u1.Email = 'hello1111@vx.com';
        u1.Username = 'hello1111@vx.com';
        u1.Alias = 'test1';
        u1.TimeZoneSidKey = 'America/Los_Angeles';
        u1.LocaleSidKey = 'en_US';
        u1.EmailEncodingKey = 'UTF-8';
        u1.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        u1.LanguageLocaleKey = 'en_US';
        Users.add(u1);
        insert Users;
        
        User us = [Select ID from User where email = 'hello111@vx.com'];
        us.ManagerId = [Select ID from User where email = 'hello1111@vx.com'].Id;
        update us;
        
        List<German_Holiday__c> holidays = new List<German_Holiday__c>();
        holidays.add(new German_Holiday__c(Holiday_Date__c = Date.newInstance(2024, 08, 26)));
        insert holidays;

        Leave_Application__c leaveApplication = new Leave_Application__c(
            Employee__c = [select Id from User where email = 'hello111@vx.com'].Id,
            Start_Date__c = Date.newInstance(2024, 08, 24),
            End_Date__c = Date.newInstance(2024, 08, 30),
            Status__c = 'Draft'
        );
        insert leaveApplication;
    }
    
    @isTest
    static void testHolidayValidation() {
        List<Leave_Application__c> leaveApplications = [SELECT Id, Employee__c, Start_Date__c, End_Date__c, Status__c FROM Leave_Application__c];
        Test.startTest();
        LeaveApplicationTriggerHandler.updateBalance(leaveApplications);
        Test.stopTest();
    }
    
    @isTest
    static void testWorkingDaysCalculation() {
        User employee = [SELECT Id FROM User WHERE Email = 'hello111@vx.com' LIMIT 1];
        
        Leave_Application__c leaveApplication = new Leave_Application__c(
            Employee__c = employee.Id,
            Start_Date__c = Date.newInstance(2024, 8, 10),
            End_Date__c = Date.newInstance(2024, 8, 20),
            Status__c = 'Draft'
        );
        insert leaveApplication;
        
        leaveApplication.Status__c = 'Approved';
        update leaveApplication;
    }
    
    @isTest
    static void testAfterBalanceCalculation() {
        User employee = [SELECT Id FROM User WHERE Email = 'hello111@vx.com' LIMIT 1];
        
        Leave_Application__c leaveApplication = new Leave_Application__c(
            Employee__c = employee.Id,
            Start_Date__c = Date.newInstance(2024, 8, 10),
            End_Date__c = Date.newInstance(2024, 8, 20),
            Status__c = 'Draft'
        );
        insert leaveApplication;
        
        leaveApplication.Status__c = 'Approved';
        update leaveApplication;
        
        List<Leave_Application__c> newLeaves = [SELECT Id, Employee__c, Status__c, Initial_Balance__c, Balance__c FROM Leave_Application__c WHERE Id = :leaveApplication.Id];
        Map<Id, Leave_Application__c> oldLeavesMap = new Map<Id, Leave_Application__c>([SELECT Id, Status__c FROM Leave_Application__c WHERE Id = :leaveApplication.Id]);
        
        Test.startTest();
        LeaveApplicationTriggerHandler.CalcafterBalance(newLeaves, oldLeavesMap);
        Test.stopTest();
        
    }
    
    @isTest
    static void testERPUpdate() {
        User employee = [SELECT Id FROM User WHERE Email = 'hello111@vx.com' LIMIT 1];
        
        Leave_Application__c leaveApplication = new Leave_Application__c(
            Employee__c = employee.Id,
            Start_Date__c = Date.newInstance(2024, 8, 10),
            End_Date__c = Date.newInstance(2024, 8, 20),
            Status__c = 'Draft'
        );
        insert leaveApplication;
        
        leaveApplication.Status__c = 'Approved';
        update leaveApplication;
        
        List<Leave_Application__c> newLeaves = [SELECT Id, Employee__c, Status__c FROM Leave_Application__c WHERE Id = :leaveApplication.Id];
        Map<Id, Leave_Application__c> oldLeavesMap = new Map<Id, Leave_Application__c>([SELECT Id, Status__c FROM Leave_Application__c WHERE Id = :leaveApplication.Id]);
        
        Test.startTest();
        LeaveApplicationTriggerHandler.ERPUpdate(newLeaves, oldLeavesMap);
        Test.stopTest();
        
        // Validate mock callout
        // This is usually validated by checking the debug logs or using a mock HTTP callout
    }

}