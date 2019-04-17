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

import ballerina/http;

function sendRequestEventToStream(string hostName) {
    ClientRequest clientRequest = {
        host: hostName
    };
    requestStream.publish(clientRequest);
}

listener http:Listener ep = new (9090);

// Order management is done using an in memory map.
// Add some sample orders to 'ordersMap' at startup.
map<json> ordersMap = {

};

// RESTful service.
@http:ServiceConfig {
    basePath: "/ordermgt"
}
service orderMgt on ep {

    future<()> ftr = start initRealtimeRequestCounter();

    // Resource that handles the HTTP POST requests that are directed to the path
    // '/orders' to create a new Order.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/order"
    }
    resource function addOrder(http:Caller con, http:Request req) returns error? {

        string hostName = untaint con.remoteAddress.host;
        sendRequestEventToStream(hostName);

        json orderReq = <json> req.getJsonPayload();
        string orderId = orderReq.Order.ID.toString();
        ordersMap[orderId] = orderReq;

        // Create response message.
        json payload = {
            status: "Order Created.",
            orderId: untaint orderId
        };
        http:Response response = new;
        response.setJsonPayload(payload);

        // Set 201 Created status code in the response message.
        response.statusCode = 201;
        // Set 'Location' header in the response message.
        // This can be used by the client to locate the newly added order.
        response.setHeader("Location", "http://localhost:9090/ordermgt/order/" +
        orderId);

        // Send response to the client.
        _ = check con->respond(response);
    }
}
