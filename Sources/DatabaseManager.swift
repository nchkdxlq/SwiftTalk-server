//
//  DatabaseManager.swift
//  PerfectTemplate
//
//  Created by nchkdxlq on 2017/12/22.
//

import Foundation
import PerfectMySQL


/*
 +------------+--------------+------+-----+---------+-------+
 | Field      | Type         | Null | Key | Default | Extra |
 +------------+--------------+------+-----+---------+-------+
 | user_id    | varchar(30)  | NO   | PRI | NULL    |       |
 | password   | varchar(30)  | YES  |     | NULL    |       |
 | gender     | varchar(1)   | YES  |     | F       |       |
 | address    | varchar(100) | YES  |     | NULL    |       |
 | name       | varchar(30)  | YES  |     | NULL    |       |
 | phone_num  | varchar(20)  | YES  |     | NULL    |       |
 | email      | varchar(20)  | YES  |     | NULL    |       |
 | avatar_url | varchar(100) | YES  |     | NULL    |       |
 +------------+--------------+------+-----+---------+-------+

 */
class DatabaseManager: NSObject {
    
    typealias DBResult = (exist: Bool, error: String?)
    
    static let manager = DatabaseManager()
    
    let user_db = MySQL()
    
    private override init() {
        super.init()
        
        config_user_database()
        
    }
    
    private func config_user_database() {
        let ret = user_db.connect(host: "127.0.0.1", user: "root", password: "luoquan", db: "swift_talk_user")
        if ret == false {
            print("connect falied, \(user_db.errorMessage())")
            return
        }
        print("connect user database success")
        
        create_user_table()
    }
    
    private func create_user_table() {
        
        let sql = "create table if not exists user_tbl(indentifier VARCHAR(20) NOT NULL, gender VARCHAR(1) NOT NULL, address VARCHAR(100) NOT NULL)"
        
        let ret = user_db.query(statement: sql)
        if ret == false {
            print(user_db.errorMessage())
        }
    }
    
    func checkExistForUserId(_ userId: String) -> DBResult {
        let sql = "SELECT COUNT(*) FROM user_tbl WHERE user_id = '\(userId)'"
        if user_db.query(statement: sql) {
            if let results = user_db.storeResults() {
                var rets = [[String?]]()
                results.forEachRow(callback: { (row) in
                    rets.append(row)
                })
                let row = rets.first!
                let column = row.first!
                let count = Int(column!) ?? 0
                return(count > 0, nil)
            } else {
                return (false, nil)
            }
        } else {
            return (false, user_db.errorMessage())
        }
    }

    func insertUser(_ userId: String, password: String, gender: String) -> DBResult  {
        let sql = "INERT INTO user_tbl(user_id, password, gender) VALUES('\(userId)', '\(password)', '\(gender)')"
        
        if user_db.query(statement: sql) {
            return(true, nil)
        }
        return (false, user_db.errorMessage())
    }
    
    func queryUser(_ userId: String, values: [String]) -> ([String: Any], String?) {
        
        let sql = "SELECT \(values.joined(separator: ",")) FROM user_tbl WHERE user_id = '\(userId)'";
        
        if user_db.query(statement: sql) == false {
            return ([:], user_db.errorMessage())
        }
        
        var userInfo = [String: Any]()
        
        let results = user_db.storeResults()
        results?.forEachRow(callback: { (row) in
            row.enumerated().forEach({ (index, value) in
                if let val = value {
                    userInfo[values[index]] = val
                }
            })
        })
        
        return (userInfo, nil)
    }
    
    
    func updateUser(_ userId: String, values: [String: Any]) -> DBResult {
        var updateColumns = [String]()
        values.forEach { (key, val) in
            updateColumns.append("\(key) = '\(val)'")
        }
        let sql = "UPDATE user_tbl SET \(updateColumns.joined(separator: ",")) WHERE user_id = '\(userId)'"
        if user_db.query(statement: sql) {
            return (true, nil)
        } else {
            return (false, user_db.errorMessage())
        }
    }
}
