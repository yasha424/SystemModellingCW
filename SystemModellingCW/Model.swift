//
//  Model.swift
//  System Modelling
//
//  Created by yasha on 03.11.2023.
//

import Foundation

class Model<T> {
    private(set) var elements: [Element<T>]
    private(set) var tNext, tCurr: Double
    private var swapCount: Int = 0
    
    init(elements: [Element<T>]) {
        self.elements = elements
        tNext = 0
        tCurr = tNext
    }
        
    func simulate(forTime time: Double) {
        while tCurr < time {
            tNext = Double.greatestFiniteMagnitude
//            var nextEvent: Element<T>?
            for element in elements {
                if element.tNext < tNext {
                    tNext = element.tNext
//                    nextEvent = element
                }
            }
            
//            if let nextEvent {
//                print("\nIt's time for event in \(nextEvent.name), time = \(tNext)")
//            }
                        
            for element in elements {
                element.doStatistics(delta: tNext - tCurr)
            }
            
            tCurr = tNext
            for element in elements {
                element.tCurr = tCurr
            }
            
            for element in elements {
                if element.tNext == tCurr {
                    element.outAct()
                }
            }
//            printInfo()
        }
//        printResult()
    }
        
    func printInfo() {
        for element in elements {
            element.printInfo()
        }
    }
    
    func printResult() {
        print("\n-------------RESULTS-------------")
        for element in elements {
            element.printResult()
            if let process = element as? Process {
                print("Mean length of queue = \(process.meanQueue / tCurr)" +
                      "\nFailure probability = \(process.getFailureProbability())" +
                      "\nFailure = \(process.failure)" +
                      "\nMean load time = \(process.totalLoadTime / tCurr)")
            }
            print()
        }
        
        print("Mean items count = \(getMeanItemsCountInModel())" +
              "\nMean time between leaving = \(getMeanTimeBetweenLeaving())" +
              "\nMean item time in model = \(getMeanItemsTimeInModel())" +
              "\nFailure probabilty = \(getFailureProbability())" +
              "\nSwaps count = \(swapCount)"
        )
    }
    
    func getMeanItemsCountInModel() -> Double {
        return elements.filter { $0 is Process }.map { $0 as! Process }.reduce(0) { partialResult, process in
            return partialResult + (process.meanQueue + process.totalLoadTime) / tCurr
        }
    }
    
    func getMeanTimeBetweenLeaving() -> Double {
        let processes = elements.filter { $0 is Process }.map { $0 as! Process }
        return tCurr / processes.reduce(0) { partialResult, process in
            return partialResult + Double(process.quantity)
        }
    }
    
    func getMeanItemsTimeInModel() -> Double {
        let processes = elements.filter { $0 is Process }.map { $0 as! Process }
        let totalClientsTimeInBank = processes.reduce(0) { partialResult, process in
            return partialResult + process.totalLoadTime + process.meanQueue
        }
        let creator = elements.first(where: { $0 is Create }) as? Create
        return totalClientsTimeInBank / Double(creator?.quantity ?? 1)
    }
    
    func getFailureProbability() -> Double {
        let processes = elements.filter { $0 is Process }.map { $0 as! Process }
        guard !processes.isEmpty, !processes.contains(where: { $0.quantity == 0 }) else { return 0 }

        let sumOfFailureProbability = processes.reduce(0) {
            $0 + Double($1.failure) / Double($1.quantity + $1.failure)
        }
        return sumOfFailureProbability / Double(processes.count)
    }
    
}

