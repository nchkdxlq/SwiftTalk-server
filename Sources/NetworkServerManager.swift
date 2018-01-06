//
//  NetworkServerManager.swift
//  PerfectTemplate
//
//  Created by nchkdxlq on 2017/12/17.
//

import Foundation
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

let serverConfig = [
    "servers": [
        [
            "name":"192.168.1.168",
            "port":10086,
            "routes": [
                ["method":"get", "uri":"/", "handler":helloWorldHandle],
                ["method":"post", "uri":"/user/register", "handler":userRegisterHandle],
                ["method":"get", "uri":"/user/user_info", "handler":userInfoRouteHandle],
                ["method":"post", "uri":"/user/update", "handler":userUpdateInfo],
                ["method":"post", "uri":"/user/modify_password", "handler":modifyPassword],
                ["method":"post", "uri":"/user/login", "handler":userLogin]
            ]
        ]
    ]
]


fileprivate func responseDataWithContent(_ content: Any? = nil,
                                         status: Int = 100200,
                                         message: String = "OK") -> [String: Any] {
    
    var responseData: [String: Any] = ["status":status, "message":message]
    if let _content = content {
        responseData["data"] = _content;
    }
    return responseData
}

fileprivate func completeResponse(_ response: HTTPResponse, content: [String: Any]?) {
    do {
        if let _content = content {
            try response.setBody(json: _content)
        }
    } catch {
        print("返回数据类型错误")
    }
    response.completed()
}


fileprivate func userInfoRouteHandle(_ request: HTTPRequest, _ response: HTTPResponse) {
    var responseInfo :[String: Any]? = nil;
    defer {
        completeResponse(response, content: responseInfo)
    }
    
    let urlPath = request.path;
    print("urlPath = ", urlPath)
    if let userAgent = request.header(.userAgent) {
        print("User-Agent", userAgent)
    }
    
    let accept =  request.header(.accept) ?? "empty"
    print("accept = ", accept)
    
    let contentType = request.header(.contentType) ?? "empty";
    print("contentType = ", contentType)
    
    guard let userId = request.param(name: "user_id") else {
        responseInfo = responseDataWithContent(nil, status: 100401, message: "less paramters")
        return;
    }
    print("userId = ", userId)
    
    let columns = ["user_id", "gender", "name", "address", "phone_num", "email", "avatar_url"]
    let dbResult = DatabaseManager.manager.queryUser(userId, values: columns)
    
    if let _ = dbResult.1 {
        responseInfo = responseDataWithContent(nil, status: 100501, message: "server db error")
        return;
    }
    
    responseInfo = responseDataWithContent(dbResult.0)
}

/*
 user_id
 password
 gender
 name
 email
 phone_num
 address

 */
fileprivate func userRegisterHandle(_ request: HTTPRequest, _ response: HTTPResponse) {
    var responseInfo :[String: Any]? = nil
    defer {
        completeResponse(response, content: responseInfo)
    }
    
    guard let userId = request.param(name: "user_id") else {
        responseInfo = responseDataWithContent(status: 100401, message: "name is nil")
        return
    }
    
    guard let password = request.param(name: "password") else {
        responseInfo = responseDataWithContent(status: 100401, message: "password is nil")
        return
    }

    let gender = request.param(name: "gender") ?? "F"
    
    let check_ret =  DatabaseManager.manager.checkExistForUserId(userId)
    if let dbError = check_ret.1 {
        print(dbError)
        responseInfo = responseDataWithContent(status: 100501, message: "server db error")
        return;
    }
    
    if check_ret.0 {
        responseInfo = responseDataWithContent(status: 100401, message: "\(userId) already registered")
        return;
    }
    let result = DatabaseManager.manager.insertUser(userId, password: password, gender: gender)
    
    if (result.0 == false) {
        print(result.1 ?? "")
        responseInfo = responseDataWithContent(status: 100501, message: "server db error")
        return
    }
    
    responseInfo = responseDataWithContent()
}


/*
 user_id
 password
 gender
 name
 email
 phone_num
 address
 
 */
