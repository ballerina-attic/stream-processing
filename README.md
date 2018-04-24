Ballerina Streaming Guide
=========================

This guide provides an understanding on Ballerina streaming capabilities and you will be learn on building a 
comprehensive streaming usecase with Ballerina Streams.

The following are the sections available in this guide.

- [Overview on Ballerina Streams](#overview)
- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Developing queries](#developing-queries)
- [Testing](#testing)
- [Deployment](#deployment)
- [Output](#output)  
 
## Overview 

Ballerina Streaming is designed to process event streams in a streaming manner, detect complex event occurrences, 
and notify them in real-time.

Ballerina Streaming supports the following:
 
* Data preprocessing
* Generating alerts based on thresholds
* Calculating aggregations over a short window or a long time period
* Joining multiple data streams
* Correlating data while finding missing and erroneous events
* Detecting temporal event patterns
* Tracking (something over space or time)
* Analyzing trends (rise, fall, turn, tipple bottom)
* And many more ...  


### Forever Statement
Streaming processing and Complex Event Processing rules can be written in side the forever statement block. Multiple
streaming queries can put together in a single Forever block. 

**Purpose**

Each streaming query within forever block is an isolated processing unit that independent to each other.

**Grammar**

Multiple streaming queries can sit together inside a single Forever statement block. Please refer the grammar below.

```antlrv4
foreverStatement
    :   FOREVER LEFT_BRACE  streamingQueryStatement+ RIGHT_BRACE
    ;   
    
streamingQueryStatement
    :   FROM (streamingInput (joinStreamingInput)? | patternClause)
        selectClause?
        orderByClause?
        outputRateLimit?
        streamingAction
    ;        
```

**Example**

Query to filter out the teachers who are older than 30 years, wait until three teacher objects are collected by the 
stream, group the 10 teachers based on their marital status, and calculate the unique marital status count of the 
teachers. Once the query is executed, publish the result to the `filteredStatusCountStream` stream.

```sql
    forever {
        from teacherStream where age > 18 window lengthBatch (3)
        select status, count(status) as totalCount
        group by status
        having totalCount > 1
        => (StatusCount [] status) {
                filteredStatusCountStream.publish(status);
        }
    }
```

### Stream
A stream is a logical series of events ordered in time. Its schema is defined/constrained via the **object definition**.
A object definition contains a unique name and a set of attributes with specific types and uniquely identifiable names 
within the object. All the events that are selected to be received into a specific stream have the same schema 
(i.e., have the same attributes in the same order). 

**Purpose**

By defining a schema it unifies common types of events together. This enables them to be processed via queries 
using their defined attributes in a streaming manner.

**Syntax**

The syntax for defining a new stream is as follows.

```sql
type <object name>  {
    <attribute type> <attribute name>;
    <attribute type> <attribute name>;
    <attribute type> <attribute name>;
    ...
};

stream<object name> <stream name>;
```
The following parameters are configured in a stream definition.

| Parameter     | Description |
| ------------- |-------------|
| `stream name`      | The name of the stream created. |
| `attribute name`   | The schema of an object is defined by its attributes with uniquely identifiable attribute names.|  
| `attribute type`   | The type of each attribute defined in the object.    |


**Example**
```sql
type Employee {
    string name;
    int age;
    string status;
};

stream<Employee> employeeStream;
```
The above creates a stream named `employeeStream` that constrained by `Employee` type which contain below attributes.

+ `name` of type `string`
+ `age` of type `int` 
+ `status` of type `string` 

### Query

Each streaming query can consume one or more streams, process the events in a streaming manner, and then generate an
 output.

**Purpose**

A query enables you to perform complex event processing and stream processing operations by processing incoming events 
one by one in the order they arrive.

**Syntax**

All queries contain an input and an output section. Some also contain a projection section. A simple query with all 
three sections is as follows.

```sql
from <input stream> 
select <attribute name>, <attribute name>, ...
=> (<array type> <parameter name>) {
      ...
      ...
}
```

**Example**

This query consumes events from the `TempStream` stream (that is already defined) and outputs the room temperature and the room number to the `RoomTempStream` stream.

```sql
type temperature {
  int deviceID;
  int roomNo;
  float value;  
}

type roomTemperature {
  int roomNo;
  float value;  
}

stream<temperature> tempStream;


from tempStream 
select roomNo, value
=> (roomTemperature[] temperature) {

      //Do whatever with the output event  
      
}
```


#### Query Projection

Streaming queries supports the following for query projections.

<table style="width:100%">
    <tr>
        <th>Action</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>Selecting required objects for projection</td>
        <td>This involves selecting only some of the attributes from the input stream to be inserted into an output stream.
            <br><br>
            E.g., The following query selects only the `roomNo` and `temp` attributes from the `TempStream` stream.
            <pre style="align:left">from TempStream<br>select roomNo, temp<br>=> ( ) { <br/><br/>}</pre>
        </td>
    </tr>
    <tr>
        <td>Selecting all attributes for projection</td>
        <td>Selecting all the attributes in an input stream to be inserted into an output stream. This can be done by using asterisk ( * ) or by omitting the `select` statement.
            <br><br>
            E.g., Both the following queries select all the attributes in the `TempStream` stream.
            <pre>from TempStream<br>select *<br>=> ( ) { <br/><br/>}</pre>
            or
            <pre>from TempStream<br>=> ( ) { <br/><br/>}</pre>
        </td>
    </tr>
    <tr>
        <td>Renaming attributes</td>
        <td>This selects attributes from the input streams and inserts them into the output stream with different names.
            <br><br>
            E.g., This query renames `roomNo` to `roomNumber` and `temp` to `temperature`.
            <pre>from TempStream <br>select roomNo as roomNumber, temp as temperature<br>=> ( ) { <br/><br/>}</pre>
        </td>
    </tr>
    <tr>
        <td>Introducing the constant value</td>
        <td>This adds constant values by assigning it to an attribute using `as`.
            <br></br>
            E.g., This query specifies 'C' to be used as the constant value for `scale` attribute. 
            <pre>from TempStream<br>select roomNo, temp, 'C' as scale<br>=> ( ) { <br/><br/>}</pre>
        </td>
    </tr>
    <tr>
        <td>Using mathematical and logical expressions</td>
        <td>This uses attributes with mathematical and logical expressions in the precedence order given below, and assigns them to the output attribute using `as`.
            <br><br>
            <b>Operator precedence</b><br>
            <table style="width:100%">
                <tr>
                    <th>Operator</th>
                    <th>Distribution</th>
                    <th>Example</th>
                </tr>
                <tr>
                    <td>
                        ()
                    </td>
                    <td>
                        Scope
                    </td>
                    <td>
                        <pre>(cost + tax) * 0.05</pre>
                    </td>
                </tr>
                <tr>
                    <td>
                         == NULL
                    </td>
                    <td>
                        Null check
                    </td>
                    <td>
                        <pre>deviceID == null</pre>
                    </td>
                </tr>
                <tr>
                    <td>
                        !
                    </td>
                    <td>
                        Logical NOT
                    </td>
                    <td>
                        <pre>! (price > 10)</pre>
                    </td>
                </tr>
                <tr>
                    <td>
                         *   /   %  
                    </td>
                    <td>
                        Multiplication, division, modulo
                    </td>
                    <td>
                        <pre>temp * 9/5 + 32</pre>
                    </td>
                </tr>
                <tr>
                    <td>
                        +   -  
                    </td>
                    <td>
                        Addition, substraction
                    </td>
                    <td>
                        <pre>temp * 9/5 - 32</pre>
                    </td>
                </tr>
                <tr>
                    <td>
                        <   <=   >   >=
                    </td>
                    <td>
                        Comparators: less-than, greater-than-equal, greater-than, less-than-equal
                    </td>
                    <td>
                        <pre>totalCost >= price * quantity</pre>
                    </td>
                </tr>
                <tr>
                    <td>
                        ==   !=  
                    </td>
                    <td>
                        Comparisons: equal, not equal
                    </td>
                    <td>
                        <pre>totalCost !=  price * quantity</pre>
                    </td>
                </tr>
                <tr>
                    <td>
                        AND
                    </td>
                    <td>
                        Logical AND
                    </td>
                    <td>
                        <pre>temp < 40 and (humidity < 40 or humidity >= 60)</pre>
                    </td>
                </tr>
                <tr>
                    <td>
                        OR
                    </td>
                    <td>
                        Logical OR
                    </td>
                    <td>
                        <pre>temp < 40 or (humidity < 40 and humidity >= 60)</pre>
                    </td>
                </tr>
            </table>
            E.g., Converting Celsius to Fahrenheit and identifying rooms with room number between 10 and 15 as server rooms.
            <pre>from TempStream<br>select roomNo, temp * 9/5 + 32 as temp, 'F' as scale, roomNo > 10 and roomNo < 15 as isServerRoom<br>=> (RoomFahrenheit [] events ) { <br/><br/>}</pre>
    </tr>
    
</table>

## What you'll build

For better understand let's take a real world usecase and implement that using Ballerina streaming features.

Let's assume, that you are a API developer and you have published few APIs to the API store. There are subscribers who
are subscribed to those APIs as well. 

Here, we are focusing on below scenario where we have a order management service which allow to add order. At this 
situation, you wanted to build an alert generation mechanism which send you an alert in below conditions. 

- API/Service request from a black listed user IP
- No of API/Service requests is greater than 10 in 10 seconds from same IP 

-- Need a Diagram


## Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)


## Developing queries

> If you want to skip the basics, you can download the git repo and directly move to "Testing" section by skipping 
"Developing" section.

### Create the project structure

Ballerina is a complete programming language that can have any custom project structure that you wish. Although the 
language allows you to have any package structure, use the following package structure for this project to follow 
this guide.

```
streaming-service
  └── api-alerting
      ├── order_mgt_service.bal
      ├── api_alert.bal
      └── test
          └── order_mgt_service_test.bal          
```
You can create the above Ballerina project using Ballerina project initializing toolkit.

- First, create a new directory in your local machine as `streaming-service` and navigate to the directory using terminal. 
- Then enter the following inputs to the Ballerina project initializing toolkit.
```bash
streaming-service$ ballerina init -i
Create Ballerina.toml [yes/y, no/n]: (y) y
Organization name: (mohan) api-alerting
Version: (0.0.1) 
Ballerina source [service/s, main/m]: (s) s
Package for the service : (no package) api-alerting
Ballerina source [service/s, main/m, finish/f]: (f) f

Ballerina project initialized
```

- Once you initialize your Ballerina project, you can change/add the names of the file to match with our guide project file 
names.

### Implement the streaming queries

- Let's write streaming query as mentioned below. Forever statement contains the streaming queries that relevant for this
usecase/scenario.

##### api_alert.bal
```ballerina

import ballerina/io;

type ClientRequest {
    string host;
};

type RequestCount {
    string host;
    int count;
};

stream<ClientRequest> requestStream;

function initRealtimeRequestCounter () {

    stream<RequestCount> requestCountStream;

    //Whenever the `requestCountStream` stream receives an event from the streaming rules defined in the `forever` block,
    //the `printRequestCount` function is invoked.
    requestCountStream.subscribe(printRequestCount);

    //Gather all the events that are coming to requestStream for ten seconds, group them by the host, count the number
    //of requests per host, and check if the count is more than ten. If yes, publish the output (host and the count) to
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

// Define the `printRequestCount` function.
function printRequestCount (RequestCount reqCount) {
    io:println("ALERT!! : Received more than 10 requests from the host within 10 seconds: " + reqCount.host);
}

```

- We can get started with a Ballerina service; 'order_mgt_service', which is the RESTful service that serves the order 
management request. order_mgt_service can have multiple resources and each resource is dedicated for a specific order 
management functionality. 

- You can add the content to your Ballerina service as shown below. In that code segment you can find the implementation 
of the service 'order_mgt_service'.
 
For each order management operation, there is a dedicated resource and inside each resource we can implement the 
order management operation logic. Here we are using the order_mgt_service.bal file that used in restful-service guide 
to explain how streaming queries can be used with some modification which calls a function to send an event to the 
stream.

##### order_mgt_service.bal
```ballerina

import ballerina/http;
import ballerina/mime;

function sendRequestEventToStream (string hostName) {
        ClientRequest clientRequest = {host : hostName};
        requestStream.publish(clientRequest);
}

endpoint http:Listener listener {
    port:9090
};

// Order management is done using an in memory map.
// Add some sample orders to 'orderMap' at startup.
map<json> ordersMap;

@Description {value:"RESTful service."}
@http:ServiceConfig {basePath:"/ordermgt"}
service<http:Service> order_mgt bind listener {

    // Invoke function to initialise streming queries
    future ftr = start initRealtimeRequestCounter();

    @Description {value:"Resource that handles the HTTP POST requests that are directed
     to the path '/orders' to create a new Order."}
    @http:ResourceConfig {
        methods:["POST"],
        path:"/order"
    }
    addOrder(endpoint client, http:Request req) {

	string hostName = untaint req.getHeader("Host");
	sendRequestEventToStream(hostName);	

        json orderReq = check req.getJsonPayload();
        string orderId = orderReq.Order.ID.toString();
        ordersMap[orderId] = orderReq;

        // Create response message.
        json payload = {status:"Order Created.", orderId:orderId};
        http:Response response;
        response.setJsonPayload(payload);

        // Set 201 Created status code in the response message.
        response.statusCode = 201;
        // Set 'Location' header in the response message.
        // This can be used by the client to locate the newly added order.
        response.setHeader("Location", "http://localhost:9090/ordermgt/order/" + orderId);

        // Send response to the client.
        _ = client -> respond(response);
    }
}

```

- With that we've completed the development of the order_mgt_service and api_alert implementation. 

### Customize the streaming queries to send email alerts

In Above implementation, we simply generate a log to the stdout. An extended version of the above implementation would
be, sending the alert as an email. Following shows you how to configure the gmail connector to send email as alerts.

- Add following code fragment to api_alert.bal as a global variable (in the same scope the ClientRequest and RequestCount types are defined).
For more information on how ballerina gmail connector is configured, please refer [here](https://github.com/wso2-ballerina/package-gmail/blob/master/Readme.md)
You have to replace "access-token", "client-id", "client-secret", "refresh-token" with your OAuth credentials.
For more information on Google OAuth 2.0 applications, please refer [here](https://developers.google.com/identity/protocols/OAuth2)

```ballerina
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
```

- Replace the function body of 'printRequestCount' with the following code fragment. Then instead of printing a log,
the program will send an email alert to the respective receipient.
you have to replace the recipient@mail.com and sender@mail.com with a correct reciepient and sender email addresses.

```ballerina
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
```

## Testing

As mentioned in previous steps, we have to invoke above developed order management service to get the alert generated 
from streaming queries. Either, we have to send more than 10 requests from same host with in 10 seconds or make a
service request from a blacklisted host to get an alert generate.


### Invoking the service 

You can run the service that you developed above, in your local environment. Open your terminal and navigate to 
`<SAMPLE_ROOT_DIRECTORY>/streaming-service` and execute the following command.

```
$ballerina run api-alerting
```
NOTE: You need to have the Ballerina installed in you local machine to run the Ballerina service.  

You can test the functionality of the order management service by sending HTTP request to 'order' operation. 
For example, we have used the curl commands to test each operation of OrderMgtService as follows. 

**Create Order** 
```
curl -v -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://localhost:9090/ordermgt/order" -H "Content-Type:application/json"

Output :  
< HTTP/1.1 201 Created
< Content-Type: application/json
< Location: http://localhost:9090/ordermgt/order/100500
< Transfer-Encoding: chunked
< Server: wso2-http-transport

{"status":"Order Created.","orderId":"100500"} 
```

## Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### Deploying locally

- As the first step you can build a Ballerina executable archive (.balx) of the service that we developed above, 
using the following command. It points to the directory in which the service we developed above located and it will 
create an executable binary out of that. Navigate to the `<SAMPLE_ROOT>/api-alerting/` folder and run the following command. 

```
$ballerina build api-alerting
```

- Once the api-alerting.balx is created inside the target folder, you can run that with the following command. 

```
$ballerina run target/api-alerting.balx
```

- The successful execution of the service should show us the following output. 
```
$ ballerina run target/api-alerting.balx 

ballerina: deploying service(s) in 'target/api-alerting.balx'
ballerina: started HTTP/WS server connector 0.0.0.0:9090
```

### Deploying on Docker

You can run the service that we developed above as a docker container. As Ballerina platform offers native support for 
running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. 

### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for 
running a ballerina programs on Kubernetes, with the use of Kubernetes annotations that you can include as part of 
your service code. Also, it will take care of the creation of the docker images. So you don't need to explicitly create 
docker images prior to deploying it on Kubernetes. 

Refer [here](https://github.com/ballerina-guides/restful-service#deployment) for more deployment options.


## Output

You will see a log line as shown below, when you invoke the service by satisfying one of the 
criteria for alert.

```
ALERT!! : Received more than 10 requests from the host within 10 seconds: localhost:9090

```
