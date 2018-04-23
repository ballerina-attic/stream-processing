import ballerina/io;
import wso2/gmail;

type ClientRequest {
    string host;
};

type RequestCount {
    string host;
    int count;
};

endpoint gmail:Client gMailEP {
    clientConfig:{
        auth:{
            accessToken:"access-token",
            clientId:"client-id",
            clientSecret:"client-secret",
            refreshToken:"refresh-token"
        }
    }
};

stream<ClientRequest> requestStream;

function initRealtimeRequestCounter () {

    stream<RequestCount> requestCountStream;

    //Whenever the `requestCountStream` stream receives an event from the streaming rules defined in the `forever` block,
    //the `printRequestCount` function is invoked.
    requestCountStream.subscribe(alertRequestCount);

    //Gather all the events that are coming to requestStream for ten seconds, group them by the host, count the number
    //of requests per host, and check if the count is more than 10. If yes, publish the output (host and the count) to
    //the `requestCountStream` stream as an alert. This `forever` block is executed once, when initializing the service.
    // The processing happens asynchronously each time the `requestStream` receives an event.
    forever {
        from requestStream
        window time(10000)
        select host, count(host) as count
        group by host
        having count > 10
        => (RequestCount [] counts) {
                //The 'counts' is the output of the streaming rules and is published to the `requestCountStream`.
                //The `select` clause should match the structure of the 'RequestCount' struct.
                requestCountStream.publish(counts);
        }
    }
}

// Define the `alertRequestCount` function.
function alertRequestCount (RequestCount reqCount) {
    gmail:MessageRequest messageRequest;
    messageRequest.recipient = "recipient@mail.com";
    messageRequest.sender = "sender@mail.com";
    messageRequest.subject = "Too many orders!!";
    messageRequest.messageBody = "Received more than 10 requests from the host within 10 seconds: " + reqCount.host;
    //Set the content type of the mail as TEXT_PLAIN or TEXT_HTML.
    messageRequest.contentType = gmail:TEXT_PLAIN;

    //Call the GMail endpoint function sendMessage().
    var sendMessageResponse = gMailEP -> sendMessage("me", messageRequest);
    match sendMessageResponse {
        (string, string) sendStatus => {
            //For a successful message request, returns message and thread id.
            string messageId;
            string threadId;
            (messageId, threadId) = sendStatus;
            io:println("Sent Message Id : " + messageId);
            io:println("Sent Thread Id : " + threadId);
        }
        gmail:GMailError e => io:println(e); //For unsuccessful attempts, returns GMail Error.
    }
}
