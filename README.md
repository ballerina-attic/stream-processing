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
- [Output](#)  
 
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


### Forever Statement Block
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
    forever{
        from teacherStream where age > 18 window lengthBatch(3)
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
type temperature{
  int deviceID;
  int roomNo;
  float value;  
}

type roomTemperature{
  int roomNo;
  float value;  
}

stream<temperature> tempStream;


from tempStream 
select roomNo, value
=> (roomTemperature[] temperature){

      //Do whatever with the output event  
      
}
```

## What you'll build

For better understand understanding let's take a real world usecase and implement that using Ballerina streaming features.

Let's assume, that you are a API developer and you have published few APIs to the API store. There are subscribers who
are subscribed to those APIs as well. At this situation, you wanted to build an alert generation mechanism which send
you an alert in below conditions.

- API request from a black listed user IP
- No of API requests from same IP is greater than 10 in 10 seconds.


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

    //Gather all the events that are coming to requestStream for five seconds, group them by the host, count the number
    //of requests per host, and check if the count is more than six. If yes, publish the output (host and the count) to
    //the `requestCountStream` stream as an alert. This `forever` block is executed once, when initializing the service.
    // The processing happens asynchronously each time the `requestStream` receives an event.
    forever {
        from requestStream
        window time(10000)
        select host, count(host) as count group by host having count > 5
        => (RequestCount [] counts) {
                //The 'counts' is the output of the streaming rules and is published to the `requestCountStream`.
                //The `select` clause should match the structure of the 'RequestCount' struct.
                requestCountStream.publish(counts);
        }
    }
}

// Define the `printRequestCount` function.
function printRequestCount (RequestCount reqCount) {
    io:println("ALERT!! : Received more than 6 requests from the host within 5 seconds: " + reqCount.host);
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

    @Description {value:"Resource that handles the HTTP GET requests that are directed
    to a specific order using path '/orders/<orderID>'"}
    @http:ResourceConfig {
        methods:["GET"],
        path:"/order/{orderId}"
    }
    findOrder(endpoint client, http:Request req, string orderId) {
	string hostName = untaint req.getHeader("Host");
	sendRequestEventToStream(hostName);	

        // Find the requested order from the map and retrieve it in JSON format.
        json? payload = ordersMap[orderId];
        http:Response response;
        if (payload == null) {
            payload = "Order : " + orderId + " cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client -> respond(response);
    }

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

    @Description {value:"Resource that handles the HTTP PUT requests that are directed
    to the path '/orders' to update an existing Order."}
    @http:ResourceConfig {
        methods:["PUT"],
        path:"/order/{orderId}"
    }
    updateOrder(endpoint client, http:Request req, string orderId) {

	string hostName = untaint req.getHeader("Host");
	sendRequestEventToStream(hostName);	

        json updatedOrder = check req.getJsonPayload();

        // Find the order that needs to be updated and retrieve in JSON format.
        json existingOrder = ordersMap[orderId];

        // Updating existing order with the attributes of the updated order.
        if (existingOrder != null) {
            existingOrder.Order.Name = updatedOrder.Order.Name;
            existingOrder.Order.Description = updatedOrder.Order.Description;
            ordersMap[orderId] = existingOrder;
        } else {
            existingOrder = "Order : " + orderId + " cannot be found.";
        }

        http:Response response;
        // Set the JSON payload to the outgoing response message to the client.
        response.setJsonPayload(existingOrder);
        // Send response to the client.
        _ = client -> respond(response);
    }

    @Description {value:"Resource that handles the HTTP DELETE requests, which are
    directed to the path '/orders/<orderId>' to delete an existing Order."}
    @http:ResourceConfig {
        methods:["DELETE"],
        path:"/order/{orderId}"
    }
    cancelOrder(endpoint client, http:Request req, string orderId) {

	string hostName = untaint req.getHeader("Host");
	sendRequestEventToStream(hostName);	

        http:Response response;
        // Remove the requested order from the map.
        _ = ordersMap.remove(orderId);

        json payload = "Order : " + orderId + " removed.";
        // Set a generated payload with order status.
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client -> respond(response);
    }
}

```

- With that we've completed the development of the order_mgt_service and api_alert implementation. 

