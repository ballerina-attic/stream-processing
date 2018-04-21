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

```
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






