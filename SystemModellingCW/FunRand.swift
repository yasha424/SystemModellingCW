//
//  FunRand.swift
//  System Modelling
//
//  Created by yasha on 03.11.2023.
//

import Darwin

struct FunRand {
    static func exponential(timeMean: Double) -> Double {
        var a = 0.0
        while a == 0.0 {
            a = Double.random(in: 0...1)
        }
        return -timeMean * log(a)
    }
    
    static func uniform(timeMin: Double, timeMax: Double) -> Double {
        var a = 0.0
        while a == 0.0 {
            a = Double.random(in: 0...1)
        }
        return timeMin + a * (timeMax - timeMin)
    }
    
    static func normal(timeMean: Double, timeDeviation: Double) -> Double {
        let x1 = Double.random(in: 0...1)
        let x2 = Double.random(in: 0...1)
        let z1 = sqrt(-2 * log(x1)) * cos(2 * Double.pi * x2) // z1 is normally distributed
        
        // конвертуємо z1 зі стандартоного нормального розподілу в наш нормальний розподіл
        return z1 * timeDeviation + timeMean
    }
    
    static func erlang(timeMean: Double, k: Int) -> Double {
        var product = 1.0
        for _ in 0..<k {
            product *= FunRand.uniform(timeMin: 0, timeMax: 1)
        }
        
        return -timeMean * log(product)
    }
    
    static func constant(_ time: Double) -> Double {
        return time
    }
}
