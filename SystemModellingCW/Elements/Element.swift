//
//  Element.swift
//  System Modelling
//
//  Created by yasha on 03.11.2023.
//

class ID {
    static private var id = -1
    
    static func getId() -> Int {
        id += 1
        return id
    }
}

class Element<T> {
    var name: String = ""
    var tNext: Double = Double.greatestFiniteMagnitude
    var delayMean: Double = 0
    var delayDev: Double = 0
    var distribution: Distribution = .exponential
    private(set) var quantity: Int = 0
    var tCurr: Double = 0
    var state: Int = 0
    var item: T? = nil
    var nextElements: [NextElement<T>]?
    let nextElementsChooseType: NextElementsChooseType
//    private(set) static var nextId: Int = 0
    private(set) var id: Int = 0
    
    
    init(chooseBy type: NextElementsChooseType) {
        nextElementsChooseType = type
        initWithDelay(1)
        name = "element\(id)"
    }
    
    init(delay: Double, name: String, chooseBy type: NextElementsChooseType) {
        nextElementsChooseType = type
        initWithDelay(delay)
        self.name = name
    }
    
    private func initWithDelay(_ delay: Double) {
        delayMean = delay
        id = ID.getId()
//        Element.nextId += 1
    }
    
    func inAct(_ item: T? = nil) {}
    
    func outAct() {
        quantity += 1
    }
    
    func getNextElement(_ item: T? = nil) -> NextElement<T>? {
        return getNextElement(by: nextElementsChooseType, item)
    }
    
    func getNextElement(by type: NextElementsChooseType, _ item: T?) -> NextElement<T>? {
        do {
            switch type {
            case .priority:
                return try getNextElementByPriority()
            case .probability:
                return try getNextElementByProbability()
            case .byQueueLength:
                return getNextElementByQueueLength()
            case .byCondition:
                return getNextElementByCondition(item)
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func getNextElementByCondition(_ item: T?) -> NextElement<T>? {
        guard let nextElements = nextElements, nextElements.count > 0 else { return nil }
        
        for nextElement in nextElements {
            if let condition = nextElement.condition, let item = item, condition(item) {
                return nextElement
            }
        }
        return nil
    }
    
    func getNextElementByQueueLength() -> NextElement<T>? {
        guard let nextElements = nextElements, nextElements.count > 0 else { return nil }
        
        let nextProcesses = nextElements.filter { $0.element is Process<T> }
        
        if let freeProcess = nextProcesses.first(where: {
            if let process = $0.element as? Process<T> {
                return process.queue.count == 0 && process.channelsStates.contains(0)
            }
            return false
        }) {
            return freeProcess
        }
        
        let sortedProcesses = nextProcesses.sorted {
            if let first = $0.element as? Process<T>, let second = $1.element as? Process<T> {
                return first.queue.count < second.queue.count
            }
            return true
        }
        
        return sortedProcesses.first
    }
    
    func getNextElementByPriority() throws -> NextElement<T>? {
        guard let nextElements = nextElements, nextElements.count > 0 else { return nil }
        
        if nextElements.contains(where: { $0.priority == nil }) {
            throw NextElementError.undefinedPriority
        }
        
        let sortedElements = nextElements.sorted(by: { $0.priority! > $1.priority! })
        for element in sortedElements {
            if element.element.isFree() {
                return element
            }
        }
        
        return sortedElements.first
    }
    
    func getNextElementByProbability() throws -> NextElement<T>? {
        guard let nextElements = nextElements, nextElements.count > 0 else { return nil }
        
        if nextElements.contains(where: { $0.probability == nil }) {
            throw NextElementError.undefinedProbability
        } else if !(0.9999999...1.0000001 ~= nextElements.reduce(0, { $0 + $1.probability! })) {
            throw NextElementError.probabilitySumNotEqualToOne
        }
        
        var sum = 0.0
        let randomValue = Double.random(in: 0...1)
        for nextElement in nextElements {
            sum += nextElement.probability!
            if randomValue <= sum {
                return nextElement
            }
        }
        
        return nil
    }
    
    func getDelay() -> Double {
        switch distribution {
        case .exponential:
            return FunRand.exponential(timeMean: delayMean)
        case .normal:
            return FunRand.normal(timeMean: delayMean, timeDeviation: delayDev)
        case .uniform:
            return FunRand.uniform(timeMin: delayMean, timeMax: delayDev)
        }
    }
    
    func printResult() {
        print("\(name), quantity = \(quantity)")
    }

    func printInfo() {
        print("\(name), state = \(state), quantity = \(quantity), tNext = \(tNext)")
    }
    
    func doStatistics(delta: Double) {}
    
    func isFree() -> Bool { return true }
}
