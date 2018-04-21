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









