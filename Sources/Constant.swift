//
//  Constant.swift
//  SwiftTalk
//
//  Created by nchkdxlq on 2018/1/2.
//

import Foundation

enum ServerError: Int {
    case paramsError = 100401
    case systemInternalError = 100500
    case dbError = 100501
    
    
    func errorMessage() -> String {
        switch self {
        case .dbError:
            return "server db error"
        case .paramsError:
            return "less paramters"
        case .systemInternalError:
            return ""
        }
    }
}

//extension ServerError:

