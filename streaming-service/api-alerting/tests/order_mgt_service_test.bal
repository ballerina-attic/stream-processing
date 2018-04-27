import ballerina/test;
import ballerina/http;
import ballerina/runtime;

any[] outputs = [];
int count = 0;
// This is the mock function which will replace the real function
@test:Mock {
    packageName: "ballerina.io",
    functionName: "println"
}
public function mockPrint(any... s) {
    outputs[count] = s[0];
    count++;
}

@test:BeforeSuite
function beforeFunc() {
    // Start the 'order_mgt' service before running the test.
    _ = test:startServices("api-alerting");
}

endpoint http:Client clientEP {
    url:"http://localhost:9090/ordermgt"
};

@test:Config
// Function to test POST resource 'addOrder'.
function testOrderAlerts() {
    int reqIndex = 0;
    // Initialize the empty http request.
    http:Request request = new;
    // Construct the request payload.
    json payload = {"Order":{"ID":"100500", "Name":"XYZ", "Description":"Sample order."}};
    request.setJsonPayload(payload);
    while (reqIndex <=20) {
        // Send 'POST' request and obtain the response.
        http:Response response = check clientEP -> post("/order", request = request);
        // Expected response code is 201.
        test:assertEquals(response.statusCode, 201,
            msg = "addOrder resource did not respond with expected response code!");
        // Check whether the response is as expected.
        json resPayload = check response.getJsonPayload();
        test:assertEquals(resPayload.toString(),
            "{\"status\":\"Order Created.\",\"orderId\":\"100500\"}", msg = "Response mismatch!");
        reqIndex = reqIndex + 1;
    }
    // Wait till we get the alert in stdout. Note that outputs array mocks the stdout
    while (!(lengthof outputs > 0)) {
        runtime:sleep(500);
    }

    test:assertEquals(outputs[0], "ALERT!! : Received more than 10 requests" +
            " within 10 seconds from the host: localhost:9090");
}

@test:AfterSuite
function afterFunc() {
    // Stop the 'order_mgt' service after running the test.
    test:stopServices("api-alerting");
}