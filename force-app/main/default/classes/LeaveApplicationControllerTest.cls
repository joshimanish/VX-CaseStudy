@isTest
public class LeaveApplicationControllerTest {

    @TestSetup
    static void setupTestData() {
        List<User> users = new List<User>();

        User manager = new User(
            FirstName = 'Manager',
            LastName = 'Test',
            Email = 'manager@vx.com',
            Username = 'manager@vx.com',
            Alias = 'mgr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LanguageLocaleKey = 'en_US'
        );
        users.add(manager);

        User employee = new User(
            FirstName = 'Employee',
            LastName = 'Test',
            Email = 'employee@vx.com',
            Username = 'employee@vx.com',
            Alias = 'emp',
            Vacation_Balance__c = 30,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LanguageLocaleKey = 'en_US'
        );
        users.add(employee);

        insert users;

        employee = [SELECT Id FROM User WHERE Email = 'employee@vx.com' LIMIT 1];
        manager = [SELECT Id FROM User WHERE Email = 'manager@vx.com' LIMIT 1];
        employee.ManagerId = manager.Id;
        update employee;
    }

    @isTest
    static void testGetLeaveTypes() {
        Test.startTest();
        List<String> leaveTypes = LeaveApplicationController.getLeaveTypes();
        Test.stopTest();

        System.assertNotEquals(null, leaveTypes, 'Leave types should not be null.');
    }

    @isTest
    static void testGetVacationBalance() {
        Test.startTest();
        Decimal vacationBalance = LeaveApplicationController.getVacationBalance();
        Test.stopTest();

        System.assertEquals(15, vacationBalance, 'Vacation balance should be 30.');
    }

    @isTest
    static void testCreateLeaveApplication() {
        User employee = [SELECT Id FROM User WHERE Email = 'employee@vx.com' LIMIT 1];

        Test.startTest();
        LeaveApplicationController.createLeaveApplication(
            employee.Id,
            Date.newInstance(2024, 8, 10),
            Date.newInstance(2024, 8, 20),
            'Vacation',
            'Family trip'
        );
        Test.stopTest();

        List<Leave_Application__c> leaveApplications = [SELECT Employee__c, Start_Date__c, End_Date__c, Type_of_Leave__c, Status__c, Manager__c FROM Leave_Application__c];
        
        System.assertNotEquals(0, leaveApplications.size(), 'There should be at least one leave application.');
        System.assertEquals(employee.Id, leaveApplications[0].Employee__c, 'Employee ID should match.');
        System.assertEquals(Date.newInstance(2024, 8, 10), leaveApplications[0].Start_Date__c, 'Start date should match.');
        System.assertEquals(Date.newInstance(2024, 8, 20), leaveApplications[0].End_Date__c, 'End date should match.');
        System.assertEquals('Draft', leaveApplications[0].Status__c, 'Status should be "Draft".');
        System.assertNotEquals(null, leaveApplications[0].Manager__c, 'Manager ID should not be null.');
    }
}