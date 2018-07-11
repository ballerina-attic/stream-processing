// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;

type ClientRequest record {
    string host;
};

type RequestCount record {
    string host;
    int count;
};

stream<ClientRequest> requestStream;

function initRealtimeRequestCounter () {

    stream<RequestCount> requestCountStream;

    //Whenever the `requestCountStream` stream receives an event from the streaming rules defined in the `forever` block,
    //the `alertRequestCount` function is invoked.
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
    io:println("ALERT!! : Received more than 10 requests within 10 seconds from the host: ", reqCount.host);
}