fileprivate func userUpdateInfo(_ request: HTTPRequest, _ response: HTTPResponse) {
    var responseInfo :[String: Any]? = nil;
    defer {
        completeResponse(response, content: responseInfo)
    }
    
    guard let user_id = request.param(name: "user_id") else {
        responseInfo = responseDataWithContent(status: 100401, message: "user_id is nil")
        return;
    }
    
    var upateColumns = [String: Any]()
    if let name = request.param(name: "name") {
        upateColumns["name"] = name
    }
    if let gender = request.param(name: "gender") {
        upateColumns["gender"] = gender
    }
    if let email = request.param(name: "email") {
        upateColumns["email"] = email
    }
    if let phone_num = request.param(name: "phone_num") {
        upateColumns["phone_num"] = phone_num
    }
    if let address = request.param(name: "address") {
        upateColumns["address"] = address
    }
    
    if upateColumns.count == 0 {
        responseInfo = responseDataWithContent(status: 100401, message: "less paramters")
        return
    }
    
    let dbResult = DatabaseManager.manager.updateUser(user_id, values: upateColumns)
    if (dbResult.0) {
        responseInfo = responseDataWithContent()
    } else {
        responseInfo = responseDataWithContent(status: 100501, message: "server db error")
    }
}


fileprivate func modifyPassword(_ request: HTTPRequest, _ response: HTTPResponse) {
    var responseInfo: [String:Any]? = nil
    defer {
        completeResponse(response, content: responseInfo)
    }
    
    guard let user_id = request.param(name: "user_id") else {
        responseInfo = responseDataWithContent(status: 100401, message: "user_id is nil")
        return
    }
    
    guard let new_password = request.param(name: "new_password") else {
        responseInfo = responseDataWithContent(status: 100401, message: "new_password is nil")
        return
    }
    
    guard let old_password = request.param(name: "old_password") else {
        responseInfo = responseDataWithContent(status: 100401, message: "old_password is nil")
        return
    }
    
    let dbResult_1 = DatabaseManager.manager.queryUser(user_id, values: ["password"])
    
    // 数据库操作错误
    guard dbResult_1.1 == nil else {
        responseInfo = responseDataWithContent(status: 100501, message: "server db error")
        return
    }
    
    // 旧密码没能从数据库找出来
    guard let db_password = dbResult_1.0["password"] as? String else {
        responseInfo = responseDataWithContent(status: 100501, message: "server db error")
        return;
    }
    print("db_password = \(db_password)")
    print("old_password = \(old_password)")
    print("new_password = \(new_password)")
    // 旧密码错误, 密码比较可以交给数据库比较
    if old_password != db_password {
        responseInfo = responseDataWithContent(status: 100402, message: "old password incorrect")
        return
    }
    
    // 新密码与进密码相同
    if db_password == new_password {
        responseInfo = responseDataWithContent(status: 100402, message: "new password is same old")
        return
    }
    
    let dbResult = DatabaseManager.manager.updateUser(user_id, values: ["password": new_password])
    if dbResult.0 {
        responseInfo = responseDataWithContent()
    } else {
        responseInfo = responseDataWithContent(status: 100501, message: "server db error")
    }
}

fileprivate func userLogin(_ request: HTTPRequest, _ response: HTTPResponse) {
    var responseInfo: [String: Any]? = nil;
    defer {
        completeResponse(response, content: responseInfo)
    }
    
    guard let user_id = request.param(name: "user_id") else {
        responseInfo = responseDataWithContent(status: 100402, message: "user_id is empty")
        return
    }
    
    guard let password = request.param(name: "password") else {
        responseInfo = responseDataWithContent(status: 100402, message: "password is empty")
        return
    }
    
    let dbResult_1 = DatabaseManager.manager.queryUser(user_id, values: ["password"])
    
    // 数据库操作错误
    guard dbResult_1.1 == nil else {
        responseInfo = responseDataWithContent(status: 100501, message: "server db error")
        return
    }
    
    // 旧密码没能从数据库找出来
    guard let db_password = dbResult_1.0["password"] as? String else {
        responseInfo = responseDataWithContent(status: 100501, message: "server db error")
        return;
    }
    
    guard db_password == password else {
        responseInfo = responseDataWithContent(status: 100402, message: "password incorrect")
        return;
    }

    let token = UUID().string
    responseInfo = responseDataWithContent(["token": token])
}


fileprivate func helloWorldHandle(_ request: HTTPRequest, _ response: HTTPResponse) {
    response.setHeader(.contentType, value: "text/html")
    response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
    response.completed()
}


class NetworkServerManager {
    
    fileprivate let server = HTTPServer()
    
    init(host: String, port: UInt16) {
        server.serverAddress = host
        server.serverPort = port;
        configRoutes()
    }
    
    fileprivate func configRoutes() {
        
    }
    
    func start() {
        do {
            print("开启服务器")
            try server.start()
        } catch PerfectError.networkError(let code, let msg) {
            print("网络出现问题 code = \(code), msg = \(msg)")
        } catch {
            print("网络未知错误")
        }
    }
    
    static func startServer() {
        do {
            // Launch the servers based on the configuration data.
            try HTTPServer.launch(configurationData: serverConfig)
        } catch {
            fatalError("\(error)") // fatal error launching one of the servers
        }
    }
}
