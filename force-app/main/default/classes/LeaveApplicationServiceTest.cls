@isTest
public class LeaveApplicationServiceTest {

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

        // Create test holidays
        List<German_Holiday__c> holidays = new List<German_Holiday__c>();
        holidays.add(new German_Holiday__c(Holiday_Date__c = Date.newInstance(2024, 12, 25))); // Christmas
        insert holidays;

        // Create test leave applications
        List<Leave_Application__c> leaveApplications = new List<Leave_Application__c>();

        leaveApplications.add(new Leave_Application__c(
            Employee__c = employee.Id,
            Start_Date__c = Date.newInstance(2024, 10, 10),
            End_Date__c = Date.newInstance(2024, 10, 15),
            Type_of_Leave__c = 'Vacation',
            Status__c = 'In Progress'
        ));

        leaveApplications.add(new Leave_Application__c(
            Employee__c = employee.Id,
            Start_Date__c = Date.newInstance(2024, 12, 10),
            End_Date__c = Date.newInstance(2024, 12, 20),
            Type_of_Leave__c = 'Sick Leave',
            Status__c = 'Draft'
        ));

        insert leaveApplications;
    }

    @isTest
    static void testGetLeaveApplicationsValidUser() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/leaveApplication/employee@vx.com';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<Leave_Application__c> leaveApplications = LeaveApplicationService.getLeaveApplications();
        Test.stopTest();

        System.assertNotEquals(null, leaveApplications, 'Leave applications should not be null for a valid user.');
        System.assertEquals(2, leaveApplications.size(), 'There should be 2 leave applications returned.');
    }

    @isTest
    static void testGetLeaveApplicationsInvalidUser() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/leaveApplication/nonexistent@vx.com';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<Leave_Application__c> leaveApplications = LeaveApplicationService.getLeaveApplications();
        Test.stopTest();
    }

}